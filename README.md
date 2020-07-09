# README
November 5, 2016  



# eCLV

# Introduction

Collection of functions that compute Expected Customer Lifetime Value in a subscription (contractual) 
setting based on research by Fader and Hardie.

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
survivalBG(alphabeta[1],alphabeta[2],1:10)
```

```
##  [1] 0.8506300 0.7467988 0.6697305 0.6098676 0.5617912 0.5221811 0.4888802
##  [8] 0.4604211 0.4357680 0.4141671
```

```r
# Churn probabilities for 10 periods
churnBG(alphabeta[1],alphabeta[2],1:10)
```

```
##  [1] 0.14937002 0.10383116 0.07706834 0.05986291 0.04807638 0.03961007
##  [7] 0.03330090 0.02845911 0.02465310 0.02160086
```

```r
#  Get the retention rates for 10 periods
retentionRates(alphabeta[1],alphabeta[2],1:10)
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

1. [How to Project Customer Retention](https://www.google.com/url?sa=t&rct=j&q=&esrc=s&source=web&cd=1&cad=rja&uact=8&ved=0ahUKEwjXxq-v4ZLQAhWp64MKHYtSC9UQFggdMAA&url=http%3A%2F%2Fciteseerx.ist.psu.edu%2Fviewdoc%2Fdownload%3Fdoi%3D10.1.1.558.935%26rep%3Drep1%26type%3Dpdf&usg=AFQjCNHiSlM9GzZC_VIbQ2rgtSJ6dtSdwA&sig2=twz37wWrSTSSHAo6Dwj0iA) by Peter Fader and Bruce Hardie (2007)

2. [Fitting the sBG Model to Multi-Cohort Data](http://brucehardie.com/notes/017/) by Peter Fader and Bruce Hardie (2007)
