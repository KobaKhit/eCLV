# Author: Koba Khitalishvili
#
# I use Google's R style guide
# https://google.github.io/styleguide/Rguide.xml#functiondefinition
#
# A set of functions based on Peter Fader's and Bruce Hardie's research in using shifted beta 
# geometric distribution (sBG) to project customer retention and calculate customer lifetime 
# value

# Paper 1. "How to project customer retention" Fader and Hardie (2007)
# http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.558.935&rep=rep1&type=pdf
#
# Presentation 1.

churnBG <- Vectorize(function(alpha,beta,period){
  # Computes churn probabilities based on sBG distribution
  # Equation (7) in Paper 1
  #
  # Args:
  #  alpha: numeric
  #  beta: numeric
  #  period: integer or vector of integers
  #
  # Returns:
  #  Vector of churn probabilities for period(s) 
  t1 = alpha/(alpha+beta)
  result = t1
  if (period > 1) {
    result = churnBG(alpha,beta,period-1)*(beta+period-2)/(alpha+beta+period-1)
  }
  
  return(result)
}, vectorize.args = c("period"))


survivalBG = Vectorize(function(alpha, beta, period){
  # Computes survival probabilites based on a sBG distribution
  #
  # Args:
  #  alpha: numeric
  #  beta: numeric
  #  period: integer or vector of integers
  #
  # Returns:
  #  Vector of survival probabilities for period(s) 
  t1 = 1-churnBG(alpha,beta,1)
  result = t1
  if(period>1){
    result = survivalBG(alpha,beta,period-1)-churnBG(alpha,beta,period)
  }
  return(result)
}, vectorize.args = c("period"))


estimateMLL <- function(active.cust, lost.cust) {
  # Estimates MLL to fit the sBG distribution curve
  #
  # Args:
  #
  
  MLL = function(alphabeta){
    # Computes likelihood. Equation (B3) in Paper 1
    #
    # Args:
    #  alphabeta: vector with alpha being the first and beta being the second elements, c(a,b)
    #
    # Returns:
    #  Vector of churn probabilities for period(s) 
    #
    # Error handling
    if(length(activeCust) != length(lostCust)){
      stop("Variables activeCust and lostCust have different lengths: ",
           length(activeCust), " and ", length(lostCust), ".")
    }
    # Example data for seven periods
    # activeCust = c(869,743,653,593,551,517,491)
    # lostCust = c(131,126,90,60,42,34,26)
    t=length(activeCust) # number of periods
    alpha = alphabeta[1]
    beta = alphabeta[2]
    return(-as.numeric(
      sum(lostCust*log(churnBG(alpha,beta,1:t))) +
        activeCust[t]*log(survivalBG(alpha,beta,t))
    ))
  }
  
  activeCust = active.cust
  lostCust = lost.cust
  
  return(optim(c(1,1), MLL))
}


estimateMLL2 <- function(active.cust, lost.cust) {
  # Alternative function that estimates MLL to fit the sBG distribution curve
  #
  # Args:
  # alphabeta: vector with alpha being the first and beta being the second elements, c(a,b)
  #  
  # Taken from 
  # http://stats.stackexchange.com/questions/76678/how-to-write-log-likelihood-for-beta-geometric-with-optim-in-r
  
  active = active.cust
  lost = lost.cust
  
  loop.lik<-function(params) {
    a<-params[1]
    b<-params[2]
    ll<-0
    for (i in 1:length(lost)) {
      ll<-ll+lost[i]*log(beta(a+1,b+i-1)/beta(a,b))
    }
    ll<-ll+active[i]*log(beta(a,b+i)/beta(a,b))
    return(-ll)    #return the negative of the function to maximize likelihood
  } 
  
  return(optim(c(1,1), loop.lik))
}

retentionRates = Vectorize(function(alpha,beta,period){
  # Computes retention rates for period(s) t given alpha and beta
  #
  # Args:
  #  alpha: numeric
  #  beta: numeric
  #  period: integer or vector of integers
  #
  # Returns:
  #  Vector of retention rates 
  #
  
  return((beta+period-1)/(alpha+beta+period-1))
  
}, vectorize.args = c("period"))


DEL <- function(alpha,beta,discount=0.025,periods = 70){
  # Computes the discounted expected lifetime 
  #
  # Args:
  #  alpha: numeric
  #  beta: numeric
  #  discount: discount rate
  #  periods: integer 
  # 
  # Returns:
  #  numeric DEL value

  return(sum(c(1,survivalBG(alpha,beta,seq(1,periods))) *
           sapply(seq(0,periods),function(x) 1/(1+discount)^x))
  )
}

DERL <- function(alpha,beta,renewals = 2,discount=0.025,periods = 70){
  # Computes the discounted expected residual lifetime 
  #
  # Args:
  #  alpha: numeric
  #  beta: numeric
  #  discount: numeric
  #  renewals: integer
  #  periods: integer
  # 
  # Returns:
  #  numeric DERL value
  #
  # Error handling
  if(renewals<2){
    stop("Renewals value should be greater than one: renewals used is  ",
         renewals)
  }
  
  return(sum(survivalBG(alpha,beta,seq(renewals+1,periods)) /
               survivalBG(alpha,beta,renewals) *
               sapply(seq(0,periods-renewals-1),function(x) 1/(1+discount)^x))
  )
}

