### information.R --- 
##----------------------------------------------------------------------
## Author: Brice Ozenne
## Created: mar 22 2021 (22:13) 
## Version: 
## Last-Updated: May 30 2022 (01:54) 
##           By: Brice Ozenne
##     Update #: 993
##----------------------------------------------------------------------
## 
### Commentary: 
## 
### Change Log:
##----------------------------------------------------------------------
## 
### Code:

## * information.lmm (documentation)
##' @title Extract The Information From a Linear Mixed Model
##' @description Extract or compute the (expected) second derivative of the log-likelihood of a linear mixed model.
##' @name information
##' 
##' @param x a \code{lmm} object.
##' @param data [data.frame] dataset relative to which the information should be computed. Only relevant if differs from the dataset used to fit the model.
##' @param indiv [logical] Should the contribution of each cluster to the information be output? Otherwise output the sum of all clusters of the derivatives.
##' @param p [numeric vector] value of the model coefficients at which to evaluate the information. Only relevant if differs from the fitted values.
##' @param effects [character] Should the information relative to all coefficients be output (\code{"all"} or \code{"fixed"}),
##' or only coefficients relative to the mean (\code{"mean"}),
##' or only coefficients relative to the variance and correlation structure (\code{"variance"} or \code{"correlation"}).
##' @param type.information [character] Should the expected information be computed  (i.e. minus the expected second derivative) or the observed inforamtion (i.e. minus the second derivative).
##' @param transform.sigma [character] Transformation used on the variance coefficient for the reference level. One of \code{"none"}, \code{"log"}, \code{"square"}, \code{"logsquare"} - see details.
##' @param transform.k [character] Transformation used on the variance coefficients relative to the other levels. One of \code{"none"}, \code{"log"}, \code{"square"}, \code{"logsquare"}, \code{"sd"}, \code{"logsd"}, \code{"var"}, \code{"logvar"} - see details.
##' @param transform.rho [character] Transformation used on the correlation coefficients. One of \code{"none"}, \code{"atanh"}, \code{"cov"} - see details.
##' @param transform.names [logical] Should the name of the coefficients be updated to reflect the transformation that has been used?
##' @param ... Not used. For compatibility with the generic method.
##'
##' @details For details about the arguments \bold{transform.sigma}, \bold{transform.k}, \bold{transform.rho}, see the documentation of the \link[LMMstar]{coef} function.
##'
##' @return
##' When argument indiv is \code{FALSE}, a matrix with the value of the infroamtion relative to each pair of coefficient (in rows and columns) and each cluster (in rows).
##' When argument indiv is \code{TRUE}, a 3-dimensional array with the value of the information relative to each pair of coefficient (dimension 2 and 3) and each cluster (dimension 1).
##' 

## * information.lmm (code)
##' @rdname information
##' @export
information.lmm <- function(x, effects = NULL, data = NULL, p = NULL, indiv = FALSE, type.information = NULL,
                            transform.sigma = NULL, transform.k = NULL, transform.rho = NULL, transform.names = TRUE, ...){

    ## ** normalize user input
    dots <- list(...)
    options <- LMMstar.options()
    if(length(dots)>0){
        stop("Unknown argument(s) \'",paste(names(dots),collapse="\' \'"),"\'. \n")
    }
    if(is.null(type.information)){
        type.information <- attr(x$information,"type.information")
        robust <- FALSE
    }else{
        type.information <- match.arg(type.information, c("expected","observed"))
        robust <- identical(attr(type.information,"robust"),TRUE)
    }
    if(is.null(effects)){
        effects <- options$effects
    }else if(identical(effects,"all")){
        effects <- c("mean","variance","correlation")
    }
    effects <- match.arg(effects, c("mean","fixed","variance","correlation"), several.ok = TRUE)
    effects[effects== "fixed"] <- "mean"

    init <- .init_transform(transform.sigma = transform.sigma, transform.k = transform.k, transform.rho = transform.rho, 
                            x.transform.sigma = x$reparametrize$transform.sigma, x.transform.k = x$reparametrize$transform.k, x.transform.rho = x$reparametrize$transform.rho)
    transform.sigma <- init$transform.sigma
    transform.k <- init$transform.k
    transform.rho <- init$transform.rho
    test.notransform <- init$test.notransform
    
    ## ** extract or recompute information
    if(is.null(data) && is.null(p) && (indiv == FALSE) && test.notransform && (robust==FALSE) && attr(x$information,"type.information")==type.information){
        keep.name <- stats::setNames(names(coef(x, effects = effects, transform.sigma = "none", transform.k = "none", transform.rho = "none", transform.names = TRUE)),
                                     names(coef(x, effects = effects, transform.sigma = transform.sigma, transform.k = transform.k, transform.rho = transform.rho, transform.names = transform.names)))    

        design <- x$design ## useful in case of NA
        out <- x$information[keep.name,keep.name,drop=FALSE]
        if(transform.names){
            dimnames(out) <- list(names(keep.name),names(keep.name))
        }
    }else{
        test.precompute <- !is.null(x$design$precompute.XX) && !indiv
         
        if(!is.null(data)){
            design <- stats::model.matrix(x, data = data, effects = "all", simplifies = FALSE)
        }else{
            design <- x$design
        }

        if(!is.null(p)){
            if(any(duplicated(names(p)))){
                stop("Incorrect argument \'p\': contain duplicated names \"",paste(unique(names(p)[duplicated(names(p))]), collapse = "\" \""),"\".\n")
            }
            if(any(names(x$param) %in% names(p) == FALSE)){
                stop("Incorrect argument \'p\': missing parameter(s) \"",paste(names(x$param)[names(x$param$type) %in% names(p) == FALSE], collapse = "\" \""),"\".\n")
            }
            p <- p[names(x$param)]
        }else{
            p <- x$param
        }
        out <- .moments.lmm(value = p, design = design, time = x$time, method.fit = x$method.fit, type.information = type.information,
                            transform.sigma = transform.sigma, transform.k = transform.k, transform.rho = transform.rho,
                            logLik = FALSE, score = FALSE, information = TRUE, vcov = FALSE, df = FALSE, indiv = indiv, effects = effects, robust = robust,
                            trace = FALSE, precompute.moments = test.precompute, transform.names = transform.names)$information
    }

    ## ** restaure NAs and name
    if(indiv){
        if(is.null(data) && length(x$index.na)>0 && any(is.na(attr(x$index.na,"cluster.index")))){
            dimnames(out)[[1]] <- x$design$cluster$levels
            out.save <- out
            out <- array(NA, dim = c(x$cluster$n, dim(out.save)[2:3]),
                          dimnames = c(list(x$cluster$levels), dimnames(out.save)[2:3]))
            out[dimnames(out.save)[[1]],,] <- out.save

            if(is.numeric(design$cluster$levels.original)){
                dimnames(out)[[1]] <- NULL
            }
        }else if(!is.numeric(design$cluster$levels.original)){
            dimnames(out)[[1]] <- design$cluster$levels.original
        } 
    }


    ## ** re-order values when converting to sd with strata (avoid sd0:0 sd0:1 sd1:0 sd1:1 sd2:0 sd2:1 ...)
    if("variance" %in% effects && transform.k %in% c("sd","var","logsd","logvar") && x$strata$n>1 && transform.names){
        out.name <- names(stats::coef(x, effects = effects, transform.sigma = transform.sigma, transform.k = transform.k, transform.rho = transform.rho, transform.names = TRUE))
        if(indiv){
            out <- out[,out.name,out.name,drop=FALSE]
        }else{
            out <- out[out.name,out.name,drop=FALSE]
        }
    }

    ## ** export
    return(out)
}

## * .information
## REML term
## d 0.5 tr[(X \OmegaM1 X)^{-1} (X \OmegaM1 d\Omega \OmegaM1 X)] = 0.5 tr[ (X \OmegaM1 d'\Omega \OmegaM1 X) (X \OmegaM1 X)^{-2} (X \OmegaM1 d\Omega \OmegaM1 X) ]
##                                                                 - 0.5 tr[ (X \OmegaM1 X)^{-1} (X \OmegaM1 d'\Omega \OmegaM1 d\Omega \OmegaM1 X) + (X \OmegaM1 X)^{-1} (X \OmegaM1 d\Omega \OmegaM1 d'\Omega \OmegaM1 X) ]
##                                                                 + 0.5 tr[ (X \OmegaM1 X)^{-1} (X \OmegaM1 d2\Omega \OmegaM1 X) ]
.information <- function(X, residuals, precision, dOmega, d2Omega,
                         Upattern.ncluster, weights, scale.Omega,
                         index.variance, time.variance, index.cluster, name.allcoef,
                         pair.meanvarcoef, pair.varcoef, indiv, REML, type.information, effects, robust,
                         precompute){

    ## ** extract information
    test.loopIndiv <- indiv || is.null(precompute)
    n.obs <- length(index.cluster)
    n.cluster <- length(index.variance)
    name.mucoef <- colnames(X)
    n.mucoef <- length(name.mucoef)
    name.varcoef <- lapply(dOmega, names)
    n.varcoef <- lapply(name.varcoef, length)
    n.allcoef <- length(name.allcoef)
    name.allvarcoef <- name.allcoef[name.allcoef %in% unique(unlist(name.varcoef))] ## make sure the ordering is correct
    n.allvarcoef <- length(name.allvarcoef)
    U.pattern <- names(dOmega)
    n.pattern <- length(U.pattern)
        
    npair.meanvarcoef <- lapply(pair.meanvarcoef, NCOL)
    npair.varcoef <- lapply(pair.varcoef, NCOL)

    ## ** prepare output
    name.effects <- attr(effects,"original.names")
    n.effects <- length(name.effects)
    if(test.loopIndiv && indiv){
        info <- array(0, dim = c(n.cluster, n.effects, n.effects),
                      dimnames = list(NULL, name.effects, name.effects))
    }else{
        info <- matrix(0, nrow = n.effects, ncol = n.effects,
                       dimnames = list(name.effects, name.effects)
                       )
    }    

    ## restrict to relevant parameters
    if(("variance" %in% effects == FALSE) && ("correlation" %in% effects == FALSE)){ ## compute hessian only for mean parameters
        test.vcov <- FALSE
        test.mean <- TRUE
    }else{
        if(REML && indiv){
            stop("Not possible to compute individual hessian for variance and/or correlation coefficients when using REML.\n")
        }
        if(("variance" %in% effects == FALSE) || ("correlation" %in% effects == FALSE)){ ## subset variance parameters
            name.varcoef <- stats::setNames(lapply(U.pattern,function(iPattern){intersect(name.effects,name.varcoef[[iPattern]])}),
                                     U.pattern)

            pair.meanvarcoef <- stats::setNames(lapply(U.pattern,function(iPattern){
                test.in <- (pair.meanvarcoef[[iPattern]][1,] %in% name.effects)+(pair.meanvarcoef[[iPattern]][2,] %in% name.effects)
                return(pair.meanvarcoef[[iPattern]][,test.in==2,drop=FALSE])
            }), U.pattern)

            pair.varcoef <- stats::setNames(lapply(U.pattern,function(iPattern){## iPattern <- 1
                test.in <- (pair.varcoef[[iPattern]][1,] %in% name.effects)+(pair.varcoef[[iPattern]][2,] %in% name.effects)
                iOut <- pair.varcoef[[iPattern]][,test.in==2,drop=FALSE]
                attr(iOut,"subset") <- which(test.in==2)
                attr(iOut,"key") <- matrix(NA, nrow = length(name.varcoef[[iPattern]]), ncol = length(name.varcoef[[iPattern]]), dimnames = list(name.varcoef[[iPattern]],name.varcoef[[iPattern]]))
                for(iCol in 1:NCOL(iOut)){
                    attr(iOut, "key")[iOut[1,iCol],iOut[2,iCol]] <- iCol
                    attr(iOut, "key")[iOut[2,iCol],iOut[1,iCol]] <- iCol
                }
                return(iOut)
            }), U.pattern)
            d2Omega <- stats::setNames(lapply(U.pattern,function(iPattern){
                
                return(d2Omega[[iPattern]][attr(pair.varcoef[[iPattern]],"subset")])
            }), U.pattern)

            n.varcoef <- lapply(name.varcoef, length)
            name.allvarcoef <- unique(unlist(name.varcoef))
            n.allvarcoef <- length(name.allvarcoef)
            npair.meanvarcoef <- lapply(pair.meanvarcoef, NCOL)
            npair.varcoef <- lapply(pair.varcoef, NCOL)
        }
        if("mean" %in% effects == FALSE){ ## compute hessian only for variance and/or correlation parameters
            if(REML && indiv){
                stop("Not possible to compute individual hessian for variance and/or correlation coefficients when using REML.\n")
            }

            test.vcov <- TRUE
            test.mean <- FALSE

        }else{ ## compute hessian all parameters
     
            test.vcov <- TRUE
            test.mean <- TRUE
        }
    }

    ## prepare REML term
    if(test.vcov && REML){
        REML.key <- matrix(NA, nrow = n.allvarcoef, ncol = n.allvarcoef, dimnames = list(name.allvarcoef, name.allvarcoef))
        maxkey <- sum(lower.tri(REML.key, diag = TRUE))
        REML.key[lower.tri(REML.key, diag = TRUE)] <- 1:maxkey
        REML.key[upper.tri(REML.key)] <- t(REML.key)[upper.tri(REML.key)]

        REML.denom <- matrix(0, nrow = n.mucoef, ncol = n.mucoef, dimnames = list(name.mucoef, name.mucoef))
        ## REML.numerator1 <- stats::setNames(lapply(U.pattern, function(iPattern) { array(0, dim = c(n.mucoef, n.mucoef, n.varcoef[[iPattern]]), dimnames = list(name.mucoef, name.mucoef, name.varcoef[[iPattern]])) }), U.pattern)
        REML.numerator1 <- array(0, dim = c(n.mucoef, n.mucoef, n.allvarcoef), dimnames = list(name.mucoef, name.mucoef, name.allvarcoef))
        REML.numerator2 <- array(0, dim = c(n.mucoef, n.mucoef, maxkey), dimnames = list(name.mucoef, name.mucoef, NULL))
    }     
    
    ## ** compute information
    ## *** looping over individuals
    if(test.loopIndiv){
        
        ## ** precompute 
        if(test.vcov){
            OmegaM1_dOmega_OmegaM1 <- stats::setNames(vector(mode = "list", length = n.pattern), U.pattern)
            tr_OmegaM1_d2OmegaAndCo <- stats::setNames(lapply(1:n.pattern, function(iPattern){rep(NA, npair.varcoef[[iPattern]])}), U.pattern)
            if(REML || type.information == "observed"){
                OmegaM1_d2OmegaAndCo_OmegaM1 <- stats::setNames(lapply(1:n.pattern, function(iPattern){array(NA, dim = c(NCOL(precision[[iPattern]]),NCOL(precision[[iPattern]]), npair.varcoef[[iPattern]]))}), U.pattern)
            }

            for(iPattern in 1:n.pattern){ ## iPattern <- 2
                iOmegaM1 <- precision[[iPattern]]
                idOmega <- dOmega[[iPattern]]

                OmegaM1_dOmega_OmegaM1[[iPattern]] <- stats::setNames(lapply(name.varcoef[[iPattern]], FUN = function(iVarcoef){iOmegaM1 %*% idOmega[[iVarcoef]] %*% iOmegaM1}), name.varcoef[[iPattern]])

                ## loop over all pairs
                for(iPair in 1:npair.varcoef[[iPattern]]){ ## iPair <- 4
                    iCoef1 <- pair.varcoef[[iPattern]][1,iPair]
                    iCoef2 <- pair.varcoef[[iPattern]][2,iPair]

                    iTerm21 <- OmegaM1_dOmega_OmegaM1[[iPattern]][[iCoef2]] %*% idOmega[[iCoef1]]
                    
                    ## trace
                    if(type.information == "expected"){
                        tr_OmegaM1_d2OmegaAndCo[[iPattern]][iPair] <- tr(iTerm21)
                    }else if(type.information == "observed"){
                        tr_OmegaM1_d2OmegaAndCo[[iPattern]][iPair] <- - tr(iTerm21 - iOmegaM1 %*% d2Omega[[iPattern]][[iPair]])
                    }
                    if(REML || type.information == "observed"){
                        iTerm12 <- OmegaM1_dOmega_OmegaM1[[iPattern]][[iCoef1]] %*% idOmega[[iCoef2]]
                        OmegaM1_d2OmegaAndCo_OmegaM1[[iPattern]][,,iPair] <- iOmegaM1 %*% d2Omega[[iPattern]][[iPair]] %*% iOmegaM1 - (iTerm12 + iTerm21) %*% iOmegaM1
                    }
                }
            }
        }
        
        ## loop
        for(iId in 1:n.cluster){ ## iId <- 7
            iPattern <- index.variance[iId]
            iIndex <- index.cluster[[iId]]
            iWeight <- weights[iId]
            ## iIndex <- which(index.cluster==iId)
            ## iIndex <- iIndex[order(time.variance[iIndex])] ## re-order observations according to the variance-covariance matrix

            iX <- X[iIndex,,drop=FALSE]
            tiX <- t(iX)
            iOmegaM1 <- precision[[iPattern]] * scale.Omega[iId]
            if(type.information == "observed"){
                iResidual <- residuals[iIndex,,drop=FALSE]
            }
        
            ## **** mean,mean
            iValue <-  iWeight * (tiX %*% iOmegaM1 %*% iX)
            if(test.mean){
                if(indiv){
                    info[iId,name.mucoef,name.mucoef] <- iValue
                }else{
                    info[name.mucoef,name.mucoef] <- info[name.mucoef,name.mucoef] + iValue
                }
            }
            if(REML && test.vcov){
                REML.denom <- REML.denom + iValue
                for(iVarcoef in name.varcoef[[iPattern]]){ ## iVarcoef <- 1
                    REML.numerator1[,,iVarcoef] <- REML.numerator1[,,iVarcoef] + iWeight * (tiX %*% OmegaM1_dOmega_OmegaM1[[iPattern]][[iVarcoef]] %*% iX) * scale.Omega[iId]
                }
            }

            ## **** var,var
            if(test.vcov){

                for(iPair in 1:npair.varcoef[[iPattern]]){ ## iPair <- 1
                    iCoef1 <- pair.varcoef[[iPattern]][1,iPair]
                    iCoef2 <- pair.varcoef[[iPattern]][2,iPair]

                    iValue <- 0.5 * iWeight * tr_OmegaM1_d2OmegaAndCo[[iPattern]][iPair]
                    ## 0.5 * ntr(iOmegaM1 %*% idOmega$sigma %*% iOmegaM1 %*% idOmega$sigma)

                    if(type.information == "observed"){
                        iValue <- iValue - 0.5 * iWeight * (t(iResidual) %*% OmegaM1_d2OmegaAndCo_OmegaM1[[iPattern]][,,iPair] %*% iResidual) * scale.Omega[iId]
                    }
                    if(indiv){
                        info[iId,iCoef1,iCoef2] <- iValue
                        if(iCoef1 != iCoef2){
                            info[iId,iCoef2,iCoef1] <- iValue
                        }
                    }else{
                        info[iCoef1,iCoef2] <- info[iCoef1,iCoef2] + iValue
                        if(iCoef1 != iCoef2){
                            info[iCoef2,iCoef1] <- info[iCoef2,iCoef1] + iValue
                        }
                    }

                    if(REML){
                        iKey <- REML.key[iCoef1,iCoef2]
                        REML.numerator2[,,iKey] <- REML.numerator2[,,iKey] + iWeight * (tiX %*% OmegaM1_d2OmegaAndCo_OmegaM1[[iPattern]][,,iPair] %*% iX) * scale.Omega[iId]
                    }
                }
            }

            ## **** mean,var
            if(type.information == "observed" && test.mean && test.vcov){

                for(iPair in 1:npair.meanvarcoef[[iPattern]]){ ## iPair <- 1
                    iCoef1 <- pair.meanvarcoef[[iPattern]][1,iPair]
                    iCoef2 <- pair.meanvarcoef[[iPattern]][2,iPair]

                    iValue <- iWeight * (tiX[iCoef1,,drop=FALSE] %*% OmegaM1_dOmega_OmegaM1[[iPattern]][[iCoef2]] %*% iResidual) * scale.Omega[iId]

                    if(indiv){
                        info[iId,iCoef1,iCoef2] <- iValue
                        info[iId,iCoef2,iCoef1] <- iValue
                    }else{
                        info[iCoef1,iCoef2] <- info[iCoef1,iCoef2] + iValue
                        info[iCoef2,iCoef1] <- info[iCoef2,iCoef1] + iValue
                    }
                }

            }
        }
    }

    ## *** looping over covariance patterns
    if(!test.loopIndiv){
    
        ## loop
        for (iPattern in U.pattern) { ## iPattern <- name.pattern[1]
            iOmegaM1 <- precision[[iPattern]]
            iTime <- NCOL(iOmegaM1)
            iTime2 <- length(iOmegaM1)
            iName.varcoef <- name.varcoef[[iPattern]]
            iN.varcoef <- length(iName.varcoef)

            iX <- matrix(unlist(precompute$XX$pattern[[iPattern]]), nrow = iTime2, ncol = dim(precompute$XX$pattern[[iPattern]])[3], byrow = FALSE)
                    
            ## **** mean,mean
            iValue <- (as.double(iOmegaM1) %*% iX)[as.double(precompute$XX$key)]
            if(test.mean){
                info[name.mucoef,name.mucoef] <- info[name.mucoef,name.mucoef] + iValue
            }

            ## **** var,var
            if(test.vcov){

                ## precompute
                iMat <- tblock(t(do.call(rbind, dOmega[[iPattern]]) %*% iOmegaM1))
                dOmega_OmegaM1 <- matrix(iMat,
                                         nrow = iTime2, ncol = iN.varcoef, dimnames = list(NULL,iName.varcoef), byrow = FALSE)
                tdOmega_OmegaM1 <- matrix(tblock(iMat),
                                          nrow = iTime2, ncol = iN.varcoef, dimnames = list(NULL,iName.varcoef), byrow = FALSE)
                iOmegaM1_dOmega_OmegaM1 <- matrix(iOmegaM1 %*% iMat,
                                                  nrow = iTime2, ncol = iN.varcoef, dimnames = list(NULL,iName.varcoef), byrow = FALSE)
                if(REML || type.information == "observed"){
                    iOmegaM1_d2Omega_OmegaM1 <- matrix(iOmegaM1 %*% tblock(t(do.call(rbind, d2Omega[[iPattern]]) %*% iOmegaM1)),
                                                       nrow = iTime2, ncol = npair.varcoef[[iPattern]], byrow = FALSE)
                    iOmegaM1_dOmega1_OmegaM1_dOmega2_OmegaM1 <- do.call(cbind,lapply(1:npair.varcoef[[iPattern]], function(iPair){ ## iPair <- 4
                        iCoef1 <- pair.varcoef[[iPattern]][1,iPair]
                        iCoef2 <- pair.varcoef[[iPattern]][2,iPair]
                        out <- matrix(tdOmega_OmegaM1[,iCoef1], nrow = iTime, ncol = iTime) %*% matrix(iOmegaM1_dOmega_OmegaM1[,iCoef2], nrow = iTime, ncol = iTime) + matrix(tdOmega_OmegaM1[,iCoef2], nrow = iTime, ncol = iTime) %*% matrix(iOmegaM1_dOmega_OmegaM1[,iCoef1], nrow = iTime, ncol = iTime)
                        return(as.double(out))
                    }))
                    iOmegaM1_d2OmegaAndCo_OmegaM1 <- iOmegaM1_d2Omega_OmegaM1 - iOmegaM1_dOmega1_OmegaM1_dOmega2_OmegaM1
                    ## iOmegaM1 %*% d2Omega[[iPattern]][[iPair]] %*% iOmegaM1 - 2 * iOmegaM1 %*% dOmega[[iPattern]][[iCoef1]] %*% iOmegaM1 %*% dOmega[[iPattern]][[iCoef2]] %*% iOmegaM1
                }
                if(REML){
                    
                    iDouble2Mat <- as.vector(precompute$XX$key)
                    ## denominator
                    REML.denom <- REML.denom + (as.double(iOmegaM1) %*% iX)[iDouble2Mat]
                    ## numerator 1
                    iX_OmegaM1_dOmega_OmegaM1_X <- t(iX) %*% iOmegaM1_dOmega_OmegaM1
                    for(iVarcoef in iName.varcoef){ ## iVarcoef <- iName.varcoef[1]
                        REML.numerator1[,,iVarcoef] <- REML.numerator1[,,iVarcoef] + iX_OmegaM1_dOmega_OmegaM1_X[iDouble2Mat,iVarcoef]
                    }
                    ## numerator 2
                    iX_OmegaM1_d2OmegaAndCo_OmegaM1_X <- t(iX) %*% iOmegaM1_d2OmegaAndCo_OmegaM1
                    for(iPair in 1:npair.varcoef[[iPattern]]){ ## iPair <- 1
                        iCoef1 <- pair.varcoef[[iPattern]][1,iPair]
                        iCoef2 <- pair.varcoef[[iPattern]][2,iPair]
                        REML.numerator2[,,REML.key[iCoef1,iCoef2]] <- REML.numerator2[,,REML.key[iCoef1,iCoef2]] + iX_OmegaM1_d2OmegaAndCo_OmegaM1_X[iDouble2Mat,iPair]
                    }
                    
                }

                ## compute contribution
                iTrace_O_dO_O_dO <- colSums(dOmega_OmegaM1[,pair.varcoef[[iPattern]][1,],drop=FALSE] * tdOmega_OmegaM1[,pair.varcoef[[iPattern]][2,],drop=FALSE])
                ## - 0.5 * tr(iOmegaM1 %*% dOmega[[iPattern]][[1]] %*% iOmegaM1 %*% dOmega[[iPattern]][[2]] - iOmegaM1 %*% d2Omega[[iPattern]][[iPair]])
                if(type.information == "expected"){
                    iValue <- 0.5 * Upattern.ncluster[iPattern] * iTrace_O_dO_O_dO
                }else if(type.information == "observed"){
                    id2Omega <- matrix(unlist(d2Omega[[iPattern]]), nrow = iTime2, ncol = npair.varcoef[[iPattern]])
                    iTrace_d2Omega <- colSums(sweep(id2Omega, MARGIN = 1, FUN = "*", STATS = as.double(precision[[iPattern]])))
                    iValue <- - 0.5 * Upattern.ncluster[iPattern] * (iTrace_O_dO_O_dO - iTrace_d2Omega) - 0.5 * as.double(as.double(precompute$RR[[iPattern]]) %*% iOmegaM1_d2OmegaAndCo_OmegaM1)
                    
                }
                
                ## store
                info[iName.varcoef,iName.varcoef]  <- info[iName.varcoef,iName.varcoef] + iValue[as.double(attr(pair.varcoef[[iPattern]],"key"))]
            }

            ## **** mean,var
            if(type.information == "observed" && test.mean && test.vcov){

                ## compute
                iValue <- t(iOmegaM1_dOmega_OmegaM1) %*% matrix(precompute$XR[[iPattern]], nrow = iTime2, ncol = n.mucoef, dimnames = list(NULL,name.mucoef))

                ## store
                info[iName.varcoef,name.mucoef] <- info[iName.varcoef,name.mucoef] + iValue
                info[name.mucoef,iName.varcoef] <- info[name.mucoef,iName.varcoef] + t(iValue)
            }
        }

    }

    ## ** export
    if(REML && test.vcov){
        REML.denomM1 <- solve(REML.denom)
        REML.numerator2.bis <- array(NA, dim = dim(REML.numerator2), dimnames = dimnames(REML.numerator2))
        ls.REML.numerator1.denomM1 <- stats::setNames(lapply(1:dim(REML.numerator1)[3], FUN = function(iDim){REML.numerator1[,,iDim] %*% REML.denomM1}), dimnames(REML.numerator1)[[3]])
        ## ls.REML.numerator1.denomM1 <- apply(REML.numerator1, MARGIN = 3, FUN = function(iM){iM %*% REML.denomM1}, simplify = FALSE) ## only work on recent R versions
        for(iKey in 1:maxkey){ ## iKey <- 1
            iIndex <- which(REML.key == iKey, arr.ind = TRUE)
            REML.numerator2.bis[,,iKey] <-  ls.REML.numerator1.denomM1[[name.allvarcoef[iIndex[1,1]]]] %*% REML.numerator1[,,name.allvarcoef[iIndex[1,2]]]
        }

        REML.all <- as.double(REML.denomM1) %*% matrix(REML.numerator2.bis + REML.numerator2, nrow = prod(dim(REML.numerator2)[1:2]), ncol = dim(REML.numerator2)[3], byrow = FALSE)
        info[name.allvarcoef,name.allvarcoef] <- info[name.allvarcoef,name.allvarcoef] - 0.5 * REML.all[as.double(REML.key)]
        
    }

    if(robust){
        if(REML){
            if(type.information=="observed"){
                stop("Cannot compute robust observed information matrix under REML. \n",
                     "Consider using the expected information matrix by setting the argument type.information=\"expected\" when calling lmm.\n")
            }
            effects2 <- "mean"
            attr(effects2,"original.names") <- attr(effects,"original.names")
            attr(effects2,"reparametrize.names") <- attr(effects,"reparametrize.names")
        }else{
            effects2 <- effects
        }
        if(is.null(weights)){
            weights <- rep(1, length(index.variance))
        }
        if(is.null(scale.Omega)){
            scale.Omega <- rep(1, length(index.variance))
        }
        attr.info <- info
        attr.bread <- crossprod(.score(X = X, residuals = residuals, precision = precision, dOmega = dOmega,
                                       weights = weights, scale.Omega = scale.Omega,
                                       index.variance = index.variance, time.variance = time.variance, 
                                       index.cluster = index.cluster, name.allcoef = name.allcoef, indiv = TRUE, REML = REML, effects = effects2,
                                       precompute = precompute) )
        if(any(c("mean","variance","correlation") %in% effects2 == FALSE)){
            keep.cols <- intersect(names(which(rowSums(abs(attr.bread))!=0)),names(which(rowSums(abs(attr.bread))!=0)))
            info <- NA*attr.info
            info[keep.cols,keep.cols] <- attr.info[keep.cols,keep.cols,drop=FALSE] %*% solve(attr.bread[keep.cols,keep.cols,drop=FALSE]) %*% attr.info[keep.cols,keep.cols,drop=FALSE]
        }else{
            info <- attr.info %*% solve(attr.bread) %*% attr.info
        }
    }
    return(info)
}

##----------------------------------------------------------------------
### information.R ends here

