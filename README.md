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

CxGcensus is not avialable on CRAN or Bioconductor, it can be
installed using the [remotes][] package.

``` r
if (!"remotes" %in% rownames(installed.packages()))
    install.packages("remotes", repos = "https://cran.r-project.org")
```

CxGcensus imports two packages that are not available through
CRAN. [tiledbsoma][], is not supported on Windows, must be installed
from source, and has C++ code so requires a correctly installed
compiler (see [instructions][macOS-installation] for macOS XCode
installation).

``` r
remotes::install_git(
    "https://github.com/single-cell-data/TileDB-SOMA.git",
    subdir = "apis/r"
)
```

Install CxGcensus from [GitHub](https://github.com/) with:

``` r
remotes::install_github("mtmorgan/CxGcensus")
```

This should also install [cellxgene.census][]

CxGcensus uses [arrow][] 'dataset' capabilities, so it must be the case that

``` r
arrow::arrow_info()$capabilities[["dataset"]]
```

returns `TRUE`. This should be the case for linux, and for macOS
binary installations from CRAN. I needed to install [arrow][] from
source on macOS, and had success by (a) using `brew install
apache-arrow` and (b) cloning the arrow GitHub repository, changing to
the `apache/R` directory, checking out the release tag with the same
version as installed by brew, and building

``` sh
brew install apache-arrow # installs, e.g., 13.0.0
git clone https://github.com/apache/arrow/
cd arrow/R
git tag | grep 13.0.0
git checkout -b apache-arrow-13.0.0 apache-arrow-13.0.0
R CMD INSTALL .
```

[remotes]: https://cran.r-project.org/package=remotes
[macOS-installation]: https://mac.r-project.org/tools/
[tiledbsoma]: https://github.com/single-cell-data/TileDB-SOMA/tree/main/apis/r
[cellxgene.census]: https://chanzuckerberg.github.io/cellxgene-census/
[arrow]: https://cran.r-project.org/package=arrow

Articles available for further exploration include

- [A. Data Discovery and Retrieval](articles/a_discovery_and_retrieval.html)
- [B. Dataset Integeration](articles/b_integration.html)
- [C. Comparison with CuratedAtlasQuery and cellxgene.census](articles/c_compare.html)
