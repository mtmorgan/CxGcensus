census_version <- "2023-07-25" # pinned test version
test_versions <- c(census_version, "stable", "latest")

test_that("datasets() works", {
    minimum_columns <- c(
        "soma_joinid", "collection_id", "collection_name",
        "collection_doi", "dataset_id", "dataset_title",
        "dataset_h5ad_path", "dataset_total_cell_count"
    )

    for (version in test_versions) {
        result <- datasets(version)
        expect_s3_class(result, "tbl_df")
        expect_true(all(colnames(result) %in% minimum_columns))
        expect_true(nrow(result) >= 593L)
    }
})

test_that("summary_cell_counts() works", {
    minimum_columns <- c(
        "soma_joinid", "organism", "category", "ontology_term_id",
        "unique_cell_count", "total_cell_count", "label"
    )
    minimum_categories <- c(
        "all", "assay", "cell_type", "disease",
        "self_reported_ethnicity",
        "sex", "suspension_type", "tissue", "tissue_general"
    )

    for (version in test_versions) {
        result <- summary_cell_counts(version)
        expect_s3_class(result, "tbl_df")
        expect_true(all(colnames(result) %in% minimum_columns))
        categories <-
            result |>
            distinct(category) |>
            pull()
        expect_true(all(categories %in% minimum_categories))
        expect_true(nrow(result) >= 1362L)
    }
})
