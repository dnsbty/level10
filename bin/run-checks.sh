#!/usr/bin/env sh

set -e

mix format --check-formatted
mix credo --strict
mix test
