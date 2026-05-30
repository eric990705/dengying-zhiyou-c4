#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd "${ROOT_DIR}"
./tools/build_macos_demo.sh
open "${ROOT_DIR}/build/灯影智游.app"
