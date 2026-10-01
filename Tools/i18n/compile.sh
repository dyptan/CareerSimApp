#!/bin/sh
# Type-checks (or compiles) the whole app target headlessly — no Xcode build, no asset compiler.
#
#   Tools/i18n/compile.sh                 type-check Main/ for iOS (about 20 s); prints errors
#   Tools/i18n/compile.sh --strings DIR   also compile, writing one .stringsdata per source file into DIR
#
# ConfettiSwiftUI (the one package the app uses) is replaced by a stub module, so no package checkout
# is needed. Run from anywhere; it works on the checkout it lives in, so it is safe in a git worktree.
set -e
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
TMP="${TMPDIR:-/tmp}/i18n-compile-$(echo "$ROOT" | cksum | cut -d' ' -f1)"
mkdir -p "$TMP/stub" "$TMP/obj"
SDK=$(xcrun --sdk iphonesimulator --show-sdk-path)
TARGET=arm64-apple-ios16.6-simulator

if [ ! -f "$TMP/stub/ConfettiSwiftUI.swiftmodule" ]; then
  cat > "$TMP/stub/Confetti.swift" <<'SWIFT'
import SwiftUI
public extension View {
    func confettiCannon(counter: Binding<Int>, num: Int = 20, confettiSize: CGFloat = 10, radius: CGFloat = 300) -> some View { self }
}
SWIFT
  xcrun swiftc -emit-module -module-name ConfettiSwiftUI -sdk "$SDK" -target $TARGET \
    -emit-module-path "$TMP/stub/ConfettiSwiftUI.swiftmodule" -parse-as-library "$TMP/stub/Confetti.swift"
fi

FILES=$(find Main -name '*.swift')
if [ "$1" = "--strings" ]; then
  OUT="$2"; mkdir -p "$OUT"; rm -f "$OUT"/*.stringsdata
  # -c writes object files into the cwd.
  (cd "$TMP/obj" && xcrun swiftc -c -Onone -sdk "$SDK" -target $TARGET -module-name CareersApp -parse-as-library \
    -I "$TMP/stub" -emit-localized-strings -emit-localized-strings-path "$OUT" \
    $(for f in $FILES; do echo "$ROOT/$f"; done))
else
  xcrun swiftc -typecheck -sdk "$SDK" -target $TARGET -module-name CareersApp -parse-as-library -I "$TMP/stub" $FILES
fi
