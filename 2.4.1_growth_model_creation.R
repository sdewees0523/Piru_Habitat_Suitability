library(here)
library(tidyverse)
library(survival)

spring <- read.csv(here("data", "models", "dredge_tables", "growth_spring_all_dredge_filtered.csv"))
early_spring <- read.csv(here("data", "models", "dredge_tables", "growth_early_spring_dredge_filtered.csv"))
late_spring <- read.csv(here("data", "models", "dredge_tables", "growth_late_spring_dredge_filtered.csv"))

spring$AICc
early_spring$AICc
late_spring$AICc

spring_height <- read.csv(here("data", "clean_data", "height_gopher_kapplin.csv")) %>% 
  mutate(height_date = case_when(start_time == 0 ~ "planting_height",
                                 start_time != 0 ~ "spring_height")) %>% 
  select(plot_number, Plant, height, height_date, end_time) %>% 
  group_by(plot_number) %>% 
  mutate(end_time = min(end_time)) %>% 
  ungroup() %>% 
  pivot_wider(id_cols = c(plot_number, Plant, end_time), names_from = height_date, values_from = height) %>% 
  drop_na() %>%
  mutate(growth = (spring_height - planting_height)/end_time) %>% 
  rename(species = Plant) %>% 
  mutate(planting_height = scale(planting_height)[,1])

fall_height <- read.csv(here("data", "clean_data", "fall_growth.csv")) %>% 
  mutate(date_measured = ymd(date_measured),
         date_measured_2 = ymd(date_measured_2)) %>% 
  select(plot_number, Plant, july_height, fall_height, date_measured, date_measured_2) %>% 
  mutate(growth = (fall_height - july_height)/(as.numeric(date_measured_2 - date_measured))) %>%
  rename(species = Plant) %>% 
  select(plot_number, species, july_height, growth) %>% 
  mutate(july_height = scale(july_height)[,1])

plant_traits <- read.csv(here("data", "clean_data", "cox_plant_traits.csv")) %>% 
  mutate(les_1 = scale(les_1)[,1],
         les_2 = scale(les_2)[,1],
         wood_density = scale(wood_density)[,1],
         wue = scale(wue)[,1],
         wue = wue*-1)

environmental <- read.csv(here("data", "clean_data", "predicted_environmental.csv")) %>% 
  mutate(date = ymd(date)) %>% 
  group_by(date) %>% 
  mutate(temperature = scale(temperature)[,1],
         vpd = scale(vpd)[,1]) %>% 
  ungroup() |> 
  drop_na()

environmental_latespring <- environmental %>% 
  filter(date > "2020-05-30" & date <= "2020-06-26") %>% 
  group_by(plot_number) %>% 
  reframe(soil_moisture = mean(soil_moisture),
          temperature = mean(temperature),
          vpd = mean(vpd))

growth_latespring_data <- spring_height %>% 
  inner_join(plant_traits, by = "species") %>% 
  inner_join(environmental_latespring, by = "plot_number") %>% 
  select(growth, les_1, les_2, wood_density, wue, temperature, soil_moisture, vpd, planting_height)

late_spring_model <- late_spring %>% 
  select(-c(X.Intercept., df, logLik, AICc, delta, weight)) %>%
  pivot_longer(cols = everything(), names_to = "variables", values_to = "coeficients") %>% 
  drop_na(coeficients) %>% 
  mutate(variables = str_replace(variables, "\\.", "*"))

independent_vars <-paste(late_spring_model$variables, collapse = " + ")

late_spring_model <- glm(as.formula(paste("growth ~", independent_vars)), 
                         data = growth_latespring_data)
summary(late_spring_model)

save(late_spring_model, file = here("data", "models", "late_spring_growth_model.rda"))

summer_all <- read.csv(here("data", "models", "dredge_tables", "growth_summer_all_dredge_filtered.csv"))
summer <- read.csv(here("data", "models", "dredge_tables", "growth_late_summer_dredge_filtered.csv"))
fall <- read.csv(here("data", "models", "dredge_tables", "growth_fall_dredge_filtered.csv"))

summer_all$AICc
summer$AICc
fall$AICc

environmental_latesummer <- environmental %>% 
  filter(date > "2020-06-26" & date <= "2020-09-30") %>% 
  group_by(plot_number) %>% 
  reframe(soil_moisture = mean(soil_moisture),
          temperature = mean(temperature),
          vpd = mean(vpd))

growth_latesummer_data <- fall_height %>% 
  inner_join(plant_traits, by = "species") %>% 
  inner_join(environmental_latesummer, by = "plot_number") %>% 
  select(growth, les_1, les_2, wood_density, wue, temperature, soil_moisture, vpd, july_height)

late_summer_model <- summer %>% 
  select(-c(X.Intercept., df, logLik, AICc, delta, weight)) %>%
  pivot_longer(cols = everything(), names_to = "variables", values_to = "coeficients") %>% 
  drop_na(coeficients) %>% 
  mutate(variables = str_replace(variables, "\\.", "*"))

independent_vars_summer <-paste(late_summer_model$variables, collapse = " + ")

late_summer_model <- glm(as.formula(paste("growth ~", independent_vars_summer)), 
                         data = growth_latesummer_data)
summary(late_summer_model)

save(late_summer_model, file = here("data", "models", "late_summer_growth_model.rda"))
