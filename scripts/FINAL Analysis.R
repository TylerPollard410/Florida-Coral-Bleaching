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
library(plotly)
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
      PercentBleaching == 0 ~ 0.001,
      PercentBleaching == 1 ~ 0.999,
      .default = PercentBleaching
    ),
    PercentBleachingLow = case_when(
      PercentBleaching == 1 ~ 0.999,
      .default = PercentBleaching
    ),
    PercentBleaching100 = PercentBleachingBounded*100
  )

write_csv(bleachingData, "_data/FloridaCoralBleachingData.csv")

# Plot Data ------
## Percent Bleaching Distribution ----
percentBleachingDensPlot <- ggplot(data = bleachingData) +
  geom_histogram(
    aes(x = PercentBleaching, after_stat(density)),
    color = "#99c7c7", fill = "#bcdcdc") + #bins = 40
  geom_density(
    aes(x = PercentBleaching),# y = after_stat(count/(4*n)*100)),
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
percentBleachingDensPlot
ggplotly(percentBleachingDensPlot)

percentBleachingDensPlot <- ggplot(data = bleachingData) +
  geom_histogram(
    aes(x = PercentBleaching), # after_stat(density)),
    color = "#99c7c7", fill = "#bcdcdc",
    bins = 100) +
  geom_density(
    #aes(x = PercentBleaching, y = after_stat(count)),
    aes(x = PercentBleaching, y = after_stat(density)*nrow(bleachingData)/100),
    color = "#007C7C",
    linewidth = 1) +
  scale_y_continuous(expand = expansion(mult = c(0,0.05))) +
  scale_x_continuous(breaks = seq(0,1,0.1), labels = scales::label_percent()) +
  labs(title = "Density Plot of Percent Bleaching from 2,394 Coral Reef Samples",
       subtitle = "Data was Collected by the Florida Reef Resilience Program from 2006 to 2016",
       x = "Percent Bleaching",
       y = "Count") +
  theme_bw() +
  theme(
    plot.title = element_text(size = 16, face = "bold"),
    plot.subtitle = element_text(size = 12)
  )
percentBleachingDensPlot
ggplotly(percentBleachingDensPlot)

percentBleachingLogDensPlot <- ggplot(data = bleachingData) +
  geom_histogram(
    aes(x = log(PercentBleachingBounded)), # after_stat(density)),
    color = "#99c7c7", fill = "#bcdcdc",
    bins = 100) +
  geom_density(
    #aes(x = PercentBleaching, y = after_stat(count)),
    aes(x = log(PercentBleachingBounded), y = after_stat(density)*nrow(bleachingData)/100),
    color = "#007C7C",
    linewidth = 1) +
  scale_y_continuous(expand = expansion(mult = c(0,0.05))) +
  #scale_x_continuous(breaks = seq(0,1,0.1), labels = scales::label_percent()) +
  labs(title = "Density Plot of Log Percent Bleaching from 2,394 Coral Reef Samples",
       subtitle = "Data was Collected by the Florida Reef Resilience Program from 2006 to 2016",
       x = "Percent Bleaching",
       y = "Count") +
  theme_bw() +
  theme(
    plot.title = element_text(size = 16, face = "bold"),
    plot.subtitle = element_text(size = 12)
  )
percentBleachingLogDensPlot

### By Covariates ----
#### Categorical ----
##### Year ----
ggplot(data = bleachingData) +
  geom_boxplot(
    aes(x = factor(Date_Year), y = PercentBleaching, fill = City_Town_Name))+
  #color = "#99c7c7", fill = "#bcdcdc") +
  scale_y_continuous(breaks = seq(0,1,0.1), labels = scales::label_percent()) +
  scale_fill_discrete(name = "City Town Name", 
                      labels = c("Broward\nCounty",
                                 "Martin\nCounty",
                                 "Miami-Dade\nCounty",
                                 "Monroe\nCounty",
                                 "Palm Beach\nCounty")) +
  labs(title = "Boxplots of Percent Bleaching vs Year by City Town Name",
       #subtitle = "Data was Collected by the Florida Reef Resilience Program from 2006 to 2016",
       x = "Date Year",
       y = "Percent Bleaching") +
  theme_bw() +
  theme(
    plot.title = element_text(size = 16, face = "bold"),
    plot.subtitle = element_text(size = 12)
  )

ggplot(data = bleachingData) +
  geom_boxplot(
    aes(x = factor(Date_Month), y = PercentBleaching),
    color = "#99c7c7", fill = "#bcdcdc") +
  scale_y_continuous(breaks = seq(0,1,0.1), labels = scales::label_percent()) +
  labs(title = "Density Plot of Percent Bleaching from 2,394 Coral Reef Samples",
       subtitle = "Data was Collected by the Florida Reef Resilience Program from 2006 to 2016",
       x = "Percent Bleaching",
       y = "Density") +
  theme_bw() +
  theme(
    plot.title = element_text(size = 16, face = "bold"),
    plot.subtitle = element_text(size = 12)
  )

##### City_Town_Name ----
ggplot(data = bleachingData, aes(group = City_Town_Name)) +
  geom_histogram(
    aes(x = PercentBleaching, fill = City_Town_Name), # after_stat(density)),
    #color = "#99c7c7", fill = "#bcdcdc",
    bins = 100) +
  # geom_density(
  #   aes(x = PercentBleaching, color = factor(City_Town_Name)),
  #   linewidth = 1) +
  scale_y_continuous(expand = expansion(mult = c(0,0.05))) +
  scale_x_continuous(breaks = seq(0,1,0.1), labels = scales::label_percent()) +
  facet_wrap(vars(City_Town_Name)) +
  labs(title = "Density Plot of Percent Bleaching from 2,394 Coral Reef Samples",
       subtitle = "Data was Collected by the Florida Reef Resilience Program from 2006 to 2016",
       x = "Percent Bleaching",
       y = "Density") +
  theme_bw() +
  theme(
    plot.title = element_text(size = 16, face = "bold"),
    plot.subtitle = element_text(size = 12),
    legend.position = "bottom"
  )

ggplot(data = bleachingData) +
  geom_boxplot(
    aes(x = City_Town_Name, y = PercentBleaching),
    color = "#99c7c7", fill = "#bcdcdc") +
  scale_y_continuous(breaks = seq(0,1,0.1), labels = scales::label_percent()) +
  labs(title = "Density Plot of Percent Bleaching from 2,394 Coral Reef Samples",
       subtitle = "Data was Collected by the Florida Reef Resilience Program from 2006 to 2016",
       x = "Percent Bleaching",
       y = "Density") +
  theme_bw() +
  theme(
    plot.title = element_text(size = 16, face = "bold"),
    plot.subtitle = element_text(size = 12)
  )

##### Exposure ----
ggplot(data = bleachingData) +
  geom_boxplot(
    aes(x = Exposure, y = PercentBleaching),
    color = "#99c7c7", fill = "#bcdcdc") +
  scale_y_continuous(breaks = seq(0,1,0.1), labels = scales::label_percent()) +
  labs(title = "Density Plot of Percent Bleaching from 2,394 Coral Reef Samples",
       subtitle = "Data was Collected by the Florida Reef Resilience Program from 2006 to 2016",
       x = "Percent Bleaching",
       y = "Density") +
  theme_bw() +
  theme(
    plot.title = element_text(size = 16, face = "bold"),
    plot.subtitle = element_text(size = 12)
  )


#### Continuous ----
contVars <- c(
  "Date_Year",
  "Lat",
  "Lon",
  "Distance_to_Shore",
  "Turbidity",
  "Cyclone_Frequency",
  "Depth_m",
  "Windspeed",
  "ClimSST",
  "SSTA",
  "SSTA_DHW",
  "TSA",
  "TSA_DHW"
)
contVar <- contVars[7]
ggplot(data = bleachingData) +
  geom_point(
    aes(x = get(contVar), y = PercentBleaching),
    color = "#99c7c7") +
  geom_smooth(aes(x = get(contVar), y = PercentBleaching)) +
  scale_y_continuous(breaks = seq(0,1,0.1), labels = scales::label_percent()) +
  labs(title = paste0("Density Plot of Percent Bleaching vs ", contVar),
       subtitle = "Data was Collected by the Florida Reef Resilience Program from 2006 to 2016",
       y = "Percent Bleaching",
       x = contVar) +
  theme_bw() +
  theme(
    plot.title = element_text(size = 16, face = "bold"),
    plot.subtitle = element_text(size = 12)
  )

## Map Spatial Covariates ----
county_coordinates <- map_data("county") 
ggplot() +
  geom_map(
    data = county_coordinates, map = county_coordinates,
    aes(x = long, y = lat, map_id = region)
  ) +
  geom_point(
    data = bleachingData,
    aes(x = Lon, y = Lat,
        color = PercentBleaching),
    size = 0.25
  ) +
  xlim(c(-83.5,-79.5)) +
  ylim(c(24, 27.5)) +
  #facet_wrap(vars(Date_Year)) +
  scale_color_continuous(low = "green", high = "red") +
  theme_bw()

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
  xlim(c(-83.5,-79.5)) +
  ylim(c(24, 27.5)) +
  facet_wrap(vars(Date_Year)) +
  scale_color_continuous(low = "green", high = "red") +
  theme_bw()

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
  facet_wrap(vars(City_Town_Name)) +
  scale_color_continuous(low = "green", high = "red") +
  theme_bw()

### Spatial Correlation ----
# library(spdep)
# library(gstat)
# library(sp)

#### Morans ----
# Convert to Spatial Data
#coral_sf <- st_as_sf(bleachingData, coords = c("Lon", "Lat"), crs = 4326)  # WGS84 CRS

# Create a spatial neighbors list using K-Nearest Neighbors
#coords <- as.matrix(bleachingData[, c("Lon", "Lat")])
#nb <- knn2nb(knearneigh(coords, k = 6))  # Using 6 nearest neighbors
#lw <- nb2listw(nb, style = "W")  # Convert neighbors to list weights

# Compute Moran's I
#moran_test <- moran.test(bleachingData$PercentBleaching, lw)

# Print Moran's I results
#print(moran_test)

#### Variogram ----
# Convert to spatial object
#coordinates(bleachingData) <- ~Lon+Lat

# Compute the empirical variogram
#vario <- variogram(PercentBleaching ~ 1, data = bleachingData)

# Fit a variogram model
#vario_model <- fit.variogram(vario, vgm("Sph"))

# Plot the variogram
#plot(vario, model = vario_model, main = "Spatial Variogram of Coral Bleaching")

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
maxData <- bleachingData |> 
  group_by(Date_Year) |>
  summarise(
    across(where(is.numeric),
           ~max(.x))
  )


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

## Corr ----
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
procData1 <- predict(preProc1, bleachingData)

## YeoJohnson ----
preProc2 <- preProcess(
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
  method = c("center", "scale", "YeoJohnson")
)
preProc2
procData2 <- predict(preProc2, bleachingData)

## Arcsinh ----
procData3 <- bleachingData |>
  mutate(
    across(c(
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
    ~predict(arcsinh_x(.x, standardize = FALSE), newdata = .x)
    ))
preProc3 <- preProcess(
  procData3 |>
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
  method = c("center", "scale")
)
preProc3
procData3 <- predict(preProc3, procData3)

# MODELS =============================================
# Normal -------
formulaBleaching_normal <- 
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
  ) + brmsfamily(family = "student", link = "log")

default_prior(formulaBleaching_normal, data = procData)

# priorsVMAX <- c(
#   #prior(horseshoe(1), class = "b")
#   prior(normal(0, 5), class = "b"),
#   prior(inv_gamma(0.1, 0.1), class = "sigma")
#   #prior(inv_gamma(0.1, 0.1), class = "shape"),
#   #prior(inv_gamma(0.1, 0.1), class = "sd")
# )

## Fit brms ----
iters <- 2000
burn <- 1000
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
  normalize = TRUE,
  control = list(adapt_delta = 0.95),
  backend = "cmdstanr"
)
#)

#save(normalFit, file = "_data/normalFit.RData")

## Diagnostics ----
fitNormal <- 1
assign(paste0("studentFit", fitNormal), normalFit)
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

pp_check(normalFit, ndraws = 100) +
  scale_x_continuous(limits = c(-1,1))

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
#### MAE
normalFitResiduals <- 
  residuals(
    normalFit,
    method = "posterior_predict",
    re_formula = NULL,
    robust = FALSE,
    probs = c(0.025, 0.975)) |>
  data.frame()
mean(abs(normalFitResiduals$Estimate))

#### MAD
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
  ) + brmsfamily(family = "lognormal", link = "identity")

default_prior(formulaBleaching_logNormal, data = procData)

# priorsVMAX <- c(
#   #prior(horseshoe(1), class = "b")
#   prior(logNormal(0, 5), class = "b"),
#   prior(inv_gamma(0.1, 0.1), class = "sigma")
#   #prior(inv_gamma(0.1, 0.1), class = "shape"),
#   #prior(inv_gamma(0.1, 0.1), class = "sd")
# )

## Fit brms ----
iters <- 2000
burn <- 1000
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
  normalize = TRUE,
  control = list(adapt_delta = 0.95),
  backend = "cmdstanr"
)
#)

#save(logNormalFit, file = "_data/logNormalFit.RData")

## Diagnostics ----
fit <- 5
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

pp_check(logNormalFit, ndraws = 100) + 
  scale_x_continuous(limits = c(0,1))

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
#### MAE
logNormalFitResiduals <- 
  residuals(
    normalFit,
    method = "posterior_predict",
    re_formula = NULL,
    robust = FALSE,
    probs = c(0.025, 0.975)) |>
  data.frame()
mean(abs(logNormalFitResiduals$Estimate))

#### MAD
logNormalFitResiduals <- 
  residuals(
    normalFit,
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

# hurdleLogNormal -------
formulaBleaching_hurdleLogNormal <- 
  bf(PercentBleaching|trunc(ub = 1) ~ 
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
  ) + brmsfamily(family = "hurdle_logNormal", link = "identity")

default_prior(formulaBleaching_hurdleLogNormal, data = procData)

# priorsVMAX <- c(
#   #prior(horseshoe(1), class = "b")
#   prior(hurdleLogNormal(0, 5), class = "b"),
#   prior(inv_gamma(0.1, 0.1), class = "sigma")
#   #prior(inv_gamma(0.1, 0.1), class = "shape"),
#   #prior(inv_gamma(0.1, 0.1), class = "sd")
# )

## Fit brms ----
iters <- 2000
burn <- 1000
chains <- 2
sims <- (iters-burn)*chains

#system.time(
hurdleLogNormalFit <- brm(
  formulaBleaching_hurdleLogNormal,
  data = procData,
  # prior = c(
  #   #prior(horseshoe(1), class = "b")
  #   prior(hurdleLogNormal(0, 5), class = "b"),
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
  normalize = TRUE,
  control = list(adapt_delta = 0.95),
  backend = "cmdstanr"
)
#)

#save(hurdleLogNormalFit, file = "_data/hurdleLogNormalFit.RData")

## Diagnostics ----
fithurdleLogNormal <- 2
assign(paste0("hurdleLogNormalFit", fithurdleLogNormal), hurdleLogNormalFit)
#save(hurdleLogNormalFitFINAL, file = "_data/hurdleLogNormalFitFINAL.RData")

plot(hurdleLogNormalFit, ask = FALSE)
#prior_summary(hurdleLogNormalFit)

print(hurdleLogNormalFit, digits = 4)

# waicList <- list(
#   waic(hurdleLogNormalFit),
#   waic(hurdleLogNormalRandFit),
#   waic(gammaFit),
#   waic(gammaRandFit)
# )
#waic <- waic(hurdleLogNormalFit)
#attributes(waic)$model_name <- paste0("hurdleLogNormalFit", fit)
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
check_collinearity(hurdleLogNormalFit)

### Check heteroskedasity ----
check_heteroscedasticity(hurdleLogNormalFit)

### Fixed Effects ----
hurdleLogNormalFitfixedEff <- fixef(hurdleLogNormalFit)
hurdleLogNormalFitfixedEff <- data.frame(hurdleLogNormalFitfixedEff) |>
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
print(hurdleLogNormalFitfixedEff, digits = 4)
hurdleLogNormalFitfixedSigEff <- hurdleLogNormalFitfixedEff |> filter(p_val < 0.2)
print(hurdleLogNormalFitfixedSigEff)

hurdleLogNormalFitPPC <- pp_check(hurdleLogNormalFit, ndraws = 100) +
  scale_x_continuous(limits = c(0,1))

### Hypothesis Tests 
# posterior_summary(hurdleLogNormalFit)
# 
# xVars <- str_subset(variables(hurdleLogNormalFit), pattern = "b_")
# hypothesis(hurdleLogNormalFit, paste(xVars, "= 0"), 
#            class = NULL, 
#            alpha = 0.1)
# 
# hypothesis(hurdleLogNormalFit, "sHWRF_1 = 0", class = "bs")
# hypID <- hypothesis(hurdleLogNormalFit, 
#                     "Intercept = 0", 
#                     group = "StormID", 
#                     scope = "coef")
# plot(hypID)

#variance_decomposition(hurdleLogNormalFit)
VarCorr(hurdleLogNormalFit)

### Residuals ----
#### MAE
hurdleLogNormalFitResiduals <- 
  residuals(
    hurdleLogNormalFit,
    method = "posterior_predict",
    re_formula = NULL,
    robust = FALSE,
    probs = c(0.025, 0.975)) |>
  data.frame()
mean(abs(hurdleLogNormalFitResiduals$Estimate))

#### MAD
hurdleLogNormalFitResiduals <- 
  residuals(
    hurdleLogNormalFit,
    method = "posterior_predict",
    re_formula = NULL,
    robust = TRUE,
    probs = c(0.025, 0.975)) |>
  data.frame()
mean(abs(hurdleLogNormalFitResiduals$Estimate))

# predResiduals <- 
#   residuals(
#     hurdleLogNormalFit, 
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
#hurdleLogNormalFit <- Fit8
### Training ----
hurdleLogNormalFitfinalFit <- posterior_predict(hurdleLogNormalFit)
# hurdleLogNormalFitfinalResiduals <- t(StormdataTrain3$VMAX - t(hurdleLogNormalFitfinalFit))
# hurdleLogNormalFitfinalResidualsMean <- colMeans(hurdleLogNormalFitfinalResiduals)
hurdleLogNormalFitfinalFitMean <- colMeans(hurdleLogNormalFitfinalFit)
hurdleLogNormalFitfinalFitMed <- apply(hurdleLogNormalFitfinalFit, 2, function(x){quantile(x, 0.5)})
hurdleLogNormalFitfinalFitLCB <- apply(hurdleLogNormalFitfinalFit, 2, function(x){quantile(x, 0.025)})
hurdleLogNormalFitfinalFitUCB <- apply(hurdleLogNormalFitfinalFit, 2, function(x){quantile(x, 0.975)})


# Beta -------
formulaBleaching_beta <- 
  bf(PercentBleachingBounded ~ 
       #Date_Year2 +
       gp(Date_Year, by = City_Town_Name) +
       #gp(Date_Year) +
       #Lat2 +
       #Lon2 +
       t2(Lat, Lon) +
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
       TSA_DHW 
     #City_Town_Name
     #(1 | City_Town_Name)
  ) + brmsfamily(family = "Beta", link = "logit")

default_prior(formulaBleaching_beta, data = procData2)

# priorsVMAX <- c(# priorsVMAX <- c(bleachingData
#   #prior(horseshoe(1), class = "b")
#   prior(beta(0, 5), class = "b"),
#   prior(inv_gamma(0.1, 0.1), class = "sigma")
#   #prior(inv_gamma(0.1, 0.1), class = "shape"),
#   #prior(inv_gamma(0.1, 0.1), class = "sd")
# )

## Fit brms ----
iters <- 2000
burn <- 1000
chains <- 2
sims <- (iters-burn)*chains

#system.time(
betaFit <- brm(
  formulaBleaching_beta,
  data = procData2,
  #data = bleachingData,
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
  normalize = TRUE,
  control = list(adapt_delta = 0.95)
  #backend = "cmdstanr"
)
#)

#save(betaFit, file = "_data/betaFit.RData")

## Diagnostics ----
fitbeta <- 39
assign(paste0("betaFit", fitbeta), betaFit)
#save(betaFitFINAL, file = "_data/betaFitFINAL.RData")

plot(betaFit, ask = FALSE)
#prior_summary(betaFit)

#betaFit <- betaFit24
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
assign(paste0("betaFitFE", fitbeta), betaFitfixedEff)

betaFitfixedSigEff <- betaFitfixedEff |> filter(p_val < 0.2)
print(betaFitfixedSigEff)

pp_check(betaFit, ndraws = 100) +
  labs(title = paste0("betaFit", fitbeta))

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
#### MAE
betaFitResidualsMean <- 
  residuals(
    betaFit,
    method = "posterior_predict",
    re_formula = NULL,
    robust = FALSE,
    probs = c(0.025, 0.975)) |>
  data.frame()
mean(abs(betaFitResidualsMean$Estimate))
# 0.1103762, 0.1019409, 0.1049707
# 0.1105017, 0.1017932, 0.1050378
# 0.1108662, 0.1028177, 0.1062437
# 0.1105874, 0.1027295, 0.1056165
#          , 0.1025664

#### MAD
betaFitResidualsMed <- 
  residuals(
    betaFit,
    method = "posterior_predict",
    re_formula = NULL,
    robust = TRUE,
    probs = c(0.025, 0.975)) |>
  data.frame()
mean(abs(betaFitResidualsMed$Estimate))
# 0.1029426, 0.09506708, 0.09777495
# 0.1027574, 0.09512276, 0.09778614
# 0.1034679, 0.09629915, 0.09894765
# 0.1028752, 0.0962147, 0.09867248
#.         , 0.09603474


loo_compare(
  loo(betaFit11), # Lat, RE City
  loo(betaFit14), # Lat, FE City
  loo(betaFit17), # Lat
  loo(betaFit20), # FE City
  loo(betaFit23), # Lon, FE City
  loo(betaFit24), # t2(Lat, Lon), FE City
  loo(betaFit25), # t2(Lat, Lon)
  loo(betaFit26)
)
# elpd_diff se_diff
# betaFit24   0.0       0.0  
# betaFit25  -3.7       3.0  
# betaFit14 -17.1       5.6  
# betaFit11 -17.6       5.7  
# betaFit23 -33.4       8.1  
# betaFit20 -33.8       8.0  
# betaFit17 -35.4       8.8 

loo_compare(
  loo(betaFit30), # Lat, RE City
  loo(betaFit31), # Lat, FE City
  loo(betaFit32), # Lat
  loo(betaFit33), # FE City
  loo(betaFit34), # Lon, FE City
  loo(betaFit35), # t2(Lat, Lon), FE City
  loo(betaFit36), # t2(Lat, Lon)
  loo(betaFit38),
  loo(betaFit39)
)

bayes_factor(betaFit11, betaFit14)
# Estimated Bayes factor in favor of betaFit11 over betaFit14: 0.00161
bayes_factor(betaFit14, betaFit17)
# Estimated Bayes factor in favor of betaFit14 over betaFit17: 40361404.13121
bayes_factor(betaFit14, betaFit20)
# Estimated Bayes factor in favor of betaFit14 over betaFit20: 1352631.32243
bayes_factor(betaFit17, betaFit20)
# Estimated Bayes factor in favor of betaFit17 over betaFit20: 0.03316
bayes_factor(betaFit14, betaFit23)

bayes_factor(betaFit24, betaFit14)
bayes_factor(betaFit24, betaFit26)
bayes_factor(betaFit29, betaFit28)
bayes_factor(betaFit31, betaFit30)
bayes_factor(betaFit30, betaFit39)

betaFitsmooths <- conditional_smooths(betaFit,
                                      method = "posterior_predict")

plot(betaFitsmooths,
     stype = "raster",
     ask = FALSE,
     theme = theme(legend.position = "bottom"))
plot(betaFitsmooths,
     stype = "contour",
     ask = FALSE,
     theme = theme(legend.position = "bottom"))

betaFitsmooths <- conditional_effects(betaFit,
                                      method = "posterior_predict")
plot(betaFitsmooths,
     #stype = "contour",
     ask = FALSE,
     points = TRUE, 
     theme = theme(legend.position = "bottom"))

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
       gp(Date_Year, by = City_Town_Name) +
       #Lat2 +
       #Lon2 +
       t2(Lat, Lon) +
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
       TSA_DHW 
       #(1 | City_Town_Name)
  ) + brmsfamily(family = "zero_inflated_beta")#, link = "logit")

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
  data = procData2,
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
  normalize = TRUE,
  control = list(adapt_delta = 0.95)
  #backend = "cmdstanr"
)
#)

#save(ziBetaFit, file = "_data/ziBetaFit.RData")

## Diagnostics ----
fitziBeta <- 3
assign(paste0("ziBetaFit", fitziBeta), ziBetaFit)
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

loo_compare(
  loo(betaFit30),
  loo(ziBetaFit3)
)

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
#### MAE
ziBetaFitResidualsMean <- 
  residuals(
    ziBetaFit,
    method = "posterior_predict",
    re_formula = NULL,
    robust = FALSE,
    probs = c(0.025, 0.975)) |>
  data.frame()
mean(abs(ziBetaFitResidualsMean$Estimate))

#### MAD
ziBetaFitResidualsMed <- 
  residuals(
    ziBetaFit,
    method = "posterior_predict",
    re_formula = NULL,
    robust = TRUE,
    probs = c(0.025, 0.975)) |>
  data.frame()
mean(abs(ziBetaFitResidualsMed$Estimate))

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




