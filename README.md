# recodepexa

**RECODe** (Risk Equations for Complications Of type 2 Diabetes) gives
10-year risks of six complications in adults with type 2 diabetes.

Basu S, Sussman JB, Berkowitz SA, Hayward RA, Yudkin JS. Development and
validation of Risk Equations for Complications Of type 2 Diabetes (RECODe)
using individual participant data from randomised trials. *Lancet Diabetes
Endocrinol.* 2017;5(10):788–798.
[doi:10.1016/S2213-8587(17)30221-8](https://doi.org/10.1016/S2213-8587(17)30221-8);
author manuscript [PMC5769867](https://pmc.ncbi.nlm.nih.gov/articles/PMC5769867/).

## Source

The equations are those of the authors' calculator: `app.R` in
[sanjaybasu/t2dmriskeqns](https://github.com/sanjaybasu/t2dmriskeqns),
commit `63135bd8`, the code behind
[sanjaybasu.shinyapps.io/recode](https://sanjaybasu.shinyapps.io/recode/).

- A script, `data-raw/extract_constants.py`, reads the coefficients,
  baseline survival (λ) and means from it, without running it, into
  `R/constants.R`. The SI version, `appSI.R`, has the same numbers.
- Each risk is 1 − λ^exp(Σβx − mean).
- The equations were developed in ACCORD: ages 40–79, HbA1c 7.5% or more,
  with cardiovascular disease or risk factors.
- They were validated externally in DPPOS (microvascular outcomes) and Look
  AHEAD (cardiovascular outcomes).

## Outcomes

These are the six outcomes the calculator implements. Each is defined as in
ACCORD, as a 10-year risk.

| Output | Definition |
|---|---|
| `nephropathy` | renal failure, end-stage renal disease (dialysis), or serum creatinine > 3.3 mg/dL |
| `retinopathy` | severe vision loss (visual acuity < 20/200) |
| `neuropathy` | loss of pressure sensation |
| `ascvd` | first fatal or non-fatal myocardial infarction or stroke |
| `chf` | congestive heart failure |
| `mortality` | death from any cause |

The paper also gives equations for other definitions, such as
microalbuminuria and the MI and stroke components. Most of them have no
published λ and mean, and none is in the authors' calculator, so they are not
included.

## Inputs

| Field | Meaning |
|---|---|
| `age`, `sex` | years; male/female |
| `black`, `hispanic` | yes/no |
| `sbp` | systolic blood pressure, mm Hg |
| `bp_meds`, `oral_dm_meds`, `statin` | current treatment, yes/no |
| `anticoagulant` | anticoagulant other than aspirin, yes/no |
| `smoker` | current tobacco smoking, yes/no |
| `cvd_history` | prior myocardial infarction or stroke, yes/no |
| `hba1c` | % |
| `total_chol`, `hdl` | mg/dL (mmol/L with `units = "si"`) |
| `creatinine` | mg/dL (µmol/L with `units = "si"`) |
| `uacr` | urine albumin:creatinine ratio, mg/g (mg/mmol with `units = "si"`) |

All inputs are required. The paper suggests leaving out the term for an
unknown predictor, which this service does not do.

## Outputs

- **`risk`:** the six 10-year risks, as probabilities, unrounded.
- **`calculator_percent`:** whole percentages, as the authors' calculator
  shows them.

## Validation

- **The authors' live calculator** (13 November 2026): its defaults and 10
  more cases, covering all inputs and risks from 1% to 100%. All 66 figures
  are identical at its whole-percent precision.
- **The paper's worked examples** (60-year-old man): renal failure 8.5%
  (paper 0.085), pressure-sensation loss 13% (0.13), all-cause death 9%
  (0.09).
- **The paper's Tables 2–4:** each coefficient was checked against the
  printed values.

## Differences between the paper and the authors' calculator

This package follows the calculator. The differences are:

| Outcome, term | Paper | Calculator | Effect |
|---|---|---|---|
| Nephropathy, Black | +0.08812 | −0.08812 | For the example man if Black: 7.9% here, 9.3% with the paper's sign |
| ASCVD, age | 0.03412 | 0.03421 | 18.27% vs 18.18% for the example man |
| All-cause death, BP drugs | 0.08776 | 0.08766 | negligible |

- **Neuropathy coefficients:** the calculator rounds them to 4 significant
  digits; the paper prints 5 decimals.
- **Microvascular means:** the calculator has more digits than the paper.

**SI units.** The authors' SI calculator (`appSI.R`) converts with ratios of
ACCORD means: creatinine × 0.9/78.6, total cholesterol × 183.2/4.7, HDL ×
41.8/1.1, ACR × 99.2/11.3. These differ from the exact factors by −1.7% to
+1.2%. This package uses the standard factors (cholesterol × 38.67,
creatinine ÷ 88.4, ACR × 8.84). For the example man entered in SI units, its
risks are 0.03 to 0.3 points lower than the SI calculator's.

## Limitations

- The equations were derived from trial participants in the United States,
  with the treatments of 2001–2009. They may be miscalibrated where newer
  drug classes, such as SGLT2 inhibitors and GLP-1 agonists, are widely
  used, or outside the US.
- The calculator has not been evaluated prospectively for its impact on
  care.

## Licence

The authors' repository has two notices: its README says CC BY-NC-SA 4.0,
and its LICENSE file (added in 2020) is MIT. This package is released under
CC BY-NC-SA 4.0, which satisfies both: attribution, non-commercial use only,
and the same licence for adaptations. The MIT notice is kept in
`inst/LICENSE-t2dmriskeqns-MIT`. For research use; not a substitute for
clinical judgement.
