#!/usr/bin/env python3
"""Turn researched country data into the numbers of a Country.Profile.

Everything numeric is derived here, so no figure is transcribed by hand:
  * the pay curve  local = anchor * (usRef / 30000) ** exponent  is a WEIGHTED least-squares
    fit in log-log space. Its points are the local pay of six reference jobs (weighted by the
    researcher's confidence: high 1.0, medium 0.7, low 0.35) plus two strong anchors that were
    independently verified for every country: the national median full-time wage (matches the US
    median of about $62k) and the 90th-percentile wage (about $135k in the US), each weighted 2x;
  * the tech factor is the local mid-level software-engineer pay against that curve, clamped
    (an over-generous IT premium floods simulated lives into IT jobs);
  * generalPayScale is the curve at the $60k rung per dollar; highEarnerThreshold is about
    3.8x the curve at $60k; capitalScale is the PPP conversion factor;
  * 'stated' national-scale pay is built from nine researched anchors and fixed ratios (the
    ratios Germany's profile uses), floored at the minimum wage and kept monotonic up each ladder.
"""
import json, math, sys

US_REF = {"cashier": 32500, "electrician": 63000, "policeOfficer": 72000,
          "mechanicalEngineer": 104000, "lawyer": 125000, "salesDirector": 220000}
US_MEDIAN, US_P90 = 62000, 135000
CONF_W = {"high": 1.0, "medium": 0.7, "low": 0.35}
EXP_LO, EXP_HI = 0.45, 1.30
TECH_LO, TECH_HI = 0.80, 1.00   # above 1.0 the simulator's typical life floods into IT (India: 4% of lives at 1.0, 28% at 1.1)


def v(x):
    return x["value"] if isinstance(x, dict) else x


def w(x, mult=1.0):
    return CONF_W.get(x.get("confidence", "low"), 0.35) * mult if isinstance(x, dict) else mult


def wfit(points):
    """points: [(usRef, local, weight)] -> (anchor, exponent, clamped, worst relative residual)."""
    xs = [math.log(u / 30000) for u, _, _ in points]
    ys = [math.log(l) for _, l, _ in points]
    ws = [wt for _, _, wt in points]
    sw = sum(ws)
    mx = sum(wt * x for wt, x in zip(ws, xs)) / sw
    my = sum(wt * y for wt, y in zip(ws, ys)) / sw
    b = sum(wt * (x - mx) * (y - my) for wt, x, y in zip(ws, xs, ys)) / sum(wt * (x - mx) ** 2 for wt, x in zip(ws, xs))
    clamped = not (EXP_LO <= b <= EXP_HI)
    b = min(max(b, EXP_LO), EXP_HI)
    a = sum(wt * (y - b * x) for wt, x, y in zip(ws, xs, ys)) / sw
    resid = [abs(math.exp(a + b * x) / math.exp(y) - 1) for x, y in zip(xs, ys)]
    return math.exp(a), b, clamped, max(resid)


def sig(x, digits=3):
    if x == 0:
        return 0
    d = digits - int(math.floor(math.log10(abs(x)))) - 1
    return round(x, d) if d > 0 else int(round(x, d))


def rnd(x, step):
    return int(round(x / step)) * step


def build(d, step, overrides=None):
    """overrides: dotted-path -> value replacing a researched/verified figure."""
    overrides = overrides or {}

    def get(path, default=None):
        if path in overrides:
            return overrides[path]
        o = d
        for p in path.split("."):
            o = o[p]
        return v(o)

    pts = []
    for k, ref in US_REF.items():
        node = d["payForGameJobs"][k]
        val = overrides.get(f"payForGameJobs.{k}", v(node))
        pts.append((ref, val, 1.0 if f"payForGameJobs.{k}" in overrides else w(node)))   # an override is a verified figure
    med, p90 = d["wageLevels"]["medianFullTime"], d["wageLevels"]["p90FullTime"]
    # The national median was independently verified for every country (the verifiers' check 5), so it
    # carries full weight; the 90th percentile carries its own confidence unless the verifier replaced it.
    pts.append((US_MEDIAN, get("wageLevels.medianFullTime"), 2.0))
    pts.append((US_P90, get("wageLevels.p90FullTime"), 2.0 if "wageLevels.p90FullTime" in overrides else w(p90, 2.0)))
    anchor, exp, clamped, worst = wfit(pts)
    curve = lambda ref: anchor * (ref / 30000) ** exp

    mn = int(get("minimumWage.annualFullTime"))
    swe = get("softwareEngineer.midLevel")
    tech = round(min(max(swe / curve(125000), TECH_LO), TECH_HI) / 0.05) * 0.05
    a = {k: overrides.get(f"nationalScales.{k}", v(x)) for k, x in d["nationalScales"].items()}
    res, doc = a["residentPhysician"], a["specialistPhysician"]
    res = min(res, 0.9 * doc)
    fo, cap = a["airlineFirstOfficer"], a["airlineCaptain"]
    fo = min(fo, 0.85 * cap)
    mn_floor = int(math.ceil(mn / step) * step)
    stated = {
        "Resident Physician": res, "Physician": doc, "Senior Physician": 1.25 * doc, "Surgeon": 1.4 * doc,
        "Anesthesiologist": 1.3 * doc, "Chief Medical Officer": 2.0 * doc, "Dentist": a["dentist"],
        "Pharmacist": a["pharmacist"],
        "Registered Nurse": a["registeredNurse"], "Senior Registered Nurse": 1.17 * a["registeredNurse"],
        "Licensed Practical Nurse": 0.77 * a["registeredNurse"], "Nurse Practitioner": 1.28 * a["registeredNurse"],
        "Teacher": a["secondaryTeacher"], "Senior Teacher": 1.17 * a["secondaryTeacher"],
        "Lead Teacher": 1.38 * a["secondaryTeacher"], "Childcare Worker": 0.72 * a["secondaryTeacher"],
        "First Officer": fo, "Pilot": math.sqrt(fo * cap), "Airline Captain": cap,
        "Chief Executive Officer": a["ceoLargeCompany"], "Chief Technology Officer": 0.82 * a["ceoLargeCompany"],
        "Managing Partner": 1.36 * a["ceoLargeCompany"],
    }
    # The researchers quote the biggest listed companies' total remuneration, which is on a different
    # basis from the game's median-style executive pay (3x to 36x the curve): executives follow the curve.
    for executive in ("Chief Executive Officer", "Chief Technology Officer", "Managing Partner"):
        stated.pop(executive)
    # Childcare is a low-wage job (its US reference is a cashier's): a fixed share of teacher pay
    # priced it above the curve and made it the simulator's favourite job in Spain and Brazil.
    stated.pop("Childcare Worker")
    stated = {k: max(rnd(x, step), mn_floor) for k, x in stated.items()}
    for ladder in (["Resident Physician", "Physician", "Senior Physician"],
                   ["Registered Nurse", "Senior Registered Nurse"],
                   ["Teacher", "Senior Teacher", "Lead Teacher"],
                   ["First Officer", "Pilot", "Airline Captain"]):
        for lo, hi in zip(ladder, ladder[1:]):
            if stated[hi] < stated[lo]:
                stated[hi] = stated[lo]
    return {
        "anchor": sig(anchor), "exponent": round(exp, 3), "fitClamped": clamped, "worstResidual": round(worst, 2),
        "tech": round(tech, 2), "sweRatioRaw": round(swe / curve(125000), 2),
        "general": sig(curve(60000) / 60000, 3), "highEarner": sig(3.8 * curve(60000), 2),
        "capital": sig(get("identity.pppPerUSD"), 2), "minimum": mn, "stated": stated,
        "curve": {ref: round(curve(ref)) for ref in (30000, 60000, 130000, 250000)},
        "living": int(round(get("livingCost"))), "step": step,
        "median": get("wageLevels.medianFullTime"), "p90": get("wageLevels.p90FullTime"),
    }
