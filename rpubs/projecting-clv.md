---
title: "Projecting Customer Retention in R"
date: "October 18, 2022"
output: 
  html_document:
    keep_md: true
---


In the paper [“How to project customer retention”](https://faculty.wharton.upenn.edu/wp-content/uploads/2012/04/Fader_hardie_jim_07.pdf) by Fader and Hardie there is a neat example of using shifted Beta Geometric distribution (sBG) to project customer retention in Excel. Below you can see the same model being replicated in R.

## Model

The likelihood function from the paper we need to maximize is below (numbered (B3) in the Appendix).

$$
LL(\alpha,\beta | \text{data}) = \sum_{t=1}^{t_f} n_t \ln [P(T=t | \alpha,\beta)] + 
(n-\sum_{t=1}^{t_f} n_t) \ln [S(t_{f} | \alpha,\beta)] 
$$
  
  - where $n_t$ is the number of lost customers in period $t$
  - $n$ is the number of active customers in the last period $t_f$
  - $t_f$ is the final period
  - $P(T=t|α,β)$ is the probability that a random customer will not renew in period $t$
  - $S(t|α,β)$ is the probability that a random customer will renew in period $t$

The probability that a random customer will not renew in period $t$ is below
$$
P(T=t) = \begin{cases} \frac{\alpha}{\alpha + \beta}, & \mbox{if } t=1 \\ 
\frac{\beta+t-2}{\alpha+\beta+t-1}, & \mbox{if } t>1 \end{cases}
$$
and the survival function, the probability a random customer will renew, is
$$
S(t | \alpha, \beta) = \begin{cases} 1-P(T=1 | \alpha, \beta), & \mbox{if } t=1 \\ 
S(t-1) - P(T=t | \alpha,\beta), & \mbox{if } t>1 \end{cases}
$$

## Code


```r
library(plotly)

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

# values
churnBG(1,1,1:10)
```

```
##  [1] 0.500000000 0.166666667 0.083333333 0.050000000 0.033333333 0.023809524
##  [7] 0.017857143 0.013888889 0.011111111 0.009090909
```

```r
# plot
t <- 1:10
churns.prob <- churnBG(1,1,1:10)
data <- data.frame(t, churns.prob)

plot_ly(data, x = ~t, y = ~churns.prob, type = 'scatter', mode = 'lines') %>%
  layout(title = "Density plot for P(T=t | aplha, beta) for t=10",
                     xaxis = list(title = "Period, t"),
                     yaxis = list(title = "P(T=t | aplha, beta)"))
```

```{=html}
<div id="htmlwidget-3397ddbf82c7032c5584" style="width:672px;height:480px;" class="plotly html-widget"></div>
<script type="application/json" data-for="htmlwidget-3397ddbf82c7032c5584">{"x":{"visdat":{"12d4b40fe108c":["function () ","plotlyVisDat"]},"cur_data":"12d4b40fe108c","attrs":{"12d4b40fe108c":{"x":{},"y":{},"mode":"lines","alpha_stroke":1,"sizes":[10,100],"spans":[1,20],"type":"scatter"}},"layout":{"margin":{"b":40,"l":60,"t":25,"r":10},"title":"Density plot for P(T=t | aplha, beta) for t=10","xaxis":{"domain":[0,1],"automargin":true,"title":"Period, t"},"yaxis":{"domain":[0,1],"automargin":true,"title":"P(T=t | aplha, beta)"},"hovermode":"closest","showlegend":false},"source":"A","config":{"modeBarButtonsToAdd":["hoverclosest","hovercompare"],"showSendToCloud":false},"data":[{"x":[1,2,3,4,5,6,7,8,9,10],"y":[0.5,0.166666666666667,0.0833333333333333,0.05,0.0333333333333333,0.0238095238095238,0.0178571428571429,0.0138888888888889,0.0111111111111111,0.00909090909090909],"mode":"lines","type":"scatter","marker":{"color":"rgba(31,119,180,1)","line":{"color":"rgba(31,119,180,1)"}},"error_y":{"color":"rgba(31,119,180,1)"},"error_x":{"color":"rgba(31,119,180,1)"},"line":{"color":"rgba(31,119,180,1)"},"xaxis":"x","yaxis":"y","frame":null}],"highlight":{"on":"plotly_click","persistent":false,"dynamic":false,"selectize":false,"opacityDim":0.2,"selected":{"opacity":1},"debounce":0},"shinyEvents":["plotly_hover","plotly_click","plotly_selected","plotly_relayout","plotly_brushed","plotly_brushing","plotly_clickannotation","plotly_doubleclick","plotly_deselect","plotly_afterplot","plotly_sunburstclick"],"base_url":"https://plot.ly"},"evals":[],"jsHooks":[]}</script>
```

### Survival Probabilities

```r
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

# values
survivalBG(1,1,1:10)
```

```
##  [1] 0.50000000 0.33333333 0.25000000 0.20000000 0.16666667 0.14285714
##  [7] 0.12500000 0.11111111 0.10000000 0.09090909
```

```r
# plot
t <- 1:10
survival.probs <- survivalBG(1,1,1:10)
data <- data.frame(t, survival.probs)

plot_ly(data, x = ~t, y = ~survival.probs, type = 'scatter', mode = 'lines') %>%
  layout(title = "Density plot for S(T=t | aplha, beta) for t=10",
                     xaxis = list(title = "Period, t"),
                     yaxis = list(title = "S(T=t | aplha, beta)"))
```

```{=html}
<div id="htmlwidget-7996e73180a31577d69d" style="width:672px;height:480px;" class="plotly html-widget"></div>
<script type="application/json" data-for="htmlwidget-7996e73180a31577d69d">{"x":{"visdat":{"12d4b5c81d48e":["function () ","plotlyVisDat"]},"cur_data":"12d4b5c81d48e","attrs":{"12d4b5c81d48e":{"x":{},"y":{},"mode":"lines","alpha_stroke":1,"sizes":[10,100],"spans":[1,20],"type":"scatter"}},"layout":{"margin":{"b":40,"l":60,"t":25,"r":10},"title":"Density plot for S(T=t | aplha, beta) for t=10","xaxis":{"domain":[0,1],"automargin":true,"title":"Period, t"},"yaxis":{"domain":[0,1],"automargin":true,"title":"S(T=t | aplha, beta)"},"hovermode":"closest","showlegend":false},"source":"A","config":{"modeBarButtonsToAdd":["hoverclosest","hovercompare"],"showSendToCloud":false},"data":[{"x":[1,2,3,4,5,6,7,8,9,10],"y":[0.5,0.333333333333333,0.25,0.2,0.166666666666667,0.142857142857143,0.125,0.111111111111111,0.1,0.090909090909091],"mode":"lines","type":"scatter","marker":{"color":"rgba(31,119,180,1)","line":{"color":"rgba(31,119,180,1)"}},"error_y":{"color":"rgba(31,119,180,1)"},"error_x":{"color":"rgba(31,119,180,1)"},"line":{"color":"rgba(31,119,180,1)"},"xaxis":"x","yaxis":"y","frame":null}],"highlight":{"on":"plotly_click","persistent":false,"dynamic":false,"selectize":false,"opacityDim":0.2,"selected":{"opacity":1},"debounce":0},"shinyEvents":["plotly_hover","plotly_click","plotly_selected","plotly_relayout","plotly_brushed","plotly_brushing","plotly_clickannotation","plotly_doubleclick","plotly_deselect","plotly_afterplot","plotly_sunburstclick"],"base_url":"https://plot.ly"},"evals":[],"jsHooks":[]}</script>
```

### Likelihood function

```r
MLL = function(alphabeta){
  # Computesl ikelihood. Equation (B3) in Paper 1
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

# Data from paper
activeCust = c(869,743,653,593,551,517,491)
lostCust = c(131,126,90,60,42,34,26)

MLL(c(1,1))
```

```
## [1] 2115.546
```

### Example From Paper
Below we recreate the example from the paper using the same data.

```r
# Data
activeCust = c(869,743,653,593,551,517,491)
lostCust = c(131,126,90,60,42,34,26)

# MLL optimization. Result are same as in the paper alpha=0.668, beta = 3.806. Good to go
# Obj. value = -1611.2
optim(c(1,1),MLL)
```

```
## Warning in log(churnBG(alpha, beta, 1:t)): NaNs produced
```

```
## $par
## [1] 0.6677123 3.8024773
## 
## $value
## [1] 1611.158
## 
## $counts
## function gradient 
##       93       NA 
## 
## $convergence
## [1] 0
## 
## $message
## NULL
```

```r
# plot of churn probabilities
plot_ly(x = 1:7, y = churnBG(alpha = 0.668, beta = 3.806, 1:7),
        type = 'scatter', mode = 'lines') %>%
  layout(title = "Density plot for P(T=t | aplha, beta) for t=10 fitted to the example data",
         xaxis = list(title = "Period, t"),
         yaxis = list(title = "P(T=t | aplha, beta)"))
```

```{=html}
<div id="htmlwidget-dbdcacad8b73cf428296" style="width:672px;height:480px;" class="plotly html-widget"></div>
<script type="application/json" data-for="htmlwidget-dbdcacad8b73cf428296">{"x":{"visdat":{"12d4b1c44b252":["function () ","plotlyVisDat"]},"cur_data":"12d4b1c44b252","attrs":{"12d4b1c44b252":{"x":[1,2,3,4,5,6,7],"y":[0.149307107733572,0.103811262702589,0.0770647093834792,0.0598658954616645,0.0480820491517688,0.0396166852099121,0.0333076694632887],"mode":"lines","alpha_stroke":1,"sizes":[10,100],"spans":[1,20],"type":"scatter"}},"layout":{"margin":{"b":40,"l":60,"t":25,"r":10},"title":"Density plot for P(T=t | aplha, beta) for t=10 fitted to the example data","xaxis":{"domain":[0,1],"automargin":true,"title":"Period, t"},"yaxis":{"domain":[0,1],"automargin":true,"title":"P(T=t | aplha, beta)"},"hovermode":"closest","showlegend":false},"source":"A","config":{"modeBarButtonsToAdd":["hoverclosest","hovercompare"],"showSendToCloud":false},"data":[{"x":[1,2,3,4,5,6,7],"y":[0.149307107733572,0.103811262702589,0.0770647093834792,0.0598658954616645,0.0480820491517688,0.0396166852099121,0.0333076694632887],"mode":"lines","type":"scatter","marker":{"color":"rgba(31,119,180,1)","line":{"color":"rgba(31,119,180,1)"}},"error_y":{"color":"rgba(31,119,180,1)"},"error_x":{"color":"rgba(31,119,180,1)"},"line":{"color":"rgba(31,119,180,1)"},"xaxis":"x","yaxis":"y","frame":null}],"highlight":{"on":"plotly_click","persistent":false,"dynamic":false,"selectize":false,"opacityDim":0.2,"selected":{"opacity":1},"debounce":0},"shinyEvents":["plotly_hover","plotly_click","plotly_selected","plotly_relayout","plotly_brushed","plotly_brushing","plotly_clickannotation","plotly_doubleclick","plotly_deselect","plotly_afterplot","plotly_sunburstclick"],"base_url":"https://plot.ly"},"evals":[],"jsHooks":[]}</script>
```

```r
# plot of survival probabilities
plot_ly(x = 0:7, y = c(1,survivalBG(alpha = 0.668, beta = 3.806, 1:7)),
        type = 'scatter', mode = 'lines') %>%
  layout(title = "Density plot for S(T=t | aplha, beta) for t=10 fitted to the example data",
         xaxis = list(title = "Period, t"),
         yaxis = list(title = "S(T=t | aplha, beta)"))
```

```{=html}
<div id="htmlwidget-ef22a149ab2a1800e24e" style="width:672px;height:480px;" class="plotly html-widget"></div>
<script type="application/json" data-for="htmlwidget-ef22a149ab2a1800e24e">{"x":{"visdat":{"12d4b621733fd":["function () ","plotlyVisDat"]},"cur_data":"12d4b621733fd","attrs":{"12d4b621733fd":{"x":[0,1,2,3,4,5,6,7],"y":[1,0.850692892266428,0.746881629563839,0.66981692018036,0.609951024718695,0.561868975566927,0.522252290357014,0.488944620893726],"mode":"lines","alpha_stroke":1,"sizes":[10,100],"spans":[1,20],"type":"scatter"}},"layout":{"margin":{"b":40,"l":60,"t":25,"r":10},"title":"Density plot for S(T=t | aplha, beta) for t=10 fitted to the example data","xaxis":{"domain":[0,1],"automargin":true,"title":"Period, t"},"yaxis":{"domain":[0,1],"automargin":true,"title":"S(T=t | aplha, beta)"},"hovermode":"closest","showlegend":false},"source":"A","config":{"modeBarButtonsToAdd":["hoverclosest","hovercompare"],"showSendToCloud":false},"data":[{"x":[0,1,2,3,4,5,6,7],"y":[1,0.850692892266428,0.746881629563839,0.66981692018036,0.609951024718695,0.561868975566927,0.522252290357014,0.488944620893726],"mode":"lines","type":"scatter","marker":{"color":"rgba(31,119,180,1)","line":{"color":"rgba(31,119,180,1)"}},"error_y":{"color":"rgba(31,119,180,1)"},"error_x":{"color":"rgba(31,119,180,1)"},"line":{"color":"rgba(31,119,180,1)"},"xaxis":"x","yaxis":"y","frame":null}],"highlight":{"on":"plotly_click","persistent":false,"dynamic":false,"selectize":false,"opacityDim":0.2,"selected":{"opacity":1},"debounce":0},"shinyEvents":["plotly_hover","plotly_click","plotly_selected","plotly_relayout","plotly_brushed","plotly_brushing","plotly_clickannotation","plotly_doubleclick","plotly_deselect","plotly_afterplot","plotly_sunburstclick"],"base_url":"https://plot.ly"},"evals":[],"jsHooks":[]}</script>
```
