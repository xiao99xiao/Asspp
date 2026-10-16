#!/bin/bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/asspp-tv-tests.XXXXXX")"
trap 'rm -rf "$TEST_ROOT"' EXIT
cp -R "$REPO_ROOT/Resources/Tests/AppleTVSupport/." "$TEST_ROOT/"
# Compile the actual production model, without starting the app or opening Keychain.
cp "$REPO_ROOT/Asspp/Backend/AppStore/AppPackage.swift" "$TEST_ROOT/Sources/"
swift test --package-path "$TEST_ROOT" --scratch-path "$REPO_ROOT/.build/apple-tv-tests" "$@"
