#!/bin/sh

set -e

# TODO: process math

prince --no-network -o "$BAKE_OUTPUT" "$BAKE_INPUT"

kde-open "$BAKE_OUTPUT"
