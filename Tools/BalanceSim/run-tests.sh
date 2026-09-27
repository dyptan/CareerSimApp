#!/bin/sh
# Runs CareersAppTests without Xcode: builds the model layer + the test files
# into a macOS XCTest bundle (views stubbed by ViewStubs.swift) and runs it.
# Useful where `xcodebuild test` can't run (e.g. a sandbox where actool hangs).
# Usage: Tools/BalanceSim/run-tests.sh   (output bundle goes to $TMPDIR)
set -e
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT="${TMPDIR:-/tmp}/careers-xctest"
PLAT=$(xcrun --sdk macosx --show-sdk-platform-path)
mkdir -p "$OUT/CareersTests.xctest/Contents/MacOS"
cd "$ROOT"
xcrun swiftc -module-name CareersApp -parse-as-library -Onone -Xlinker -bundle \
  -o "$OUT/CareersTests.xctest/Contents/MacOS/CareersTests" \
  -F "$PLAT/Developer/Library/Frameworks" -I "$PLAT/Developer/usr/lib" -L "$PLAT/Developer/usr/lib" \
  -Xlinker -rpath -Xlinker "$PLAT/Developer/Library/Frameworks" -Xlinker -rpath -Xlinker "$PLAT/Developer/usr/lib" \
  -framework XCTest -lXCTestSwiftSupport \
  $(ls Main/Models/*.swift | grep -v GameCenterManager) Main/Resources/JobCatalog.swift \
  Tools/BalanceSim/ViewStubs.swift CareersAppTests/*.swift
xcrun xctest "$OUT/CareersTests.xctest" 2>&1 | grep -E "error:|Executed .* tests" | tail -25
