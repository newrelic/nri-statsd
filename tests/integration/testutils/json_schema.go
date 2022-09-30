/*
 * Copyright 2022 New Relic Corporation. All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 */

package testutils

import (
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"testing"

	"github.com/xeipuuv/gojsonschema"
)

var (
	errSchemaValidate = errors.New("provided json doesn't have expected format")
)

// ValidateJSONSchema checks if the jsonDocument match the provided schema file.
func ValidateJSONSchema(t *testing.T, schemaFileName, jsonDocument string) error {
	pwd, err := os.Getwd()
	if err != nil {
		return fmt.Errorf("failed to validate json schema, error: %w", err)
	}

	schemaURI := fmt.Sprintf("file://%s", filepath.Join(pwd, "data", schemaFileName))

	schemaLoader := gojsonschema.NewReferenceLoader(schemaURI)
	documentLoader := gojsonschema.NewStringLoader(jsonDocument)

	result, err := gojsonschema.Validate(schemaLoader, documentLoader)
	if err != nil {
		return fmt.Errorf("error loading JSON schema, error: %w", err)
	}

	if result.Valid() {
		return nil
	}

	t.Logf("Errors while validating json schema: '%s'\n", schemaURI)

	for _, desc := range result.Errors() {
		t.Logf("\t- %s\n", desc)
	}
	t.Log()
	return errSchemaValidate
}

// ValidationField is a struct used in JSON schema
type ValidationField struct {
	Keyword      string
	KeywordValue interface{}
}
