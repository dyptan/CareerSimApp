# Country data

How the pay, tuition, living-cost and grade figures of ten countries were produced, so they can be audited and refreshed:
Australia, Brazil, China, India, Mexico, Poland, South Korea, Spain, Sweden and Turkey (2025–26 figures).
The first eight countries (United States, Canada, France, Germany, Italy, Japan, Ukraine, United Kingdom) were written by hand
from their sources and are not part of this pipeline.

## Pipeline

1. **`research/<country>.research.json`** — one researcher per country. Every figure carries a source URL and a confidence
   (`high` / `medium` / `low`); `research/SPEC.md` is the schema and says what each part means.
2. **`research/<country>.verify.json`** — an independent second pass that re-derived the critical figures (minimum wage, driving
   age, tuition, nurse / teacher / resident-doctor pay, median wage, how the school-leaving result is graded, exchange rate and PPP,
   student loan) from fresh searches without trusting the first pass. Anything marked `off` was corrected in `emit.py` (see `overrides`).
3. **`gen.py`** — turns a research file into the numbers of a `Country.Profile`:
   * the pay curve `local = anchor × (US pay / $30,000) ^ exponent` is a weighted least-squares fit in log-log space through the local
     pay of six reference jobs (weighted by confidence) plus the verified national median and 90th-percentile wages;
   * the tech factor, `generalPayScale` (curve at the $60k rung), `highEarnerThreshold` (≈ 3.8 × that) and `capitalScale` (the PPP
     factor) are derived; national-scale pay (doctors, nurses, teachers, pilots) is built from nine anchors and fixed ratios, floored
     at the minimum wage and kept rising up each ladder.
4. **`emit.py`** — writes the Swift. Its `META` table holds the decisions made by hand: names, school tiers, the grade scale,
   the two player-facing highlight sentences, tuition fixes and the verifiers' corrections.
5. **`splice.py`** — puts the result into `Main/Models/Country.swift` between the `More countries` markers. Idempotent.

## Refreshing

```
python3 Tools/CountryData/emit.py Tools/CountryData/research /tmp/country-out
python3 Tools/CountryData/splice.py /tmp/country-out Main/Models/Country.swift
Tools/BalanceSim/run-tests.sh
```

To change a figure, edit the research JSON (keep its source) or add an entry to that country's `overrides` in `emit.py`.
Never edit the generated block in `Country.swift` by hand: the next splice overwrites it.

## Why the output differs from the raw research

* **Executives (CEO, CTO, managing partner) and childcare workers follow the pay curve.** The researchers quoted top-company total
  pay (3×–36× the curve), which is not the median-style figure the game uses for the US; a childcare share of teacher pay priced
  that job above the curve and made it the simulator's favourite in Spain and Brazil.
* **The tech factor is capped at 1.0.** Above it the simulator's typical life floods into IT jobs (India: 4% of lives in sysadmin
  jobs at 1.0, 28% at 1.1). Countries where IT pays *less* than the curve keep a factor below 1.
* **Loan rates are real rates:** nominal minus inflation, floored at 0 (the sources mixed percent and fractions).
* **Legal figures use the verified value**, not "within tolerance": minimum wages and driving ages.
* **Occupation-level pay is mostly low confidence** for Australia, Brazil, China, India, Mexico and Turkey. The national median and
  90th-percentile wages carry the fit; treat the individual job pay as an estimate.
