#' @title Run DESeq2 for computed sample combinations
#'
#' @description
#' \code{erssa_deseq2} function runs DESeq2 Wald test to identify
#' differentially expressed (DE) genes for each sample combination computed by
#' \code{comb_gen} function. A gene is considered to be
#' differentially expressed by defined padj (Default=0.05) and log2FoldChange
#' (Default=1) values. As an option, the function can also save the DESeq2
#' result tables as csv files to the drive.
#'
#' @details
#' The main function calls DESeq2 functions to perform Wald test for each
#' computed combinations generated by \code{comb_gen}. In all tests, the
#' pair-wise test sets the condition defined in the object "control" as the
#' control condition.
#'
#' In typical usage, after each test, the list of differentially expressed genes
#' are filtered by padj and log2FoldChange values and only the filtered gene
#' names are saved for further analysis. However, it is also possible
#' to save all of the generated result tables to the drive for additional
#' analysis that is outside the scope of this package.
#'
#' @param count_table.filtered Count table pre-filtered to remove non- to low-
#' expressing genes. Can be the output of \code{count_filter} function.
#' @param combinations List of combinations that is produced by \code{comb_gen}
#'  function.
#' @param condition_table A condition table with two columns and each sample as
#' a row. Column 1 contains sample names and Column 2 contains sample condition
#' (e.g. Control, Treatment).
#' @param control One of the condition names that will serve as control.
#' @param cutoff_stat The cutoff in padj for DE consideration. Genes with lower
#'  padj pass the cutoff. Default = 0.05.
#' @param cutoff_Abs_logFC The cutoff in abs(log2FoldChange) for differential
#' expression consideration. Genes with higher abs(log2FoldChange) pass
#' the cutoff. Default = 1.
#' @param save_table Boolean. When set to TRUE, function will, in addition, save
#' the generated DESeq2 result table as csv files. The files are saved on the
#' drive in the working directory in a new folder named "ERSSA_DESeq2_table".
#' Tables are saved separately by the replicate level. Default = FALSE.
#'
#' @return A list of list of vectors. Top list contains elements corresponding to
#' replicate levels. Each child list contains elements corresponding to each
#' combination at the respective replicate level. The child vectors contain
#' differentially expressed gene names.
#' @param path Path to which the files will be saved. Default to current working
#' directory.
#'
#' @author Zixuan Shao, \email{Zixuanshao.zach@@gmail.com}
#'
#' @examples
#' # load example filtered count_table, condition_table and combinations
#' # generated by comb_gen function
#' # example dataset containing 1000 genes, 4 replicates and 5 comb. per rep.
#' # level
#' data(count_table.filtered.partial, package = "ERSSA")
#' data(combinations.partial, package = "ERSSA")
#' data(condition_table.partial, package = "ERSSA")
#'
#' # run erssa_deseq2 with heart condition as control
#' deg.partial = erssa_deseq2(count_table.filtered.partial,
#'   combinations.partial, condition_table.partial, control='heart')
#'
#' @references
#' Love MI, Huber W, Anders S (2014). “Moderated estimation of fold change and
#' dispersion for RNA-seq data with DESeq2.” Genome Biology, 15, 550. doi:
#' 10.1186/s13059-014-0550-8.
#'
#' @export
#'
#' @importFrom utils write.csv
#' @importFrom DESeq2 DESeqDataSetFromMatrix
#' @importFrom stats relevel
#' @importFrom DESeq2 DESeq
#' @importFrom DESeq2 lfcShrink

erssa_deseq2 = function(count_table.filtered=NULL, combinations=NULL,
                        condition_table=NULL, control=NULL, cutoff_stat = 0.05,
                        cutoff_Abs_logFC = 1, save_table=FALSE, path='.'){

    # check all required arguments supplied
    if (is.null(count_table.filtered)){
        stop(paste0('Missing required count_table.filtered argument in ',
                    'erssa_deseq2 function'))
    } else if (is.null(combinations)){
        stop("Missing required combinations argument in erssa_deseq2 function")
    } else if (is.null(condition_table)){
        stop(paste0("Missing required condition_table argument in erssa_deseq2",
                    " function"))
    } else if (is.null(control)){
        stop("Missing required control argument in erssa_deseq2 function")
    } else if (!(is.data.frame(count_table.filtered))){
        stop('count_table is not an expected data.frame object')
    } else if (length(unique(sapply(count_table.filtered, class)))!=1){
        stop(paste0('More than one data type detected in count table, please ',
                    'make sure count table contains only numbers and that the ',
                    'list of gene names is the data.frame index'))
    } else if (!(is.data.frame(condition_table))){
        stop('condition_table is not an expected data.frame object')
    }

    message(paste0('Start DESeq2 Wald test with padj cutoff = ',cutoff_stat,
                   ', Abs(log2FoldChange) cutoff = ', cutoff_Abs_logFC,'\n'))
    message(paste0('Save results tables to drive: ', save_table,'\n'))

    # rename input condition table column name
    colnames(condition_table) = c('sample_name','condition')

    # check control is one of the two conditions
    if (!(control %in% condition_table$condition)){
        stop('Control name does not match one of the two sample conditions')
    }

    if (save_table==TRUE){
        # create dir to save results
        folder_path = file.path(path, 'ERSSA_DESeq2_table')
        dir.create(folder_path, showWarnings = FALSE)
    }

    # loop through each replicate level
    DE_genes = lapply(names(combinations), function(rep_level) {

        comb_rl = combinations[rep_level][[1]]

        if (save_table==TRUE){
            # create dir to save results
            folder_path = file.path(path, 'ERSSA_DESeq2_table', rep_level)
            dir.create(folder_path, showWarnings = FALSE)
        }

        DE_genes_rl = lapply(seq_along(comb_rl), function(index) {

            # combination string to vector
            comb_samples_i = strsplit(comb_rl[index], ';')[[1]]

            # parse out sample counts
            count_table.filtered_i = count_table.filtered[,colnames(
                count_table.filtered) %in% comb_samples_i]

            # DESeq2
            group = sapply(colnames(count_table.filtered_i), function(x)
                condition_table$condition[
                    which(condition_table$sample_name==x)])
            group=as.data.frame(group)
            dds = DESeqDataSetFromMatrix(countData = count_table.filtered_i,
                                         colData = group,
                                         design = ~ group)
            dds$group = relevel(dds$group, ref = control)
            dds = DESeq(dds, quiet=TRUE)
            resLFC = lfcShrink(dds, coef=2)

            res_cutoff = resLFC[which(resLFC$padj < cutoff_stat & abs(
                resLFC$log2FoldChange) > cutoff_Abs_logFC),]

            # save entire result table to drive
            if (save_table==TRUE){
                write.csv(resLFC, file = file.path(folder_path,paste0(
                    'ERSSA_DESeq2_',rep_level,'_comb',index,'.csv')))
            }

            message(paste0(rep_level,'; combination_',index,' | done\n'))

            # save list of DE genes to list
            return(rownames(res_cutoff))
        })

        # rename list name
        names(DE_genes_rl) = paste0('comb_', seq_along(DE_genes_rl))

        # add DE gene lists to main list
        return(DE_genes_rl)
    })

    names(DE_genes) = names(combinations)


    return(DE_genes)
}


#' @title Run DESeq2 for computed sample combinations with parallel computing
#'
#' @description
#' \code{erssa_deseq2_parallel} function performs the same calculation as
#' \code{erssa_deseq2} except now employs BiocParallel to perform parallel
#' DESeq2 calculations. This function runs DESeq2 Wald test to identify
#' differentially expressed (DE) genes for each sample combination computed by
#' \code{comb_gen} function. A gene is considered to be
#' differentially expressed by defined padj (Default=0.05) and log2FoldChange
#' (Default=1) values. As an option, the function can also save the DESeq2
#' result tables as csv files to the drive.
#'
#' @details
#' The main function calls DESeq2 functions to perform Wald test for each
#' computed combinations generated by \code{comb_gen}. In all tests, the
#' pair-wise test sets the condition defined in the object "control" as the
#' control condition.
#'
#' In typical usage, after each test, the list of differentially expressed genes
#' are filtered by padj and log2FoldChange values and only the filtered gene
#' names are saved for further analysis. However, it is also possible
#' to save all of the generated result tables to the drive for additional
#' analysis that is outside the scope of this package.
#'
#' @param count_table.filtered Count table pre-filtered to remove non- to low-
#' expressing genes. Can be the output of \code{count_filter} function.
#' @param combinations List of combinations that is produced by \code{comb_gen}
#' function.
#' @param condition_table A condition table with two columns and each sample as
#' a row. Column 1 contains sample names and Column 2 contains sample condition
#' (e.g. Control, Treatment).
#' @param control One of the condition names that will serve as control.
#' @param cutoff_stat The cutoff in padj for DE consideration. Genes with lower
#' padj pass the cutoff. Default = 0.05.
#' @param cutoff_Abs_logFC The cutoff in abs(log2FoldChange) for differential
#' expression consideration. Genes with higher abs(log2FoldChange) pass the
#' cutoff. Default = 1.
#' @param save_table Boolean. When set to TRUE, function will, in addition, save
#' the generated DESeq2 result table as csv files. The files are saved on the
#' drive in the working directory in a new folder named "ERSSA_DESeq2_table".
#' Tables are saved separately by the replicate level. Default = FALSE.
#' @param path Path to which the files will be saved. Default to current working
#' directory.
#' @param num_workers Number of workers for parallel computing. Default=1.
#'
#' @return A list of list of vectors. Top list contains elements corresponding to
#' replicate levels. Each child list contains elements corresponding to
#' each combination at the respective replicate level. The child vectors
#' contain differentially expressed gene names.
#'
#' @author Zixuan Shao, \email{Zixuanshao.zach@@gmail.com}
#'
#' @examples
#' # load example filtered count_table, condition_table and combinations
#' # generated by comb_gen function
#' # example dataset containing 1000 genes, 4 replicates and 5 comb. per rep.
#' # level
#' data(count_table.filtered.partial, package = "ERSSA")
#' data(combinations.partial, package = "ERSSA")
#' data(condition_table.partial, package = "ERSSA")
#'
#' # run erssa_deseq2_parallel with heart condition as control
#' deg.partial = erssa_deseq2_parallel(count_table.filtered.partial,
#' combinations.partial, condition_table.partial, control='heart',
#' num_workers=1)
#'
#' @references
#' Morgan M, Obenchain V, Lang M, Thompson R, Turaga N (2018). BiocParallel:
#' Bioconductor facilities for parallel evaluation. R package version 1.14.1,
#' https://github.com/Bioconductor/BiocParallel.
#'
#' Love MI, Huber W, Anders S (2014). “Moderated estimation of fold change and
#' dispersion for RNA-seq data with DESeq2.” Genome Biology, 15, 550. doi:
#' 10.1186/s13059-014-0550-8.
#'
#' @export
#'
#' @importFrom utils write.csv
#' @importFrom DESeq2 DESeqDataSetFromMatrix
#' @importFrom stats relevel
#' @importFrom DESeq2 DESeq
#' @importFrom DESeq2 lfcShrink
#' @importFrom BiocParallel SnowParam
#' @importFrom BiocParallel bplapply

erssa_deseq2_parallel = function(count_table.filtered=NULL, combinations=NULL,
                                 condition_table=NULL, control=NULL,
                                 cutoff_stat = 0.05, cutoff_Abs_logFC = 1,
                                 save_table=FALSE, path='.', num_workers=1){

    # check all required arguments supplied
    if (is.null(count_table.filtered)){
        stop(paste0('Missing required count_table.filtered argument in ',
                    'erssa_deseq2_parallel function'))
    } else if (is.null(combinations)){
        stop(paste0("Missing required combinations argument in ",
                    "erssa_deseq2_parallel function"))
    } else if (is.null(condition_table)){
        stop(paste0("Missing required condition_table argument in ",
                    "erssa_deseq2_parallel function"))
    } else if (is.null(control)){
        stop(paste0("Missing required control argument in ",
                    "erssa_deseq2_parallel function"))
    } else if (!(is.data.frame(count_table.filtered))){
        stop('count_table is not an expected data.frame object')
    } else if (length(unique(sapply(count_table.filtered, class)))!=1){
        stop(paste0('More than one data type detected in count table, please ',
                    'make sure count table contains only numbers and that the ',
                    'list of gene names is the data.frame index'))
    } else if (!(is.data.frame(condition_table))){
        stop('condition_table is not an expected data.frame object')
    }

    message(paste0('Start DESeq2 Wald test with padj cutoff = ',cutoff_stat,
                   ', Abs(log2FoldChange) cutoff = ', cutoff_Abs_logFC,'\n'))
    message(paste0('Save results tables to drive: ', save_table,'\n'))
    message(paste0('Run parallel DESeq2 with ',num_workers, ' workers\n'))

    # rename input condition table column name
    colnames(condition_table) = c('sample_name','condition')

    # check control is one of the two conditions
    if (!(control %in% condition_table$condition)){
        stop('Control name does not match one of the two sample conditions')
    }

    folder_path = file.path(path, 'ERSSA_DESeq2_table')
    if (save_table==TRUE){
        # create dir to save results
        dir.create(folder_path, showWarnings = FALSE)
    }

    # loop through each replicate level
    DE_genes = lapply(names(combinations), function(rep_level) {

        comb_rl = combinations[rep_level][[1]]

        if (save_table==TRUE){
            # create dir to save results
            folder_path = file.path(path, 'ERSSA_DESeq2_table', rep_level)
            dir.create(folder_path, showWarnings = FALSE)
        }

        deseq2_par = function(index, rep_level, comb_rl, count_table.filtered,
                              condition_table, control, cutoff_stat,
                              cutoff_Abs_logFC, folder_path, save_table){

            # combination string to vector
            comb_samples_i = strsplit(comb_rl[index], ';')[[1]]

            # parse out sample counts
            count_table.filtered_i = count_table.filtered[,colnames(
                count_table.filtered) %in% comb_samples_i]

            # DESeq2
            group = sapply(colnames(count_table.filtered_i), function(x)
                condition_table$condition[which(
                    condition_table$sample_name==x)])
            group=as.data.frame(group)
            dds = DESeq2::DESeqDataSetFromMatrix(countData =
                                                     count_table.filtered_i,
                                                 colData = group,
                                                 design = ~ group)
            dds$group = relevel(dds$group, ref = control)
            dds = DESeq2::DESeq(dds, quiet=TRUE)
            resLFC = DESeq2::lfcShrink(dds, coef=2)

            res_cutoff = resLFC[which(resLFC$padj < cutoff_stat &
                                          abs(resLFC$log2FoldChange) >
                                          cutoff_Abs_logFC),]

            # save entire result table to drive
            if (save_table==TRUE){
                write.csv(resLFC, file = file.path(
                    folder_path,paste0('ERSSA_DESeq2_',rep_level,'_comb',
                                       index,'.csv')))
            }

            return(rownames(res_cutoff))
        }

        param = SnowParam(workers = num_workers, type = "SOCK")

        DE_genes_rl=bplapply(X=seq_along(comb_rl),
                             FUN=deseq2_par, BPPARAM = param,
                             rep_level, comb_rl, count_table.filtered,
                             condition_table, control, cutoff_stat,
                             cutoff_Abs_logFC, folder_path,
                             save_table)
        names(DE_genes_rl) = sapply(seq_along(DE_genes_rl),
                                    function(x) paste0('comb_',x))

        # add DE gene lists to main list
        message(paste0(rep_level,' combinations | done\n'))
        return(DE_genes_rl)
    })

    names(DE_genes) = names(combinations)

    return(DE_genes)
}

