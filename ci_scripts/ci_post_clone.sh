#!/bin/sh
# Xcode Cloud runs this automatically after cloning, before the build.
#
# The project carries a fixed CURRENT_PROJECT_VERSION, which is fine for
# building locally but means every archive would offer App Store Connect the
# same (MARKETING_VERSION, CFBundleVersion) pair. It refuses a pair it already
# holds, so the archive compiles cleanly and then fails at "Preparing build for
# App Store Connect" — on whichever platform had already consumed that number,
# which is why the failure appeared to move between iOS and macOS.
#
# CI_BUILD_NUMBER is unique and increasing per Xcode Cloud build, so stamping it
# in gives every upload its own build number. Only the CI working copy is
# rewritten; nothing is committed and local builds are untouched.
#
# Nothing here is fatal. A missing variable or an agvtool failure means the
# build keeps its project-file version — the same position as before this
# script existed — rather than failing the whole run at the clone step.
set -u

if [ -z "${CI_BUILD_NUMBER:-}" ] || [ -z "${CI_PRIMARY_REPOSITORY_PATH:-}" ]; then
    echo "warning: CI_BUILD_NUMBER / CI_PRIMARY_REPOSITORY_PATH not set — leaving the build number as the project file has it."
    exit 0
fi

cd "$CI_PRIMARY_REPOSITORY_PATH" || exit 0

if xcrun agvtool new-version -all "$CI_BUILD_NUMBER"; then
    echo "Build number set to $(xcrun agvtool what-version -terse)"
else
    echo "warning: agvtool could not set the build number; leaving it as the project file has it."
fi
