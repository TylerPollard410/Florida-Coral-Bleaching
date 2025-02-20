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
  - [Data Preprocessing](#data-preprocessing)
  - [Model Specification](#model-specification)

# Motivation

Coral bleaching occurs when corals experience stress due to changes in
environmental conditions such as temperature, light, or nutrient levels.
This stress leads corals to expel their symbiotic algae, resulting in
the loss of their coloration and, in severe cases, coral death.

Several factors contribute to coral bleaching, including rising sea
temperatures, sea-level changes, and ocean acidification, all of which
are consequences of climate change. Understanding the key environmental
drivers of bleaching is critical for conservation efforts.

The objective of this study is to identify and quantify the **impact of
key environmental covariates on coral bleaching** while also assessing
**how bleaching has changed over time** across different locations in
Florida. Using **spatiotemporal modeling**, we analyze trends in coral
bleaching by incorporating both **spatial variation** (reef locations)
and **temporal patterns** (yearly changes) within a **Bayesian
regression framework**.

# Data

This study utilizes a dataset with 2,394 observations collected between
2006 and 2016 sourced from the [Florida Reef Resilience
Program](https://www.bco-dmo.org/dataset/773466). The data includes key
covariates such as date year, latitude, longitude, sea surface
temperature, turbidity, cyclone frequency, and other environmental
factors. The response variable is Percent Bleaching, which measures the
proportion of coral affected in each transect.

The Percent Bleaching data exhibits a right-skewed distribution (Figure
1), with a substantial number of observations reporting 0% bleaching.

<div class="figure" style="text-align: center">

<img src="README_files/figure-gfm/PercentBleaching Density-1.png" alt="Figure 1: Density Plot of Percent Bleaching from 2,394 Coral Reef Samples"  />
<p class="caption">
Figure 1: Density Plot of Percent Bleaching from 2,394 Coral Reef
Samples
</p>

</div>

## Spatial Structure

Coral bleaching observations were **geographically distributed across
Florida’s reef systems** (Figure 2). Mapping Percent Bleaching reveals
**spatial clustering**, with certain areas experiencing more severe
bleaching than others.

<div class="figure" style="text-align: center">

<img src="README_files/figure-gfm/Spatial Structure-1.png" alt="Figure 2: Map of Percent Bleaching from 2,394 Coral Reef Samples around Florida"  />
<p class="caption">
Figure 2: Map of Percent Bleaching from 2,394 Coral Reef Samples around
Florida
</p>

</div>

## Temporal Structure

The dataset spans **2006 to 2016**, providing an opportunity to analyze
**bleaching trends over time** (Figure 3). Boxplots of Percent Bleaching
over the years, categorized by City_Town_Name, reveal distinct temporal
patterns across locations.

<div class="figure" style="text-align: center">

<img src="README_files/figure-gfm/Temporal Structure-1.png" alt="Figure 3: Boxplots of Percent Bleaching vs Year by City Town Name"  />
<p class="caption">
Figure 3: Boxplots of Percent Bleaching vs Year by City Town Name
</p>

</div>

# Model Description

| **Model** | **Temporal Structure** | **Spatial Structure** | **LOO Score** |
|----|----|----|----|
| **Model A** | Linear (`Date_Year`) | None | -XXXX |
| **Model B** | Linear (`Date_Year`) | Lat/Lon Fixed Effects | -XXXX |
| **Model C** | Global GP | None | -XXXX |
| **Model D** | City-Specific GP | None | **Lowest LOO** |
| **Final Model** | City-Specific GP | Spatial Smoother | Slightly lower LOO than Model D |

## Data Preprocessing

Before fitting the model, we applied several preprocessing steps:

- **Response Variable Transformation**: Since the Beta regression model
  requires values strictly in the (0,1) range, we replaced:

  - 0% bleaching values with 0.001

  - 100% bleaching values with 0.999

- **Covariate Transformations**:

  - **Yeo-Johnson transformation** was applied to all continuous
    covariates to reduce skewness.

  - **Centering and scaling** were performed to standardize covariates
    for better model convergence.

## Model Specification

To model the proportion of coral bleaching $Y_i$, we use a **Bayesian
Beta regression** with a **logit link function**:

$$
\begin{aligned}
Y_i \sim \text{Beta}(\mu_i \phi, (1-\mu_i) \phi)
\end{aligned}
$$

where $\mu_i$ is the **mean bleaching percentage**, and $\phi$ is the
**precision parameter**. The mean structure is defined as:

1.  Model 1

2.  Model 2

3.  Model 3
