# Accept wrapped or unwrapped input, map aliases, drop JSON nulls and empty
# strings (the platform's spelling of "not supplied"), keep known fields only.
.rc_normalize <- function(model_input, dots, vars, alias) {
  if (is.null(model_input)) {
    if (length(dots) == 0) return(NULL)
    model_input <- dots
  }
  if (is.list(model_input) && !is.data.frame(model_input)) {
    model_input <- model_input[!vapply(model_input, is.null, logical(1))]
  }
  out <- as.list(model_input)
  if (length(out) == 0) return(NULL)
  names(out) <- tolower(names(out))
  for (a in intersect(names(out), names(alias))) {
    canon <- alias[[a]]
    if (!canon %in% names(out)) names(out)[match(a, names(out))] <- canon
  }
  out <- out[intersect(names(out), vars)]
  out[!vapply(out, function(v) is.character(v) && length(v) == 1L &&
                !nzchar(trimws(v)), logical(1))]
}
