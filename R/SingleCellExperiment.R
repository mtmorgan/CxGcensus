single_cell_experiment_constructor <-
    function()
{
    if (!requireNamespace("SingleCellExperiment", quietly = TRUE)) {
        stop(wrap(
            "install 'SingleCellExperiment' with ",
            "`BiocManager::install('SingleCellExperiment')`"
        ))
    }
    SingleCellExperiment::SingleCellExperiment
}
