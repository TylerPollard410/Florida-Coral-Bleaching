Tyler Pollard, Rachel Hardy, and Hanan Ali
2024-05-06

<!-- start custom head snippets, customize with your own _includes/head-custom.html file -->

<!-- Setup Google Analytics -->
<!-- {% include head-custom-google-analytics.html %} -->

<!-- You can set your favicon here -->
<!-- link rel="shortcut icon" type="image/x-icon" href="{{ '/favicon.ico' | relative_url }}" -->

<!-- Change content width onfull screen -->
<!-- <link rel="stylesheet" href="/Hurricane-Analysis/assets/css/custom.css"> -->


<!-- MathJax -->
<!-- inline config -->
<script>
  MathJax = {
    tex: {
      inlineMath: [['$', '$'], ['\\(', '\\)']],
      macros: {
      	RR: "{\\bf R}",
      	bold: ["{\\bf #1}", 1],
        indep: "{\\perp \\!\\!\\! \\perp}",
    	}
    },
    svg: {
    fontCache: 'global'
  	},
  };
</script>

<!-- load MathJax -->
<script type="text/javascript" id="MathJax-script" async
  src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js">
</script>

<!-- end custom head snippets -->

- [Motivation](#motivation)
- [Data](#data)
  - [Spatial Structure](#spatial-structure)
  - [Temporal Structure](#temporal-structure)
- [Model Description](#model-description)

# Motivation

Coral bleaching is when corals are stressed by changes in conditions
such as temperature, light, or nutrients, leading them to then expel the
symbiotic algae living in their tissues, causing them to turn completely
white. There are several factors that contribute to coral bleaching,
including but not limited to: rising sea temperatures, rising sea
levels, and ocean acidification, all of which are consequences of
climate change. This study will utilize data containing covariates such
as date year, latitude, longitude, temperature, turbidity, and more. The
response variable for this study is the percentage of coral bleaching
occurring in transect segments. The dataset contains 2,394 observations
from 2006 to 2016 and is sourced from the [Florida Reef Resilience
Program](https://www.bco-dmo.org/dataset/773466). .

# Data

The distribution for `PercentBleaching` was skewed right with support
\[0,1\] and a relatively large number of observations (201 out of 2394)
of 0 `PercentBleaching` as seen in the figure below. The beta
distribution was a natural selection to model the data due to the
support. After further examining the 0 values, they were deemed valid
and considered as part of the same process that generated the rest of
the data. To adhere to the soft (0,1) in beta regression, the 0 values
were replaced with 0.001 and the 1 values were replaced by 0.999 as a
simple workaround.

<div class="figure" style="text-align: center">

<img src="README_files/figure-gfm/PercentBleaching Density-1.png" alt="Figure 1: Density Plot of Percent Bleaching from 2,394 Coral Reef Samples"  />
<p class="caption">
Figure 1: Density Plot of Percent Bleaching from 2,394 Coral Reef
Samples
</p>

</div>

## Spatial Structure

Coral bleaching observations were **geographically distributed across
Florida’s reef systems**. Mapping Percent Bleaching reveals **spatial
clustering**, with certain areas experiencing more severe bleaching than
others. These spatial effects were captured using a **tensor product
spline (`t2(Lat, Lon)`)** to model continuous variation.

<div class="figure" style="text-align: center">

<img src="README_files/figure-gfm/Spatial Structure-1.png" alt="Figure 2: Map of Percent Bleaching from 2,394 Coral Reef Samples around Florida"  />
<p class="caption">
Figure 2: Map of Percent Bleaching from 2,394 Coral Reef Samples around
Florida
</p>

</div>

## Temporal Structure

The dataset spans **2006 to 2016**, allowing an analysis of **temporal
bleaching trends**. Boxplots of Percent Bleaching across years show
**variation over time**, with city-specific differences. To account for
**nonlinear temporal trends**, we incorporated a **Gaussian Process
(`gp(Date_Year, by = City_Town_Name)`)**, allowing each city to have its
own temporal trend.

<div class="figure" style="text-align: center">

<img src="README_files/figure-gfm/Temporal Structure-1.png" alt="Figure 3: Boxplots of Percent Bleaching vs Year by City Town Name"  />
<p class="caption">
Figure 3: Boxplots of Percent Bleaching vs Year by City Town Name
</p>

</div>

# Model Description

To model the percentage of coral bleaching $Y_i$, a Bayesian Beta
regression with a logit link function for the mean percentage $\mu_i$ is
used:

$$
\begin{aligned}
Y_i \sim Beta(\mu_i\phi, \mu_i(1-\phi))
\end{aligned}
$$

1.  Model 1

2.  Model 2

3.  Model 3
