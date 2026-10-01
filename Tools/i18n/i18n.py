#!/usr/bin/env python3
"""Localisation tooling for CareersApp.  See Tools/i18n/README.md.

    i18n.py extract                 compile the app headlessly; write .stringsdata into the scratch dir
    i18n.py skeleton LANG [FILE.swift ...] -o OUT.json
                                    the catalog keys (of those files, or all) that have no LANG translation
                                    yet, as a JSON file to fill in
    i18n.py chunks LANG NL NC OUTDIR  split what LANG still lacks into NL Localizable and NC Catalogue work files,
                                    each ready to fill in: "strings" values are "" and "_context" explains
    i18n.py lint FILE.json... [--chunk WORK.json]
                                    validate translation file(s) as a translator would: every key filled, placeholders and
                                    plural forms right for the language (from the folder or file name); with --chunk, also
                                    that the files together cover every key of that work file
    i18n.py check [-v]              validate every translations/**/*.json; after `extract`, report coverage
    i18n.py verify                  the shipped catalogs themselves: every live string has all five translations
                                    with matching placeholders and plural forms (fast, no compile; used by CI)
    i18n.py build                   extract + sync Localizable.xcstrings + apply the translations
    i18n.py apply                   apply the translations to the catalogs without re-extracting
    i18n.py audit [--words] [FILE.swift ...]
                                    list string literals that look like user-visible English but are
                                    not localized (nothing extracted for them)

Translations are one folder per language, any number of files each:  Tools/i18n/translations/<lang>/*.json

    { "table": "Localizable",                    // or "Catalogue"; default Localizable
      "strings": {
        "Hello %@": "Hallo %@",
        "%lld years": { "one": "%lld Jahr", "other": "%lld Jahre" }     // a plural: one/few/many/other
      } }

Keys that vary with a count are declared once, in English, in translations/en/*.json as an object of
variants ("%lld years": {"one": "%lld year", "other": "%lld years"}); every language must then give an
object too (uk: one/few/many/other, fr and it: one/other [+ many], de: one/other, ja: other).
Keys with two or more placeholders must use positional specifiers in every translation (%1$@ %2$lld).
A plural key has exactly one %lld; format other numbers to Strings (Fmt) and pass them as %@.
For the Catalogue table the key is a namespaced id ("job.title.Cashier"); translations/en/ holds its English text.
"""
import glob
import zlib
import json
import os
import re
import subprocess
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
TRANSLATIONS = os.path.join(ROOT, "Tools", "i18n", "translations")
CATALOGS = {
    "Localizable": os.path.join(ROOT, "Main", "Resources", "Localizable.xcstrings"),
    "Catalogue": os.path.join(ROOT, "Main", "Resources", "Catalogue.xcstrings"),
}
LANGS = ["de", "fr", "it", "ja", "uk"]
PLURAL_REQUIRED = {
    "en": {"one", "other"},
    "de": {"one", "other"},
    "fr": {"one", "other"},
    "it": {"one", "other"},
    "ja": {"other"},
    "uk": {"one", "few", "many", "other"},
}
PLURAL_ALLOWED = {
    "en": {"one", "other"},
    "de": {"one", "other"},
    "fr": {"one", "many", "other"},
    "it": {"one", "many", "other"},
    "ja": {"other"},
    "uk": {"one", "few", "many", "other"},
}


def scratch_dir():
    base = os.environ.get("I18N_SCRATCH") or os.path.join(
        os.environ.get("TMPDIR", "/tmp"), "i18n-strings-%d" % zlib.crc32(ROOT.encode())
    )
    return base


# ---------------------------------------------------------------- placeholders

SPEC = re.compile(r"%(?:(\d+)\$)?[-+0]*\d*(?:\.\d+)?(?:hh|h|ll|l|z|q|L|t|j)?([@dDiuUfFs])|%%")  # a bare "% a" in prose ("30% a year") is not a placeholder


def specs(text):
    """The placeholders of a format string, in order: [(position or None, class)]."""
    out = []
    for m in SPEC.finditer(text):
        if m.group(0) == "%%":
            continue
        conv = m.group(3)
        cls = "obj" if conv in "@sS" else "float" if conv in "fF" else "int"
        out.append((int(m.group(1)) if m.group(1) else None, cls))
    return out


def check_placeholders(key, text, label, errors):
    want = specs(key)
    got = specs(text)
    positional = [g for g in got if g[0] is not None]
    if len(want) >= 2 and got and not positional:
        errors.append(f"{label}: '{key}' has {len(want)} placeholders; the translation must use positional ones (%1$@, %2$lld)")
        return
    if positional:
        if len(positional) != len(got):
            errors.append(f"{label}: '{key}' mixes positional and plain placeholders")
            return
        for pos, cls in got:
            if pos < 1 or pos > len(want) or want[pos - 1][1] != cls:
                errors.append(f"{label}: '{key}' placeholder %{pos}$ has the wrong type or index in '{text}'")
                return
    else:
        if [g[1] for g in got] != [w[1] for w in want] and not (len(got) <= len(want) and [g[1] for g in got] == [w[1] for w in want][: len(got)] and "plural" in label):
            errors.append(f"{label}: '{key}' placeholders {[g[1] for g in got]} do not match the key's {[w[1] for w in want]}: '{text}'")


# ---------------------------------------------------------------- translations

def load_translation_files():
    """[(path, lang, table, strings)]"""
    out = []
    for f in sorted(glob.glob(os.path.join(TRANSLATIONS, "*", "*.json"))):
        lang = os.path.basename(os.path.dirname(f))
        with open(f, encoding="utf-8") as fh:
            data = json.load(fh)
        out.append((f, lang, data.get("table", "Localizable"), data.get("strings", {})))
    return out


def merged_translations(errors):
    """{table: {key: {lang: value}}}"""
    merged = {}
    origin = {}
    for f, lang, table, strings in load_translation_files():
        for key, value in strings.items():
            slot = merged.setdefault(table, {}).setdefault(key, {})
            if lang in slot:
                if slot[lang] != value:
                    errors.append(f"{os.path.relpath(f, ROOT)}: '{key}' [{lang}] is also in {origin[(table, key, lang)]} with different text")
                continue
            slot[lang] = value
            origin[(table, key, lang)] = os.path.relpath(f, ROOT)
    return merged


def validate_all(merged, errors):
    for table, strings in merged.items():
        for key, langs in strings.items():
            if table == "Catalogue":
                for lang in LANGS + ["en"]:
                    if lang not in langs:
                        errors.append(f"Catalogue '{key}' has no '{lang}'")
                for lang, value in langs.items():
                    if not isinstance(value, str) or not value.strip():
                        errors.append(f"Catalogue '{key}' [{lang}] must be a non-empty string")
                continue
            plural = isinstance(langs.get("en"), dict)
            if "en" in langs and not plural:
                errors.append(f"'{key}' [en]: English entries exist only to declare plural variants (an object)")
            for lang, value in langs.items():
                if lang not in LANGS + ["en"]:
                    errors.append(f"'{key}' has unknown language '{lang}'")
                    continue
                label = f"[{lang}]"
                if plural and not isinstance(value, dict):
                    errors.append(f"'{key}' {label} is a plural in English, so it needs plural variants")
                elif not plural and isinstance(value, dict):
                    errors.append(f"'{key}' {label} has plural variants but English does not declare '{key}' a plural")
                if isinstance(value, dict):
                    cats = set(value)
                    if not cats <= PLURAL_ALLOWED[lang] or not PLURAL_REQUIRED[lang] <= cats:
                        errors.append(f"'{key}' {label} plural categories {sorted(cats)}; need {sorted(PLURAL_REQUIRED[lang])}")
                    for cat, text in value.items():
                        if not isinstance(text, str) or not text.strip():
                            errors.append(f"'{key}' {label}.{cat} is empty")
                        else:
                            check_placeholders(key, text, f"'{key}' {label}.{cat} plural", errors)
                else:
                    if not isinstance(value, str) or not value.strip():
                        errors.append(f"'{key}' {label} is empty")
                    else:
                        check_placeholders(key, value, f"'{key}' {label}", errors)
            if plural:
                n = len([1 for sp in specs(key) if sp[1] == "int"])
                if n != 1:
                    errors.append(f"'{key}' is a plural but has {n} integer placeholders (needs exactly one)")


# ---------------------------------------------------------------- stringsdata

def read_stringsdata(directory):
    """{table: {key: [(file, line, comment)]}}"""
    out = {}
    for f in sorted(glob.glob(os.path.join(directory, "*.stringsdata"))):
        with open(f, encoding="utf-8") as fh:
            data = json.load(fh)
        src = data.get("source", os.path.basename(f))
        for table, entries in data.get("tables", {}).items():
            for e in entries:
                out.setdefault(table, {}).setdefault(e["key"], []).append(
                    (src, e.get("location", {}).get("startingLine", 0), e.get("comment", ""))
                )
    return out


def run_extract(directory):
    subprocess.check_call([os.path.join(ROOT, "Tools", "i18n", "compile.sh"), "--strings", directory], cwd=ROOT)


# ---------------------------------------------------------------- catalogs

def load_catalog(path):
    if not os.path.exists(path):
        return {"sourceLanguage": "en", "strings": {}, "version": "1.0"}
    with open(path, encoding="utf-8") as fh:
        return json.load(fh)


def write_catalog(path, data):
    def order(item):
        return (item[0].lower(), item[0])

    data = dict(data)
    data["strings"] = dict(sorted(data["strings"].items(), key=order))
    text = json.dumps(data, indent=2, separators=(",", " : "), ensure_ascii=False, sort_keys=True) + "\n"
    text = text.replace('"strings" : {}', '"strings" : {\n\n  }')
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(text)


def unit(text, state="translated"):
    return {"stringUnit": {"state": state, "value": text}}


def localization(value):
    if isinstance(value, dict):
        return {"variations": {"plural": {cat: unit(text) for cat, text in value.items()}}}
    return unit(value)


def apply_translations(errors):
    merged = merged_translations(errors)
    validate_all(merged, errors)
    changed = 0
    for table, strings in merged.items():
        path = CATALOGS[table]
        catalog = load_catalog(path)
        entries = catalog["strings"]
        for key, langs in strings.items():
            entry = entries.get(key)
            if entry is None:
                if table == "Catalogue":
                    entry = {"extractionState": "manual"}
                else:
                    # Not in the catalog: the key was not extracted (typo, or the source changed).
                    errors.append(f"apply: '{key}' is not in {os.path.basename(path)}; run `i18n.py build`")
                    continue
                entries[key] = entry
            if entry.get("shouldTranslate") is False:
                continue
            locs = entry.setdefault("localizations", {})
            for lang, value in langs.items():
                new = localization(value)
                if locs.get(lang) != new:
                    locs[lang] = new
                    changed += 1
        write_catalog(path, catalog)
    return changed


def sync_localizable(directory):
    files = sorted(glob.glob(os.path.join(directory, "*.stringsdata")))
    if not files:
        sys.exit("no .stringsdata files in " + directory)
    subprocess.check_call(
        ["xcrun", "xcstringstool", "sync", CATALOGS["Localizable"], "--stringsdata"] + files, cwd=ROOT
    )


# ---------------------------------------------------------------- commands

def cmd_extract(args):
    d = scratch_dir()
    run_extract(d)
    data = read_stringsdata(d)
    print(f"{sum(len(v) for v in data.values())} keys in {d}")


def needs_translation(table, key, catalog):
    return catalog["strings"].get(key, {}).get("shouldTranslate") is not False


def cmd_skeleton(args):
    out = None
    files = []
    lang = None
    i = 0
    while i < len(args):
        if args[i] == "-o":
            out = args[i + 1]
            i += 2
        elif lang is None:
            lang = args[i]
            i += 1
        else:
            files.append(os.path.normpath(args[i]))
            i += 1
    if lang not in LANGS or not out:
        sys.exit("usage: i18n.py skeleton LANG [FILE.swift ...] -o OUT.json   (LANG one of %s)" % " ".join(LANGS))
    d = scratch_dir()
    if "--reuse" not in args and "--reuse" not in sys.argv:
        run_extract(d)
    data = read_stringsdata(d)
    errors = []
    merged = merged_translations(errors)
    catalog = load_catalog(CATALOGS["Localizable"])
    strings, context = {}, {}
    for key, places in data.get("Localizable", {}).items():
        mine = places
        if files:
            mine = [p for p in places if any(os.path.normpath(p[0]).endswith(f) or f.endswith(os.path.normpath(p[0])) for f in files)]
        if not mine or not needs_translation("Localizable", key, catalog):
            continue
        langs = merged.get("Localizable", {}).get(key, {})
        if lang in langs:
            continue
        plural = langs.get("en") if isinstance(langs.get("en"), dict) else None
        ctx = {"where": ", ".join(sorted({"%s:%s" % (os.path.basename(p[0]), p[1]) for p in mine}))}
        comments = sorted({p[2] for p in mine if p[2]})
        if comments:
            ctx["comment"] = " | ".join(comments)
        if plural:
            ctx["english"] = plural
            strings[key] = {c: "" for c in sorted(PLURAL_REQUIRED[lang])}
        else:
            strings[key] = ""
        context[key] = ctx
    skeleton = {"table": "Localizable", "strings": dict(sorted(strings.items())), "_context": dict(sorted(context.items()))}
    with open(out, "w", encoding="utf-8") as fh:
        json.dump(skeleton, fh, ensure_ascii=False, indent=2)
        fh.write("\n")
    print(f"{len(strings)} keys without a '{lang}' translation written to {out}")


def cmd_chunks(args):
    lang, nl, nc, outdir = args[0], int(args[1]), int(args[2]), args[3]
    if lang not in LANGS:
        sys.exit("LANG must be one of " + " ".join(LANGS))
    d = scratch_dir()
    data = read_stringsdata(d)
    errors = []
    merged = merged_translations(errors)
    catalog = load_catalog(CATALOGS["Localizable"])
    items = []  # (sortkey, table, key, value, context)
    for key, places in data.get("Localizable", {}).items():
        if not needs_translation("Localizable", key, catalog):
            continue
        langs = merged.get("Localizable", {}).get(key, {})
        if lang in langs:
            continue
        plural = langs.get("en") if isinstance(langs.get("en"), dict) else None
        first = min(places, key=lambda p: (p[0], p[1]))
        ctx = {"where": ", ".join(sorted({"%s:%s" % (os.path.basename(p[0]), p[1]) for p in places}))}
        comments = sorted({p[2] for p in places if p[2]})
        if comments:
            ctx["comment"] = " | ".join(comments)
        if plural:
            ctx["english"] = plural
        value = {c: "" for c in sorted(PLURAL_REQUIRED[lang])} if plural else ""
        items.append(((0, first[0], first[1]), "Localizable", key, value, ctx))
    for key, langs in merged.get("Catalogue", {}).items():
        if lang in langs:
            continue
        items.append(((1, key, 0), "Catalogue", key, "", {"english": langs.get("en", "")}))
    items.sort(key=lambda it: it[0])
    os.makedirs(outdir, exist_ok=True)
    for table, n in (("Localizable", nl), ("Catalogue", nc)):
        rows_all = [it for it in items if it[1] == table]
        per = -(-len(rows_all) // n) if n else 0
        for i in range(n):
            rows = rows_all[i * per:(i + 1) * per]
            if not rows:
                continue
            doc = {"table": table, "strings": {it[2]: it[3] for it in rows}, "_context": {it[2]: it[4] for it in rows}}
            path = os.path.join(outdir, f"{lang}-{table}-{i + 1:02d}.json")
            with open(path, "w", encoding="utf-8") as fh:
                json.dump(doc, fh, ensure_ascii=False, indent=1)
                fh.write("\n")
            print(path, len(rows), "keys")


def cmd_lint(args):
    chunk = None
    if "--chunk" in args:
        i = args.index("--chunk")
        chunk = args[i + 1]
        args = args[:i] + args[i + 2:]
    errors = []
    total = 0
    table = None
    strings, context = {}, {}
    lang = None
    for path in args:
        with open(path, encoding="utf-8") as fh:
            doc = json.load(fh)
        this_lang = os.path.basename(os.path.dirname(os.path.abspath(path)))
        if this_lang not in LANGS:
            this_lang = os.path.basename(path).split("-")[0]
        if this_lang not in LANGS:
            sys.exit("cannot tell the language of " + path)
        lang = lang or this_lang
        table = doc.get("table", "Localizable")
        for k, v in doc.get("strings", {}).items():
            if k in strings:
                errors.append(f"'{k}' appears twice")
            strings[k] = v
        context.update(doc.get("_context", {}))
    if chunk:
        with open(chunk, encoding="utf-8") as fh:
            cdoc = json.load(fh)
        table = cdoc.get("table", "Localizable")
        missing = [k for k in cdoc["strings"] if k not in strings]
        extra = [k for k in strings if k not in cdoc["strings"]]
        for k in missing[:50]:
            errors.append(f"missing key: '{k}'")
        if len(missing) > 50:
            errors.append(f"... and {len(missing) - 50} more missing keys")
        for k in extra[:50]:
            errors.append(f"key not in the work file (typo? the key must be copied exactly): '{k}'")
    merged = merged_translations([])
    for key, v in strings.items():
        total += 1
        en = merged.get(table, {}).get(key, {}).get("en")
        label = f"'{key}' [{lang}]"
        if table == "Catalogue":
            if not isinstance(v, str) or not v.strip():
                errors.append(f"{label} is empty")
            continue
        plural = isinstance(en, dict)
        if plural != isinstance(v, dict):
            errors.append(f"{label} {'must' if plural else 'must not'} be plural variants")
            continue
        if plural:
            cats = set(v)
            if not cats <= PLURAL_ALLOWED[lang] or not PLURAL_REQUIRED[lang] <= cats:
                errors.append(f"{label} plural categories {sorted(cats)}; need {sorted(PLURAL_REQUIRED[lang])}")
            for cat, text in v.items():
                if not isinstance(text, str) or not text.strip():
                    errors.append(f"{label}.{cat} is empty")
                else:
                    check_placeholders(key, text, f"{label}.{cat} plural", errors)
        elif not isinstance(v, str) or not v.strip():
            errors.append(f"{label} is empty")
        else:
            check_placeholders(key, v, label, errors)
    for e in errors[:200]:
        print("ERROR", e)
    print(f"{total} keys, {len(errors)} problems")
    sys.exit(1 if errors else 0)


def cmd_check(args):
    errors = []
    merged = merged_translations(errors)
    validate_all(merged, errors)
    d = scratch_dir()
    if os.path.isdir(d) and glob.glob(os.path.join(d, "*.stringsdata")):
        data = read_stringsdata(d)
        catalog = load_catalog(CATALOGS["Localizable"])
        extracted = data.get("Localizable", {})
        for lang in LANGS:
            missing = [
                (k, places[0][0] + ":" + str(places[0][1]))
                for k, places in sorted(extracted.items())
                if needs_translation("Localizable", k, catalog) and lang not in merged.get("Localizable", {}).get(k, {})
            ]
            print(f"[{lang}] {len(extracted) - len(missing)}/{len(extracted)} extracted keys translated")
            if "-v" in args:
                for k, w in missing:
                    print(f"    missing  {w}  {k!r}")
        plural_missing = [k for k, v in merged.get("Localizable", {}).items() if k not in extracted]
        for k in plural_missing[:50]:
            errors.append(f"translation key not produced by the sources (typo, or the source changed): '{k}'")
        # a key with a count in it that was never declared a plural in English
        for k in sorted(extracted):
            if re.search(r"%(\d+\$)?lld", k) and not isinstance(merged.get("Localizable", {}).get(k, {}).get("en"), dict):
                if "-p" in args:
                    print(f"    count without plural? {extracted[k][0][0]}:{extracted[k][0][1]}  {k!r}")
    for e in errors[:300]:
        print("ERROR", e)
    if len(errors) > 300:
        print(f"... and {len(errors) - 300} more")
    print(f"{len(errors)} problems")
    sys.exit(1 if errors else 0)


def cmd_verify(args):
    """The catalogs as they ship: complete in every language, placeholders and plurals intact."""
    errors = []
    checked = 0
    for table, path in CATALOGS.items():
        catalog = load_catalog(path)
        for key, entry in catalog["strings"].items():
            if entry.get("shouldTranslate") is False or entry.get("extractionState") == "stale":
                continue
            checked += 1
            locs = entry.get("localizations", {})
            en = locs.get("en", {})
            plural_en = "variations" in en and "plural" in en.get("variations", {})
            for lang in LANGS:
                loc = locs.get(lang)
                if not loc:
                    errors.append(f"{table}: '{key}' has no '{lang}' translation")
                    continue
                if "variations" in loc:
                    forms = {c: u["stringUnit"]["value"] for c, u in loc["variations"].get("plural", {}).items()}
                    if not PLURAL_REQUIRED[lang] <= set(forms):
                        errors.append(f"{table}: '{key}' [{lang}] plural forms {sorted(forms)}; need {sorted(PLURAL_REQUIRED[lang])}")
                    for cat, text in forms.items():
                        check_placeholders(key, text, f"{table}: '{key}' [{lang}.{cat}] plural", errors)
                else:
                    if plural_en:
                        errors.append(f"{table}: '{key}' [{lang}] must vary by plural like the English")
                    text = loc.get("stringUnit", {}).get("value", "")
                    if not text.strip():
                        errors.append(f"{table}: '{key}' [{lang}] is empty")
                    elif table == "Localizable":
                        check_placeholders(key, text, f"{table}: '{key}' [{lang}]", errors)
    for e in errors[:300]:
        print("ERROR", e)
    if len(errors) > 300:
        print(f"... and {len(errors) - 300} more")
    print(f"{checked} live strings checked, {len(errors)} problems")
    sys.exit(1 if errors else 0)


def cmd_apply(args):
    errors = []
    changed = apply_translations(errors)
    for e in errors[:100]:
        print("ERROR", e)
    print(f"{changed} localizations written")
    sys.exit(1 if errors else 0)


def cmd_build(args):
    d = scratch_dir()
    run_extract(d)
    sync_localizable(d)
    cmd_apply(args)


# ---------------------------------------------------------------- audit

class Lit:
    __slots__ = ("line", "end_line", "text", "multiline", "before", "interps", "after")

    def __init__(self, line, end_line, text, multiline, before, interps, after=""):
        self.line = line
        self.end_line = end_line
        self.text = text
        self.multiline = multiline
        self.before = before
        self.interps = interps
        self.after = after


def lex_strings(src):
    """Yields Lit for every string literal outside comments. Interpolations become '\x00'."""
    i, n, line = 0, len(src), 1
    lits = []

    def skip_block_comment(i, line):
        depth = 0
        while i < n:
            if src.startswith("/*", i):
                depth += 1
                i += 2
            elif src.startswith("*/", i):
                depth -= 1
                i += 2
                if depth == 0:
                    return i, line
            else:
                if src[i] == "\n":
                    line += 1
                i += 1
        return i, line

    def read_string(i, line):
        """i at the first quote. Returns (text, i_after, line_after, multiline, interps)."""
        hashes = 0
        j = i
        while j > 0 and src[j - 1] == "#":
            j -= 1
            hashes += 1
        multiline = src.startswith('"""', i)
        q = '"""' if multiline else '"'
        i += len(q)
        buf = []
        interps = []
        closing = q + "#" * hashes
        esc = "\\" + "#" * hashes
        while i < n:
            if src.startswith(closing, i):
                return "".join(buf), i + len(closing), line, multiline, interps
            if src.startswith(esc, i):
                k = i + len(esc)
                if k < n and src[k] == "(":
                    depth, k = 1, k + 1
                    start = k
                    while k < n and depth:
                        c = src[k]
                        if c == '"':
                            _, k2, line2, _, _ = read_string(k, line)
                            line = line2
                            k = k2
                            continue
                        if c == "(":
                            depth += 1
                        elif c == ")":
                            depth -= 1
                        elif c == "\n":
                            line += 1
                        k += 1
                    interps.append(src[start : k - 1])
                    buf.append("\x00")
                    i = k
                    continue
                # simple escape
                if k < n:
                    ch = src[k]
                    if ch == "u" and src[k + 1 : k + 2] == "{":
                        end = src.index("}", k)
                        buf.append(chr(int(src[k + 2 : end], 16)))
                        i = end + 1
                        continue
                    buf.append({"n": "\n", "t": "\t", "r": "\r", "0": "\0", '"': '"', "\\": "\\", "'": "'"}.get(ch, ch))
                    i = k + 1
                    continue
            c = src[i]
            if c == "\n":
                line += 1
            buf.append(c)
            i += 1
        return "".join(buf), i, line, multiline, interps

    while i < n:
        c = src[i]
        if c == "\n":
            line += 1
            i += 1
        elif src.startswith("//", i):
            while i < n and src[i] != "\n":
                i += 1
        elif src.startswith("/*", i):
            i, line = skip_block_comment(i, line)
        elif c == "#" and (src.startswith('#"', i) or src.startswith('##"', i)):
            while src[i] == "#":
                i += 1
        elif c == '"':
            start_line = line
            before = src[max(0, i - 60) : i]
            text, i2, line, multiline, interps = read_string(i, line)
            if multiline:
                lines = text.split("\n")
                if lines and lines[0].strip() == "":
                    lines = lines[1:]
                indent = None
                if lines:
                    last = lines[-1]
                    if last.strip() == "":
                        indent = len(last)
                        lines = lines[:-1]
                if indent is None:
                    indent = min((len(l) - len(l.lstrip()) for l in lines if l.strip()), default=0)
                text = "\n".join(l[indent:] if len(l) >= indent else l.lstrip() for l in lines)
            lits.append(Lit(start_line, line, text, multiline, before, interps, src[i2 : i2 + 12]))
            i = i2
        else:
            i += 1
    return lits


def skeleton_literal(text):
    return re.sub(r"\s+", " ", text.replace("\x00", "\x01")).strip()


def skeleton_key(key):
    k = SPEC.sub(lambda m: "%" if m.group(0) == "%%" else "\x01", key)
    return re.sub(r"\s+", " ", k).strip()


NON_UI_BEFORE = re.compile(
    r"(comment:|print|assert|assertionFailure|precondition|preconditionFailure|fatalError|NSLog|Logger|logger|os_log|"
    r"systemName:|systemImage:|Image\(|named:|Color\(|\.font\(|\.fontWeight\(|import |@available|#if|#available|"
    r"\.contains\(|\.hasPrefix\(|\.hasSuffix\(|\.firstIndex|\.split\(|separator:|\.replacingOccurrences|"
    r"\bid:|\.id\s*==|rawValue|forKey:|\.sheet|identifier:|UserDefaults|\.accessibilityIdentifier|dispatchPrecondition|"
    r"Notification\.Name|\.tag\(|\.symbolEffect|format:|NSPredicate|URL\(|Bundle\.|Locale\(|\.range\(of:)\s*\(?\s*$"
)


def audit(files, keys_skel, show_words=False, ignore=None):
    results = []
    for path in files:
        with open(os.path.join(ROOT, path), encoding="utf-8") as fh:
            src = fh.read()
        ignored_lines = {i + 1 for i, l in enumerate(src.split("\n")) if "i18n:ignore" in l}
        for lit in lex_strings(src):
            if lit.line in ignored_lines or lit.end_line in ignored_lines:
                continue
            text = lit.text
            plain = text.replace("\x00", " ")
            words = re.findall(r"[^\W\d_]{2,}", plain, re.UNICODE)
            prose = len(words) >= 2 and re.search(r"[^\W\d_]{2,}[\s,;:.!?'’—–-]+[^\W\d_]{2,}", plain)
            word = len(words) == 1 and re.fullmatch(r"[A-Z][a-z]{3,}.*|[a-z]{4,}", plain.strip() or "-") and not words[0].isupper()
            if not (prose or (show_words and word)):
                continue
            if skeleton_literal(text) in keys_skel:
                continue
            if NON_UI_BEFORE.search(lit.before):
                continue
            tail_line = lit.before.split("\n")[-1].strip()
            if re.match(r"\s*:", lit.after) and (tail_line in ("", "[", ",") or tail_line.endswith("case") or tail_line.endswith(",")):
                continue  # a dictionary key or a case label: an id, not display text
            if re.search(r"\.(png|jpg|json|swift|html|txt)$", plain.strip()) or "://" in plain:
                continue
            if ignore and (path + "::" + plain.strip()[:80]) in ignore:
                continue
            results.append((path, lit.line, plain.strip().replace("\n", "⏎")[:110]))
    return results


def cmd_audit(args):
    show_words = "--words" in args
    args = [a for a in args if not a.startswith("--")]
    files = args or sorted(
        os.path.relpath(p, ROOT) for p in glob.glob(os.path.join(ROOT, "Main", "**", "*.swift"), recursive=True)
    )
    d = scratch_dir()
    if not glob.glob(os.path.join(d, "*.stringsdata")):
        run_extract(d)
    data = read_stringsdata(d)
    keys = set()
    for table in data.values():
        for k in table:
            keys.add(skeleton_key(k))
    ignore = set()
    ign = os.path.join(ROOT, "Tools", "i18n", "audit-ignore.txt")
    if os.path.exists(ign):
        ignore = {l.rstrip("\n") for l in open(ign, encoding="utf-8") if l.strip() and not l.startswith("#")}
    results = audit(files, keys, show_words, ignore)
    for path, line, text in results:
        print(f"{path}:{line}: {text}")
    print(f"{len(results)} literals look like user-visible English but are not localized", file=sys.stderr)
    sys.exit(1 if results else 0)


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(2)
    cmd, args = sys.argv[1], sys.argv[2:]
    {
        "extract": cmd_extract,
        "skeleton": cmd_skeleton,
        "check": cmd_check,
        "lint": cmd_lint,
        "chunks": cmd_chunks,
        "apply": cmd_apply,
        "verify": cmd_verify,
        "build": cmd_build,
        "audit": cmd_audit,
    }.get(cmd, lambda a: sys.exit(__doc__))(args)


if __name__ == "__main__":
    main()
