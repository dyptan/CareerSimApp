#!/bin/sh
# Xcode Cloud runs this automatically after cloning, before the build.
#
# The project carries a fixed CURRENT_PROJECT_VERSION, which is fine for
# building locally but means every archive would upload the same
# (MARKETING_VERSION, CFBundleVersion) pair. App Store Connect refuses a build
# whose pair it already holds, so the archive compiles cleanly and then fails
# at "Preparing build for App Store Connect" — on whichever platform had
# already consumed that number, which is why the failure appeared to move
# between iOS and macOS.
#
# CI_BUILD_NUMBER is unique and increasing per Xcode Cloud build, so stamping it
# in gives every upload its own build number. This only rewrites the working
# copy on the CI machine; nothing is committed.
set -e

: "${CI_BUILD_NUMBER:?CI_BUILD_NUMBER is not set — expected to run inside Xcode Cloud}"
cd "${CI_PRIMARY_REPOSITORY_PATH:?CI_PRIMARY_REPOSITORY_PATH is not set}"

xcrun agvtool new-version -all "$CI_BUILD_NUMBER"
echo "Build number set to $(xcrun agvtool what-version -terse)"
