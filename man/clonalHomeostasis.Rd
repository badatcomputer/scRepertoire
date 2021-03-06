% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/clonalHomeostasis.R
\name{clonalHomeostasis}
\alias{clonalHomeostasis}
\title{Examining the clonal homeostasis}
\usage{
clonalHomeostasis(
  df,
  cloneTypes = c(Rare = 1e-04, Small = 0.001, Medium = 0.01, Large = 0.1, Hyperexpanded
    = 1),
  call = c("gene", "nt", "aa", "gene+nt"),
  exportTable = F
)
}
\arguments{
\item{df}{The product of CombineContig() or the seurat object after combineSeurat()}

\item{cloneTypes}{The cutpoints of the proportions}

\item{call}{How to call the clonotype - CDR3 gene, CDR3 nt or CDR3 aa, or CDR3+nucleotide}

\item{exportTable}{Exports a table of the data into the global environment in addition to the visualization}
}
\description{
Examining the clonal homeostasis
}
