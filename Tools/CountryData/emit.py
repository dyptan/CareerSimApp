#!/usr/bin/env python3
"""Emit Swift source for the new countries' Country.Profile and Schooling, from researched data.

Usage: emit.py <data-dir> <out-dir>      (writes cases.txt, switch.txt, profiles.txt, schooling.txt)
"""
import json, math, os, sys
sys.path.insert(0, os.path.dirname(__file__))
import gen

# ---- per-country decisions (names, tiers, scales and highlights are written by hand) -----------------------------
META = {
 "australia": dict(case="australia", title="Australia", flag="🇦🇺", symbol="A$", cname="Australian dollars", suffix="au", adj="Australian",
    step=500, driving=17, sch="australian",
    overrides={"nationalScales.residentPhysician": 97000},
    tuition={("bachelor","community"): 9537, ("bachelor","state"): 9537, ("bachelor","elite"): 9537},
    highlights=["Pay is high and compressed: the minimum wage is about half the typical full-time wage.",
                "University fees are set by subject, not by university, and HECS-HELP loans are indexed to prices, so they carry no real interest."]),
 "brazil": dict(case="brazil", title="Brazil", flag="🇧🇷", symbol="R$", cname="reais", suffix="br", adj="Brazilian",
    step=1000, driving=18, sch="brazilian", overrides={}, tuition={},
    highlights=["The minimum wage is paid in 13 instalments, and the average worker earns about 2.3 times the minimum.",
                "Public universities, the most selective included, charge no tuition, but entry is by the ENEM exam, and many students pay for a private college instead."]),
 "china": dict(case="china", title="China", flag="🇨🇳", symbol="CN¥", cname="yuan", suffix="cn", adj="Chinese",
    step=1000, driving=18, sch="chinese", tuition={},
    # the independent verification's figures (19 correct, 4 off, 9 unverifiable)
    overrides={"wageLevels.medianFullTime": 64000, "wageLevels.p90FullTime": 130000, "livingCost": 50000,
               "nationalScales.registeredNurse": 75000, "nationalScales.secondaryTeacher": 110000,
               "nationalScales.residentPhysician": 100000, "nationalScales.airlineFirstOfficer": 350000,
               "payForGameJobs.cashier": 48000, "payForGameJobs.mechanicalEngineer": 115000,
               "payForGameJobs.lawyer": 80000, "softwareEngineer.midLevel": 160000},
    highlights=["Minimum wages are set province by province, and pay in IT and finance is far above hotels and catering.",
                "Public universities charge a few thousand yuan a year, and one exam, the gaokao, decides where you can go."]),
 "india": dict(case="india", title="India", flag="🇮🇳", symbol="₹", cname="rupees", suffix="in", adj="Indian",
    step=5000, driving=18, sch="indian",
    overrides={"nationalScales.secondaryTeacher": 370000},
    tuition={("doctorate","community"): 15000, ("medicine","community"): 60000},
    highlights=["There is no single minimum wage: each state sets its own, and most workers earn little.",
                "Elite government institutions such as AIIMS cost very little, but places go by national entrance exams."]),
 "mexico": dict(case="mexico", title="Mexico", flag="🇲🇽", symbol="MX$", cname="Mexican pesos", suffix="mx", adj="Mexican",
    step=1000, driving=18, sch="mexican", overrides={},
    tuition={("bachelor","state"): 5500, ("medicine","community"): 5500, ("medicine","state"): 5500,
             ("law","community"): 5500, ("law","state"): 5500},
    highlights=["Pay is low and unequal: nearly half of workers earn no more than one minimum wage.",
                "Public universities such as UNAM are almost free, while the top private ones cost far more than most families earn."]),
 "poland": dict(case="poland", title="Poland", flag="🇵🇱", symbol="zł", cname="zloty", suffix="pl", adj="Polish",
    step=1000, driving=None, sch="polish", overrides={}, tuition={},
    highlights=["Full-time study at public universities is free, medicine and law included.",
                "The state student loan charges less than inflation, so its real cost is nothing."]),
 "spain": dict(case="spain", title="Spain", flag="🇪🇸", symbol="€", cname="euros", suffix="es", adj="Spanish",
    step=500, driving=18, sch="spanish", overrides={}, tuition={},
    highlights=["Public university costs about €900 a year, and vocational training (FP) has no tuition.",
                "The minimum wage is paid in 14 instalments, and pay is low next to the rest of western Europe."]),
 "sweden": dict(case="sweden", title="Sweden", flag="🇸🇪", symbol="kr", cname="Swedish kronor", suffix="se", adj="Swedish",
    step=1000, driving=18, sch="swedish", overrides={}, tuition={},
    highlights=["There is no legal minimum wage: union agreements set the floor, retail's among them.",
                "University is free, and student support is part grant, part loan."]),
 "turkey": dict(case="turkey", title="Turkey", flag="🇹🇷", symbol="₺", cname="Turkish lira", suffix="tr", adj="Turkish",
    step=10000, driving=18, sch="turkish", overrides={"identity.pppPerUSD": 20},
    tuition={},
    highlights=["Prices rise about 30% a year, so pay here is in 2026 lira and ages fast.",
                "State universities are free, while the top private ones cost over ₺1 million a year."]),
 "south-korea": dict(case="southKorea", title="South Korea", flag="🇰🇷", symbol="₩", cname="won", suffix="kr", adj="South Korean",
    step=100000, driving=18, sch="korean", overrides={}, tuition={},
    highlights=["The minimum wage is about 60% of the typical full-time wage.",
                "University entry rests on one November exam, the CSAT, graded 1 (best) to 9, and the state student loan charges less than inflation."]),
}

SCHOOLING = {
 "australian": ('"Primary School"', '"Junior Secondary School"', '"Senior Secondary Certificate"', '"TAFE Diploma"',
                ('"TAFE / Regional Institute"', '"University"', '"Group of Eight"'), '"ATAR"', '.linear(low: 30, high: 99.9, pattern: "%.1f")'),
 "brazilian": ('"Ensino Fundamental I"', '"Ensino Fundamental II"', '"Ensino Médio"', '"Curso Técnico"',
               ('"Faculdade"', '"Universidade pública"', '"Insper / FGV / PUC"'), '"ENEM score"', '.linear(low: 400, high: 900, pattern: "%.0f")'),
 "chinese": ('"Primary School (xiaoxue)"', '"Junior Middle School (chuzhong)"', '"Senior High School (gaozhong)"', '"Vocational College (gaozhi)"',
             ('"Higher Vocational College"', '"Provincial University"', '"985 / Double First-Class University"'), '"Gaokao score"', '.linear(low: 300, high: 720, pattern: "%.0f/750")'),
 "indian": ('"Primary School"', '"Secondary School (Class 10)"', '"Class 12 (Senior Secondary)"', '"ITI / Polytechnic Diploma"',
            ('"Government Degree College"', '"State University"', '"IIT / IIM / AIIMS"'), '"Class 12 percentage"', '.linear(low: 40, high: 98, pattern: "%.0f%%")'),
 "mexican": ('"Primaria"', '"Secundaria"', '"Bachillerato"', '"Técnico Superior Universitario"',
             ('"Universidad Tecnológica"', '"Universidad pública"', '"Tec de Monterrey / ITAM"'), '"Promedio"', '.linear(low: 6, high: 10, pattern: "%.1f")'),
 "polish": ('"Szkoła podstawowa"', '"Szkoła podstawowa (klasy 4–8)"', '"Matura"', '"Technikum"',
            ('"Uczelnia zawodowa"', '"Uniwersytet"', '"UW / UJ / SGH"'), '"Matura result"', '.linear(low: 30, high: 98, pattern: "%.0f%%")'),
 "spanish": ('"Educación Primaria"', '"ESO"', '"Bachillerato"', '"Formación Profesional"',
             ('"FP Grado Superior"', '"Universidad pública"', '"Carlos III / Pompeu Fabra / IE"'), '"Nota de admisión"', '.linear(low: 5, high: 14, pattern: "%.2f/14")'),
 "swedish": ('"Grundskola"', '"Högstadiet"', '"Gymnasieexamen"', '"Yrkeshögskola"',
             ('"Folkhögskola"', '"Högskola / Universitet"', '"KTH / Karolinska / Lund"'), '"Meritvärde"', '.linear(low: 10, high: 20, pattern: "%.1f/20")'),
 "turkish": ('"İlkokul"', '"Ortaokul"', '"Lise diploması"', '"Önlisans (MYO)"',
             ('"Meslek Yüksekokulu"', '"Devlet üniversitesi"', '"Bilkent / Koç / Sabancı"'), '"Diploma notu"', '.linear(low: 50, high: 100, pattern: "%.0f/100")'),
 "korean": ('"Elementary School (chodeung)"', '"Middle School (jung)"', '"High School (godeung)"', '"Junior College (jeonmun)"',
            ('"Junior College"', '"Regional University"', '"SKY (Seoul National, Korea, Yonsei)"'), '"CSAT grade"', '.linear(low: 9, high: 1, pattern: "%.1f (1 = best)")'),
}

# order of the enum: the US first, then alphabetical by title (the existing eight are kept in the file)
EXISTING = {"canada": "Canada", "france": "France", "germany": "Germany", "italy": "Italy", "japan": "Japan", "ukraine": "Ukraine", "unitedKingdom": "United Kingdom"}


def n(x):
    x = int(round(x))
    return f"{x:,}".replace(",", "_")


def num(x):
    if isinstance(x, float) and not float(x).is_integer():
        return repr(round(x, 4))
    return n(x)


def tiers(row):
    vals = [row[k] for k in ("community", "state", "elite")]
    if len(set(vals)) == 1:
        return f"TuitionTable.flat({n(vals[0])})"
    return f"[.community: {n(vals[0])}, .state: {n(vals[1])}, .elite: {n(vals[2])}]"


def real_rate(loan):
    nom, inf = loan["nominalRate"]["value"], loan["inflation"]["value"]
    nom = nom / 100 if nom > 1 else nom
    inf = inf / 100 if inf > 1 else inf
    r = max(0.0, nom - inf)
    return round(r / 0.005) * 0.005


def first_sentence(s, limit=210):
    s = " ".join(s.split())
    cut = s.find(". ")
    s = s if cut < 0 else s[: cut + 1]
    return s if len(s) <= limit else s[: limit - 1].rstrip() + "…"


def profile_text(key, d, m):
    b = gen.build(d, m["step"], m["overrides"])
    t = d["tuition"]
    rows = {}
    for lvl in ("vocational", "bachelor", "master", "doctorate", "medicine", "law"):
        rows[lvl] = {tier: t[lvl][tier]["value"] for tier in ("community", "state", "elite")}
        for (l2, tier), val in m["tuition"].items():
            if l2 == lvl:
                rows[lvl][tier] = val
    stated = ",\n".join(f'                        "{k}": {n(v)}' for k, v in b["stated"].items())
    cat = f"categoryFactor: [.technology: {b['tech']}],\n                      " if abs(b["tech"] - 1.0) > 1e-9 else ""
    sym = m["symbol"]
    loan = real_rate(d["studentLoan"])
    wage = d["minimumWage"]["note"]
    drv = f"drivingAge: {m['driving']}, " if m["driving"] not in (None, 18) else ""
    doc = [
        f"/// {m['title']}: the pay curve is fitted through the local pay of six reference jobs and the national median ({int(b['median']):,}) and",
        f"/// 90th-percentile ({int(b['p90']):,}) full-time wages; {first_sentence(d['minimumWage']['arithmetic'], 170)}",
        f"/// {first_sentence(d['tuition']['notes'], 230)}",
        f"/// {first_sentence(d['studentLoan']['description'], 200)}",
    ]
    doc = "\n    ".join(doc)
    return f'''    {doc}
    private static let {m['case']}Profile = Profile(
        title: "{m['title']}", adjective: "{m['adj']}", flag: "{m['flag']}", currencySymbol: "{sym}", currencyName: "{m['cname']}",
        leaderboardSuffix: "{m['suffix']}",
        pay: PayModel(anchor: {n(b['anchor'])}, exponent: {b['exponent']},
                      {cat}stated: [
{stated},
                      ]),
        step: {m['step']},
        minimumAnnualPay: {n(b['minimum'])}, minimumWageNote: "{wage}",
        tuition: TuitionTable(
            vocational: {tiers(rows['vocational'])},
            bachelor: {tiers(rows['bachelor'])},
            master: {tiers(rows['master'])},
            doctorate: {tiers(rows['doctorate'])},
            professional: [.health: {tiers(rows['medicine'])},
                           .law: {tiers(rows['law'])}]),
        studentLoanInterest: {loan:g},
        livingCostFloor: {n(b['living'])}, highEarnerThreshold: {n(b['highEarner'])},
        generalPayScale: {b['general']:g}, capitalScale: {b['capital']:g}, {drv}schooling: .{m['sch']},
        highlights: [
            "{m['highlights'][0]}",
            "{m['highlights'][1]}",
        ])
''', b


def schooling_text(name):
    p, mid, lv, voc, (tc, ts, te), gn, scale = SCHOOLING[name]
    return f'''    static let {name} = Self(
        primarySchool: {p}, middleSchool: {mid}, schoolLeaving: {lv},
        vocational: {voc},
        tiers: [.community: {tc}, .state: {ts}, .elite: {te}],
        gradeName: {gn}, scale: {scale})
'''


if __name__ == "__main__":
    data_dir, out_dir = sys.argv[1], sys.argv[2]
    os.makedirs(out_dir, exist_ok=True)
    keys = [k for k in META if os.path.exists(f"{data_dir}/{k}.research.json")]
    profiles, schoolings, report = [], [], []
    for k in keys:
        d = json.load(open(f"{data_dir}/{k}.research.json"))
        txt, b = profile_text(k, d, META[k])
        profiles.append(txt)
        schoolings.append(schooling_text(META[k]["sch"]))
        report.append((k, b))
    open(f"{out_dir}/profiles.txt", "w").write("\n".join(profiles))
    open(f"{out_dir}/schooling.txt", "w").write("\n".join(schoolings))
    titles = {**{c: t for c, t in EXISTING.items()}, **{META[k]["case"]: META[k]["title"] for k in keys}}
    order = ["unitedStates"] + [c for c, _ in sorted(titles.items(), key=lambda kv: kv[1])]
    open(f"{out_dir}/cases.txt", "w").write("\n".join(f"    case {c}" for c in order) + "\n")
    cases = {"unitedStates": "unitedStatesProfile", **{c: f"{c}Profile" for c in titles}}
    width = max(len(c) for c in order) + 2
    open(f"{out_dir}/switch.txt", "w").write("\n".join(f"        case .{c}:".ljust(width + 14) + f"return Self.{cases[c]}" for c in order) + "\n")
    for k, b in report:
        print(k, "tech", b["tech"], "exp", b["exponent"], "min", b["minimum"], "living", b["living"], "highEarner", b["highEarner"])
