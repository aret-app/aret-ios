#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
build_dir=$(mktemp -d)
trap 'rm -rf "$build_dir"' EXIT
swiftc -swift-version 6 -module-cache-path "$build_dir/modules" ARET-iOS/Storage/RecordingJournal.swift Tests/RecordingJournal/main.swift -o "$build_dir/journal-tests"
"$build_dir/journal-tests"
