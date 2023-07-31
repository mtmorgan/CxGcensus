census_version <- "2023-07-25" # pinned test version
test_versions <- c(census_version, "stable", "latest")
organisms <- c("mus_musculus", "homo_sapiens")

test_that("feature_data() works", {
    minimum_columns <- c(
        "soma_joinid", "feature_id", "feature_name", "feature_length"
    )

    for (organism in organisms) {
        result <- feature_data(organism, census_version)
        expect_s3_class(result, "tbl_df")
        expect_true(all(colnames(result) %in% minimum_columns))
        expect_true(nrow(result) >= 52392L)
    }
})
