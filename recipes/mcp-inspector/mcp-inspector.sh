#!/bin/sh
DIR="$(cd "$(dirname "$0")" && pwd)"
exec node "${DIR}/../lib/mcp-inspector/cli/build/cli.js" "$@"
