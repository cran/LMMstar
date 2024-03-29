### dummy.coef.R --- 
##----------------------------------------------------------------------
## Author: Brice Ozenne
## Created: okt 20 2021 (11:08) 
## Version: 
## Last-Updated: jul 10 2023 (18:04) 
##           By: Brice Ozenne
##     Update #: 44
##----------------------------------------------------------------------
## 
### Commentary: 
## 
### Change Log:
##----------------------------------------------------------------------
## 
### Code:

## * dummy.coef.lmm (documentation)
##' @title Marginal Mean Values For Linear Mixed Model
##' @description Compute the marginal mean (via the emmeans package) for each combination of categorical covariates.
##' When there is no numeric covariate, this outputs all the mean values fitted by the model.
##'
##' @param object a \code{lmm} object.
##' @param drop [logical] should combinations of covariates that do no exist in the original dataset be removed?
##' @param ... arguments passed to \code{emmeans}.
##' 
##' @return A data.frame containing the level for which the means have been computed (if more than one),
##' the estimated mean (\code{estimate}), standard error (\code{se}), degree of freedom (\code{df}), and 95\% confidence interval (\code{lower} and \code{upper}).
##'
##' @keywords methods



## * dummy.coef.lmm (code)
##' @export
dummy.coef.lmm <- function(object, drop = TRUE,...){

    requireNamespace("emmeans")
    var.cat <- intersect(all.vars(object$formula$mean),  names(object$xfactor$mean))

    if(length(var.cat)==0){
        outEmmeans <- as.data.frame(emmeans::emmeans(object,specs=~1,...))
        out <- data.frame(estimate = outEmmeans$emmean,
                          se = outEmmeans$SE,
                          df = outEmmeans$df,
                          lower = outEmmeans$lower.CL,
                          upper = outEmmeans$upper.CL,
                          stringsAsFactors = FALSE)
        attr(out,"message") <- attr(outEmmeans,"mesg")[1]
    }else{
        ff <- stats::as.formula(paste("~",paste(var.cat, collapse = "+")))
        
        out <- as.data.frame(emmeans::emmeans(object,specs=ff, ...))
        names(out)[names(out)=="emmean"] <- "estimate"
        names(out)[names(out)=="SE"] <- "se"
        names(out)[names(out)=="lower.CL"] <- "lower"
        names(out)[names(out)=="upper.CL"] <- "upper"
        attr(out,"message") <- attr(out,"mesg")[1]

        if(drop){
            var.ff <- attr(out,"pri.vars")
            data.original <- as.data.frame(object$data.original)
            existing.levels <- unique(nlme::collapse(data.original[,var.ff,drop=FALSE], as.factor = FALSE))
            out <- out[nlme::collapse(out[,var.ff,drop=FALSE], as.factor = FALSE) %in% existing.levels,,drop=FALSE]
        }

        attr(out,"estName") <- NULL
        attr(out,"clNames") <- NULL
        attr(out,"pri.vars") <- NULL
        attr(out,"adjust") <- NULL
        attr(out,"side") <- NULL
        attr(out,"delta") <- NULL
        attr(out,"type") <- NULL
        attr(out,"mesg") <- NULL
    }
    ## Note (Github isssue 2): out inherits from summary_emm and data.frame
    ##                         using data.frame on out ensures that it is just a data.frame
    return(data.frame(out))
}
##----------------------------------------------------------------------
### dummy.coef.R ends here
