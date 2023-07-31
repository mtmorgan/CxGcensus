census_version <- "2023-07-25" # pinned test version
test_versions <- c(census_version, "stable", "latest")

test_that("census_versions() works", {
    expect_silent(response <- census_versions())
    expect_s3_class(response, "tbl_df")
    expect_setequal(response$status, c(NA, "stable", "latest"))
})

test_that("census_version() works", {
    for (version in test_versions) {
        version <- census_version(version)
        expect_type(version, "character")
        expect_true(is_census_version(version))
    }
    expect_error(census_version("foo"))
})

test_that("census() works", {
    for (version in test_versions) {
        expect_silent(response <- census(version))
        expect_true(inherits(response, "SOMACollection"))
        expect_identical(
            names(response$to_list()),
            c("census_data", "census_info")
        )
    }
})

test_that("census_id() works", {
    expect_silent(response <- census_id(census_version))
    expect_identical(response, "75c2fc7")
})

test_that("census_names() works", {
    for (version in test_versions) {
        expect_silent(response <- census_names(version))
        expect_setequal(response, c("mus_musculus", "homo_sapiens"))
    }
})
