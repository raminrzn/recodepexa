yn <- function(v) if (v == 1) "yes" else "no"
from_codes <- function(v, ...) recode_risk(
  age = v[1], sex = if (v[2] == 1) "female" else "male", black = yn(v[3]), hispanic = yn(v[4]),
  sbp = v[5], bp_meds = yn(v[6]), smoker = yn(v[7]), cvd_history = yn(v[8]),
  oral_dm_meds = yn(v[9]), statin = yn(v[10]), anticoagulant = yn(v[11]), hba1c = v[12],
  total_chol = v[13], hdl = v[14], creatinine = v[15], uacr = v[16], ...)

test_that("the paper's worked examples", {
  # 60-year-old white non-smoking man, SBP 140, no CVD, no medicines, HbA1c 8%,
  # total cholesterol 190, HDL 50, creatinine 1.1, ACR 10. The paper gives
  # renal failure/ESRD ~0.085, pressure sensation loss ~0.13 and all-cause
  # mortality ~0.09 (computed with its rounded coefficients and means).
  r <- do.call(recode_risk, get_default_input())$risk
  expect_equal(round(r$nephropathy, 3), 0.085, tolerance = 0.01)
  expect_equal(round(r$neuropathy, 2), 0.13)
  expect_equal(round(r$mortality, 2), 0.09)
})

test_that("results equal the authors' live calculator (sanjaybasu.shinyapps.io/recode)", {
  # Its defaults show 9, 9, 13, 18, 3 and 9%; 10 more cases were entered on
  # 13 November 2026 (inputs in app.R order: age, female, black, hispanic, SBP,
  # BP drugs, smoker, CVD history, oral drugs, statin, anticoagulant, HbA1c,
  # total and HDL cholesterol, creatinine, ACR). It shows whole percentages.
  expect_equal(unname(unlist(do.call(recode_risk, get_default_input())$calculator_percent)),
               c(9, 9, 13, 18, 3, 9))
  for (l in readLines(test_path("app_live_cases.txt"))) {
    p <- strsplit(l, " => ")[[1]]
    v <- as.numeric(strsplit(p[1], " ")[[1]])
    expect_equal(unname(unlist(from_codes(v)$calculator_percent)),
                 as.numeric(strsplit(p[2], " ")[[1]]), info = p[1])
  }
})

test_that("coefficients agree with the paper's Tables 2-4, except where documented", {
  # The paper prints 5 decimals (4 for some). Known differences between the
  # paper and the authors' calculator, which this package follows:
  #   renal failure/ESRD, Black: paper +0.08812, calculator -0.0881241594;
  #   ASCVD, age: paper 0.03412, calculator 0.03421;
  #   all-cause mortality, BP drugs: paper 0.08776, calculator 0.08766;
  #   neuropathy: the calculator's coefficients are the paper's rounded to 4
  #   significant digits.
  eq <- recodepexa:::.rc_eq
  paper_renal <- c(age = -0.01938, sex = -0.01129, black = 0.08812, hisp = 0.2338,
                   cursmoke = 0.1483, sysbp = 0.00303, cvdhist = -0.02164, bprx = -0.07952,
                   oralrx = -0.1256, anticoag = 0.03199, hgba1c = 0.1369, totchol = -0.00111,
                   hdlchol = 0.00629, sercreat = 0.8609, uralbcreat = 0.00036)
  d <- abs(eq$nephropathy$coef[names(paper_renal)] - paper_renal)
  expect_equal(names(d)[d > 6e-5], "black")
  expect_equal(unname(eq$nephropathy$coef["black"]), -paper_renal[["black"]], tolerance = 1e-4)
  expect_equal(unname(eq$ascvd$coef["age"]), 0.03421)
  expect_equal(unname(eq$mortality$coef["bprx"]), 0.08766)
  paper_neuro <- c(age = 0.03022, sex = -0.1868, black = -0.09448, sysbp = 0.00456,
                   cvdhist = 0.26672, bprx = 0.18192, oralrx = -0.25747, hgba1c = 0.18866,
                   totchol = 0.00219, hdlchol = -0.00539, sercreat = 0.60442)
  expect_equal(unname(signif(paper_neuro, 4)), unname(signif(eq$neuropathy$coef[names(paper_neuro)], 4)),
               tolerance = 2e-3)
  # Baseline survival and means (the calculator's micro means are more precise).
  expect_equal(unname(sapply(eq, `[[`, "s0")), c(0.973, 0.921, 0.87, 0.85, 0.96, 0.93))
  expect_equal(round(-unname(sapply(eq, `[[`, "offset")), 2), c(0.23, 4.56, 4.75, 3.65, 5.15, 4.66))
})

test_that("SI units use standard conversions", {
  conv <- do.call(recode_risk, get_default_input())
  si <- do.call(recode_risk, utils::modifyList(get_default_input(), list(
    units = "si", total_chol = 190 / 38.67, hdl = 50 / 38.67, creatinine = 1.1 * 88.4,
    uacr = 10 / 8.84)))
  expect_equal(si$risk, conv$risk, tolerance = 1e-12)
})

test_that("inputs are checked and notes given", {
  expect_error(do.call(recode_risk, utils::modifyList(get_default_input(), list(sex = "x"))), "sex")
  expect_error(do.call(recode_risk, utils::modifyList(get_default_input(), list(hba1c = 30))), "hba1c")
  young <- do.call(recode_risk, utils::modifyList(get_default_input(), list(age = 35)))
  expect_length(young$notes, 1)
})

test_that("gateway returns full precision", {
  g <- jsonlite::fromJSON(gateway(model_input = get_default_input()))
  r <- do.call(recode_risk, get_default_input())
  expect_equal(g$risk$ascvd, r$risk$ascvd, tolerance = 1e-13)
})
