#!/bin/sh
# Refreshes Main/Resources/Localizable.xcstrings from the Swift sources, without the Xcode IDE.
#
#   Tools/i18n/refresh-catalog.sh
#       builds the app into build/i18n-dd with string extraction on, then syncs the catalog
#   I18N_SKIP_BUILD=1 I18N_DERIVED_DATA=<DerivedData> Tools/i18n/refresh-catalog.sh
#       syncs from an existing build (CI, or a build made by another tool)
#
# Why a script: the IDE syncs the catalog itself on every build, but xcodebuild never does.
# The compiler writes a .stringsdata file per source file; `xcstringstool sync` merges them.
# A fresh derived-data folder matters: a partial set of .stringsdata files makes sync mark
# live strings stale. Review `git diff Main/Resources/Localizable.xcstrings` afterwards.
set -e
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
DD="${I18N_DERIVED_DATA:-build/i18n-dd}"

if [ -z "$I18N_SKIP_BUILD" ]; then
  rm -rf "$DD"
  xcodebuild -project CareersApp.xcodeproj -scheme CareersApp \
    -destination 'generic/platform=iOS Simulator' -configuration Debug \
    -derivedDataPath "$DD" -skipMacroValidation \
    SWIFT_EMIT_LOC_STRINGS=YES CODE_SIGNING_ALLOWED=NO build
fi

# Only the app target's files: CareersApp.build, not CareersAppTests.build or a package's.
set --
while IFS= read -r f; do
  [ -n "$f" ] && set -- "$@" "$f"
done <<LIST
$(find "$DD/Build/Intermediates.noindex" -path '*/CareersApp.build/Objects-normal/*' -name '*.stringsdata')
LIST

if [ "$#" -eq 0 ]; then
  echo "No .stringsdata files under $DD - is SWIFT_EMIT_LOC_STRINGS on and the build fresh?" >&2
  exit 1
fi
echo "Syncing $# .stringsdata files into Main/Resources/Localizable.xcstrings" >&2
xcrun xcstringstool sync Main/Resources/Localizable.xcstrings --stringsdata "$@"
git --no-pager diff --stat -- Main/Resources/Localizable.xcstrings || true
