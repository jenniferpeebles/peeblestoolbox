library(peeblestoolbox)

# Exercise the same reader with and without the BOM, including a legacy locale.
local({
  original_locale <- Sys.getlocale("LC_CTYPE")
  on.exit(Sys.setlocale("LC_CTYPE", original_locale), add = TRUE)
  source_path <- system.file("extdata", "msa_counties_2023.csv",
                             package = "peeblestoolbox")
  bytes <- readBin(source_path, "raw", n = file.info(source_path)$size)
  bom <- as.raw(c(0xef, 0xbb, 0xbf))
  if (identical(bytes[seq_len(3L)], bom)) bytes <- bytes[-seq_len(3L)]
  plain_path <- tempfile(fileext = ".csv")
  bom_path <- tempfile(fileext = ".csv")
  on.exit(unlink(c(plain_path, bom_path)), add = TRUE)
  writeBin(bytes, plain_path)
  writeBin(c(bom, bytes), bom_path)

  for (locale in unique(c(original_locale, "C"))) {
    stopifnot(nzchar(Sys.setlocale("LC_CTYPE", locale)))
    plain <- peeblestoolbox:::.msa_lookup(plain_path)
    marked <- peeblestoolbox:::.msa_lookup(bom_path)
    stopifnot(
      identical(plain, marked),
      identical(names(marked)[1L], "cbsa_code"),
      nrow(marked) == 1252L,
      all(nchar(marked$county_geoid) == 5L),
      identical(marked$county[marked$county_geoid == "72011"],
                "A\u00f1asco Municipio")
    )
    atlanta <- ga_msa_counties("12060")
    stopifnot(
      nrow(atlanta) == 29L,
      all(atlanta$cbsa_code == "12060"),
      all(atlanta$state_abbr == "GA"),
      identical(is_atlanta_msa(c("Fulton", "Lumpkin County", "Lamar")),
                c(TRUE, TRUE, FALSE)),
      identical(add_atlanta_msa(data.frame(county = c("Fulton", "Lamar")),
                               "county")$in_atlanta_msa, c(TRUE, FALSE))
    )
  }
})
