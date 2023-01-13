
[![Language](https://img.shields.io/badge/language-R-blue)](https://img.shields.io/badge/language-R-blue)
[![GitHub issues](https://img.shields.io/github/issues/KobaKhit/eCLV)](https://github.com/KobaKhit/eCLV/issues)
[![GitHub forks](https://img.shields.io/github/forks/KobaKhit/eCLV)](https://github.com/KobaKhit/eCLV/network)
[![GitHub stars](https://img.shields.io/github/stars/KobaKhit/eCLV)](https://github.com/KobaKhit/eCLV/stargazers)
[![GitHub license](https://img.shields.io/github/license/KobaKhit/eCLV)](https://github.com/KobaKhit/eCLV)


Collection of functions that compute Expected Customer Lifetime Value in a subscription (contractual) setting based on research by Fader and Hardie. More on [Rpubs](https://rpubs.com/Koba/projecting-clv).

This approach only requires two inputs:

  - Active Customers in period $t$
  - Churned customers in period $t$
  
Given these we plug it into the shifted-beta-geometric probability model to get retention rates for any given customer in period t. Paired with spend we are able to project customer's lifetime value. 

![](README_files/figure-html/unnamed-chunk-1-1.png)<!-- -->


## Usage

We will use the example data from paper 1 in the references section.


```r
# Load the functions
source("lib-BG.R")

# Example from paper
# Data
activeCust = c(869,743,653,593,551,517,491)
lostCust = c(131,126,90,60,42,34,26)

# Estimate the maximum likelihood function to get the alpha, beta values
# Alternative function to estimate MLL
# estimateMLL2(active.cust = activeCust,
#             lost.cust = lostCust)$par
alphabeta = estimateMLL(active.cust = activeCust,
            lost.cust = lostCust)$par

alphabeta
```

```
## [1] 0.6677123 3.8024773
```

```r
# Survival probabilities for 10 periods
periods = 1:10
sProb = survivalBG(alphabeta[1],alphabeta[2], periods)
# Churn probabilities for 10 periods
cProb = churnBG(alphabeta[1],alphabeta[2],periods)
# Get the retention rates for 10 periods
rProb = retentionRates(alphabeta[1],alphabeta[2],periods)
# create plot
dat = data.frame(sProb,cProb,rProb)
matplot(dat, type = c("b"), ylab = 'probability', xlab='period', 
        pch=1:3,col=c('darkgray','red','blue'), lty=1:3, 
        main='Shifted Beta Geometric Model Probabilities, t=10')
legend(x=1,y=0.5, legend=c("Survival Prob", "Churn Prob","Retention Prob"), 
       col=c('darkgray','red','blue'), lty=1:3, pch=1:3) 
```

![](README_files/figure-html/unnamed-chunk-1-1.png)<!-- -->

```r
sProb
```

```
##  [1] 0.8506300 0.7467988 0.6697305 0.6098676 0.5617912 0.5221811 0.4888802
##  [8] 0.4604211 0.4357680 0.4141671
```

```r
cProb
```

```
##  [1] 0.14937002 0.10383116 0.07706834 0.05986291 0.04807638 0.03961007
##  [7] 0.03330090 0.02845911 0.02465310 0.02160086
```

```r
rProb
```

```
##  [1] 0.8506300 0.8779362 0.8968017 0.9106164 0.9211691 0.9294932 0.9362273
##  [8] 0.9417872 0.9464553 0.9504304
```

```r
# Discounted Expected Lifetime
DEL(alphabeta[1],alphabeta[2],discount = 0.1)
```

```
## [1] 5.920551
```

```r
# Discounted Expected Residual Lifetime
DERL(alphabeta[1],alphabeta[2],discount = 0.1, renewals = 4)
```

```
## [1] 6.893253
```

```r
# Expected Lifetime Value per customer assuming expected net cash flow is 100$ per period
DEL(alphabeta[1],alphabeta[2],discount = 0.1)*100
```

```
## [1] 592.0551
```

```r
# Expected Residual Lifetime Value per customer who renewed 4 times
# assuming expected net cash flow is 100$ per period
DERL(alphabeta[1],alphabeta[2],renewals = 4, discount = 0.1)*100
```

```
## [1] 689.3253
```

## References

1. [How to Project Customer Retention](https://faculty.wharton.upenn.edu/wp-content/uploads/2012/04/Fader_hardie_jim_07.pdf) by Peter Fader and Bruce Hardie (2007)

2. [Fitting the sBG Model to Multi-Cohort Data](http://brucehardie.com/notes/017/) by Peter Fader and Bruce Hardie (2007)
