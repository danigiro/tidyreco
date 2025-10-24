map <- function(.x, .f, ...) {
  lapply(.x, .f, ...)
}

map_mold <- function(...) {
  out <- vapply(..., USE.NAMES = FALSE)
  names(out) <- names(..1)
  out
}

map_dbl <- function(.x, .f, ...) {
  map_mold(.x, .f, double(1), ...)
}

map_chr <- function(.x, .f, ...) {
  map_mold(.x, .f, character(1), ...)
}

map_lgl <- function(.x, .f, ...) {
  map_mold(.x, .f, logical(1), ...)
}

dist_types <- function(dist) {
  map_chr(vctrs::vec_data(dist), function(x) class(x)[1])
}

map2 <- function(.x, .y, .f, ...) {
  mapply(.f, .x, .y, MoreArgs = list(...), SIMPLIFY = FALSE)
}

calc <- function(f, ...) {
  f(...)
}

reduce <- function(.x, .f, ..., .init) {
  f <- function(x, y) .f(x, y, ...)
  Reduce(f, .x, init = .init)
}
