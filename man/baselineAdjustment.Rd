% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/baselineAdjustment.R
\name{baselineAdjustment}
\alias{baselineAdjustment}
\title{Perform Baseline Adjustment}
\usage{
baselineAdjustment(
  object,
  variable,
  repetition,
  constrain,
  new.level = NULL,
  collapse.time = NULL
)
}
\arguments{
\item{object}{[data.frame] dataset}

\item{variable}{[character] Column in the dataset to be constrained at specific timepoints.}

\item{repetition}{[formula] Time and cluster structure, typically \code{~time|id}. See examples below.}

\item{constrain}{[vector] Levels of the time variable at which the variable is constained.}

\item{new.level}{[character or numeric] Level used at the constraint. If \code{NULL}, then the first level of the variable argument is used.}

\item{collapse.time}{[character] When not \code{NULL} character used to combine the time and argument variable into a new (interaction) variable.}
}
\value{
A vector of length the number of rows of the dataset.
}
\description{
Create a new variable based on a time variable and a group variable where groups are constrained to be equal at specific timepoints.
}
\examples{
data(ncgsL, package = "LMMstar")
ncgsL$group <- relevel(ncgsL$group, "placebo")

## baseline adjustment 1
ncgsL$treat <- baselineAdjustment(ncgsL, variable = "group",
               repetition= ~ visit|id, constrain = 1)
table(treat = ncgsL$treat, visit = ncgsL$visit, group = ncgsL$group)

ncgsL$treattime <- baselineAdjustment(ncgsL, variable = "group",
                   repetition= ~ visit|id, constrain = 1, collapse.time = ".")
table(treattime = ncgsL$treattime, visit = ncgsL$visit, group = ncgsL$group)

## baseline adjustment 2
ncgsL$treat2 <- baselineAdjustment(ncgsL, variable = "group",
                 new.level = "baseline",
                 repetition= ~ visit|id, constrain = 1)
table(treat = ncgsL$treat2, visit = ncgsL$visit, group = ncgsL$group)

ncgsL$treattime2 <- baselineAdjustment(ncgsL, variable = "group",
                   new.level = "baseline",
                   repetition= ~ visit|id, constrain = 1, collapse.time = ".")
table(treattime = ncgsL$treattime2, visit = ncgsL$visit, group = ncgsL$group)

}
\keyword{utilities}
