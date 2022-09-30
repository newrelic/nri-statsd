/*
 * Copyright 2022 New Relic Corporation. All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 */

package testutils

import (
	"context"
	"fmt"
	"net"
	"net/http"
	"os"
	"testing"
	"time"

	"github.com/testcontainers/testcontainers-go"
	"github.com/testcontainers/testcontainers-go/wait"
)

const (
	HttpServerPort = "8081"
	StatsdPort     = "8125"
	Hostname       = "host.docker.internal"
	ImageName      = "newrelic/nri-statsd:test"
)

func GetPrjDir() string {
	return fmt.Sprintf("%s/../../", GetTestsDir())
}

func GetTestsDir() (testDir string) {
	var err error
	testDir, err = os.Getwd()
	if err != nil {
		panic(err)
	}
	return
}

func StartHttpServer(t *testing.T, handler func(http.ResponseWriter, *http.Request)) *http.Server {
	srv := &http.Server{Addr: ":" + HttpServerPort}

	http.HandleFunc("/metrics", handler)

	go func() {
		// always returns error. ErrServerClosed on graceful close
		if err := srv.ListenAndServe(); err != http.ErrServerClosed {
			// unexpected error. port in use?
			t.Logf("Failed to start http server, error: %v", err)
		}
	}()

	return srv
}

// RunStatsdContainer will start a container running nri-statsd with newrelic backend configured.
func RunStatsdContainer(t *testing.T, ctx context.Context) (testcontainers.Container, error) {

	req := testcontainers.ContainerRequest{
		ImagePlatform:   getImagePlatform(),
		Image:           ImageName,
		AlwaysPullImage: false,
		ExposedPorts: []string{
			fmt.Sprintf("%[1]s:%[1]s/udp", StatsdPort),
		},
		ExtraHosts: []string{
			Hostname + ":host-gateway",
		},
		Env: map[string]string{
			"NR_API_KEY":               "abcd",
			"NR_ACCOUNT_ID":            "12345667",
			"NR_ENDPOINT_METRICS_ADDR": fmt.Sprintf("http://%s:%s/metrics", Hostname, HttpServerPort),
			"NR_STATSD_VERBOSE":        "1",
		},

		WaitingFor: wait.ForLog("Initialised backend"),
	}

	container, err := testcontainers.GenericContainer(ctx, testcontainers.GenericContainerRequest{
		ContainerRequest: req,
		Started:          true,
	})

	if err != nil {
		return nil, err
	}

	container.StartLogProducer(ctx)
	container.FollowOutput(&TestLogConsumer{
		t: t,
	})
	return container, err
}

// TestLogConsumer is used to print container logs to stdout.
type TestLogConsumer struct {
	t *testing.T
}

func (g *TestLogConsumer) Accept(l testcontainers.Log) {
	g.t.Logf("[CONTAINER LOG] %s %s\n", time.Now().Format("2006/01/02 15:04:05"), l.Content)
}

func SendUDPMessage(address, message string) error {
	conn, err := net.Dial("udp", address)
	if err != nil {
		return fmt.Errorf("failed to send UDP message, error: %w", err)
	}
	defer func() {
		conn.Close()
	}()

	fmt.Fprint(conn, message)
	return nil
}

func GetHostname() string {
	if isRunningInDockerContainer() {
		return Hostname
	}
	return "0.0.0.0"
}

func isRunningInDockerContainer() bool {
	// docker creates a .dockerenv file at the root
	// of the directory tree inside the container.
	// if this file exists then the viewer is running
	// from inside a container so return true

	_, err := os.Stat("/.dockerenv")
	return err == nil
}

func getImagePlatform() string {
	platform := os.Getenv("DOCKER_DEFAULT_PLATFORM")
	if platform != "" {
		return platform
	}
	return "linux/amd64"
}
