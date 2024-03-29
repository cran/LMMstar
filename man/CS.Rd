% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/structure.R
\name{CS}
\alias{CS}
\title{Compound Symmetry Structure}
\usage{
CS(formula, var.cluster, var.time, type = NULL, group.type = NULL, add.time)
}
\arguments{
\item{formula}{formula indicating on which variable to stratify the residual variance and correlation (left hand side)
and variables influencing the residual variance and correlation (right hand side).}

\item{var.cluster}{[character] cluster variable.}

\item{var.time}{[character] time variable.}

\item{type}{[character] \itemize{
\item \code{"ho"}, \code{"homo"}, or \code{"homogeneous"}: constant variance and covariate-specific correlation.
Analogous to crossed or nested random effects.
\item \code{"he"}, \code{"hetero"}, or \code{"heterogeneous"}: variance and correlation specific to the level of covariates.
Can be seen as more flexible crossed or nested random effects model.
}}

\item{group.type}{[integer vector] grouping of the regressor for the correlation structure.
A constant value corresponds to nested random effects (default) and a regressor-specific value to crossed random effects}

\item{add.time}{not used.}
}
\value{
An object of class \code{CS} that can be passed to the argument \code{structure} of the \code{lmm} function.
}
\description{
Variance-covariance structure where the variance and correlation of the residuals is constant within covariate levels.
Can be stratified on a categorical variable.
The default has no covariate and therefore the variance and correlation are constant within cluster.
}
\details{
A typical formula would be \code{~1}, indicating a variance constant over time and the same correlation between all pairs of times.
}
\examples{
## no covariates
CS(~1, var.cluster = "id", var.time = "time")
CS(gender~1, var.cluster = "id", var.time = "time")

## covariates
CS(~time, var.cluster = "id", var.time = "time")
CS(gender~time, var.cluster = "id", var.time = "time")
CS(list(~time,~1), var.cluster = "id", var.time = "time")
CS(list(gender~time,gender~1), var.cluster = "id", var.time = "time")

}
\keyword{multivariate}
