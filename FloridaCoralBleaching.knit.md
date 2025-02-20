---
author: "Tyler Pollard, Rachel Hardy, and Hanan Ali"
date: "2024-05-06"
header-includes:
  - \usepackage{mathtools}
output:  
  github_document:
    html_preview: true
    includes: 
      in_header: _includes/head.html
    toc: true
    toc_depth: 3
---





# Motivation

Coral bleaching occurs when corals experience stress due to changes in environmental conditions such as temperature, light, or nutrient levels. This stress leads corals to expel their symbiotic algae, resulting in the loss of their coloration and, in severe cases, coral death.

Several factors contribute to coral bleaching, including rising sea temperatures, sea-level changes, and ocean acidification, all of which are consequences of climate change. Understanding the key environmental drivers of bleaching is critical for conservation efforts.

The objective of this study is to identify and quantify the **impact of key environmental covariates on coral bleaching** while also assessing **how bleaching has changed over time** across different locations in Florida. Using **spatiotemporal modeling**, we analyze trends in coral bleaching by incorporating both **spatial variation** (reef locations) and **temporal patterns** (yearly changes) within a **Bayesian regression framework**.



# Data

This study utilizes a dataset with 2,394 observations collected between 2006 and 2016 sourced from the [Florida Reef Resilience Program](https://www.bco-dmo.org/dataset/773466). The data includes various environmental and spatial covariates hypothesized to influence coral bleaching. The response variable, **Percent Bleaching**, measures the proportion of coral affected in each transect. Below is a list of key environmental and geographic covariates that may contribute to bleaching events: 


```{=html}
<div id="pavlukpwui" style="padding-left:0px;padding-right:0px;padding-top:10px;padding-bottom:10px;overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
<style>#pavlukpwui table {
  font-family: system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji';
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

#pavlukpwui thead, #pavlukpwui tbody, #pavlukpwui tfoot, #pavlukpwui tr, #pavlukpwui td, #pavlukpwui th {
  border-style: none;
}

#pavlukpwui p {
  margin: 0;
  padding: 0;
}

#pavlukpwui .gt_table {
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

#pavlukpwui .gt_caption {
  padding-top: 4px;
  padding-bottom: 4px;
}

#pavlukpwui .gt_title {
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

#pavlukpwui .gt_subtitle {
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

#pavlukpwui .gt_heading {
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

#pavlukpwui .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#pavlukpwui .gt_col_headings {
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

#pavlukpwui .gt_col_heading {
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

#pavlukpwui .gt_column_spanner_outer {
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

#pavlukpwui .gt_column_spanner_outer:first-child {
  padding-left: 0;
}

#pavlukpwui .gt_column_spanner_outer:last-child {
  padding-right: 0;
}

#pavlukpwui .gt_column_spanner {
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

#pavlukpwui .gt_spanner_row {
  border-bottom-style: hidden;
}

#pavlukpwui .gt_group_heading {
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

#pavlukpwui .gt_empty_group_heading {
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

#pavlukpwui .gt_from_md > :first-child {
  margin-top: 0;
}

#pavlukpwui .gt_from_md > :last-child {
  margin-bottom: 0;
}

#pavlukpwui .gt_row {
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

#pavlukpwui .gt_stub {
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

#pavlukpwui .gt_stub_row_group {
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

#pavlukpwui .gt_row_group_first td {
  border-top-width: 2px;
}

#pavlukpwui .gt_row_group_first th {
  border-top-width: 2px;
}

#pavlukpwui .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}

#pavlukpwui .gt_first_summary_row {
  border-top-style: solid;
  border-top-color: #D3D3D3;
}

#pavlukpwui .gt_first_summary_row.thick {
  border-top-width: 2px;
}

#pavlukpwui .gt_last_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#pavlukpwui .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}

#pavlukpwui .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}

#pavlukpwui .gt_last_grand_summary_row_top {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: double;
  border-bottom-width: 6px;
  border-bottom-color: #D3D3D3;
}

#pavlukpwui .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}

#pavlukpwui .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#pavlukpwui .gt_footnotes {
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

#pavlukpwui .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}

#pavlukpwui .gt_sourcenotes {
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

#pavlukpwui .gt_sourcenote {
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}

#pavlukpwui .gt_left {
  text-align: left;
}

#pavlukpwui .gt_center {
  text-align: center;
}

#pavlukpwui .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}

#pavlukpwui .gt_font_normal {
  font-weight: normal;
}

#pavlukpwui .gt_font_bold {
  font-weight: bold;
}

#pavlukpwui .gt_font_italic {
  font-style: italic;
}

#pavlukpwui .gt_super {
  font-size: 65%;
}

#pavlukpwui .gt_footnote_marks {
  font-size: 75%;
  vertical-align: 0.4em;
  position: initial;
}

#pavlukpwui .gt_asterisk {
  font-size: 100%;
  vertical-align: 0;
}

#pavlukpwui .gt_indent_1 {
  text-indent: 5px;
}

#pavlukpwui .gt_indent_2 {
  text-indent: 10px;
}

#pavlukpwui .gt_indent_3 {
  text-indent: 15px;
}

#pavlukpwui .gt_indent_4 {
  text-indent: 20px;
}

#pavlukpwui .gt_indent_5 {
  text-indent: 25px;
}

#pavlukpwui .katex-display {
  display: inline-flex !important;
  margin-bottom: 0.75em !important;
}

#pavlukpwui div.Reactable > div.rt-table > div.rt-thead > div.rt-tr.rt-tr-group-header > div.rt-th-group:after {
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
  
  
</table>
</div>
```

The Percent Bleaching data exhibits a right-skewed distribution (Figure 1), with a substantial number of observations reporting 0% bleaching.

<div class="figure" style="text-align: center">
<img src="README_files/figure-gfm/PercentBleaching Density-1.png" alt="Figure 1: Density Plot of Percent Bleaching from 2,394 Coral Reef Samples"  />
<p class="caption">Figure 1: Density Plot of Percent Bleaching from 2,394 Coral Reef Samples</p>
</div>

## Spatial Structure

Coral bleaching observations were **geographically distributed across Florida's reef systems** (Figure 2). Mapping Percent Bleaching reveals **spatial clustering**, with certain areas experiencing more severe bleaching than others. 

<div class="figure" style="text-align: center">
<img src="README_files/figure-gfm/Spatial Structure-1.png" alt="Figure 2: Map of Percent Bleaching from 2,394 Coral Reef Samples around Florida"  />
<p class="caption">Figure 2: Map of Percent Bleaching from 2,394 Coral Reef Samples around Florida</p>
</div>

## Temporal Structure

The dataset spans **2006 to 2016**, providing an opportunity to analyze **bleaching trends over time** (Figure 3). Boxplots of Percent Bleaching over the years, categorized by City_Town_Name, reveal distinct temporal patterns across locations.

<div class="figure" style="text-align: center">
<img src="README_files/figure-gfm/Temporal Structure-1.png" alt="Figure 3: Boxplots of Percent Bleaching vs Year by City Town Name"  />
<p class="caption">Figure 3: Boxplots of Percent Bleaching vs Year by City Town Name</p>
</div>

# Model Description


## Data Preprocessing

Before fitting the model, we applied several preprocessing steps:

* **Response Variable Transformation**: Since the Beta regression model requires values strictly in the (0,1) range, we replaced:

  + 0\% bleaching values with 0.001

  + 100\% bleaching values with 0.999

* **Covariate Transformations**:

  + **Yeo-Johnson transformation** was applied to all continuous covariates to reduce skewness.

  + **Centering and scaling** were performed to standardize covariates for better model convergence.
  
## Model Specification

To model the proportion of coral bleaching $Y_i$, we use a **Bayesian Beta regression** with a **logit link function**:

$$
\begin{aligned}
Y_i \sim \text{Beta}(\mu_i \phi, (1-\mu_i) \phi)
\end{aligned}
$$

where $\mu_i$ is the **mean bleaching percentage**, and $\phi$ is the **precision parameter**. The mean structure is defined as:

1. Model 1

2. Model 2

3. Model 3











