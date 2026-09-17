library(here)
library(tidyverse)
library(survival)

spring <- read.csv(here("data", "models", "dredge_tables", "growth_spring_all_dredge_filtered.csv")) %>% 
  mutate(season = "spring_all")
early_spring <- read.csv(here("data", "models", "dredge_tables", "growth_early_spring_dredge_filtered.csv")) %>% 
  mutate(season = "early_spring")
late_spring <- read.csv(here("data", "models", "dredge_tables", "growth_late_spring_dredge_filtered.csv")) %>% 
  mutate(season = "late_spring")

early_drought <- rbind(spring, early_spring, late_spring) %>% 
  filter(AICc == min(AICc, na.rm = TRUE))

print(early_drought$season)

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
         les_2 = scale(les_2)[,1]*-1,
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

environmental_earlyspring <- environmental %>% 
  filter(date <= "2020-05-30") %>% 
  group_by(plot_number) %>% 
  reframe(soil_moisture = mean(soil_moisture),
          temperature = mean(temperature),
          vpd = mean(vpd))

growth_early_spring_data <- spring_height %>% 
  inner_join(plant_traits, by = "species") %>% 
  inner_join(environmental_earlyspring, by = "plot_number") %>% 
  select(growth, les_1, les_2, wood_density, wue, temperature, soil_moisture, vpd, planting_height)

early_spring_model <- early_drought %>% 
  filter(AICc == min(AICc, na.rm = TRUE)) %>%
  select(-c(X.Intercept., df, logLik, AICc, delta, weight, season)) %>%
  pivot_longer(cols = everything(), names_to = "variables", values_to = "coeficients") %>% 
  drop_na(coeficients) %>% 
  mutate(variables = str_replace(variables, "\\.", "*"))

independent_vars <-paste(early_spring_model$variables, collapse = " + ")

early_spring_model <- glm(as.formula(paste("growth ~", independent_vars)), 
                         data = growth_early_spring_data)
summary(early_spring_model)
save(early_spring_model, file = here("data", "models", "early_spring_growth_model.rda"))

summer_all <- read.csv(here("data", "models", "dredge_tables", "growth_summer_all_dredge_filtered.csv")) %>% 
  mutate(season = "summer_all")
summer <- read.csv(here("data", "models", "dredge_tables", "growth_late_summer_dredge_filtered.csv")) %>% 
  mutate(season = "summer")
fall <- read.csv(here("data", "models", "dredge_tables", "growth_fall_dredge_filtered.csv")) %>% 
  mutate(season = "fall")

late_drought <- rbind(summer_all, summer, fall) %>% 
  filter(AICc == min(AICc, na.rm = TRUE))
print(late_drought$season)

environmental_fall <- environmental %>% 
  filter(date > "2020-09-30") %>% 
  group_by(plot_number) %>% 
  reframe(soil_moisture = mean(soil_moisture),
          temperature = mean(temperature),
          vpd = mean(vpd))

growth_fall_data <- fall_height %>% 
  inner_join(plant_traits, by = "species") %>% 
  inner_join(environmental_fall, by = "plot_number") %>% 
  select(growth, les_1, les_2, wood_density, wue, temperature, soil_moisture, vpd, july_height)

fall_model <- late_drought %>% 
  select(-c(X.Intercept., df, logLik, AICc, delta, weight, season)) %>%
  pivot_longer(cols = everything(), names_to = "variables", values_to = "coeficients") %>% 
  drop_na(coeficients) %>% 
  mutate(variables = str_replace(variables, "\\.", "*"))

independent_vars_fall <-paste(fall_model$variables, collapse = " + ")

fall_model <- glm(as.formula(paste("growth ~", independent_vars_fall)), 
                         data = growth_fall_data)
summary(fall_model)
save(fall_model, file = here("data", "models", "fall_growth_model.rda"))
