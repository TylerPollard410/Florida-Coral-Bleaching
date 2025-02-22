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
    - [Gaussian Process (GP) for Temporal
      Trends](#gaussian-process-gp-for-temporal-trends)
    - [Tensor-Product Spline for Spatial
      Variation](#tensor-product-spline-for-spatial-variation)
    - [Fixed Effects](#fixed-effects)
    - [Prior Specification](#prior-specification)
- [Model Comparison](#model-comparison)

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
Program](https://www.bco-dmo.org/dataset/773466). The data includes
various environmental and spatial covariates hypothesized to influence
coral bleaching. The response variable, **Percent Bleaching**, measures
the proportion of coral affected in each transect. Below is a list of
key environmental and geographic covariates that may contribute to
bleaching events:

<div id="hwneodjjlw" style="padding-left:0px;padding-right:0px;padding-top:10px;padding-bottom:10px;overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
<style>#hwneodjjlw table {
  font-family: system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji';
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
&#10;#hwneodjjlw thead, #hwneodjjlw tbody, #hwneodjjlw tfoot, #hwneodjjlw tr, #hwneodjjlw td, #hwneodjjlw th {
  border-style: none;
}
&#10;#hwneodjjlw p {
  margin: 0;
  padding: 0;
}
&#10;#hwneodjjlw .gt_table {
  display: table;
  border-collapse: collapse;
  line-height: normal;
  margin-left: auto;
  margin-right: auto;
  color: #333333;
  font-size: 16px;
  font-weight: normal;
  font-style: normal;
  background-color: #FFFFFF;
  width: auto;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #A8A8A8;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #A8A8A8;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
}
&#10;#hwneodjjlw .gt_caption {
  padding-top: 4px;
  padding-bottom: 4px;
}
&#10;#hwneodjjlw .gt_title {
  color: #333333;
  font-size: 125%;
  font-weight: initial;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-color: #FFFFFF;
  border-bottom-width: 0;
}
&#10;#hwneodjjlw .gt_subtitle {
  color: #333333;
  font-size: 85%;
  font-weight: initial;
  padding-top: 3px;
  padding-bottom: 5px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-color: #FFFFFF;
  border-top-width: 0;
}
&#10;#hwneodjjlw .gt_heading {
  background-color: #FFFFFF;
  text-align: center;
  border-bottom-color: #FFFFFF;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
}
&#10;#hwneodjjlw .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#hwneodjjlw .gt_col_headings {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
}
&#10;#hwneodjjlw .gt_col_heading {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: normal;
  text-transform: inherit;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: bottom;
  padding-top: 5px;
  padding-bottom: 6px;
  padding-left: 5px;
  padding-right: 5px;
  overflow-x: hidden;
}
&#10;#hwneodjjlw .gt_column_spanner_outer {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: normal;
  text-transform: inherit;
  padding-top: 0;
  padding-bottom: 0;
  padding-left: 4px;
  padding-right: 4px;
}
&#10;#hwneodjjlw .gt_column_spanner_outer:first-child {
  padding-left: 0;
}
&#10;#hwneodjjlw .gt_column_spanner_outer:last-child {
  padding-right: 0;
}
&#10;#hwneodjjlw .gt_column_spanner {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  vertical-align: bottom;
  padding-top: 5px;
  padding-bottom: 5px;
  overflow-x: hidden;
  display: inline-block;
  width: 100%;
}
&#10;#hwneodjjlw .gt_spanner_row {
  border-bottom-style: hidden;
}
&#10;#hwneodjjlw .gt_group_heading {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: middle;
  text-align: left;
}
&#10;#hwneodjjlw .gt_empty_group_heading {
  padding: 0.5px;
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  vertical-align: middle;
}
&#10;#hwneodjjlw .gt_from_md > :first-child {
  margin-top: 0;
}
&#10;#hwneodjjlw .gt_from_md > :last-child {
  margin-bottom: 0;
}
&#10;#hwneodjjlw .gt_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  margin: 10px;
  border-top-style: solid;
  border-top-width: 1px;
  border-top-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: middle;
  overflow-x: hidden;
}
&#10;#hwneodjjlw .gt_stub {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-right-style: solid;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#hwneodjjlw .gt_stub_row_group {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-right-style: solid;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  padding-left: 5px;
  padding-right: 5px;
  vertical-align: top;
}
&#10;#hwneodjjlw .gt_row_group_first td {
  border-top-width: 2px;
}
&#10;#hwneodjjlw .gt_row_group_first th {
  border-top-width: 2px;
}
&#10;#hwneodjjlw .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#hwneodjjlw .gt_first_summary_row {
  border-top-style: solid;
  border-top-color: #D3D3D3;
}
&#10;#hwneodjjlw .gt_first_summary_row.thick {
  border-top-width: 2px;
}
&#10;#hwneodjjlw .gt_last_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#hwneodjjlw .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#hwneodjjlw .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}
&#10;#hwneodjjlw .gt_last_grand_summary_row_top {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: double;
  border-bottom-width: 6px;
  border-bottom-color: #D3D3D3;
}
&#10;#hwneodjjlw .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}
&#10;#hwneodjjlw .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#hwneodjjlw .gt_footnotes {
  color: #333333;
  background-color: #FFFFFF;
  border-bottom-style: none;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
}
&#10;#hwneodjjlw .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#hwneodjjlw .gt_sourcenotes {
  color: #333333;
  background-color: #FFFFFF;
  border-bottom-style: none;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
}
&#10;#hwneodjjlw .gt_sourcenote {
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#hwneodjjlw .gt_left {
  text-align: left;
}
&#10;#hwneodjjlw .gt_center {
  text-align: center;
}
&#10;#hwneodjjlw .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}
&#10;#hwneodjjlw .gt_font_normal {
  font-weight: normal;
}
&#10;#hwneodjjlw .gt_font_bold {
  font-weight: bold;
}
&#10;#hwneodjjlw .gt_font_italic {
  font-style: italic;
}
&#10;#hwneodjjlw .gt_super {
  font-size: 65%;
}
&#10;#hwneodjjlw .gt_footnote_marks {
  font-size: 75%;
  vertical-align: 0.4em;
  position: initial;
}
&#10;#hwneodjjlw .gt_asterisk {
  font-size: 100%;
  vertical-align: 0;
}
&#10;#hwneodjjlw .gt_indent_1 {
  text-indent: 5px;
}
&#10;#hwneodjjlw .gt_indent_2 {
  text-indent: 10px;
}
&#10;#hwneodjjlw .gt_indent_3 {
  text-indent: 15px;
}
&#10;#hwneodjjlw .gt_indent_4 {
  text-indent: 20px;
}
&#10;#hwneodjjlw .gt_indent_5 {
  text-indent: 25px;
}
&#10;#hwneodjjlw .katex-display {
  display: inline-flex !important;
  margin-bottom: 0.75em !important;
}
&#10;#hwneodjjlw div.Reactable > div.rt-table > div.rt-thead > div.rt-tr.rt-tr-group-header > div.rt-th-group:after {
  height: 0px !important;
}
</style>
<table class="gt_table" data-quarto-disable-processing="false" data-quarto-bootstrap="false">
  <thead>
    <tr class="gt_col_headings">
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" scope="col" id="Covariate">Covariate</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" scope="col" id="Description">Description</th>
    </tr>
  </thead>
  <tbody class="gt_table_body">
    <tr><td headers="Covariate" class="gt_row gt_left">Date_Year</td>
<td headers="Description" class="gt_row gt_left">Year of observation</td></tr>
    <tr><td headers="Covariate" class="gt_row gt_left">City_Town_Name</td>
<td headers="Description" class="gt_row gt_left">Categorical variable representing the specific city or town</td></tr>
    <tr><td headers="Covariate" class="gt_row gt_left">Lat</td>
<td headers="Description" class="gt_row gt_left">Latitude of the coral reef transect</td></tr>
    <tr><td headers="Covariate" class="gt_row gt_left">Lon</td>
<td headers="Description" class="gt_row gt_left">Longitude of the coral reef transect</td></tr>
    <tr><td headers="Covariate" class="gt_row gt_left">Distance_to_Shore</td>
<td headers="Description" class="gt_row gt_left">Distance from the reef to the shoreline (km)</td></tr>
    <tr><td headers="Covariate" class="gt_row gt_left">Exposure</td>
<td headers="Description" class="gt_row gt_left">Level of wave exposure (e.g., sheltered, exposed)</td></tr>
    <tr><td headers="Covariate" class="gt_row gt_left">Turbidity</td>
<td headers="Description" class="gt_row gt_left">Water clarity, with higher values indicating more suspended particles</td></tr>
    <tr><td headers="Covariate" class="gt_row gt_left">Cyclone_Frequency</td>
<td headers="Description" class="gt_row gt_left">Number of cyclones affecting the area per year</td></tr>
    <tr><td headers="Covariate" class="gt_row gt_left">Depth_m</td>
<td headers="Description" class="gt_row gt_left">Depth of the coral reef (meters)</td></tr>
    <tr><td headers="Covariate" class="gt_row gt_left">Windspeed</td>
<td headers="Description" class="gt_row gt_left">Average wind speed (m/s)</td></tr>
    <tr><td headers="Covariate" class="gt_row gt_left">ClimSST</td>
<td headers="Description" class="gt_row gt_left">Climatological sea surface temperature (°C)</td></tr>
    <tr><td headers="Covariate" class="gt_row gt_left">SSTA</td>
<td headers="Description" class="gt_row gt_left">Sea surface temperature anomaly (°C)</td></tr>
    <tr><td headers="Covariate" class="gt_row gt_left">SSTA_DHW</td>
<td headers="Description" class="gt_row gt_left">Degree heating weeks derived from SSTA</td></tr>
    <tr><td headers="Covariate" class="gt_row gt_left">TSA</td>
<td headers="Description" class="gt_row gt_left">Tropical sea surface temperature anomaly (°C)</td></tr>
    <tr><td headers="Covariate" class="gt_row gt_left">TSA_DHW</td>
<td headers="Description" class="gt_row gt_left">Degree heating weeks derived from TSA</td></tr>
  </tbody>
  &#10;  
</table>
</div>

The Percent Bleaching data exhibits a right-skewed distribution (Figure
1), with a substantial number of observations reporting 0% bleaching.

<div class="figure" style="text-align: center">

<img src="README_files/figure-gfm/PercentBleaching Density-1.png" alt="Figure 1: Density Plot of Percent Bleaching from 2,394 Coral Reef Samples" width="100%" />
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

<img src="README_files/figure-gfm/Spatial Structure-1.png" alt="Figure 2: Map of Percent Bleaching from 2,394 Coral Reef Samples around Florida" width="100%" />
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

<img src="README_files/figure-gfm/Temporal Structure-1.png" alt="Figure 3: Boxplots of Percent Bleaching vs Year by City Town Name" width="100%" />
<p class="caption">
Figure 3: Boxplots of Percent Bleaching vs Year by City Town Name
</p>

</div>

# Model Description

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

To model the proportion of coral bleaching $Y_i$ for $i = 1, ..., 2835$,
we use a **Bayesian Beta regression** with a **logit link function**:

$$
Y_i \sim \text{Beta}(\mu_i \phi, (1-\mu_i) \phi)
$$

where $\mu_i$ is the mean bleaching percentage, and $\phi$ is the
precision parameter. Various models for the mean structure were examined
and defined as:

<div style="padding-left:0px;padding-right:0px;padding-top:10px;padding-bottom:10px;overflow-x:auto;width:auto;">

$$
\begin{aligned}
\textbf{Model 1}: \text{logit}(\mu_i) &= \text{Date_Year}_i\beta_1 + \text{Lat}_i\beta_2 + \text{Lon}_i\beta_3 + \sum_{p} X_{ip}\beta_p \\
\textbf{Model 2}: \text{logit}(\mu_i) &= \text{Date_Year}_i\beta_1 + g(\text{Lat}_i, \text{Lon}_i) + \sum_{p} X_{ip}\beta_p \\
\textbf{Model 3}: \text{logit}(\mu_i) &= f(\text{Date_Year}_i) + \text{Lat}_i\beta_2 + \text{Lon}_i\beta_3 + \sum_{p} X_{ip}\beta_p \\
\textbf{Model 4}: \text{logit}(\mu_i) &= f(\text{Date_Year}_i) + g(\text{Lat}_i, \text{Lon}_i) + \sum_{p} X_{ip}\beta_p \\
\textbf{Model 5}: \text{logit}(\mu_i) &= f(\text{Date_Year}_i, \text{City_Town_Name}_i) + \text{Lat}_i\beta_2 + \text{Lon}_i\beta_3 + \sum_{p} X_{ip}\beta_p \\
\textbf{Model 6}: \text{logit}(\mu_i) &= f(\text{Date_Year}_i, \text{City_Town_Name}_i) + g(\text{Lat}_i, \text{Lon}_i) + \sum_{p} X_{ip}\beta_p \\
\end{aligned}
$$

</div>

where:

### Gaussian Process (GP) for Temporal Trends

$$
f(\text{Date_Year}_i, \text{City_Town_Name}_i) \sim \mathcal{GP} (0, (k_c(t_i, t_j))_{i,j = 1}^n) \\ 
$$

where the covariance function for each city $c$ is:

$$
k_c(t_i, t_j) = \sigma_c^2 \exp\left( -\frac{||t_i - t_j||^2}{2 \rho_c^2} \right)
$$

with:

- $t_i, t_j$ as observed `Date_Year` values.
- $c_i$ representing the city (`City_Town_Name`), where each city has a
  separate GP.
- $k_c(t_i, t_j)$ as the covariance function, using an
  exponentiated-quadratic (squared exponential) kernel.
- $\sigma_c^2$ representing a standard deviation parameter of the GP for
  city $c$.
- $\rho_c$ as the characteristic length-scale parameter.

### Tensor-Product Spline for Spatial Variation

$$
g(\text{Lat}_i, \text{Lon}_i) = \sum_{k_1} \sum_{k_2} \beta_{k_1 k_2} B_{k_1}(\text{Lat}) B_{k_2}(\text{Lon})
$$

where:

- $B_{k_1}(\text{Lat})$ and $B_{k_2}(\text{Lon})$ are basis functions
  for latitude and longitude.
- $\beta_{k_1 k_2}$ are the coefficients to be estimated.
- The smoothing penalty is controlled by a hyperparameter $\lambda$,
  which regularizes the estimated coefficients.

### Fixed Effects

$$
\sum_{p} X_{ip} \beta_p
$$

where:

- $X_{ip}$ is the value of the $p$-th covariate for observation $i$.
- $\beta_p$ is the corresponding regression coefficient.

### Prior Specification

- **Fixed Effects**:
  - $\beta_p \sim \mathcal{N}(0,5)$ for all covariates $p$.
- **Gaussian Process (Temporal Trends)**:
  - $\sigma_c \sim \text{half-Cauchy}(0,2)$
  - $\rho_c \sim \text{InvGamma}(4.308447, 0.957567)$ (explicitly
    defined by `brms`)
- **Tensor-Product Spline**:
  - $\beta_{k_1 k_2} \sim \mathcal{N}(0,5)$
  - $\lambda \sim \text{half-Cauchy}(0,2)$ (if explicitly included in
    smoothing penalty)
- **Precision Parameter**:
  - $\phi \sim \text{Gamma}(0.1, 0.1)$

This model accounts for both spatial and temporal dependencies, allowing
for flexible trend estimation.

# Model Comparison

We tested the 6 models abive to evaluate different approaches for
capturing spatiotemporal variation in coral bleaching. The candidate
models included:

- **Linear models** with Date_Year as a fixed effect.
- **Gaussian Process (GP) models**, both with and without city-specific
  trends.
- **Spatial models**, incorporating either Lat and Lon as fixed effects
  or a smooth spatial term.

After running convergence checks, the final model was selected using
**Leave-One-Out Cross-Validation (LOO-CV)**, ensuring it provided the
best balance between fit and complexity.

<div id="rkxfudrayc" style="padding-left:0px;padding-right:0px;padding-top:10px;padding-bottom:10px;overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
<style>#rkxfudrayc table {
  font-family: system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji';
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
&#10;#rkxfudrayc thead, #rkxfudrayc tbody, #rkxfudrayc tfoot, #rkxfudrayc tr, #rkxfudrayc td, #rkxfudrayc th {
  border-style: none;
}
&#10;#rkxfudrayc p {
  margin: 0;
  padding: 0;
}
&#10;#rkxfudrayc .gt_table {
  display: table;
  border-collapse: collapse;
  line-height: normal;
  margin-left: auto;
  margin-right: auto;
  color: #333333;
  font-size: 16px;
  font-weight: normal;
  font-style: normal;
  background-color: #FFFFFF;
  width: auto;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #A8A8A8;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #A8A8A8;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
}
&#10;#rkxfudrayc .gt_caption {
  padding-top: 4px;
  padding-bottom: 4px;
}
&#10;#rkxfudrayc .gt_title {
  color: #333333;
  font-size: 125%;
  font-weight: initial;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-color: #FFFFFF;
  border-bottom-width: 0;
}
&#10;#rkxfudrayc .gt_subtitle {
  color: #333333;
  font-size: 85%;
  font-weight: initial;
  padding-top: 3px;
  padding-bottom: 5px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-color: #FFFFFF;
  border-top-width: 0;
}
&#10;#rkxfudrayc .gt_heading {
  background-color: #FFFFFF;
  text-align: center;
  border-bottom-color: #FFFFFF;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
}
&#10;#rkxfudrayc .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#rkxfudrayc .gt_col_headings {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
}
&#10;#rkxfudrayc .gt_col_heading {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: normal;
  text-transform: inherit;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: bottom;
  padding-top: 5px;
  padding-bottom: 6px;
  padding-left: 5px;
  padding-right: 5px;
  overflow-x: hidden;
}
&#10;#rkxfudrayc .gt_column_spanner_outer {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: normal;
  text-transform: inherit;
  padding-top: 0;
  padding-bottom: 0;
  padding-left: 4px;
  padding-right: 4px;
}
&#10;#rkxfudrayc .gt_column_spanner_outer:first-child {
  padding-left: 0;
}
&#10;#rkxfudrayc .gt_column_spanner_outer:last-child {
  padding-right: 0;
}
&#10;#rkxfudrayc .gt_column_spanner {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  vertical-align: bottom;
  padding-top: 5px;
  padding-bottom: 5px;
  overflow-x: hidden;
  display: inline-block;
  width: 100%;
}
&#10;#rkxfudrayc .gt_spanner_row {
  border-bottom-style: hidden;
}
&#10;#rkxfudrayc .gt_group_heading {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: middle;
  text-align: left;
}
&#10;#rkxfudrayc .gt_empty_group_heading {
  padding: 0.5px;
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  vertical-align: middle;
}
&#10;#rkxfudrayc .gt_from_md > :first-child {
  margin-top: 0;
}
&#10;#rkxfudrayc .gt_from_md > :last-child {
  margin-bottom: 0;
}
&#10;#rkxfudrayc .gt_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  margin: 10px;
  border-top-style: solid;
  border-top-width: 1px;
  border-top-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: middle;
  overflow-x: hidden;
}
&#10;#rkxfudrayc .gt_stub {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-right-style: solid;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#rkxfudrayc .gt_stub_row_group {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-right-style: solid;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  padding-left: 5px;
  padding-right: 5px;
  vertical-align: top;
}
&#10;#rkxfudrayc .gt_row_group_first td {
  border-top-width: 2px;
}
&#10;#rkxfudrayc .gt_row_group_first th {
  border-top-width: 2px;
}
&#10;#rkxfudrayc .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#rkxfudrayc .gt_first_summary_row {
  border-top-style: solid;
  border-top-color: #D3D3D3;
}
&#10;#rkxfudrayc .gt_first_summary_row.thick {
  border-top-width: 2px;
}
&#10;#rkxfudrayc .gt_last_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#rkxfudrayc .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#rkxfudrayc .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}
&#10;#rkxfudrayc .gt_last_grand_summary_row_top {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: double;
  border-bottom-width: 6px;
  border-bottom-color: #D3D3D3;
}
&#10;#rkxfudrayc .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}
&#10;#rkxfudrayc .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#rkxfudrayc .gt_footnotes {
  color: #333333;
  background-color: #FFFFFF;
  border-bottom-style: none;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
}
&#10;#rkxfudrayc .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#rkxfudrayc .gt_sourcenotes {
  color: #333333;
  background-color: #FFFFFF;
  border-bottom-style: none;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
}
&#10;#rkxfudrayc .gt_sourcenote {
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#rkxfudrayc .gt_left {
  text-align: left;
}
&#10;#rkxfudrayc .gt_center {
  text-align: center;
}
&#10;#rkxfudrayc .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}
&#10;#rkxfudrayc .gt_font_normal {
  font-weight: normal;
}
&#10;#rkxfudrayc .gt_font_bold {
  font-weight: bold;
}
&#10;#rkxfudrayc .gt_font_italic {
  font-style: italic;
}
&#10;#rkxfudrayc .gt_super {
  font-size: 65%;
}
&#10;#rkxfudrayc .gt_footnote_marks {
  font-size: 75%;
  vertical-align: 0.4em;
  position: initial;
}
&#10;#rkxfudrayc .gt_asterisk {
  font-size: 100%;
  vertical-align: 0;
}
&#10;#rkxfudrayc .gt_indent_1 {
  text-indent: 5px;
}
&#10;#rkxfudrayc .gt_indent_2 {
  text-indent: 10px;
}
&#10;#rkxfudrayc .gt_indent_3 {
  text-indent: 15px;
}
&#10;#rkxfudrayc .gt_indent_4 {
  text-indent: 20px;
}
&#10;#rkxfudrayc .gt_indent_5 {
  text-indent: 25px;
}
&#10;#rkxfudrayc .katex-display {
  display: inline-flex !important;
  margin-bottom: 0.75em !important;
}
&#10;#rkxfudrayc div.Reactable > div.rt-table > div.rt-thead > div.rt-tr.rt-tr-group-header > div.rt-th-group:after {
  height: 0px !important;
}
</style>
<table class="gt_table" data-quarto-disable-processing="false" data-quarto-bootstrap="false">
  <thead>
    <tr class="gt_col_headings">
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" style="white-space: nowrap;" scope="col" id="Model">Model</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" style="white-space: nowrap;" scope="col" id="TempStr">Temporal Structure</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" style="white-space: nowrap;" scope="col" id="SpaceStr">Spatial Structure</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" style="white-space: nowrap;" scope="col" id="elpd_diff_loo">elpd_diff_loo<span class="gt_footnote_marks" style="white-space:nowrap;font-style:italic;font-weight:normal;line-height:0;"><sup>1</sup></span></th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" style="white-space: nowrap;" scope="col" id="se_diff_loo">se_diff_loo<span class="gt_footnote_marks" style="white-space:nowrap;font-style:italic;font-weight:normal;line-height:0;"><sup>2</sup></span></th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" style="white-space: nowrap;" scope="col" id="p_loo">p_loo<span class="gt_footnote_marks" style="white-space:nowrap;font-style:italic;font-weight:normal;line-height:0;"><sup>3</sup></span></th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" style="white-space: nowrap;" scope="col" id="looic">looic<span class="gt_footnote_marks" style="white-space:nowrap;font-style:italic;font-weight:normal;line-height:0;"><sup>4</sup></span></th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" style="white-space: nowrap;" scope="col" id="se_looic">se_looic<span class="gt_footnote_marks" style="white-space:nowrap;font-style:italic;font-weight:normal;line-height:0;"><sup>5</sup></span></th>
    </tr>
  </thead>
  <tbody class="gt_table_body">
    <tr><td headers="Model" class="gt_row gt_left" style="white-space: nowrap;">Model 6</td>
<td headers="TempStr" class="gt_row gt_left" style="white-space: nowrap;">City-Specific GP</td>
<td headers="SpaceStr" class="gt_row gt_left" style="white-space: nowrap;">Tensor Smooth</td>
<td headers="elpd_diff_loo" class="gt_row gt_right" style="white-space: nowrap;">0.00</td>
<td headers="se_diff_loo" class="gt_row gt_right" style="white-space: nowrap;">0.00</td>
<td headers="p_loo" class="gt_row gt_right" style="white-space: nowrap;">80.47</td>
<td headers="looic" class="gt_row gt_right" style="white-space: nowrap;">−5,711.89</td>
<td headers="se_looic" class="gt_row gt_right" style="white-space: nowrap;">134.45</td></tr>
    <tr><td headers="Model" class="gt_row gt_left" style="white-space: nowrap;">Model 5</td>
<td headers="TempStr" class="gt_row gt_left" style="white-space: nowrap;">City-Specific GP</td>
<td headers="SpaceStr" class="gt_row gt_left" style="white-space: nowrap;">Linear</td>
<td headers="elpd_diff_loo" class="gt_row gt_right" style="white-space: nowrap;">−16.19</td>
<td headers="se_diff_loo" class="gt_row gt_right" style="white-space: nowrap;">6.26</td>
<td headers="p_loo" class="gt_row gt_right" style="white-space: nowrap;">75.56</td>
<td headers="looic" class="gt_row gt_right" style="white-space: nowrap;">−5,679.50</td>
<td headers="se_looic" class="gt_row gt_right" style="white-space: nowrap;">133.96</td></tr>
    <tr><td headers="Model" class="gt_row gt_left" style="white-space: nowrap;">Model 4</td>
<td headers="TempStr" class="gt_row gt_left" style="white-space: nowrap;">Global GP</td>
<td headers="SpaceStr" class="gt_row gt_left" style="white-space: nowrap;">Tensor Smooth</td>
<td headers="elpd_diff_loo" class="gt_row gt_right" style="white-space: nowrap;">−93.13</td>
<td headers="se_diff_loo" class="gt_row gt_right" style="white-space: nowrap;">20.50</td>
<td headers="p_loo" class="gt_row gt_right" style="white-space: nowrap;">43.11</td>
<td headers="looic" class="gt_row gt_right" style="white-space: nowrap;">−5,525.64</td>
<td headers="se_looic" class="gt_row gt_right" style="white-space: nowrap;">133.72</td></tr>
    <tr><td headers="Model" class="gt_row gt_left" style="white-space: nowrap;">Model 3</td>
<td headers="TempStr" class="gt_row gt_left" style="white-space: nowrap;">Global GP</td>
<td headers="SpaceStr" class="gt_row gt_left" style="white-space: nowrap;">Linear</td>
<td headers="elpd_diff_loo" class="gt_row gt_right" style="white-space: nowrap;">−124.21</td>
<td headers="se_diff_loo" class="gt_row gt_right" style="white-space: nowrap;">22.02</td>
<td headers="p_loo" class="gt_row gt_right" style="white-space: nowrap;">33.40</td>
<td headers="looic" class="gt_row gt_right" style="white-space: nowrap;">−5,463.46</td>
<td headers="se_looic" class="gt_row gt_right" style="white-space: nowrap;">131.95</td></tr>
    <tr><td headers="Model" class="gt_row gt_left" style="white-space: nowrap;">Model 2</td>
<td headers="TempStr" class="gt_row gt_left" style="white-space: nowrap;">Linear</td>
<td headers="SpaceStr" class="gt_row gt_left" style="white-space: nowrap;">Tensor Smooth</td>
<td headers="elpd_diff_loo" class="gt_row gt_right" style="white-space: nowrap;">−460.63</td>
<td headers="se_diff_loo" class="gt_row gt_right" style="white-space: nowrap;">33.49</td>
<td headers="p_loo" class="gt_row gt_right" style="white-space: nowrap;">24.05</td>
<td headers="looic" class="gt_row gt_right" style="white-space: nowrap;">−4,790.64</td>
<td headers="se_looic" class="gt_row gt_right" style="white-space: nowrap;">120.73</td></tr>
    <tr><td headers="Model" class="gt_row gt_left" style="white-space: nowrap;">Model 1</td>
<td headers="TempStr" class="gt_row gt_left" style="white-space: nowrap;">Linear</td>
<td headers="SpaceStr" class="gt_row gt_left" style="white-space: nowrap;">Linear</td>
<td headers="elpd_diff_loo" class="gt_row gt_right" style="white-space: nowrap;">−491.58</td>
<td headers="se_diff_loo" class="gt_row gt_right" style="white-space: nowrap;">33.90</td>
<td headers="p_loo" class="gt_row gt_right" style="white-space: nowrap;">18.32</td>
<td headers="looic" class="gt_row gt_right" style="white-space: nowrap;">−4,728.73</td>
<td headers="se_looic" class="gt_row gt_right" style="white-space: nowrap;">118.72</td></tr>
  </tbody>
  &#10;  <tfoot class="gt_footnotes">
    <tr>
      <td class="gt_footnote" colspan="8"><span class="gt_footnote_marks" style="white-space:nowrap;font-style:italic;font-weight:normal;line-height:0;"><sup>1</sup></span> Difference in Expected Log pointwise Predictive Density for a new dataset</td>
    </tr>
    <tr>
      <td class="gt_footnote" colspan="8"><span class="gt_footnote_marks" style="white-space:nowrap;font-style:italic;font-weight:normal;line-height:0;"><sup>2</sup></span> Standard Error of component-wise elpd_diff_loo between two models</td>
    </tr>
    <tr>
      <td class="gt_footnote" colspan="8"><span class="gt_footnote_marks" style="white-space:nowrap;font-style:italic;font-weight:normal;line-height:0;"><sup>3</sup></span> Effective number of parameters</td>
    </tr>
    <tr>
      <td class="gt_footnote" colspan="8"><span class="gt_footnote_marks" style="white-space:nowrap;font-style:italic;font-weight:normal;line-height:0;"><sup>4</sup></span> Leave-one-out Information Criteria</td>
    </tr>
    <tr>
      <td class="gt_footnote" colspan="8"><span class="gt_footnote_marks" style="white-space:nowrap;font-style:italic;font-weight:normal;line-height:0;"><sup>5</sup></span> Standard Error of looic</td>
    </tr>
  </tfoot>
</table>
</div>
