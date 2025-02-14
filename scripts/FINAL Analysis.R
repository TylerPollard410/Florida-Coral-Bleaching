## ST54- Final Project
# Florida Coral Bleaching
# Tyler Pollard

library(knitr)
library(data.table)
library(MASS)
library(bestNormalize)
library(plyr)
library(stringr)
library(sf)
library(spData)
library(tictoc)
library(cowplot)
library(GGally)
library(patchwork)
library(fitdistrplus)
library(caret)
library(splines)
library(mgcv)
library(DescTools)
library(tseries)
library(forecast)
library(car)
library(bayesplot)
library(BayesFactor)
library(rstanarm)
library(tidybayes)
library(loo)
library(brms)
library(bayesplot)
library(performance)
library(gt)
library(gtsummary)
library(tidyverse)

# Clean data for all Models----
## Original Data ----
bleaching_data <- fread("_data/global_bleaching_environmental.csv", 
                        na.strings = c("", "NA", "nd"))

## Filter Data ----
## Filter to only complete Percent Bleaching and FRRP data set 
## Remove unwanted variables like temperature statistic columns
## and arrange by date for viewing purposes
filteredData <- bleaching_data |>
  filter(!is.na(Percent_Bleaching)) |>
  filter(Data_Source == "FRRP") |>
  distinct(Site_ID, Sample_ID, .keep_all = TRUE) 

## Remove unwanted variables like temperature statistic columns
## and arrange by date for viewing purposes
filteredData <- filteredData |>
  select(
    Site_ID,
    # For ordering
    Date,
    Date_Year,
    Date_Month,
    Date_Day,
    City_Town_Name,
    # Covariates
    Lat = Latitude_Degrees,
    Lon = Longitude_Degrees,
    Distance_to_Shore,
    Exposure,
    Turbidity,
    Cyclone_Frequency,
    Depth_m,
    ClimSST,
    SSTA,
    SSTA_DHW,
    TSA,
    TSA_DHW,
    Windspeed,
    # Response
    PercentBleaching = Percent_Bleaching
  ) |>
  arrange(Date)

## Remove rows with missing predictors values
bleachingData <- filteredData |>
  mutate(
    PercentBleaching = PercentBleaching/100,
    PercentBleachingBounded = case_when(
      PercentBleaching == 0 ~ 0.0001,
      PercentBleaching == 1 ~ 0.9999,
      .default = PercentBleaching
    ),
    PercentBleachingLow = case_when(
      PercentBleaching == 1 ~ 0.9999,
      .default = PercentBleaching
    )
  )

write_csv(bleachingData, "_data/FloridaCoralBleachingData.csv")

# Plot Data ------
## Percent Bleaching Distribution ----
ggplot(data = bleachingData) +
  geom_histogram(
    aes(x = PercentBleaching, after_stat(density)),
    color = "#99c7c7", fill = "#bcdcdc",
    bins = 100) +
  geom_density(
    aes(x = PercentBleaching),
    color = "#007C7C", 
    linewidth = 1) +
  scale_y_continuous(expand = expansion(mult = c(0,0.05))) +
  scale_x_continuous(breaks = seq(0,1,0.1), labels = scales::label_percent()) +
  labs(title = "Density Plot of Percent Bleaching from 2,394 Coral Reef Samples",
       subtitle = "Data was Collected by the Florida Reef Resilience Program from 2006 to 2016",
       x = "Percent Bleaching",
       y = "Density") +
  theme_bw() +
  theme(
    plot.title = element_text(size = 16, face = "bold"),
    plot.subtitle = element_text(size = 12)
  )

## Map ----
county_coordinates <- map_data("county") 
ggplot() +
  geom_map(
    data = county_coordinates, map = county_coordinates,
    aes(x = long, y = lat, map_id = region)
  ) +
  geom_point(
    data = bleachingData,
    aes(x = Lon, y = Lat,
        color = PercentBleaching)
  ) +
  xlim(c(-84,-79)) +
  ylim(c(24, 28)) +
  facet_wrap(vars(Date_Year)) +
  scale_color_continuous(low = "green", high = "red") +
  theme_bw()

maxData <- bleachingData |> 
  group_by(Date_Year) |>
  summarise(
    across(where(is.numeric),
           ~max(.x))
  )

### Spatial Correlation ----
library(spdep)
library(gstat)
library(sp)

#### Morans ----
# Convert to Spatial Data
coral_sf <- st_as_sf(bleachingData, coords = c("Lon", "Lat"), crs = 4326)  # WGS84 CRS

# Create a spatial neighbors list using K-Nearest Neighbors
coords <- as.matrix(bleachingData[, c("Lon", "Lat")])
nb <- knn2nb(knearneigh(coords, k = 6))  # Using 6 nearest neighbors
lw <- nb2listw(nb, style = "W")  # Convert neighbors to list weights

# Compute Moran's I
moran_test <- moran.test(bleachingData$PercentBleaching, lw)

# Print Moran's I results
print(moran_test)

#### Variogram ----
# Convert to spatial object
coordinates(bleachingData) <- ~Lon+Lat

# Compute the empirical variogram
vario <- variogram(PercentBleaching ~ 1, data = bleachingData)

# Fit a variogram model
vario_model <- fit.variogram(vario, vgm("Sph"))

# Plot the variogram
plot(vario, model = vario_model, main = "Spatial Variogram of Coral Bleaching")

## ggpairs ----
### Temperature ----
tempData <- bleachingData |> select(
  ClimSST,
  SSTA,
  SSTA_DHW,
  TSA,
  TSA_DHW,
  PercentBleaching
)
ggpairs(tempData)

### Other covariates ----
otherData <- bleachingData |> select(
  Distance_to_Shore,
  Exposure,
  Turbidity,
  Cyclone_Frequency,
  Depth_m,
  Windspeed,
  PercentBleaching
)
ggpairs(otherData)

## Temporal Autocorrelation ----
PlotACF(bleachingData$PercentBleaching)

## Dickey fuller
adf.test(bleachingData$PercentBleaching)
autocorr.plot(bleachingData$PercentBleaching, ask = FALSE)
auto.arima(bleachingData$PercentBleaching, 
           seasonal = TRUE, stationary = TRUE)

# Pre-Process Data ----
bleachingData <- bleachingData |>
  mutate(
    Date_Year2 = Date_Year,
    Lat2 = Lat,
    Lon2 = Lon,
    .after = Lon
  )
preProc1 <- preProcess(
  bleachingData |>
    select(
      Date_Year2,
      Lat2,
      Lon2,
      Distance_to_Shore,
      Turbidity,
      Cyclone_Frequency,
      Depth_m,
      Windspeed,
      ClimSST,
      SSTA,
      SSTA_DHW,
      TSA,
      TSA_DHW
    ),
  method = c("center", "scale", "corr")
)
preProc1

procData <- predict(preProc1, bleachingData)

# MODELS =============================================
# Normal -------
formulaBleaching_normal <- 
  bf(PercentBleaching ~ 
       Date_Year2 +
       Lat2 +
       Lon2 +
       Distance_to_Shore +
       Exposure +
       Turbidity +
       Cyclone_Frequency +
       Depth_m +
       Windspeed +
       ClimSST +
       SSTA +
       #SSTA_DHW +
       TSA +
       TSA_DHW +
       (1 | City_Town_Name)
  ) + brmsfamily(family = "gaussian", link = "identity")

default_prior(formulaBleaching_normal, data = procData)

# priorsVMAX <- c(
#   #prior(horseshoe(1), class = "b")
#   prior(normal(0, 5), class = "b"),
#   prior(inv_gamma(0.1, 0.1), class = "sigma")
#   #prior(inv_gamma(0.1, 0.1), class = "shape"),
#   #prior(inv_gamma(0.1, 0.1), class = "sd")
# )

## Fit brms ----
iters <- 4000
burn <- 2000
chains <- 2
sims <- (iters-burn)*chains

#system.time(
normalFit <- brm(
  formulaBleaching_normal,
  data = procData,
  # prior = c(
  #   #prior(horseshoe(1), class = "b")
  #   prior(normal(0, 5), class = "b"),
  #   prior(inv_gamma(0.1, 0.1), class = "sigma"),
  #   #prior(inv_gamma(0.1, 0.1), class = "b", dpar = "sigma", lb = 0),
  #   #prior(inv_gamma(0.1, 0.1), class = "shape"),
  #   prior(inv_gamma(0.1, 0.1), class = "sd")
  # ),
  save_pars = save_pars(all = TRUE), 
  chains = chains,
  iter = iters,
  cores = parallel::detectCores(),
  seed = 52,
  warmup = burn,
  #init = 0,
  normalize = FALSE,
  control = list(adapt_delta = 0.95),
  backend = "cmdstanr"
)
#)

#save(normalFit, file = "_data/normalFit.RData")

## Diagnostics ----
fit <- 1
assign(paste0("normalFit", fit), normalFit)
#save(normalFitFINAL, file = "_data/normalFitFINAL.RData")

plot(normalFit, ask = FALSE)
#prior_summary(normalFit)

print(normalFit, digits = 4)

# waicList <- list(
#   waic(normalFit),
#   waic(normalRandFit),
#   waic(gammaFit),
#   waic(gammaRandFit)
# )
#waic <- waic(normalFit)
#attributes(waic)$model_name <- paste0("normalFit", fit)
#waicList[[paste0("fit", 4)]] <- waic4

### Compare Candidate Models ----
# waicList
# 
# waicListComp <- loo_compare(
#   waicList
# )
# waicListComp <- waicListComp |>
#   data.frame() |>
#   rownames_to_column(var = "Model")
# 
# save(waicList, waicListComp, file = "_data/waicComps.RData")



### Multicollinearity ----
check_collinearity(normalFit)

### Check heteroskedasity ----
check_heteroscedasticity(normalFit)

### Fixed Effects ----
normalFitfixedEff <- fixef(normalFit)
normalFitfixedEff <- data.frame(normalFitfixedEff) |>
  mutate(
    p_val = dnorm(Estimate/Est.Error)
  ) |>
  mutate(
    across(everything(), function(x){round(x, 4)})
  ) |>
  mutate(
    Sig = ifelse(p_val < 0.01, "***",
                 ifelse(p_val < 0.05, "**",
                        ifelse(p_val < 0.1, "*", "")))
  )
print(normalFitfixedEff, digits = 4)
normalFitfixedSigEff <- normalFitfixedEff |> filter(p_val < 0.2)
print(normalFitfixedSigEff)

pp_check(normalFit, ndraws = 100)

### Hypothesis Tests 
# posterior_summary(normalFit)
# 
# xVars <- str_subset(variables(normalFit), pattern = "b_")
# hypothesis(normalFit, paste(xVars, "= 0"), 
#            class = NULL, 
#            alpha = 0.1)
# 
# hypothesis(normalFit, "sHWRF_1 = 0", class = "bs")
# hypID <- hypothesis(normalFit, 
#                     "Intercept = 0", 
#                     group = "StormID", 
#                     scope = "coef")
# plot(hypID)

#variance_decomposition(normalFit)
VarCorr(normalFit)

### Residuals ----
normalFitResiduals <- 
  residuals(
    normalFit,
    method = "posterior_predict",
    re_formula = NULL,
    robust = FALSE,
    probs = c(0.025, 0.975)) |>
  data.frame()
mean(abs(normalFitResiduals$Estimate))

# predResiduals <- 
#   residuals(
#     normalFit, 
#     #newdata = StormdataTestArcsinh,
#     newdata = StormdataTestYeo,
#     #newdata = StormdataTest2,
#     method = "posterior_predict",
#     allow_new_levels = TRUE,
#     re_formula = NULL,
#     robust = FALSE,
#     probs = c(0.025, 0.975)) |>
#   data.frame()
# mean(abs(predResiduals$Estimate))

## Posteriors ----
#normalFit <- Fit8
### Training ----
normalFitfinalFit <- posterior_predict(normalFit)
# normalFitfinalResiduals <- t(StormdataTrain3$VMAX - t(normalFitfinalFit))
# normalFitfinalResidualsMean <- colMeans(normalFitfinalResiduals)
normalFitfinalFitMean <- colMeans(normalFitfinalFit)
normalFitfinalFitMed <- apply(normalFitfinalFit, 2, function(x){quantile(x, 0.5)})
normalFitfinalFitLCB <- apply(normalFitfinalFit, 2, function(x){quantile(x, 0.025)})
normalFitfinalFitUCB <- apply(normalFitfinalFit, 2, function(x){quantile(x, 0.975)})

# logNormal -------
formulaBleaching_logNormal <- 
  bf(PercentBleachingBounded ~ 
       Date_Year2 +
       Lat2 +
       Lon2 +
       Distance_to_Shore +
       Exposure +
       Turbidity +
       Cyclone_Frequency +
       Depth_m +
       Windspeed +
       ClimSST +
       SSTA +
       #SSTA_DHW +
       TSA +
       TSA_DHW +
       (1 | City_Town_Name)
  ) + brmsfamily(family = "lognormal", link = "log")

default_prior(formulaBleaching_logNormal, data = procData)

# priorsVMAX <- c(
#   #prior(horseshoe(1), class = "b")
#   prior(logNormal(0, 5), class = "b"),
#   prior(inv_gamma(0.1, 0.1), class = "sigma")
#   #prior(inv_gamma(0.1, 0.1), class = "shape"),
#   #prior(inv_gamma(0.1, 0.1), class = "sd")
# )

## Fit brms ----
iters <- 4000
burn <- 2000
chains <- 2
sims <- (iters-burn)*chains

#system.time(
logNormalFit <- brm(
  formulaBleaching_logNormal,
  data = procData,
  # prior = c(
  #   #prior(horseshoe(1), class = "b")
  #   prior(logNormal(0, 5), class = "b"),
  #   prior(inv_gamma(0.1, 0.1), class = "sigma"),
  #   #prior(inv_gamma(0.1, 0.1), class = "b", dpar = "sigma", lb = 0),
  #   #prior(inv_gamma(0.1, 0.1), class = "shape"),
  #   prior(inv_gamma(0.1, 0.1), class = "sd")
  # ),
  save_pars = save_pars(all = TRUE), 
  chains = chains,
  iter = iters,
  cores = parallel::detectCores(),
  seed = 52,
  warmup = burn,
  #init = 0,
  normalize = FALSE,
  control = list(adapt_delta = 0.95),
  backend = "cmdstanr"
)
#)

#save(logNormalFit, file = "_data/logNormalFit.RData")

## Diagnostics ----
fit <- 1
assign(paste0("logNormalFit", fit), logNormalFit)
#save(logNormalFitFINAL, file = "_data/logNormalFitFINAL.RData")

plot(logNormalFit, ask = FALSE)
#prior_summary(logNormalFit)

print(logNormalFit, digits = 4)

# waicList <- list(
#   waic(logNormalFit),
#   waic(logNormalRandFit),
#   waic(gammaFit),
#   waic(gammaRandFit)
# )
#waic <- waic(logNormalFit)
#attributes(waic)$model_name <- paste0("logNormalFit", fit)
#waicList[[paste0("fit", 4)]] <- waic4

### Compare Candidate Models ----
# waicList
# 
# waicListComp <- loo_compare(
#   waicList
# )
# waicListComp <- waicListComp |>
#   data.frame() |>
#   rownames_to_column(var = "Model")
# 
# save(waicList, waicListComp, file = "_data/waicComps.RData")



### Multicollinearity ----
check_collinearity(logNormalFit)

### Check heteroskedasity ----
check_heteroscedasticity(logNormalFit)

### Fixed Effects ----
logNormalFitfixedEff <- fixef(logNormalFit)
logNormalFitfixedEff <- data.frame(logNormalFitfixedEff) |>
  mutate(
    p_val = dnorm(Estimate/Est.Error)
  ) |>
  mutate(
    across(everything(), function(x){round(x, 4)})
  ) |>
  mutate(
    Sig = ifelse(p_val < 0.01, "***",
                 ifelse(p_val < 0.05, "**",
                        ifelse(p_val < 0.1, "*", "")))
  )
print(logNormalFitfixedEff, digits = 4)
logNormalFitfixedSigEff <- logNormalFitfixedEff |> filter(p_val < 0.2)
print(logNormalFitfixedSigEff)

pp_check(logNormalFit, ndraws = 100)

### Hypothesis Tests 
# posterior_summary(logNormalFit)
# 
# xVars <- str_subset(variables(logNormalFit), pattern = "b_")
# hypothesis(logNormalFit, paste(xVars, "= 0"), 
#            class = NULL, 
#            alpha = 0.1)
# 
# hypothesis(logNormalFit, "sHWRF_1 = 0", class = "bs")
# hypID <- hypothesis(logNormalFit, 
#                     "Intercept = 0", 
#                     group = "StormID", 
#                     scope = "coef")
# plot(hypID)

#variance_decomposition(logNormalFit)
VarCorr(logNormalFit)

### Residuals ----
logNormalFitResiduals <- 
  residuals(
    logNormalFit,
    method = "posterior_predict",
    re_formula = NULL,
    robust = FALSE,
    probs = c(0.025, 0.975)) |>
  data.frame()
mean(abs(logNormalFitResiduals$Estimate))

# predResiduals <- 
#   residuals(
#     logNormalFit, 
#     #newdata = StormdataTestArcsinh,
#     newdata = StormdataTestYeo,
#     #newdata = StormdataTest2,
#     method = "posterior_predict",
#     allow_new_levels = TRUE,
#     re_formula = NULL,
#     robust = FALSE,
#     probs = c(0.025, 0.975)) |>
#   data.frame()
# mean(abs(predResiduals$Estimate))

## Posteriors ----
#logNormalFit <- Fit8
### Training ----
logNormalFitfinalFit <- posterior_predict(logNormalFit)
# logNormalFitfinalResiduals <- t(StormdataTrain3$VMAX - t(logNormalFitfinalFit))
# logNormalFitfinalResidualsMean <- colMeans(logNormalFitfinalResiduals)
logNormalFitfinalFitMean <- colMeans(logNormalFitfinalFit)
logNormalFitfinalFitMed <- apply(logNormalFitfinalFit, 2, function(x){quantile(x, 0.5)})
logNormalFitfinalFitLCB <- apply(logNormalFitfinalFit, 2, function(x){quantile(x, 0.025)})
logNormalFitfinalFitUCB <- apply(logNormalFitfinalFit, 2, function(x){quantile(x, 0.975)})


# Beta -------
formulaBleaching_beta <- 
  bf(PercentBleachingBounded ~ 
       Date_Year2 +
       Lat2 +
       Lon2 +
       Distance_to_Shore +
       Exposure +
       Turbidity +
       Cyclone_Frequency +
       Depth_m +
       Windspeed +
       ClimSST +
       SSTA +
       #SSTA_DHW +
       TSA +
       TSA_DHW +
       (1 | City_Town_Name)
  ) + brmsfamily(family = "Beta", link = "logit")

default_prior(formulaBleaching_beta, data = procData)

# priorsVMAX <- c(
#   #prior(horseshoe(1), class = "b")
#   prior(beta(0, 5), class = "b"),
#   prior(inv_gamma(0.1, 0.1), class = "sigma")
#   #prior(inv_gamma(0.1, 0.1), class = "shape"),
#   #prior(inv_gamma(0.1, 0.1), class = "sd")
# )

## Fit brms ----
iters <- 4000
burn <- 2000
chains <- 2
sims <- (iters-burn)*chains

#system.time(
betaFit <- brm(
  formulaBleaching_beta,
  data = procData,
  # prior = c(
  #   #prior(horseshoe(1), class = "b")
  #   prior(beta(0, 5), class = "b"),
  #   prior(inv_gamma(0.1, 0.1), class = "sigma"),
  #   #prior(inv_gamma(0.1, 0.1), class = "b", dpar = "sigma", lb = 0),
  #   #prior(inv_gamma(0.1, 0.1), class = "shape"),
  #   prior(inv_gamma(0.1, 0.1), class = "sd")
  # ),
  save_pars = save_pars(all = TRUE), 
  chains = chains,
  iter = iters,
  cores = parallel::detectCores(),
  seed = 52,
  warmup = burn,
  #init = 0,
  normalize = FALSE,
  control = list(adapt_delta = 0.95),
  backend = "cmdstanr"
)
#)

#save(betaFit, file = "_data/betaFit.RData")

## Diagnostics ----
fit <- 1
assign(paste0("betaFit", fit), betaFit)
#save(betaFitFINAL, file = "_data/betaFitFINAL.RData")

plot(betaFit, ask = FALSE)
#prior_summary(betaFit)

print(betaFit, digits = 4)

# waicList <- list(
#   waic(betaFit),
#   waic(betaRandFit),
#   waic(gammaFit),
#   waic(gammaRandFit)
# )
#waic <- waic(betaFit)
#attributes(waic)$model_name <- paste0("betaFit", fit)
#waicList[[paste0("fit", 4)]] <- waic4

### Compare Candidate Models ----
# waicList
# 
# waicListComp <- loo_compare(
#   waicList
# )
# waicListComp <- waicListComp |>
#   data.frame() |>
#   rownames_to_column(var = "Model")
# 
# save(waicList, waicListComp, file = "_data/waicComps.RData")



### Multicollinearity ----
check_collinearity(betaFit)

### Check heteroskedasity ----
check_heteroscedasticity(betaFit)

### Fixed Effects ----
betaFitfixedEff <- fixef(betaFit)
betaFitfixedEff <- data.frame(betaFitfixedEff) |>
  mutate(
    p_val = dnorm(Estimate/Est.Error)
  ) |>
  mutate(
    across(everything(), function(x){round(x, 4)})
  ) |>
  mutate(
    Sig = ifelse(p_val < 0.01, "***",
                 ifelse(p_val < 0.05, "**",
                        ifelse(p_val < 0.1, "*", "")))
  )
print(betaFitfixedEff, digits = 4)
betaFitfixedSigEff <- betaFitfixedEff |> filter(p_val < 0.2)
print(betaFitfixedSigEff)

pp_check(betaFit, ndraws = 100)

### Hypothesis Tests 
# posterior_summary(betaFit)
# 
# xVars <- str_subset(variables(betaFit), pattern = "b_")
# hypothesis(betaFit, paste(xVars, "= 0"), 
#            class = NULL, 
#            alpha = 0.1)
# 
# hypothesis(betaFit, "sHWRF_1 = 0", class = "bs")
# hypID <- hypothesis(betaFit, 
#                     "Intercept = 0", 
#                     group = "StormID", 
#                     scope = "coef")
# plot(hypID)

#variance_decomposition(betaFit)
VarCorr(betaFit)

### Residuals ----
betaFitResiduals <- 
  residuals(
    betaFit,
    method = "posterior_predict",
    re_formula = NULL,
    robust = FALSE,
    probs = c(0.025, 0.975)) |>
  data.frame()
mean(abs(betaFitResiduals$Estimate))

# predResiduals <- 
#   residuals(
#     betaFit, 
#     #newdata = StormdataTestArcsinh,
#     newdata = StormdataTestYeo,
#     #newdata = StormdataTest2,
#     method = "posterior_predict",
#     allow_new_levels = TRUE,
#     re_formula = NULL,
#     robust = FALSE,
#     probs = c(0.025, 0.975)) |>
#   data.frame()
# mean(abs(predResiduals$Estimate))

## Posteriors ----
#betaFit <- Fit8
### Training ----
betaFitfinalFit <- posterior_predict(betaFit)
# betaFitfinalResiduals <- t(StormdataTrain3$VMAX - t(betaFitfinalFit))
# betaFitfinalResidualsMean <- colMeans(betaFitfinalResiduals)
betaFitfinalFitMean <- colMeans(betaFitfinalFit)
betaFitfinalFitMed <- apply(betaFitfinalFit, 2, function(x){quantile(x, 0.5)})
betaFitfinalFitLCB <- apply(betaFitfinalFit, 2, function(x){quantile(x, 0.025)})
betaFitfinalFitUCB <- apply(betaFitfinalFit, 2, function(x){quantile(x, 0.975)})


# ziBeta -------
formulaBleaching_ziBeta <- 
  bf(PercentBleachingLow ~ 
       Date_Year2 +
       Lat2 +
       Lon2 +
       Distance_to_Shore +
       Exposure +
       Turbidity +
       Cyclone_Frequency +
       Depth_m +
       Windspeed +
       ClimSST +
       SSTA +
       #SSTA_DHW +
       TSA +
       TSA_DHW +
       (1 | City_Town_Name)
  ) + brmsfamily(family = "zero_inflated_beta", link = "logit")

default_prior(formulaBleaching_ziBeta, data = procData)

# priorsVMAX <- c(
#   #prior(horseshoe(1), class = "b")
#   prior(ziBeta(0, 5), class = "b"),
#   prior(inv_gamma(0.1, 0.1), class = "sigma")
#   #prior(inv_gamma(0.1, 0.1), class = "shape"),
#   #prior(inv_gamma(0.1, 0.1), class = "sd")
# )

## Fit brms ----
iters <- 4000
burn <- 2000
chains <- 2
sims <- (iters-burn)*chains

#system.time(
ziBetaFit <- brm(
  formulaBleaching_ziBeta,
  data = procData,
  # prior = c(
  #   #prior(horseshoe(1), class = "b")
  #   prior(ziBeta(0, 5), class = "b"),
  #   prior(inv_gamma(0.1, 0.1), class = "sigma"),
  #   #prior(inv_gamma(0.1, 0.1), class = "b", dpar = "sigma", lb = 0),
  #   #prior(inv_gamma(0.1, 0.1), class = "shape"),
  #   prior(inv_gamma(0.1, 0.1), class = "sd")
  # ),
  save_pars = save_pars(all = TRUE), 
  chains = chains,
  iter = iters,
  cores = parallel::detectCores(),
  seed = 52,
  warmup = burn,
  #init = 0,
  normalize = FALSE,
  control = list(adapt_delta = 0.95),
  backend = "cmdstanr"
)
#)

#save(ziBetaFit, file = "_data/ziBetaFit.RData")

## Diagnostics ----
fit <- 1
assign(paste0("ziBetaFit", fit), ziBetaFit)
#save(ziBetaFitFINAL, file = "_data/ziBetaFitFINAL.RData")

plot(ziBetaFit, ask = FALSE)
#prior_summary(ziBetaFit)

print(ziBetaFit, digits = 4)

# waicList <- list(
#   waic(ziBetaFit),
#   waic(ziBetaRandFit),
#   waic(gammaFit),
#   waic(gammaRandFit)
# )
#waic <- waic(ziBetaFit)
#attributes(waic)$model_name <- paste0("ziBetaFit", fit)
#waicList[[paste0("fit", 4)]] <- waic4

### Compare Candidate Models ----
# waicList
# 
# waicListComp <- loo_compare(
#   waicList
# )
# waicListComp <- waicListComp |>
#   data.frame() |>
#   rownames_to_column(var = "Model")
# 
# save(waicList, waicListComp, file = "_data/waicComps.RData")



### Multicollinearity ----
check_collinearity(ziBetaFit)

### Check heteroskedasity ----
check_heteroscedasticity(ziBetaFit)

### Fixed Effects ----
ziBetaFitfixedEff <- fixef(ziBetaFit)
ziBetaFitfixedEff <- data.frame(ziBetaFitfixedEff) |>
  mutate(
    p_val = dnorm(Estimate/Est.Error)
  ) |>
  mutate(
    across(everything(), function(x){round(x, 4)})
  ) |>
  mutate(
    Sig = ifelse(p_val < 0.01, "***",
                 ifelse(p_val < 0.05, "**",
                        ifelse(p_val < 0.1, "*", "")))
  )
print(ziBetaFitfixedEff, digits = 4)
ziBetaFitfixedSigEff <- ziBetaFitfixedEff |> filter(p_val < 0.2)
print(ziBetaFitfixedSigEff)

pp_check(ziBetaFit, ndraws = 100)

### Hypothesis Tests 
# posterior_summary(ziBetaFit)
# 
# xVars <- str_subset(variables(ziBetaFit), pattern = "b_")
# hypothesis(ziBetaFit, paste(xVars, "= 0"), 
#            class = NULL, 
#            alpha = 0.1)
# 
# hypothesis(ziBetaFit, "sHWRF_1 = 0", class = "bs")
# hypID <- hypothesis(ziBetaFit, 
#                     "Intercept = 0", 
#                     group = "StormID", 
#                     scope = "coef")
# plot(hypID)

#variance_decomposition(ziBetaFit)
VarCorr(ziBetaFit)

### Residuals ----
ziBetaFitResiduals <- 
  residuals(
    ziBetaFit,
    method = "posterior_predict",
    re_formula = NULL,
    robust = FALSE,
    probs = c(0.025, 0.975)) |>
  data.frame()
mean(abs(ziBetaFitResiduals$Estimate))

# predResiduals <- 
#   residuals(
#     ziBetaFit, 
#     #newdata = StormdataTestArcsinh,
#     newdata = StormdataTestYeo,
#     #newdata = StormdataTest2,
#     method = "posterior_predict",
#     allow_new_levels = TRUE,
#     re_formula = NULL,
#     robust = FALSE,
#     probs = c(0.025, 0.975)) |>
#   data.frame()
# mean(abs(predResiduals$Estimate))

## Posteriors ----
#ziBetaFit <- Fit8
### Training ----
ziBetaFitfinalFit <- posterior_predict(ziBetaFit)
# ziBetaFitfinalResiduals <- t(StormdataTrain3$VMAX - t(ziBetaFitfinalFit))
# ziBetaFitfinalResidualsMean <- colMeans(ziBetaFitfinalResiduals)
ziBetaFitfinalFitMean <- colMeans(ziBetaFitfinalFit)
ziBetaFitfinalFitMed <- apply(ziBetaFitfinalFit, 2, function(x){quantile(x, 0.5)})
ziBetaFitfinalFitLCB <- apply(ziBetaFitfinalFit, 2, function(x){quantile(x, 0.025)})
ziBetaFitfinalFitUCB <- apply(ziBetaFitfinalFit, 2, function(x){quantile(x, 0.975)})


# zoiBeta -------
formulaBleaching_zoiBeta <- 
  bf(PercentBleaching ~ 
       Date_Year2 +
       Lat2 +
       Lon2 +
       Distance_to_Shore +
       Exposure +
       Turbidity +
       Cyclone_Frequency +
       Depth_m +
       Windspeed +
       ClimSST +
       SSTA +
       #SSTA_DHW +
       TSA +
       TSA_DHW +
       (1 | City_Town_Name)
  ) + brmsfamily(family = "zero_one_inflated_beta", link = "logit")

default_prior(formulaBleaching_zoiBeta, data = procData)

# priorsVMAX <- c(
#   #prior(horseshoe(1), class = "b")
#   prior(zoiBeta(0, 5), class = "b"),
#   prior(inv_gamma(0.1, 0.1), class = "sigma")
#   #prior(inv_gamma(0.1, 0.1), class = "shape"),
#   #prior(inv_gamma(0.1, 0.1), class = "sd")
# )

## Fit brms ----
iters <- 4000
burn <- 2000
chains <- 2
sims <- (iters-burn)*chains

#system.time(
zoiBetaFit <- brm(
  formulaBleaching_zoiBeta,
  data = procData,
  # prior = c(
  #   #prior(horseshoe(1), class = "b")
  #   prior(zoiBeta(0, 5), class = "b"),
  #   prior(inv_gamma(0.1, 0.1), class = "sigma"),
  #   #prior(inv_gamma(0.1, 0.1), class = "b", dpar = "sigma", lb = 0),
  #   #prior(inv_gamma(0.1, 0.1), class = "shape"),
  #   prior(inv_gamma(0.1, 0.1), class = "sd")
  # ),
  save_pars = save_pars(all = TRUE), 
  chains = chains,
  iter = iters,
  cores = parallel::detectCores(),
  seed = 52,
  warmup = burn,
  #init = 0,
  normalize = FALSE,
  control = list(adapt_delta = 0.95),
  backend = "cmdstanr"
)
#)

#save(zoiBetaFit, file = "_data/zoiBetaFit.RData")

## Diagnostics ----
fit <- 1
assign(paste0("zoiBetaFit", fit), zoiBetaFit)
#save(zoiBetaFitFINAL, file = "_data/zoiBetaFitFINAL.RData")

plot(zoiBetaFit, ask = FALSE)
#prior_summary(zoiBetaFit)

print(zoiBetaFit, digits = 4)
summary(zoiBetaFit)

# waicList <- list(
#   waic(zoiBetaFit),
#   waic(zoiBetaRandFit),
#   waic(gammaFit),
#   waic(gammaRandFit)
# )
#waic <- waic(zoiBetaFit)
#attributes(waic)$model_name <- paste0("zoiBetaFit", fit)
#waicList[[paste0("fit", 4)]] <- waic4

### Compare Candidate Models ----
# waicList
# 
# waicListComp <- loo_compare(
#   waicList
# )
# waicListComp <- waicListComp |>
#   data.frame() |>
#   rownames_to_column(var = "Model")
# 
# save(waicList, waicListComp, file = "_data/waicComps.RData")



### Multicollinearity ----
check_collinearity(zoiBetaFit)

### Check heteroskedasity ----
check_heteroscedasticity(zoiBetaFit)

### Fixed Effects ----
zoiBetaFitfixedEff <- fixef(zoiBetaFit)
zoiBetaFitfixedEff <- data.frame(zoiBetaFitfixedEff) |>
  mutate(
    p_val = dnorm(Estimate/Est.Error)
  ) |>
  mutate(
    across(everything(), function(x){round(x, 4)})
  ) |>
  mutate(
    Sig = ifelse(p_val < 0.01, "***",
                 ifelse(p_val < 0.05, "**",
                        ifelse(p_val < 0.1, "*", "")))
  )
print(zoiBetaFitfixedEff, digits = 4)
zoiBetaFitfixedSigEff <- zoiBetaFitfixedEff |> filter(p_val < 0.2)
print(zoiBetaFitfixedSigEff)

pp_check(zoiBetaFit, ndraws = 100)

### Hypothesis Tests 
# posterior_summary(zoiBetaFit)
# 
# xVars <- str_subset(variables(zoiBetaFit), pattern = "b_")
# hypothesis(zoiBetaFit, paste(xVars, "= 0"), 
#            class = NULL, 
#            alpha = 0.1)
# 
# hypothesis(zoiBetaFit, "sHWRF_1 = 0", class = "bs")
# hypID <- hypothesis(zoiBetaFit, 
#                     "Intercept = 0", 
#                     group = "StormID", 
#                     scope = "coef")
# plot(hypID)

#variance_decomposition(zoiBetaFit)
VarCorr(zoiBetaFit)

### Residuals ----
zoiBetaFitResiduals <- 
  residuals(
    zoiBetaFit,
    method = "posterior_predict",
    re_formula = NULL,
    robust = FALSE,
    probs = c(0.025, 0.975)) |>
  data.frame()
mean(abs(zoiBetaFitResiduals$Estimate))

# predResiduals <- 
#   residuals(
#     zoiBetaFit, 
#     #newdata = StormdataTestArcsinh,
#     newdata = StormdataTestYeo,
#     #newdata = StormdataTest2,
#     method = "posterior_predict",
#     allow_new_levels = TRUE,
#     re_formula = NULL,
#     robust = FALSE,
#     probs = c(0.025, 0.975)) |>
#   data.frame()
# mean(abs(predResiduals$Estimate))

## Posteriors ----
#zoiBetaFit <- Fit8
### Training ----
zoiBetaFitfinalFit <- posterior_predict(zoiBetaFit)
# zoiBetaFitfinalResiduals <- t(StormdataTrain3$VMAX - t(zoiBetaFitfinalFit))
# zoiBetaFitfinalResidualsMean <- colMeans(zoiBetaFitfinalResiduals)
zoiBetaFitfinalFitMean <- colMeans(zoiBetaFitfinalFit)
zoiBetaFitfinalFitMed <- apply(zoiBetaFitfinalFit, 2, function(x){quantile(x, 0.5)})
zoiBetaFitfinalFitLCB <- apply(zoiBetaFitfinalFit, 2, function(x){quantile(x, 0.025)})
zoiBetaFitfinalFitUCB <- apply(zoiBetaFitfinalFit, 2, function(x){quantile(x, 0.975)})



