# Runs the RECODe authors' own server expressions (app.R, commit 63135bd8) on
# a set of cases, with round() replaced by identity so the unrounded risks
# come out. Nothing else in the code is changed. Writes JSON fixtures.
args <- commandArgs(TRUE); app <- args[1]; out <- args[2]
exprs <- parse(app)
srv <- Filter(function(e) is.call(e) && as.character(e[[1]]) %in% c("=", "<-") &&
                identical(as.character(e[[2]]), "server"), as.list(exprs))[[1]]
server_body <- srv[[3]][[3]]   # body of function(input, output)
run_case <- function(inp) {
  env <- new.env()
  env$input <- lapply(inp, as.character)   # Shiny inputs arrive as strings
  env$output <- new.env()
  env$round <- function(x, digits = 0) x
  env$reactive <- function(expr) { ex <- substitute(expr); en <- parent.frame(); function() eval(ex, en) }
  env$renderText <- function(...) NULL
  env$renderDataTable <- function(...) NULL
  eval(server_body, env)
  sapply(c("neph_beta", "retin_beta", "neuro_beta", "mi_beta", "chf_beta", "death_beta"),
         function(f) env[[f]]())
}
keys <- c("age","sex","black","hisp","sysbp","bprx","cursmoke","cvdhist","oralrx","statin","anticoag","hgba1c","totchol","hdlchol","sercreat","uralbcreat")
cases <- list(
  c(60,0,0,0,140,0,0,0,0,0,0,8,190,50,1.1,10),
  c(68,1,1,0,155,1,1,1,1,1,0,9.2,210,42,1.4,120),
  c(45,0,0,1,120,0,0,0,1,0,0,7.1,170,55,0.8,5),
  c(75,0,0,0,170,1,0,1,1,1,1,10.5,240,35,2.1,600),
  c(55,1,0,1,130,1,1,0,0,1,0,8.4,200,60,0.7,25),
  c(62,0,1,0,145,1,0,0,1,0,1,11.0,185,38,1.6,300),
  c(79,1,0,0,135,1,0,1,0,1,0,6.8,160,65,1.0,15),
  c(40,0,0,0,118,0,1,0,1,0,0,12.0,260,30,0.9,40),
  c(70,1,1,0,165,1,1,1,1,0,1,8.0,190,45,2.8,1500),
  c(58,0,0,1,138,0,0,1,1,1,0,7.6,175,48,1.2,60),
  c(66,1,0,0,150,1,0,0,1,1,0,9.8,220,52,1.1,8),
  c(50,1,1,1,125,0,0,0,1,1,0,7.5,180,55,0.9,12),
  c(72,0,0,0,180,1,1,1,0,0,0,9.0,230,40,1.8,250),
  c(48,1,0,0,110,0,0,0,0,0,1,6.5,150,70,0.6,3))
res <- lapply(cases, function(v) list(inputs = setNames(as.list(v), keys),
                                      percent = as.list(run_case(setNames(as.list(v), keys)))))
jsonlite::write_json(res, out, auto_unbox = TRUE, digits = NA, pretty = TRUE)
cat("cases:", length(res), "\n")
print(round(t(sapply(res, function(r) unlist(r$percent)))[1:3, ], 6))
