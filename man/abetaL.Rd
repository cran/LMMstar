% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/doc-data.R
\docType{data}
\name{abetaL}
\alias{abetaL}
\title{Data From The Bland Altman Study (Long Format)}
\usage{
data(abetaL)
}
\description{
Extract data from a longitudinal case control study including 87 patients newly diagnosed with bipolar disorder and 44 age and sex matched healthy controls.
Contains demographic data and lifestyle factors at baseline, as well as measures of psychosocial functioning at baseline and 1 year follow-up.
This dataset is in the long format (i.e. one line per measurement).

\itemize{
\item id Study participant.
\item sex M/F.
\item age in years.
\item group Bipolar disorder (BD) or healthy control (HC).
\item episode Whether the patient experience an affective episode during follow-up.
\item visit index of time at which pss, fast, and qol measurements where performed.
\item year time at which pss, fast, and qol measurements where performed.
\item pss Perceived stress score.
\item fast Functioning assessment short test.
\item qol WHO quality of life score.
\item educationyears Years of education including basic school.
\item alcohol Daily alcohol consumption.
\item missingreason Reason of drop out or missed visit.
}
}
\references{
Pech, Josefine, et al. The impact of a new affective episode on psychosocial functioning, quality of life and perceived stress in newly diagnosed patients with bipolar disorder: A prospective one-year case-control study.Journal of Affective Disorders 277 (2020): 486-494.
}
\keyword{data}
