% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/viz.R
\name{compareClonotypes}
\alias{compareClonotypes}
\title{Demonstrate the difference in clonal proportion between multiple clonotypes}
\usage{
compareClonotypes(
  df,
  call = c("gene", "nt", "aa", "gene+nt"),
  samples = NULL,
  clonotypes = NULL,
  numbers = NULL,
  graph = c("alluvial", "area")
)
}
\arguments{
\item{df}{The product of CombineContig()}

\item{call}{How to call the clonotype - CDR3 gene, CDR3 nt or CDR3 aa, or CDR3+nucleotide}

\item{clonotypes}{The specific sequences of interest}

\item{numbers}{The top number clonotype sequences}

\item{graph}{The type of graph produced, either "alluvial" or "area"}
}
\description{
Demonstrate the difference in clonal proportion between multiple clonotypes
}
