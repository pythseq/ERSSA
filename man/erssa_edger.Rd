% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/DE_edgeR.R
\name{erssa_edger}
\alias{erssa_edger}
\title{Run edgeR for computed sample combinations}
\usage{
erssa_edger(count_table.filtered = NULL, combinations = NULL,
  condition_table = NULL, control = NULL, cutoff_stat = 0.05,
  cutoff_Abs_logFC = 1, save_table = FALSE, path = ".")
}
\arguments{
\item{count_table.filtered}{Count table pre-filtered to remove non- to
low- expressing genes. Can be the output of \code{count_filter} function.}

\item{combinations}{List of combinations that is produced by \code{comb_gen}
function.}

\item{condition_table}{A condition table with two columns and each sample as
a row. Column 1 contains sample names and Column 2 contains sample condition
(e.g. Control, Treatment).}

\item{control}{One of the condition names that will serve as control.}

\item{cutoff_stat}{The cutoff in FDR for DE consideration. Genes with lower
FDR pass the cutoff. Default = 0.05.}

\item{cutoff_Abs_logFC}{The cutoff in abs(logFC) for differential expression
consideration. Genes with higher abs(logFC) pass the cutoff. Default = 1.}

\item{save_table}{Boolean. When set to TRUE, function will, in addition, save
the generated edgeR TopTags table as csv files. The files are saved on the
drive in the working directory in a new folder named "ERSSA_edgeR_table".
Tables are saved separately by the replicate level. Default = FALSE.}

\item{path}{Path to which the files will be saved. Default to current working
directory.}
}
\value{
A list of list of vectors. Top list contains elements corresponding to
replicate levels. Each child list contains elements corresponding to each
combination at the respective replicate level. The child vectors contain
differentially expressed gene names.
}
\description{
\code{erssa_edger} function runs classic edgeR method to identify
differentially expressed (DE) genes for each sample combination computed by
\code{comb_gen} function. A gene is considered to be
differentially expressed by defined FDR (Default=0.05) and logFC
(Default=1) values. As an option, the function can also save the edgeR
topTags tables as csv files to the drive.
}
\details{
The main function calls edgeR functions to perform exact test for each
computed combinations generated by \code{comb_gen}. In all tests, the
pair-wise test sets the condition defined in the object "control" as the
control condition.

In typical usage, after each test, the list of differentially expressed genes
are filtered by FDR and log2FC values and only the filtered gene
names are saved for further analysis. However, it is also possible
to save all of the generated TopTags table to the drive for additional
analysis that is outside the scope of this package.
}
\examples{
# load example filtered count_table, condition_table and combinations
# generated by comb_gen function
# example dataset containing 1000 genes, 4 replicates and 5 comb. per rep.
# level
data(count_table.filtered.partial, package = "ERSSA")
data(combinations.partial, package = "ERSSA")
data(condition_table.partial, package = "ERSSA")

#run erssa_edger with heart condition as control
deg.partial = erssa_edger(count_table.filtered.partial, combinations.partial,
 condition_table.partial, control='heart')

}
\references{
Robinson MD, McCarthy DJ, Smyth GK (2010). “edgeR: a Bioconductor package
for differential expression analysis of digital gene expression data.”
Bioinformatics, 26(1), 139-140.
}
\author{
Zixuan Shao, \email{Zixuanshao.zach@gmail.com}
}
