# CxGcensus

<!-- badges: start -->
<!-- badges: end -->

CxGcensus is an alternative *R* client to the [CELLxGENE
census](https://chanzuckerberg.github.io/cellxgene-census/). It
emaphsizes use cases related to data discovery, and uses in-memory and
on-disk caches to reduce latency associated with repeated queries.

CELLxGENE census is an internet resource providing access to hundreds
of human and mouse single-cell RNA-seq datasets. 'CxGcensus' is an
interface to this resource, allowing discovery and download of
datasets, features (genes), and observations (individual cells) from
across experiments. Datasets, features, and observations are
accessible as familiar 'tibbles'; measures of single-cell expression
are presented in the R / Bioconductor 'SingleCellExperiment' data
representation for easy integration with, for example, 'Orchestrating
Single-Cell Analysis with Bioconductor'
([OSCA](https://bioconductor.org/books/OSCA)).

Install CxGcensus from [GitHub](https://github.com/) with:

``` r
## install.packages("devtools")
devtools::install_github("mtmorgan/CxGcensus")
```

Articles available for further exploration include

- [A. Data Discovery and Retrieval](articles/a_discovery_and_retrieval.html)
- [B. Dataset Integeration](articles/b_integration.html)
