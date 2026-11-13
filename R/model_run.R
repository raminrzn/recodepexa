.rc_vars <- c("age", "sex", "black", "hispanic", "sbp", "bp_meds", "smoker", "cvd_history",
              "oral_dm_meds", "statin", "anticoagulant", "hba1c", "total_chol", "hdl",
              "creatinine", "uacr", "units")
.rc_alias <- c(hisp = "hispanic", sysbp = "sbp", bprx = "bp_meds", cursmoke = "smoker",
               current_smoker = "smoker", cvdhist = "cvd_history", oralrx = "oral_dm_meds",
               anticoag = "anticoagulant", hgba1c = "hba1c", totchol = "total_chol",
               hdlchol = "hdl", sercreat = "creatinine", uralbcreat = "uacr", acr = "uacr")

#' RECODe (ModelsCloud entry point)
#' @param model_input Named list of inputs; see [recode_risk()].
#' @param ... The same fields as named arguments.
#' @return See [recode_risk()].
#' @export
model_run <- function(model_input = NULL, ...) {
  args <- .rc_normalize(model_input, list(...), .rc_vars, .rc_alias)
  if (is.null(args)) stop("No input supplied.", call. = FALSE)
  do.call(recode_risk, args)
}

#' Example RECODe inputs
#' @param n Optional number of rows.
#' @param ... Ignored.
#' @export
get_sample_input <- function(n = NULL, ...) {
  rows <- list(get_default_input(),
               list(age = 68, sex = "female", black = "yes", hispanic = "no", sbp = 155,
                    bp_meds = "yes", smoker = "yes", cvd_history = "yes", oral_dm_meds = "yes",
                    statin = "yes", anticoagulant = "no", hba1c = 9.2, total_chol = 210,
                    hdl = 42, creatinine = 1.4, uacr = 120))
  if (!is.null(n)) rows <- utils::head(rows, n)
  rows
}

#' Default RECODe input: the paper's worked example (and the calculator's defaults)
#' @param ... Ignored.
#' @export
get_default_input <- function(...) {
  list(age = 60, sex = "male", black = "no", hispanic = "no", sbp = 140, bp_meds = "no",
       smoker = "no", cvd_history = "no", oral_dm_meds = "no", statin = "no",
       anticoagulant = "no", hba1c = 8, total_chol = 190, hdl = 50, creatinine = 1.1,
       uacr = 10)
}
