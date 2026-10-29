#!/bin/bash
set -euo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
cd "$(dirname "$0")/.."
if ! command -v swiftlint >/dev/null 2>&1; then
    echo "error: SwiftLint is missing. Install it with: brew install swiftlint" >&2
    exit 127
fi
swiftlint lint --strict --no-cache --config .swiftlint.yml "$@"
