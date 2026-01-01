#!/bin/bash
# CClean-Killer - Test Runner Entry Point
# Simple wrapper for npm test compatibility

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

exec "$SCRIPT_DIR/framework/test-runner.sh" "$@"
