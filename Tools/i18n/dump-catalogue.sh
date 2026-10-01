#!/bin/sh
# Regenerates the job-catalogue key list for translators from the catalogue itself — run it after adding,
# renaming or rewording a job (CareerGraphTests fails when the file is behind the catalogue).
#
#   Tools/i18n/dump-catalogue.sh            # writes Tools/i18n/translations/en/Catalogue-jobs.json
#
# It compiles the model layer and the job catalogue headlessly (the same way as Tools/BalanceSim/run-tests.sh)
# with Tools/i18n/DumpCatalogue/main.swift, which prints every job's title, base title, seniority word,
# summary and experience-ladder name as `{"table": "Catalogue", "strings": {"job.title.Cashier": "Cashier", …}}`.
set -e
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
OUT_JSON="Tools/i18n/translations/en/Catalogue-jobs.json"
BIN="${TMPDIR:-/tmp}/dump-catalogue-$(echo "$ROOT" | cksum | cut -d' ' -f1)"
mkdir -p "$(dirname "$OUT_JSON")"
# shellcheck disable=SC2046
xcrun swiftc -module-name CareersApp -Onone -o "$BIN" \
  $(ls Main/Models/*.swift | grep -v GameCenterManager) Main/Resources/JobCatalog.swift \
  Tools/BalanceSim/ViewStubs.swift Tools/i18n/DumpCatalogue/main.swift
"$BIN" "$OUT_JSON"
