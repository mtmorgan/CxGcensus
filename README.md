
<!-- README.md is generated from README.Rmd. Please edit that file -->

# CxGcensus

<!-- badges: start -->
<!-- badges: end -->

CxGcensus is an alternative *R* client to the [CELLxGENE
census](https://chanzuckerberg.github.io/cellxgene-census/). It
emaphsizes use cases related to data discovery, and uses in-memory and
on-disk caches to reduce latency associated with repeated queries.

## Installation

Install CxGcensus from [GitHub](https://github.com/) with:

``` r
## install.packages("devtools")
devtools::install_github("mtmorgan/CxGcensus")
```

## Example

Load the package

``` r
library(CxGcensus)
```

Discover datasets available in the census

``` r
datasets()
#> # A tibble: 562 × 8
#>    soma_joinid collection_id           collection_name collection_doi dataset_id
#>          <int> <chr>                   <chr>           <chr>          <chr>     
#>  1           0 6b701826-37bb-4356-979… Abdominal Whit… <NA>           9d8e5dca-…
#>  2           1 4195ab4c-20bd-4cd3-8b3… A spatially re… <NA>           a6388a6f-…
#>  3           2 4195ab4c-20bd-4cd3-8b3… A spatially re… <NA>           842c6f5d-…
#>  4           3 4195ab4c-20bd-4cd3-8b3… A spatially re… <NA>           74520626-…
#>  5           4 4195ab4c-20bd-4cd3-8b3… A spatially re… <NA>           396a9124-…
#>  6           5 74e10dc4-cbb2-4605-a18… Spatial proteo… 10.1016/j.cel… e84f2780-…
#>  7           6 74e10dc4-cbb2-4605-a18… Spatial proteo… 10.1016/j.cel… dfdf1ae2-…
#>  8           7 74e10dc4-cbb2-4605-a18… Spatial proteo… 10.1016/j.cel… d1cbed97-…
#>  9           8 74e10dc4-cbb2-4605-a18… Spatial proteo… 10.1016/j.cel… b03e4ef8-…
#> 10           9 6d203948-a779-4b69-9b3… Differential c… 10.1016/j.cel… f1f123cc-…
#> # ℹ 552 more rows
#> # ℹ 3 more variables: dataset_title <chr>, dataset_h5ad_path <chr>,
#> #   dataset_total_cell_count <int>
```

Summarize information about cells in the census

``` r
summary_cell_counts() |>
    filter(category == "sex") |>
    select(
        organism, label,
        unique_cell_count, total_cell_count
    )
#> # A tibble: 6 × 4
#>   organism     label   unique_cell_count total_cell_count
#>   <chr>        <chr>               <int>            <int>
#> 1 Homo sapiens female           14516846         22513226
#> 2 Homo sapiens male             17097019         28197731
#> 3 Homo sapiens unknown           2145022          3083771
#> 4 Mus musculus female            1066585          1431227
#> 5 Mus musculus male              1655113          2462185
#> 6 Mus musculus unknown            192620           192620
```

Learn about features (genes) in, e.g., `homo_sapiens` datasets in the
census

``` r
feature_data("homo_sapiens")
#> # A tibble: 60,664 × 4
#>    soma_joinid feature_id      feature_name  feature_length
#>          <int> <chr>           <chr>                  <int>
#>  1           0 ENSG00000243485 MIR1302-2HG             1021
#>  2           1 ENSG00000237613 FAM138A                 1219
#>  3           2 ENSG00000186092 OR4F5                   2618
#>  4           3 ENSG00000238009 RP11-34P13.7            3726
#>  5           4 ENSG00000239945 RP11-34P13.8            1319
#>  6           5 ENSG00000239906 RP11-34P13.14            323
#>  7           6 ENSG00000241860 RP11-34P13.13           7559
#>  8           7 ENSG00000241599 RP11-34P13.9             457
#>  9           8 ENSG00000286448 AP006222.3               736
#> 10           9 ENSG00000236601 RP4-669L17.2            1095
#> # ℹ 60,654 more rows
```

## Session information

This README was compiled with CxGcensus version 0.0.0.9001. Full session
info is:

``` r
sessionInfo()
#> R version 4.3.0 Patched (2023-05-01 r84362)
#> Platform: aarch64-apple-darwin21.6.0 (64-bit)
#> Running under: macOS Monterey 12.6.6
#> 
#> Matrix products: default
#> BLAS:   /Users/ma38727/bin/R-4-3-branch/lib/libRblas.dylib 
#> LAPACK: /Users/ma38727/bin/R-4-3-branch/lib/libRlapack.dylib;  LAPACK version 3.11.0
#> 
#> locale:
#> [1] en_US.UTF-8/en_US.UTF-8/en_US.UTF-8/C/en_US.UTF-8/en_US.UTF-8
#> 
#> time zone: America/New_York
#> tzcode source: internal
#> 
#> attached base packages:
#> [1] stats     graphics  grDevices utils     datasets  methods   base     
#> 
#> other attached packages:
#> [1] CxGcensus_0.0.0.9001 RcppSpdlog_0.0.13    dplyr_1.1.2         
#> 
#> loaded via a namespace (and not attached):
#>  [1] utf8_1.2.3                  generics_0.1.3             
#>  [3] spdl_0.0.5                  xml2_1.3.4                 
#>  [5] tiledbsoma_0.0.0.9028       lattice_0.21-8             
#>  [7] digest_0.6.31               magrittr_2.0.3             
#>  [9] tiledb_0.19.1.8             evaluate_0.21              
#> [11] grid_4.3.0                  aws.s3_0.3.21              
#> [13] aws.signature_0.6.0         fastmap_1.1.1              
#> [15] jsonlite_1.8.5              Matrix_1.5-4.1             
#> [17] urltools_1.7.3              httr_1.4.6                 
#> [19] purrr_1.0.1                 fansi_1.0.4                
#> [21] cellxgene.census_0.0.0.9000 cli_3.6.1                  
#> [23] rlang_1.1.1                 triebeard_0.4.1            
#> [25] bit64_4.0.5                 withr_2.5.0                
#> [27] base64enc_0.1-3             cachem_1.0.8               
#> [29] yaml_2.3.7                  tools_4.3.0                
#> [31] nanotime_0.3.7              memoise_2.0.1              
#> [33] curl_5.0.1                  assertthat_0.2.1           
#> [35] vctrs_0.6.3                 R6_2.5.1                   
#> [37] zoo_1.8-12                  lifecycle_1.0.3            
#> [39] fs_1.6.2                    bit_4.0.5                  
#> [41] arrow_12.0.1                pkgconfig_2.0.3            
#> [43] pillar_1.9.0                glue_1.6.2                 
#> [45] data.table_1.14.8           Rcpp_1.0.10                
#> [47] xfun_0.39                   tibble_3.2.1               
#> [49] tidyselect_1.2.0            knitr_1.43                 
#> [51] htmltools_0.5.5             rmarkdown_2.22             
#> [53] compiler_4.3.0              RcppCCTZ_0.2.12
```
