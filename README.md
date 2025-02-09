Tyler Pollard
2024-08-25

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
- [Methods & Variable Selection](#methods--variable-selection)
- [Model 1: Multiple Linear
  Regression](#model-1-multiple-linear-regression)
- [Model 2: Beta Regression](#model-2-beta-regression)
- [Model Results](#model-results)
- [Conclusions & Further Questions](#conclusions--further-questions)

# Motivation

Coral bleaching is when corals are stressed by changes in conditions
such as temperature, light, or nutrients, leading them to then expel the
symbiotic algae living in their tissues, causing them to turn completely
white.

There are several factors that contribute to coral bleaching, including
but not limited to: rising sea temperatures, rising sea levels, and
ocean acidification, all of which are consequences of climate change.

This study will utilize data containing covariates such as date (month
and year), temperature, turbidity, cyclone frequency, depth, and more.
The response variable for this study is the percentage of coral
bleaching occurring in transect segments.

The dataset contains 2,394 observations from 2006 to 2016 and is sourced
from the Florida Reef Resilience Program. [Data
source:](https://www.bco-dmo.org/dataset/773466)

The objective of this study is to determine what covariates most heavily
impact coral bleaching, and if coral bleaching has progressed over time.

# Methods & Variable Selection

The distribution for Percent_Bleaching was highly skewed right with
support \[0,1\], so a beta distribution was a natural selection to model
the data. Due to the large number of samples and our lack of prior
information about the data, we also chose to evoke the Bayesian Central
Limit Theorem and model the data with a multiple linear regression
model.

The data set included information on 3 types of possible predictors of
Percent_Bleaching that we could include in our model:

Sample Site: Distance_to_Shore, Exposure, Turbidity, Cyclone_Frequency
Date Information: Date_Year, Date_Month, Date_Day Temperature: ClimSST,
SSTA, SSTA_DHW, TSA, TSA_DHW

TSA: Thermal Stress Anomaly: Weekly sea surface temperature minus the
maximum of weekly climatological sea surface temperature. TSA_DHW:
Thermal Stress Anomaly (TSA), Degree Heating Week (DHW): Sum of previous
12 weeks when TSA \>=1 degree C. SSTA: Sea Surface Temperature Anomaly:
Weekly sea surface temperature minus weekly climatological sea surface
temperature.

The SSTA SSTA_DHW and TSA TSA_DHW set of predictors were highly
correlated with each other. The Gaussian model was initially fit twice
with each of these temperature sets and from DIC/WAIC calculations the
TSA/TSA_DHW\* set was slightly better and the full set of predictors
above without SSTA and SSTA_DHW were included in both initial models.

Before the models were fit 25% of the data was randomly selected to be
excluded as a test data set and the models were fit on the remaining 75%
training data set. Each model was iteratively fit to identify parameters
that were deemed insignificant based on their posterior 95% credible
interval. The corresponding predictors were removed from the model and
the model was fit again until all parameters were significant.

Since the final two candidate models had different likelihoods,
posterior predictive checks and mean absolute deviance were used to
select the best model.

# Model 1: Multiple Linear Regression

The first model to be fit was a multiple linear regression model chosen
to have uninformative Gaussian priors and a normal likelihood with the
response

The linear model will take on the form

The following priors were selected:

The significant variables for this model are Date_Year, Date_Month,
Distance_to_Shore, Turbidity, Cyclone_Frequency, Depth_m, TSA, and
TSA_DHW.

This model had great convergence and a decent mean absolute deviation of
10.51, but ultimately was not the best for the data at hand due to the
presence of negative values in the posterior distribution.

# Model 2: Beta Regression

The second model to be fit was a beta regression model with a likelihood
that assumes a beta distribution for the Percent_Bleaching response
variable

The beta regression model takes on the form:

The following priors were selected for the model:

The significant covariates for this model are Distance_to_Shore,
Date_Year, TSA and Cyclone_Frequency.

This model had good coverage with mean absolute deviation of 0.1018. On
the right, the posterior predictive checks on the training data closely
resemble the observed data.

# Model Results

The beta regression model proved to be a better fitting model than the
multiple linear regression model after comparing the Bayesian p-values
from the posterior predictive checks for the lower quantile, median, and
upper quantile.

The p-values were all 0 and 0.988, 0.201, and 0.122 for the quantile
checks for MLR and beta, respectively.

The MLR model had better p-values for mean and standard deviation, but
this was disregarded due to the presence of these parameters in the
model.

Using the parameters from final beta regression model and the out of
sample test data, the posterior predictive distribution was generated
from 8000 MCMC simulations. The upper plot on the right shows each of
these posterior predictive distribution samples compared to the true
distribution of the test data.

The final beta regression model had coverage of 94.1% as seen in the
lower plot on the right of the 95% credible interval for each of the 596
test data points compared to the actual value.

# Conclusions & Further Questions

Conclusions:

Thermal stress anomaly (TSA) and year (Date_Year) were the most
significant effects on coral bleaching.

Holding all other predictors constant, increasing thermal stress
anomaly, year, or distance to shore resulted in higher percent
bleaching.

There is a significant effect of cyclone frequency on percent bleaching
which could be due to large storms cooling surface water temperatures.

Further Exploration:

Our posterior appeared to be shifted to the right because the data are
zero-inflated, so a hierarchical model could have been another pathway
for a Bayesian analysis.

With more time and computing power, it would be interesting to fit a
model for the entire aggregated data set which contains over 40,000
observations from across the globe, however, this would entail much more
data cleaning beforehand and the inclusion of spatial effects.
