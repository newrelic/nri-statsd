package integrations

import (
	"compress/gzip"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
	"test/testutils"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"github.com/stretchr/testify/suite"
	"github.com/testcontainers/testcontainers-go"
)

const (
	schemaFileName = "metrics-schema.json"
	timeout        = 5 * time.Minute
)

type StatsdTestSuite struct {
	suite.Suite
	container testcontainers.Container
	ctx       context.Context
	cancelFn  context.CancelFunc
}

func TestStatsdSuite(t *testing.T) {
	ctx, cancelFn := context.WithCancel(context.Background())

	suite.Run(t, &StatsdTestSuite{
		ctx:      ctx,
		cancelFn: cancelFn,
	})
}

func (s *StatsdTestSuite) SetupSuite() {
	t := s.T()
	var err error
	s.container, err = testutils.RunStatsdContainer(t, s.ctx)

	require.NoError(t, err)
}

func (s *StatsdTestSuite) TearDownSuite() {
	err := s.container.StopLogProducer()
	assert.NoError(s.T(), err)

	err = s.container.Terminate(s.ctx)
	assert.NoError(s.T(), err)
}

func (s *StatsdTestSuite) TestStatsdPayload() {
	t := s.T()

	response := make(chan string, 100)

	// HTTP handler to intercepts requests made by statsd service.
	httpHandler := func(w http.ResponseWriter, r *http.Request) {
		gr, err := gzip.NewReader(r.Body)
		assert.NoError(t, err)
		defer gr.Close()

		var body interface{}
		assert.NoError(t, json.NewDecoder(gr).Decode(&body))

		jsonBody, err := json.Marshal(body)
		assert.NoError(t, err)

		response <- string(jsonBody)
		w.WriteHeader(http.StatusAccepted)
	}

	// Initialize a http server to retrieve metrics from statsd.
	server := testutils.StartHttpServer(t, httpHandler)
	defer func() {
		assert.NoError(t, server.Shutdown(s.ctx))
	}()

	metrics := []string{
		"prod.test.counter:1|c",
		"prod.test.counter:22|c",
		"prod.test.counter:1|c|@0.1",
		"prod.test.num:32|g",
		"prod.test.num2:13|g",
	}

	// Send metrics to statsd via UDP connection.
	go func() {
		for _, metric := range metrics {
			err := testutils.SendUDPMessage(fmt.Sprintf("%s:%s", testutils.GetHostname(), testutils.StatsdPort), metric)
			assert.NoError(t, err)
		}
	}()

	go func() {
		<-time.After(timeout)
		s.cancelFn()
	}()

	// waiting for 2 payloads.
	payloads := make([]string, 2)

	for i := range payloads {
		select {
		case jsonBody := <-response:
			t.Logf("Received payload: %v", jsonBody)
			assert.NoError(t, testutils.ValidateJSONSchema(t, schemaFileName, jsonBody))
			payloads[i] = jsonBody

		case <-s.ctx.Done():
			assert.Fail(t, "Failed to receive payload from statsd integration")
		}
	}

	assertReceivedMetrics(t, payloads, metrics)
}

// assertMetrics check if received payloads contains the provided statsd metrics.
// we need to check in multiple payloads because of they way metrics are processed by statsd.
func assertReceivedMetrics(t *testing.T, playloads []string, metrics []string) bool {
	for _, metric := range metrics {

		metricName := strings.Split(metric, ":")[0]

		found := false
		for _, payload := range playloads {
			if strings.Contains(payload, metricName) {
				found = true
				break
			}
		}

		assert.Truef(t, found, "Metric %s not found in payloads", metric)
	}
	return false
}
