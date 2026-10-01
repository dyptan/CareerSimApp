#!/usr/bin/env python3
"""Splice the emitter's output into Main/Models/Country.swift. Idempotent: the generated profile and
schooling blocks live between marker comments and are replaced on every run.

Usage: splice.py <out-dir> <Country.swift>
"""
import re, sys

out, path = sys.argv[1], sys.argv[2]
src = open(path).read()
cases = open(f"{out}/cases.txt").read()
switch = open(f"{out}/switch.txt").read()
profiles = open(f"{out}/profiles.txt").read()
schooling = open(f"{out}/schooling.txt").read()

# 1) enum cases
m = re.search(r"(enum Country: String, Codable, CaseIterable, Identifiable \{\n)((?:    case \w+\n)+)", src)
assert m, "enum cases not found"
src = src[: m.start(2)] + cases + src[m.end(2):]

# 2) profile switch
m = re.search(r"(    var profile: Profile \{\n        switch self \{\n)((?:        case \.\w+:.*\n)+)(        \}\n    \}\n)", src)
assert m, "profile switch not found"
src = src[: m.start(2)] + switch + src[m.end(2):]

# 3) generated profiles, after the hand-written ones, before the enum's closing brace
BEGIN = "    // MARK: - More countries (generated from sourced 2025-26 data; see Tools/i18n and the PR)\n\n"
END = "    // MARK: end of more countries\n"
block = BEGIN + profiles.rstrip("\n") + "\n\n" + END
if BEGIN in src:
    a = src.index(BEGIN); b = src.index(END) + len(END)
    src = src[:a] + block + src[b:]
else:
    anchor = '            "Priced as in peacetime: the war\'s effects on work and flights aren\'t in the game.",\n        ])\n'
    assert src.count(anchor) == 1, "ukraine profile end not found"
    src = src.replace(anchor, anchor + "\n" + block)

# 4) generated schooling, inside `extension Country.Schooling`
SB = "    // MARK: more countries (generated)\n\n"
SE = "    // MARK: end of more countries\n"
sblock = SB + schooling.rstrip("\n") + "\n\n" + SE
if SB in src:
    a = src.index(SB); b = src.index(SE, a) + len(SE)
    src = src[:a] + sblock + src[b:]
else:
    anchor = '        tiers: [.community: "College", .state: "University", .elite: "Top university"],\n        gradeName: "NMT score", scale: .nmt)\n'
    assert src.count(anchor) == 1, "ukrainian schooling not found"
    src = src.replace(anchor, anchor + "\n" + sblock)
open(path, "w").write(src)
print("spliced:", len(re.findall(r"\n    case \w+\n", cases)) + 0, "cases")
