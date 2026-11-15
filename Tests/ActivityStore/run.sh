#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
build_dir=$(mktemp -d)
trap 'rm -rf "$build_dir"' EXIT
library_extension=so
if [[ $(uname -s) == Darwin ]]; then library_extension=dylib; fi
swiftc -swift-version 6 -module-cache-path "$build_dir/modules" -emit-module -module-name Combine Tests/ActivityStore/Combine.swift -emit-module-path "$build_dir/Combine.swiftmodule" -emit-library -o "$build_dir/libCombine.$library_extension"
swiftc -swift-version 6 -module-cache-path "$build_dir/modules" -I "$build_dir" -L "$build_dir" -lCombine ARET-iOS/Storage/ActivityStore.swift Tests/ActivityStore/main.swift -o "$build_dir/activity-tests"
LD_LIBRARY_PATH="$build_dir:${LD_LIBRARY_PATH:-}" DYLD_LIBRARY_PATH="$build_dir:${DYLD_LIBRARY_PATH:-}" "$build_dir/activity-tests"
