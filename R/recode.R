#' RECODe: 10-year risks of complications of type 2 diabetes (Basu 2017)
#'
#' Ten-year risks of six outcomes in adults with type 2 diabetes, from the
#' Risk Equations for Complications Of type 2 Diabetes, as implemented in the
#' authors' calculator (github.com/sanjaybasu/t2dmriskeqns, commit 63135bd8,
#' `app.R`). Each risk is 1 - S0^exp(sum(beta x) - mean). The equations were
#' developed in ACCORD (ages 40-79, HbA1c 7.5% or more, with cardiovascular
#' disease or risk factors).
#'
#' Outcomes (ACCORD definitions):
#' * `nephropathy`: renal failure, end-stage renal disease (dialysis) or serum
#'   creatinine above 3.3 mg/dL;
#' * `retinopathy`: severe vision loss (visual acuity below 20/200);
#' * `neuropathy`: loss of pressure sensation;
#' * `ascvd`: first fatal or non-fatal myocardial infarction or stroke;
#' * `chf`: congestive heart failure;
#' * `mortality`: death from any cause.
#'
#' @param age Age, years.
#' @param sex "male" or "female".
#' @param black,hispanic Black; Hispanic or Latino: yes/no.
#' @param sbp Systolic blood pressure, mm Hg.
#' @param bp_meds On blood-pressure-lowering treatment: yes/no.
#' @param smoker Currently smoking tobacco: yes/no.
#' @param cvd_history Prior myocardial infarction or stroke: yes/no.
#' @param oral_dm_meds On oral diabetes medication: yes/no.
#' @param statin On a statin: yes/no.
#' @param anticoagulant On an anticoagulant other than aspirin: yes/no.
#' @param hba1c Haemoglobin A1c, %.
#' @param total_chol,hdl Total and HDL cholesterol: mg/dL, or mmol/L when
#'   `units = "si"`.
#' @param creatinine Serum creatinine: mg/dL, or umol/L when `units = "si"`.
#' @param uacr Urine albumin:creatinine ratio: mg/g, or mg/mmol when
#'   `units = "si"`.
#' @param units "conventional" (default) or "si". SI values are converted
#'   with the standard factors (cholesterol x 38.67, creatinine / 88.4, ACR x
#'   8.84); the authors' SI calculator uses slightly different factors (see
#'   README).
#' @return A list: `risk` (the six 10-year risks as probabilities,
#'   unrounded), `calculator_percent` (whole percentages, as the authors'
#'   calculator shows them), `definitions`, `inputs_conventional` (the values
#'   used, in conventional units) and `notes`.
#' @export
recode_risk <- function(age, sex, black, hispanic, sbp, bp_meds, smoker, cvd_history,
                        oral_dm_meds, statin, anticoagulant, hba1c, total_chol, hdl,
                        creatinine, uacr, units = "conventional") {
  units <- .rc_choice(units, "units", c(conventional = "conventional", us = "conventional",
                                        si = "si"))
  x <- c(
    age = .rc_num(age, "age", 18, 100),
    sex = .rc_choice(sex, "sex", c(male = 0, m = 0, female = 1, f = 1)),
    black = .rc_yesno(black, "black"),
    hisp = .rc_yesno(hispanic, "hispanic"),
    sysbp = .rc_num(sbp, "sbp", 60, 260),
    bprx = .rc_yesno(bp_meds, "bp_meds"),
    cursmoke = .rc_yesno(smoker, "smoker"),
    cvdhist = .rc_yesno(cvd_history, "cvd_history"),
    oralrx = .rc_yesno(oral_dm_meds, "oral_dm_meds"),
    statin = .rc_yesno(statin, "statin"),
    anticoag = .rc_yesno(anticoagulant, "anticoagulant"),
    hgba1c = .rc_num(hba1c, "hba1c", 3, 20))
  if (units == "si") {
    lab <- c(totchol = .rc_num(total_chol, "total_chol", 1, 15) * 38.67,
             hdlchol = .rc_num(hdl, "hdl", 0.2, 5) * 38.67,
             sercreat = .rc_num(creatinine, "creatinine", 10, 1500) / 88.4,
             uralbcreat = .rc_num(uacr, "uacr", 0, 1500) * 8.84)
  } else {
    lab <- c(totchol = .rc_num(total_chol, "total_chol", 40, 600),
             hdlchol = .rc_num(hdl, "hdl", 8, 200),
             sercreat = .rc_num(creatinine, "creatinine", 0.1, 15),
             uralbcreat = .rc_num(uacr, "uacr", 0, 13000))
  }
  x <- c(x, lab)

  risk <- vapply(.rc_eq, function(eq) {
    lp <- sum(eq$coef * x[names(eq$coef)]) + eq$offset
    1 - eq$s0^exp(lp)
  }, numeric(1))

  notes <- character(0)
  if (x[["age"]] < 40 || x[["age"]] > 79) {
    notes <- c(notes, "Age is outside ACCORD's range (40-79).")
  }
  list(risk = as.list(risk),
       calculator_percent = as.list(round(100 * risk)),
       definitions = .rc_definitions,
       inputs_conventional = as.list(x),
       notes = notes)
}

.rc_definitions <- list(
  nephropathy = "Renal failure, end-stage renal disease (dialysis) or serum creatinine > 3.3 mg/dL",
  retinopathy = "Severe vision loss (visual acuity < 20/200)",
  neuropathy = "Loss of pressure sensation",
  ascvd = "First fatal or non-fatal myocardial infarction or stroke",
  chf = "Congestive heart failure",
  mortality = "Death from any cause")

.rc_num <- function(x, field, lo, hi) {
  if (is.character(x)) x <- suppressWarnings(as.numeric(x))
  if (!is.numeric(x) || length(x) != 1L || is.na(x) || x < lo || x > hi) {
    stop("`", field, "` must be a number from ", lo, " to ", hi, ".", call. = FALSE)
  }
  as.numeric(x)
}

.rc_choice <- function(x, field, map) {
  key <- gsub("[^a-z0-9]", "", tolower(as.character(x)))
  if (length(key) != 1L || !key %in% names(map)) {
    stop("Unrecognised `", field, "`: \"", paste(x, collapse = ","), "\".", call. = FALSE)
  }
  map[[key]]
}

.rc_yesno <- function(x, field) {
  if (is.logical(x) && length(x) == 1L && !is.na(x)) return(as.numeric(x))
  .rc_choice(x, field, c(yes = 1, y = 1, true = 1, `1` = 1, no = 0, n = 0, false = 0, `0` = 0))
}
