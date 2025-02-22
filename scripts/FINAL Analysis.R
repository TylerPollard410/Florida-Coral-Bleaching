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

#write_csv(bleachingData, "_data/FloridaCoralBleachingData.csv")

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



# 1. Pre-Process Data ----
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
procData2pre <- bleachingData |>
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
    ~predict(yeojohnson(.x, standardize = FALSE), newdata = .x)
    ))
preProc2 <- preProcess(
  procData2pre |>
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
  method = c("center", "scale") #, "YeoJohnson")
)
preProc2
procData2 <- predict(preProc2, procData2pre)

# Lat2Reg <- bleachingData$Lat2
# Lat2Yeo <- yeojohnson(bleachingData$Lat2)
# Lat2YeoPred <- predict(Lat2Yeo)
# 
# Lat2YeoProc <- preProcess(bleachingData |> select(Lat2),
#                           method = c("YeoJohnson"))

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

# 2. MODELS =============================================
## Set Model Parameters ----
iters <- 4000
burn <- 2000
chains <- 4
sims <- (iters-burn)*chains

## Fit Models ----
### Model 1 -------
formulaMod1 <- 
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
       TSA_DHW 
  ) + brmsfamily(family = "Beta", link = "logit")

default_prior(formulaMod1, data = procData2)

priorsMod1 <- c(
  prior(normal(0, 5), class = "b"),  # Fixed effects
  #prior(cauchy(0,2), class = "sdgp"),  # GP output variance
  #prior(inv_gamma(4,1), class = "lscale"),  # GP length scale
  #prior(cauchy(0,2), class = "sds"),  # Tensor spline smoothness
  prior(gamma(0.1, 0.1), class = "phi")  # Beta regression precision
)

system.time(
  fitMod1 <- brm(
    formulaMod1,
    data = procData2,
    prior = priorsMod1,
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
)

save(fitMod1, file = "_data/models/fitMod1.RData")
get_prior(fitMod1)
print(fitMod1, digits = 4)

### Model 2 -------
formulaMod2 <- 
  bf(PercentBleachingBounded ~ 
       Date_Year2 +
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
  ) + brmsfamily(family = "Beta", link = "logit")

default_prior(formulaMod2, data = procData2)

priorsMod2 <- c(
  prior(normal(0, 5), class = "b"),  # Fixed effects
  #prior(cauchy(0,2), class = "sdgp"),  # GP output variance
  #prior(inv_gamma(4,1), class = "lscale"),  # GP length scale
  prior(cauchy(0,2), class = "sds"),  # Tensor spline smoothness
  prior(gamma(0.1, 0.1), class = "phi")  # Beta regression precision
)

system.time(
  fitMod2 <- brm(
    formulaMod2,
    data = procData2,
    prior = priorsMod2,
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
)

save(fitMod2, file = "_data/models/fitMod2.RData")
get_prior(fitMod2)

### Model 3 -------
formulaMod3 <- 
  bf(PercentBleachingBounded ~ 
       gp(Date_Year) +
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
       TSA_DHW 
  ) + brmsfamily(family = "Beta", link = "logit")

default_prior(formulaMod3, data = procData2)

priorsMod3 <- c(
  prior(normal(0, 5), class = "b"),  # Fixed effects
  prior(cauchy(0,2), class = "sdgp"),  # GP output variance
  prior(inv_gamma(4,1), class = "lscale"),  # GP length scale
  #prior(cauchy(0,2), class = "sds"),  # Tensor spline smoothness
  prior(gamma(0.1, 0.1), class = "phi")  # Beta regression precision
)

system.time(
  fitMod3 <- brm(
    formulaMod3,
    data = procData2,
    prior = priorsMod3,
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
)

save(fitMod3, file = "_data/models/fitMod3.RData")
get_prior(fitMod3)

### Model 4 -------
formulaMod4 <- 
  bf(PercentBleachingBounded ~ 
       gp(Date_Year) +
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
  ) + brmsfamily(family = "Beta", link = "logit")

default_prior(formulaMod4, data = procData2)

priorsMod4 <- c(
  prior(normal(0, 5), class = "b"),  # Fixed effects
  prior(cauchy(0,2), class = "sdgp"),  # GP output variance
  prior(inv_gamma(4,1), class = "lscale"),  # GP length scale
  prior(cauchy(0,2), class = "sds"),  # Tensor spline smoothness
  prior(gamma(0.1, 0.1), class = "phi")  # Beta regression precision
)

system.time(
  fitMod4 <- brm(
    formulaMod4,
    data = procData2,
    prior = priorsMod4,
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
)

save(fitMod4, file = "_data/models/fitMod4.RData")
get_prior(fitMod4)

### Model 5 -------
formulaMod5 <- 
  bf(PercentBleachingBounded ~ 
       gp(Date_Year, by = City_Town_Name) +
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
       TSA_DHW
  ) + brmsfamily(family = "Beta", link = "logit")

default_prior(formulaMod5, data = procData2)

priorsMod5 <- c(
  prior(normal(0,5), class = "b"),  # Fixed effects
  prior(cauchy(0,2), class = "sdgp"),  # GP output variance
  prior(inv_gamma(4,1), class = "lscale"),  # GP length scale
  #prior(cauchy(0,2), class = "sds"),  # Tensor spline smoothness
  prior(gamma(0.1, 0.1), class = "phi")  # Beta regression precision
)

system.time(
  fitMod5 <- brm(
    formulaMod5,
    data = procData2,
    prior = priorsMod5,
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
)

save(fitMod5, file = "_data/models/fitMod5.RData")
get_prior(fitMod5)

### Model 6 -------
formulaMod6 <- 
  bf(PercentBleachingBounded ~ 
       gp(Date_Year, by = City_Town_Name) +
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
  ) + brmsfamily(family = "Beta", link = "logit")

default_prior(formulaMod6, data = procData2)

priorsMod6 <- c(
  prior(normal(0,5), class = "b"),  # Fixed effects
  prior(cauchy(0,2), class = "sdgp"),  # GP output variance
  prior(inv_gamma(4,1), class = "lscale"),  # GP length scale
  prior(cauchy(0,2), class = "sds"),  # Tensor spline smoothness
  prior(gamma(0.1, 0.1), class = "phi")  # Beta regression precision
)

system.time(
  fitMod6 <- brm(
    formulaMod6,
    data = procData2,
    prior = priorsMod6,
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
)

save(fitMod6, file = "_data/models/fitMod6.RData")
get_prior(fitMod6)

# 3. Compare Models ----
## Load Models ----
# load(file = "_data/models/Model1.RData")
# load(file = "_data/models/Model2.RData")
# load(file = "_data/models/Model3.RData")
# load(file = "_data/models/Model4.RData")
# load(file = "_data/models/Model5.RData")
# load(file = "_data/models/Model6.RData")

## Loo ----
loo1 <- loo(fitMod1)
loo2 <- loo(fitMod2)
loo3 <- loo(fitMod3)
loo4 <- loo(fitMod4)
loo5 <- loo(fitMod5)
loo6 <- loo(fitMod6)

looList <- list(
  "Model 1" = loo1,
  "Model 2" = loo2,
  "Model 3" = loo3,
  "Model 4" = loo4,
  "Model 5" = loo5,
  "Model 6" = loo6
)

## WAIC ----
waic1 <- waic(fitMod1)
waic2 <- waic(fitMod2)
waic3 <- waic(fitMod3)
waic4 <- waic(fitMod4)
waic5 <- waic(fitMod5)
waic6 <- waic(fitMod6)

waicList <- list(
  "Model 1" = waic1,
  "Model 2" = waic2,
  "Model 3" = waic3,
  "Model 4" = waic4,
  "Model 5" = waic5,
  "Model 6" = waic6
)

## Loo Compare ----
looComp <- loo_compare(looList)
looComp

looCompDF <- looComp |>
  data.frame() |>
  rownames_to_column(var = "Model")

waicComp <- loo_compare(waicList)
waicList

waicCompDF <- waicComp |>
  data.frame() |>
  rownames_to_column(var = "Model")

## Comparison Table -----
fitCompDF <- data.frame(
  Model = paste("Model", 1:6),
  TempStr = c(
    rep("Linear", 2),
    rep("Global GP", 2),
    rep("City-Specific GP", 2)
  ),
  SpaceStr = c(
    rep(c("Linear", "Tensor Smooth"), times = 3)
  )) |>
  left_join(
    looCompDF |> 
      rename(
        elpd_diff_loo = elpd_diff,
        se_diff_loo = se_diff
      )
  ) |>
  left_join(
    waicCompDF |> 
      rename(
        elpd_diff_waic = elpd_diff,
        se_diff_waic = se_diff
      )
  )
fitCompDF
save(fitCompDF, file = "_data/fitCompDF.RData")

### gt ----
fitCompDF |>
  select(
    Model, 
    TempStr,
    SpaceStr, 
    looic, 
    se_looic, 
    p_loo,
    elpd_diff_loo, 
    se_diff_loo
  ) |>
  arrange(desc(elpd_diff_loo)) |>
  gt() |>
  fmt_auto() |>
  cols_label(
    TempStr = "Temporal Structure",
    SpaceStr = "Spatial Structure"
    # looic = "LOOIC",
    # se_looic = "SE LOOIC",
    # p_loo = "p-value",
    # elpd_diff_loo = "LOO ELPD Difference",
    # se_diff_loo = "SE LOO Difference"
  )

# 4. Model refinement-----
load(file = "_data/models/Model6.RData")
selectBaseMod <- Model6

formulaModSelect <- 
  bf(PercentBleachingBounded ~ 
       gp(Date_Year, by = City_Town_Name) +
       t2(Lat, Lon) +
       Distance_to_Shore +
       #Exposure + # Remove 2
       Turbidity +
       #Cyclone_Frequency + # Remove 4
       #Depth_m + # Remove 3
       Windspeed +
       #ClimSST + # Remove 1
       #SSTA +
       #SSTA_DHW + # Remove 5
       TSA +
       TSA_DHW
  ) + brmsfamily(family = "Beta", link = "logit")

default_prior(formulaModSelect, data = procData2)

priorsModSelect <- c(
  prior(normal(0,5), class = "b"),  # Fixed effects
  prior(cauchy(0,2), class = "sdgp"),  # GP output variance
  #prior(inv_gamma(4,1), class = "lscale"),  # GP length scale
  prior(cauchy(0,2), class = "sds"),  # Tensor spline smoothness
  prior(gamma(0.1, 0.1), class = "phi")  # Beta regression precision
)

iters <- 2000
burn <- 1000
chains <- 2
sims <- (iters-burn)*chains

system.time(
  fitModSelect <- brm(
    formulaModSelect,
    data = procData2,
    prior = priorsModSelect,
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
)

#save(fitModSelect, file = "_data/models/fitMod6.RData")
get_prior(fitModSelect)

fitSelect <- 5
assign(paste0("fitModSelect", fitSelect), fitModSelect)

print(fitModSelect, digits = 4)

## Fixed Effects ----
fixedEffSelect <- fixef(fitModSelect) |>
  data.frame() |>
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
print(fixedEffSelect, digits = 4)

## Hypothesis ----
hyp1 <- hypothesis(fitModSelect1,
                   hypothesis = c(
                     "Distance_to_Shore = 0",
                     "ExposureSheltered = 0",
                     "Turbidity = 0",
                     "Cyclone_Frequency = 0",
                     "Depth_m = 0",
                     "Windspeed = 0",
                     "SSTA = 0",
                     "TSA = 0",
                     "TSA_DHW = 0"
                   ),
                   robust = TRUE
)
hyp1

hyp2 <- hypothesis(fitModSelect2,
                   hypothesis = c(
                     "Distance_to_Shore = 0",
                     #"ExposureSheltered = 0",
                     "Turbidity = 0",
                     "Cyclone_Frequency = 0",
                     "Depth_m = 0",
                     "Windspeed = 0",
                     "SSTA = 0",
                     "TSA = 0",
                     "TSA_DHW = 0"
                   ),
                   robust = TRUE
)
hyp2

hyp3 <- hypothesis(fitModSelect3,
                   hypothesis = c(
                     "Distance_to_Shore = 0",
                     #"ExposureSheltered = 0",
                     "Turbidity = 0",
                     "Cyclone_Frequency = 0",
                     #"Depth_m = 0",
                     "Windspeed = 0",
                     "SSTA = 0",
                     "TSA = 0",
                     "TSA_DHW = 0"
                   ),
                   robust = TRUE
)
hyp3

hyp4 <- hypothesis(fitModSelect4,
                   hypothesis = c(
                     "Distance_to_Shore = 0",
                     #"ExposureSheltered = 0",
                     "Turbidity = 0",
                     #"Cyclone_Frequency = 0",
                     #"Depth_m = 0",
                     "Windspeed = 0",
                     "SSTA = 0",
                     "TSA = 0",
                     "TSA_DHW = 0"
                   ),
                   robust = TRUE
)
hyp4

hyp5 <- hypothesis(fitModSelect5,
                   hypothesis = c(
                     "Distance_to_Shore = 0",
                     #"ExposureSheltered = 0",
                     "Turbidity = 0",
                     #"Cyclone_Frequency = 0",
                     #"Depth_m = 0",
                     "Windspeed = 0",
                     #"SSTA = 0",
                     "TSA = 0",
                     "TSA_DHW = 0"
                   ),
                   robust = TRUE
)
hyp5


hyp1
hyp2
hyp3
hyp4
hyp5


## Compare ----
selectBaseMod$formula
fitModSelect1$formula
fitModSelect2$formula
fitModSelect3$formula
fitModSelect4$formula
fitModSelect5$formula

### Bayes Factor ----
fitModSelectBF_1B <- bayes_factor(fitModSelect1, selectBaseMod) # Removed ClimSST
fitModSelectBF_21 <- bayes_factor(fitModSelect2, fitModSelect1) # Removed Exposure
fitModSelectBF_32 <- bayes_factor(fitModSelect3, fitModSelect2) # Removed Depth_m
fitModSelectBF_43 <- bayes_factor(fitModSelect4, fitModSelect3) # Removed Cyclone_Frequency
fitModSelectBF_54 <- bayes_factor(fitModSelect5, fitModSelect4) # Removed SSTA

### Loo ----
looSelectBase <- loo(selectBaseMod)
looSelect1 <- loo(fitModSelect1)
looSelect2 <- loo(fitModSelect2)
looSelect3 <- loo(fitModSelect3)
looSelect4 <- loo(fitModSelect4)
looSelect5 <- loo(fitModSelect5)

looSelectComp <- loo_compare(
  looSelectBase,
  looSelect1,
  looSelect2,
  looSelect3,
  looSelect4,
  looSelect5
)
looSelectComp

### MAE ----
set.seed(52)
selectBaseModMAE <- 
  residuals(
    selectBaseMod,
    method = "posterior_predict",
    re_formula = NULL,
    robust = FALSE,
    probs = c(0.025, 0.975)) |>
  data.frame() |>
  summarise(
    MAE = mean(abs(Estimate))
  ) |>
  pull(MAE)
selectBaseModMAEdf <- data.frame(
  Model = "Baseline",
  MAE = selectBaseModMAE
)

set.seed(52)
fitModSelectResidualsMean <- 
  residuals(
    fitModSelect, 
    method = "posterior_predict",
    re_formula = NULL,
    robust = FALSE,
    probs = c(0.025, 0.975)) |>
  data.frame() |>
  summarise(
    MAE = mean(abs(Estimate))
  ) |>
  pull(MAE)

#fitSelectMAEtemp <- mean(abs(fitModSelectResidualsMean$Estimate))
fitSelectMAEtemp <- data.frame(
  Model = paste("Mod", fitSelect),
  MAE = fitModSelectResidualsMean
)
fitSelectMAE <- bind_rows(
  fitSelectMAEtemp,
  fitSelectMAE
)
#fitSelectMAE <- selectBaseModMAEdf
fitSelectMAE |>
  arrange(MAE)

### MAD ----
set.seed(52)
selectBaseModMAD <- 
  residuals(
    selectBaseMod,
    method = "posterior_predict",
    re_formula = NULL,
    robust = TRUE,
    probs = c(0.025, 0.975)) |>
  data.frame() |>
  summarise(
    MAD = mean(abs(Estimate))
  ) |>
  pull(MAD)
selectBaseModMADdf <- data.frame(
  Model = "Baseline",
  MAD = selectBaseModMAD
)

set.seed(52)
fitModSelectResidualsMAD <- 
  residuals(
    fitModSelect, 
    method = "posterior_predict",
    re_formula = NULL,
    robust = TRUE,
    probs = c(0.025, 0.975)) |>
  data.frame() |>
  summarise(
    MAD = mean(abs(Estimate))
  ) |>
  pull(MAD)

#fitSelectMADtemp <- mean(abs(fitModSelectResidualsMean$Estimate))
fitSelectMADtemp <- data.frame(
  Model = paste("Mod", fitSelect),
  MAD = fitModSelectResidualsMAD
)
fitSelectMAD <- bind_rows(
  fitSelectMADtemp,
  fitSelectMAD
)
#fitSelectMAD <- selectBaseModMADdf
fitSelectMAD |>
  arrange(MAD)

## Refinement Table ----
refinementDF <- data.frame(
  PriorModel = c(
    NA,
    "Model 6",
    "Model 7",
    "Model 8",
    "Model 9"
    #"Model 10"
  ),
  RefinedModel = c(
    "Model 6",
    "Model 7",
    "Model 8",
    "Model 9",
    "Model 10"
    #"Model 11"
  ),
  CovariateRemoved = c(
    NA,
    "ClimSST",
    "Exposure",
    "Depth_m",
    "Cyclone_Frequency"
    #"SSTA"
  ),
  BF = c(
    NA,
    fitModSelectBF_1B$bf,
    fitModSelectBF_21$bf,
    fitModSelectBF_32$bf,
    fitModSelectBF_43$bf
    #fitModSelectBF_54$bf
  ),
  RefinedMAE = c(
    rev(fitSelectMAE$MAE)[-1]
  ),
  RefinedMAD = c(
    rev(fitSelectMAD$MAD)[-1]
  )
)
refinementDF

save(fitModSelect1, file = "_data/models/refineFit1.RData")
save(fitModSelect2, file = "_data/models/refineFit2.RData")
save(fitModSelect3, file = "_data/models/refineFit3.RData")
save(fitModSelect4, file = "_data/models/refineFit4.RData")
save(fitModSelect5, file = "_data/models/refineFit5.RData")
save(refinementDF, file = "_data/refinementDF.RData")

# 5. FINAL MODEL =======================
formulaModfinal <- 
  bf(PercentBleachingBounded ~ 
       gp(Date_Year, by = City_Town_Name) +
       t2(Lat, Lon) +
       Distance_to_Shore +
       #Exposure +
       Turbidity +
       #Cyclone_Frequency +
       #Depth_m +
       Windspeed +
       #ClimSST +
       SSTA +
       #SSTA_DHW +
       TSA +
       TSA_DHW
  ) + brmsfamily(family = "Beta", link = "logit")

default_prior(formulaModfinal, data = procData2)

priorsModFinal <- c(
  prior(normal(0,5), class = "b"),  # Fixed effects
  prior(cauchy(0,2), class = "sdgp"),  # GP output variance
  #prior(inv_gamma(4,1), class = "lscale"),  # GP length scale
  prior(cauchy(0,2), class = "sds"),  # Tensor spline smoothness
  prior(gamma(0.1, 0.1), class = "phi")  # Beta regression precision
)

iters <- 4000
burn <- 2000
chains <- 4
sims <- (iters-burn)*chains

system.time(
  finalMod <- brm(
    formulaModfinal,
    data = procData2,
    prior = priorsModFinal,
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
)

save(finalMod, file = "_data/finalMod.RData")

load(file = "_data/models/finalMod3.RData")
finalMod <- finalMod3
#finalMod <- fitModSelect4
#finalMod <- fitMod6

finalModPriors <- get_prior(finalMod)
gpPrior <- finalModPriors |>
  filter(class == "lscale", source == "default") |>
  pull(prior) |>
  unique()
lscalePriorAlpha <- as.numeric(str_extract(gpPrior, "(?<=inv_gamma\\()[^,]+"))
lscalePriorBeta <- as.numeric(str_extract(gpPrior, "(?<=, )[^)]+"))

## Diagnostics ----
prior_summary(finalMod)
posterior_summary(finalMod)

plot(finalMod, ask = FALSE)
print(finalMod, digits = 4)

### PPC ----
# Makes draws for plots
set.seed(52) # for reproducibility
posteriorFinalMod <- posterior_predict(finalMod)

# Observed data
## Response
obsY <- bleachingData$PercentBleachingBounded

## Grouping
groupCity <- bleachingData$City_Town_Name

# Random draws
numDraws <- 250
set.seed(52) # for reproducibility
drawsInd <- sample(x = 1:sims, size = numDraws)

# Posterior sample
postYsamp <- posteriorFinalMod[drawsInd, ]

#### Plot guide ----
fillPPC <- "#d1e1ec"
colorPPC <- "#b3cde0"
fill2PPC <- "#011f4b"

#### Density ----
set.seed(52) # for reproducibility
ppcDensPlot2 <- ppc_dens_overlay(
  y = obsY,
  #yrep = posteriorFinalMod 
  yrep = postYsamp
) +
  scale_x_continuous(
    name = "Percent Bleaching",
    limits = c(0,1),
    breaks = seq(0, 1, 0.1)
    #expand = expansion(mult = 0.01)
  ) +
  scale_y_continuous(
    name = "Density",
    expand = expansion(mult = c(0, 0.01))
  ) +
  labs(
    title = "Posterior Predictive Distribution vs Observed Percent Bleaching",
    subtitle = paste(sims, "Simulations")
  )
ppcDensPlot2
ppcDensPlotBuild2B <- ggplot_build(ppcDensPlot2)
levels(ppcDensPlotBuild2B$plot$data$is_y_label) <- c("italic(y)" = "Observed", 'italic(y)[rep]' = "Posterior")
ppcDensPlotBuild2B

#### Stats ----
# Make stat functions
meanFunc <- function(y){mean(y)}
sdFunc <- function(y){sd(y)}
medianFunc <- function(y){median(y)}
lcbFunc <- function(y){quantile(y, 0.025)}
ucbFunc <- function(y){quantile(y, 0.975)}
rangeFunc <- function(y){max(y) - min(y)}

##### Mean ----
set.seed(52) # for reproducibility
meanY <- meanFunc(obsY)

ppcMeanStat <- ppc_stat_data(
  y = obsY,
  yrep = posteriorFinalMod,
  group = NULL,
  stat = c("meanFunc")
) |>
  mutate(
    meanProbLow = value < meanY,
    meanProbHigh = value > meanY
  )

# ppcMeanPlot <- ppc_stat(
#   y = obsY,
#   yrep = posteriorFinalMod,
#   stat = "mean",
#   freq = TRUE
# )
# ppcMeanPlot
# ppcMeanPlotBuild <- ggplot_build(ppcMeanPlot)

ppcMeanPlotGG <- ggplot() +
  geom_histogram(
    data = ppcMeanStat |> filter(variable != "y"),
    aes(x = value, color = "Posterior"),
    fill = fillPPC
  ) +
  geom_vline(
    data = ppcMeanStat |> filter(variable == "y"),
    aes(xintercept = value, color = "Observed"),
    linewidth = 1
  ) +
  # annotate(
  #   "text", 
  #   x = 
  # ) +
  scale_x_continuous(
    name = "Percent Bleaching"
    #expand = expansion(mult = 0.01)
  ) +
  scale_y_continuous(
    name = "Number of Posterior Draws",
    expand = expansion(mult = c(0, 0.01))
  ) +
  scale_color_manual(
    name = "Data",
    values = c(
      "Posterior" = colorPPC,
      "Observed" = "black"
    ),
    breaks = c("Posterior", "Observed")
  ) +
  labs(title = "Mean",
       subtitle = paste("p-value =", round(mean(ppcMeanStat$meanProbLow[-1]), 4))
       # title = "Posterior Predictive Check for Distribution Mean",
       # subtitle = paste(sims, "Simulations, Bayesian p-value =", 
       #                  round(mean(ppcMeanStat$meanProbLow[-1]), 4))
  ) +
  theme_bw() +
  guides(color = guide_legend(byrow = TRUE)) +
  theme(
    panel.grid.major.x = element_blank(),
    panel.grid.minor.x = element_blank(),
    legend.key.spacing.y = unit(5, "points")
  )
ppcMeanPlotGG

##### SD ----
set.seed(52) # for reproducibility
sdY <- sdFunc(obsY)

ppcSDStat <- ppc_stat_data(
  y = obsY,
  yrep = posteriorFinalMod,
  group = NULL,
  stat = c("sdFunc")
) |>
  mutate(
    sdProbLow = value < sdY,
    sdProbHigh = value > sdY
  )

# ppcSDPlot <- ppc_stat(
#   y = obsY,
#   yrep = posteriorFinalMod,
#   stat = "sdFunc",
#   freq = TRUE
# )
# ppcSDPlot
#ppcSDPlotBuild <- ggplot_build(ppcSDPlot)

ppcSDPlotGG <- ggplot() +
  geom_histogram(
    data = ppcSDStat |> filter(variable != "y"),
    aes(x = value, color = "Posterior"),
    fill = fillPPC
  ) +
  geom_vline(
    data = ppcSDStat |> filter(variable == "y"),
    aes(xintercept = value, color = "Observed"),
    linewidth = 1
  ) +
  scale_x_continuous(
    name = "Percent Bleaching"
    #expand = expansion(mult = 0.01)
  ) +
  scale_y_continuous(
    name = "Number of Posterior Draws",
    expand = expansion(mult = c(0, 0.01))
  ) +
  scale_color_manual(
    name = "Data",
    values = c(
      "Posterior" = colorPPC,
      "Observed" = "black"
    ),
    breaks = c("Posterior", "Observed")
  ) +
  labs(title = "SD",
       subtitle = paste("p-value =", round(mean(ppcSDStat$sdProbLow[-1]), 4))
       # title = "Posterior Predictive Check for Distribution Mean",
       # subtitle = paste(sims, "Simulations, Bayesian p-value =", 
       #                  round(mean(ppcMeanStat$meanProbLow[-1]), 4))
  ) +
  theme_bw() +
  guides(color = guide_legend(byrow = TRUE)) +
  theme(
    panel.grid.major.x = element_blank(),
    panel.grid.minor.x = element_blank(),
    legend.key.spacing.y = unit(5, "points")
  )
ppcSDPlotGG


##### Median ----
set.seed(52) # for reproducibility
medianY <- medianFunc(obsY)

ppcMedianStat <- ppc_stat_data(
  y = obsY,
  yrep = posteriorFinalMod,
  group = NULL,
  stat = c("medianFunc")
) |>
  mutate(
    medianProbLow = value < medianY,
    medianProbHigh = value > medianY
  )

# ppcMedianPlot <- ppc_stat(
#   y = obsY,
#   yrep = posteriorFinalMod,
#   stat = "medianFunc",
#   freq = TRUE
# )
# ppcMedianPlot
#ppcMedianPlotBuild <- ggplot_build(ppcMedianPlot)

ppcMedianPlotGG <- ggplot() +
  geom_histogram(
    data = ppcMedianStat |> filter(variable != "y"),
    aes(x = value, color = "Posterior"),
    fill = fillPPC
  ) +
  geom_vline(
    data = ppcMedianStat |> filter(variable == "y"),
    aes(xintercept = value, color = "Observed"),
    linewidth = 1
  ) +
  scale_x_continuous(
    name = "Percent Bleaching"
    #expand = expansion(mult = 0.01)
  ) +
  scale_y_continuous(
    name = "Number of Posterior Draws",
    expand = expansion(mult = c(0, 0.01))
  ) +
  scale_color_manual(
    name = "Data",
    values = c(
      "Posterior" = colorPPC,
      "Observed" = "black"
    ),
    breaks = c("Posterior", "Observed")
  ) +
  labs(title = "Median",
       subtitle = paste("p-value =", round(mean(ppcMedianStat$medianProbLow[-1]), 4))
       # title = "Posterior Predictive Check for Distribution Mean",
       # subtitle = paste(sims, "Simulations, Bayesian p-value =", 
       #                  round(mean(ppcMeanStat$meanProbLow[-1]), 4))
  ) +
  theme_bw() +
  guides(color = guide_legend(byrow = TRUE)) +
  theme(
    panel.grid.major.x = element_blank(),
    panel.grid.minor.x = element_blank(),
    legend.key.spacing.y = unit(5, "points")
  )
ppcMedianPlotGG


##### LCB ----
set.seed(52) # for reproducibility
lcbY <- lcbFunc(obsY)

ppcLCBStat <- ppc_stat_data(
  y = obsY,
  yrep = posteriorFinalMod,
  group = NULL,
  stat = c("lcbFunc")
) |>
  mutate(
    lcbProbLow = value < lcbY,
    lcbProbHigh = value > lcbY
  )

# ppcLCBPlot <- ppc_stat(
#   y = obsY,
#   yrep = posteriorFinalMod,
#   stat = "lcbFunc",
#   freq = TRUE
# )
# ppcLCBPlot
#ppcLCBPlotBuild <- ggplot_build(ppcLCBPlot)

ppcLCBPlotGG <- ggplot() +
  geom_histogram(
    data = ppcLCBStat |> filter(variable != "y"),
    aes(x = value, color = "Posterior"),
    fill = fillPPC
  ) +
  geom_vline(
    data = ppcLCBStat |> filter(variable == "y"),
    aes(xintercept = value, color = "Observed"),
    linewidth = 1
  ) +
  scale_x_continuous(
    name = "Percent Bleaching"
    #expand = expansion(mult = 0.01)
  ) +
  scale_y_continuous(
    name = "Number of Posterior Draws",
    expand = expansion(mult = c(0, 0.01))
  ) +
  scale_color_manual(
    name = "Data",
    values = c(
      "Posterior" = colorPPC,
      "Observed" = "black"
    ),
    breaks = c("Posterior", "Observed")
  ) +
  labs(title = "LCB",
       subtitle = paste("p-value =", round(mean(ppcLCBStat$lcbProbLow[-1]), 4))
       # title = "Posterior Predictive Check for Distribution Mean",
       # subtitle = paste(sims, "Simulations, Bayesian p-value =", 
       #                  round(mean(ppcMeanStat$meanProbLow[-1]), 4))
  ) +
  theme_bw() +
  guides(color = guide_legend(byrow = TRUE)) +
  theme(
    panel.grid.major.x = element_blank(),
    panel.grid.minor.x = element_blank(),
    legend.key.spacing.y = unit(5, "points")
  )
ppcLCBPlotGG


##### UCB ----
set.seed(52) # for reproducibility
ucbY <- ucbFunc(obsY)

ppcUCBStat <- ppc_stat_data(
  y = obsY,
  yrep = posteriorFinalMod,
  group = NULL,
  stat = c("ucbFunc")
) |>
  mutate(
    ucbProbLow = value < ucbY,
    ucbProbHigh = value > ucbY
  )

# ppcUCBPlot <- ppc_stat(
#   y = obsY,
#   yrep = posteriorFinalMod,
#   stat = "ucbFunc",
#   freq = TRUE
# )
# ppcUCBPlot
#ppcUCBPlotBuild <- ggplot_build(ppcUCBPlot)

ppcUCBPlotGG <- ggplot() +
  geom_histogram(
    data = ppcUCBStat |> filter(variable != "y"),
    aes(x = value, color = "Posterior"),
    fill = fillPPC
  ) +
  geom_vline(
    data = ppcUCBStat |> filter(variable == "y"),
    aes(xintercept = value, color = "Observed"),
    linewidth = 1
  ) +
  scale_x_continuous(
    name = "Percent Bleaching"
    #expand = expansion(mult = 0.01)
  ) +
  scale_y_continuous(
    name = "Number of Posterior Draws",
    expand = expansion(mult = c(0, 0.01))
  ) +
  scale_color_manual(
    name = "Data",
    values = c(
      "Posterior" = colorPPC,
      "Observed" = "black"
    ),
    breaks = c("Posterior", "Observed")
  ) +
  labs(title = "UCB",
       subtitle = paste("p-value =", round(mean(ppcUCBStat$ucbProbLow[-1]), 4))
       # title = "Posterior Predictive Check for Distribution Mean",
       # subtitle = paste(sims, "Simulations, Bayesian p-value =", 
       #                  round(mean(ppcMeanStat$meanProbLow[-1]), 4))
  ) +
  theme_bw() +
  guides(color = guide_legend(byrow = TRUE)) +
  theme(
    panel.grid.major.x = element_blank(),
    panel.grid.minor.x = element_blank(),
    legend.key.spacing.y = unit(5, "points")
  )
ppcUCBPlotGG

#### Combined plot ----
ppcDens

ppcCombPlot <- 
  (ppcMeanPlotGG + ppcSDPlotGG) /
  (ppcLCBPlotGG + ppcMedianPlotGG + ppcUCBPlotGG) +
  plot_layout(
    guides = "collect",
    axes = "collect_x"
  ) +
  plot_annotation(
    title = "Posterior Predictive Checks for Distributional Statistics",
    subtitle = paste("Bayesian predictive p-values for", sims, "Simulations")
  )
ppcCombPlot


## Fixed Effects ----
print(finalMod, digits = 4)
fixedEff <- fixef(finalMod) |>
  data.frame() |>
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
print(fixedEff, digits = 4)

condEffData <- conditional_effects(
  finalMod, 
  re_formula = NULL,
  method = "posterior_predict",
  robust = FALSE
)
condEffPlot <- plot(
  condEffData,
  ask = FALSE,
  points = TRUE
)
condEffPlot






