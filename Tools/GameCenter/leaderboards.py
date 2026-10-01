#!/usr/bin/env python3
"""The game's Game Center leaderboards: one per country, each named in all six languages.

A run is scored as net worth ÷ age in the country's own money (`Player.leaderboardScore`), so a euro board and a
dollar board cannot be compared and every country has a board of its own (`Country.leaderboardID`):

    dev.dyptan.carrersim.wealth_velocity          United States (the original board)
    dev.dyptan.carrersim.wealth_velocity_<suffix> every other country

    leaderboards.py list                 print the 18 boards with their localizations
    leaderboards.py check                verify the table matches Main/Models/Country.swift (run in CI / before a release)
    leaderboards.py json                 write the boards as JSON (for review or other tooling)
    leaderboards.py create [--apply]     create the boards and their localizations in App Store Connect through the
                                         App Store Connect API.  Without --apply it only prints the requests.

`create --apply` needs an App Store Connect API key (Users and Access ▸ Integrations ▸ App Store Connect API) with
the App Manager role, passed through the environment — nothing is stored:

    ASC_KEY_ID=ABC123DEFG  ASC_ISSUER_ID=69a6de...-....  ASC_KEY_PATH=~/AuthKey_ABC123DEFG.p8
    ASC_APP_ID=<numeric Apple ID of the app, App Store Connect ▸ App Information>      (or ASC_BUNDLE_ID=dev.dyptan.carrersim)

It is idempotent: boards whose vendor identifier already exists are skipped, missing localizations are added.
Boards are created as drafts: a leaderboard goes live with the next app version you submit (App Store Connect ▸
the version ▸ Game Center ▸ add the leaderboards).  Standard library only; the JWT is signed with the `openssl` CLI.
"""
import base64
import json
import os
import re
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
BASE_ID = "dev.dyptan.carrersim.wealth_velocity"
LANGS = ["en", "de", "fr", "it", "ja", "uk"]
# App Store Connect locale codes for Game Center localizations.
ASC_LOCALE = {"en": "en-US", "de": "de-DE", "fr": "fr-FR", "it": "it", "ja": "ja", "uk": "uk"}

# "Wealth velocity": net worth per year of age. Name pattern per language (the country name is appended).
NAME = {
    "en": "Wealth Velocity – {country}",
    "de": "Vermögenstempo – {country}",
    "fr": "Vitesse d’enrichissement – {country}",
    "it": "Velocità di arricchimento – {country}",
    "ja": "資産スピード – {country}",
    "uk": "Швидкість накопичення – {country}",
}
DESCRIPTION = {
    "en": "Net worth divided by age at retirement, in local money. Get rich younger to rank higher.",
    "de": "Vermögen geteilt durch das Alter beim Ruhestand, in Landeswährung. Wer früher reich wird, steht weiter oben.",
    "fr": "Patrimoine divisé par l’âge à la retraite, dans la monnaie du pays. Plus on s’enrichit jeune, plus on monte.",
    "it": "Patrimonio diviso per l’età alla pensione, nella valuta locale. Più giovane diventi ricco, più sali.",
    "ja": "引退時の純資産を年齢で割った値(現地通貨)。若くして豊かになるほど上位に入ります。",
    "uk": "Статок, поділений на вік під час виходу на пенсію, у місцевій валюті. Чим раніше розбагатієш, тим вище місце.",
}
# Shown after the score: "<currency> per year (of age)".
PER_YEAR = {"en": "/yr", "de": "/Jahr", "fr": "/an", "it": "/anno", "ja": "/年", "uk": "/рік"}

# suffix, currency symbol, and the country's name in each language
COUNTRIES = [
    ("", "$", dict(en="United States", de="Vereinigte Staaten", fr="États-Unis", it="Stati Uniti", ja="アメリカ合衆国", uk="США")),
    ("ca", "C$", dict(en="Canada", de="Kanada", fr="Canada", it="Canada", ja="カナダ", uk="Канада")),
    ("uk", "£", dict(en="United Kingdom", de="Vereinigtes Königreich", fr="Royaume-Uni", it="Regno Unito", ja="イギリス", uk="Велика Британія")),
    ("fr", "€", dict(en="France", de="Frankreich", fr="France", it="Francia", ja="フランス", uk="Франція")),
    ("de", "€", dict(en="Germany", de="Deutschland", fr="Allemagne", it="Germania", ja="ドイツ", uk="Німеччина")),
    ("it", "€", dict(en="Italy", de="Italien", fr="Italie", it="Italia", ja="イタリア", uk="Італія")),
    ("jp", "¥", dict(en="Japan", de="Japan", fr="Japon", it="Giappone", ja="日本", uk="Японія")),
    ("ua", "₴", dict(en="Ukraine", de="Ukraine", fr="Ukraine", it="Ucraina", ja="ウクライナ", uk="Україна")),
    ("au", "A$", dict(en="Australia", de="Australien", fr="Australie", it="Australia", ja="オーストラリア", uk="Австралія")),
    ("br", "R$", dict(en="Brazil", de="Brasilien", fr="Brésil", it="Brasile", ja="ブラジル", uk="Бразилія")),
    ("cn", "CN¥", dict(en="China", de="China", fr="Chine", it="Cina", ja="中国", uk="Китай")),
    ("in", "₹", dict(en="India", de="Indien", fr="Inde", it="India", ja="インド", uk="Індія")),
    ("mx", "MX$", dict(en="Mexico", de="Mexiko", fr="Mexique", it="Messico", ja="メキシコ", uk="Мексика")),
    ("pl", "zł", dict(en="Poland", de="Polen", fr="Pologne", it="Polonia", ja="ポーランド", uk="Польща")),
    ("es", "€", dict(en="Spain", de="Spanien", fr="Espagne", it="Spagna", ja="スペイン", uk="Іспанія")),
    ("se", "kr", dict(en="Sweden", de="Schweden", fr="Suède", it="Svezia", ja="スウェーデン", uk="Швеція")),
    ("tr", "₺", dict(en="Turkey", de="Türkei", fr="Turquie", it="Turchia", ja="トルコ", uk="Туреччина")),
    ("kr", "₩", dict(en="South Korea", de="Südkorea", fr="Corée du Sud", it="Corea del Sud", ja="韓国", uk="Південна Корея")),
]


def boards():
    out = []
    for suffix, symbol, names in COUNTRIES:
        vendor = BASE_ID + ("_" + suffix if suffix else "")
        out.append({
            "vendorIdentifier": vendor,
            "referenceName": "Wealth velocity – " + names["en"],
            "defaultFormatter": "INTEGER",
            "submissionType": "BEST_SCORE",
            "scoreSortType": "DESC",
            "localizations": {
                lang: {
                    "locale": ASC_LOCALE[lang],
                    "name": NAME[lang].format(country=names[lang]),
                    "description": DESCRIPTION[lang],
                    # " €/Jahr": the suffix follows the number, so it carries the space.
                    "formatterSuffix": " " + symbol + PER_YEAR[lang],
                    "formatterSuffixSingular": " " + symbol + PER_YEAR[lang],
                }
                for lang in LANGS
            },
        })
    return out


def check():
    src = open(os.path.join(ROOT, "Main", "Models", "Country.swift"), encoding="utf-8").read()
    code = sorted(set(re.findall(r'leaderboardSuffix:\s*"([a-z]*)"', src)))
    table = sorted(s for s, _, _ in COUNTRIES)
    ok = True
    if code != table:
        ok = False
        print("Country.swift suffixes :", code)
        print("leaderboards.py suffixes:", table)
        print("MISSING here:", sorted(set(code) - set(table)), " EXTRA here:", sorted(set(table) - set(code)))
    for b in boards():
        for lang, loc in b["localizations"].items():
            if len(loc["name"]) > 64:
                ok = False
                print("name over 64 characters:", b["vendorIdentifier"], lang, loc["name"])
            if len(loc["description"]) > 255:
                ok = False
                print("description over 255 characters:", b["vendorIdentifier"], lang)
    print(f"{len(COUNTRIES)} boards x {len(LANGS)} languages;", "consistent with Country.swift" if ok else "PROBLEMS above")
    return ok


# --------------------------------------------------------------- App Store Connect

API = "https://api.appstoreconnect.apple.com"


def b64(data):
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode()


def der_to_raw(der):
    """An ECDSA DER signature to the 64-byte r||s form JWT wants."""
    assert der[0] == 0x30
    i = 2 if der[1] < 0x80 else 2 + (der[1] & 0x7F)
    parts = []
    for _ in range(2):
        assert der[i] == 0x02
        n = der[i + 1]
        parts.append(der[i + 2 : i + 2 + n].lstrip(b"\x00").rjust(32, b"\x00"))
        i += 2 + n
    return parts[0] + parts[1]


def token():
    import time
    key_id, issuer = os.environ["ASC_KEY_ID"], os.environ["ASC_ISSUER_ID"]
    key_path = os.path.expanduser(os.environ["ASC_KEY_PATH"])
    header = b64(json.dumps({"alg": "ES256", "kid": key_id, "typ": "JWT"}).encode())
    now = int(time.time())
    claims = b64(json.dumps({"iss": issuer, "iat": now, "exp": now + 15 * 60, "aud": "appstoreconnect-v1"}).encode())
    signing_input = f"{header}.{claims}".encode()
    der = subprocess.run(["openssl", "dgst", "-sha256", "-sign", key_path], input=signing_input, capture_output=True, check=True).stdout
    return f"{header}.{claims}.{b64(der_to_raw(der))}"


def call(method, path, body=None, tok=None):
    req = urllib.request.Request(API + path, method=method, data=json.dumps(body).encode() if body else None)
    req.add_header("Authorization", "Bearer " + tok)
    req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req) as r:
            return json.load(r)
    except urllib.error.HTTPError as e:
        sys.exit(f"{method} {path} -> {e.code}: {e.read().decode()[:600]}")


def create(apply):
    all_boards = boards()
    if not apply:
        print("DRY RUN — nothing is sent. Re-run with --apply (and the ASC_* environment) to create the boards.\n")
        for b in all_boards:
            print(json.dumps({"POST /v1/gameCenterLeaderboards": {k: v for k, v in b.items() if k != "localizations"}}, ensure_ascii=False))
            for lang, loc in b["localizations"].items():
                print("   ", json.dumps({"POST /v1/gameCenterLeaderboardLocalizations": loc}, ensure_ascii=False))
        print(f"\n{len(all_boards)} leaderboards, {len(all_boards) * len(LANGS)} localizations")
        return
    tok = token()
    app_id = os.environ.get("ASC_APP_ID")
    if not app_id:
        q = urllib.parse.quote(os.environ["ASC_BUNDLE_ID"])
        app_id = call("GET", f"/v1/apps?filter[bundleId]={q}", tok=tok)["data"][0]["id"]
    detail = call("GET", f"/v1/apps/{app_id}/gameCenterDetail", tok=tok)["data"]["id"]
    existing = {}
    nxt = f"/v1/gameCenterDetails/{detail}/gameCenterLeaderboards?limit=200"
    while nxt:
        page = call("GET", nxt, tok=tok)
        for item in page["data"]:
            existing[item["attributes"]["vendorIdentifier"]] = item["id"]
        nxt = page.get("links", {}).get("next", "").replace(API, "") or None
    for b in all_boards:
        vendor = b["vendorIdentifier"]
        if vendor in existing:
            lid = existing[vendor]
            print("exists ", vendor)
        else:
            attrs = {k: v for k, v in b.items() if k != "localizations"}
            body = {"data": {"type": "gameCenterLeaderboards", "attributes": attrs,
                             "relationships": {"gameCenterDetail": {"data": {"type": "gameCenterDetails", "id": detail}}}}}
            lid = call("POST", "/v1/gameCenterLeaderboards", body, tok)["data"]["id"]
            print("created", vendor)
        have = set()
        page = call("GET", f"/v1/gameCenterLeaderboards/{lid}/localizations?limit=50", tok=tok)
        for item in page["data"]:
            have.add(item["attributes"]["locale"])
        for lang, loc in b["localizations"].items():
            if loc["locale"] in have:
                continue
            body = {"data": {"type": "gameCenterLeaderboardLocalizations", "attributes": loc,
                             "relationships": {"gameCenterLeaderboard": {"data": {"type": "gameCenterLeaderboards", "id": lid}}}}}
            call("POST", "/v1/gameCenterLeaderboardLocalizations", body, tok)
            print("   + localization", loc["locale"])


def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else ""
    if cmd == "list":
        for b in boards():
            print(b["vendorIdentifier"])
            for lang, loc in b["localizations"].items():
                print(f"   {loc['locale']:6} {loc['name']}   [{loc['formatterSuffix'].strip()}]")
    elif cmd == "check":
        sys.exit(0 if check() else 1)
    elif cmd == "json":
        path = os.path.join(ROOT, "Tools", "GameCenter", "leaderboards.json")
        with open(path, "w", encoding="utf-8") as fh:
            json.dump(boards(), fh, ensure_ascii=False, indent=2)
            fh.write("\n")
        print("wrote", path)
    elif cmd == "create":
        create("--apply" in sys.argv)
    else:
        print(__doc__)
        sys.exit(2)


if __name__ == "__main__":
    main()
