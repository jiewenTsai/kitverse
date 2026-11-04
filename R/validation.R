# Validation reports of the kitverse packages (inst/validation/validation.md in each package;
# the standard is kitDesign's inst/validation/criteria.md)

#' Validation reports of the kitverse packages
#'
#' Every kitverse package keeps a validation report, written to the KIT validation standard
#' (`kitDesign::kit_validation("kitDesign", "criteria")`). With no `package`, lists the reports of
#' kitverse and its core packages: the installed file and the address on GitHub. With a `package`,
#' opens that report.
#'
#' @param package `NULL` to list, or one of `"kitverse"`, `"kits"`, `"kitsUI"`, `"kitJoin"`,
#'   `"kitDesign"`, or `"criteria"` for the standard itself.
#' @param open Open the report (with `package`).
#' @return Without `package`, a data frame (`package`, `version`, `file`, `url`; `file` is `NA` when
#'   the installed version has no report yet). With `package`, the path of the report, invisibly.
#' @examples
#' kitverse_validation()
#' @export
kitverse_validation <- function(package = NULL, open = interactive()) {
  pkgs <- c("kitverse", ktv_core())
  if (is.null(package)) {
    have <- vapply(pkgs, function(p) nzchar(system.file(package = p)), logical(1))
    pkgs <- pkgs[have]
    return(data.frame(
      package = pkgs,
      version = vapply(pkgs, function(p) as.character(utils::packageVersion(p)), character(1)),
      file = vapply(pkgs, function(p) kitDesign::kit_validation(p, open = FALSE), character(1)),
      url = vapply(pkgs, kitDesign::kit_validation_url, character(1)),
      row.names = NULL, stringsAsFactors = FALSE
    ))
  }
  if (identical(package, "criteria")) {
    return(invisible(kitDesign::kit_validation("kitDesign", "criteria", open = open)))
  }
  if (!package %in% pkgs) {
    stop("`package` is one of ", paste(c(pkgs, "criteria"), collapse = ", "), call. = FALSE)
  }
  path <- kitDesign::kit_validation(package, open = open)
  if (is.na(path)) {
    message("The installed ", package, " has no report yet: ", kitDesign::kit_validation_url(package))
  }
  invisible(path)
}
