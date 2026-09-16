library(here)
library(tidyverse)
library(survival)

spring <- read.csv(here("data", "models", "dredge_tables", "spring_all_dredge_filtered.csv"))
early_spring <- read.csv(here("data", "models", "dredge_tables", "early_spring_dredge_filtered.csv"))
late_spring <- read.csv(here("data", "models", "dredge_tables", "late_spring_dredge_filtered.csv"))

spring$AICc
early_spring$AICc
late_spring$AICc

plant_traits <- read.csv(here("data", "clean_data", "cox_plant_traits.csv")) %>% 
  mutate(les_1 = scale(les_1)[,1],
         les_2 = scale(les_2)[,1]* -1,
         wood_density = scale(wood_density)[,1],
         wue = scale(wue)[,1],
         wue = wue*-1)

environmental <- read.csv(here("data", "clean_data", "predicted_environmental.csv")) %>% 
  mutate(date = ymd(date)) %>% 
  group_by(date) %>% 
  mutate(temperature = scale(temperature)[,1],
         vpd = scale(vpd)[,1]) %>% 
  ungroup()

height <- read.csv(here("data", "clean_data", "height_gopher_kapplin.csv"))%>%
   mutate(alive = case_when(dead == 1 ~ 0,
                           dead == 0 ~ 1)) %>% 
  mutate(start_date = ymd(start_date),
         end_date = ymd(end_date),
         height = scale(height)[,1])

height_environment_trait<- height %>% 
  left_join(environmental, by = "plot_number", multiple = "all") %>% 
  rename(species = Plant) %>% 
  left_join(plant_traits, by = "species")

cox_early_spring <- height_environment_trait %>% 
  filter(species != "HEWH") %>% 
  filter(date <= "2020-05-30" & end_date <= "2020-06-26") %>% 
  group_by(plot_number) %>%
  reframe(start_time = mean(start_time), 
          end_time = mean(end_time), 
          dead = mean(dead), 
          soil_moisture = mean(soil_moisture), 
          temperature = mean(temperature), 
          vpd = mean(vpd), 
          les_1 = mean(les_1), 
          les_2 = mean(les_2), 
          wood_density = mean(wood_density), 
          wue = mean(wue), 
          height = mean(height)) |> 
            drop_na()

early_spring_model <- early_spring %>% 
  select(-c(X.Intercept., df, logLik, AICc, delta, weight)) %>%
  pivot_longer(cols = everything(), names_to = "variables", values_to = "coeficients") %>% 
  drop_na(coeficients) %>% 
  mutate(variables = str_replace(variables, "\\.", "*"))

independent_vars <-paste(early_spring_model$variables, collapse = " + ")

early_spring_model <- coxph(as.formula(paste("survival::Surv(end_time, dead) ~", independent_vars)), 
      data = cox_early_spring, x = TRUE, y = TRUE, model = TRUE)

save(early_spring_model, file =here("data", "models", "early_spring_model.rds"))

summer_all <- read.csv(here("data", "models", "dredge_tables", "summer_all_dredge_filtered.csv"))
summer <- read.csv(here("data", "models", "dredge_tables", "summer_dredge_filtered.csv"))
fall <- read.csv(here("data", "models", "dredge_tables", "fall_dredge_filtered.csv"))

summer_all$AICc
summer$AICc
fall$AICc

cox_summer <- height_environment_trait %>% 
  filter(species != "HEWH") %>% 
  filter(end_date > "2020-06-26") %>% 
  filter(date >= start_date & date <= "2020-09-30") %>% 
  group_by(plot_number) %>%
  reframe(start_time = mean(start_time), 
          end_time = mean(end_time), 
          dead = mean(dead), 
          soil_moisture = mean(soil_moisture), 
          temperature = mean(temperature), 
          vpd = mean(vpd), 
          les_1 = mean(les_1), 
          les_2 = mean(les_2), 
          wood_density = mean(wood_density), 
          wue = mean(wue), 
          height = mean(height)) |> 
            drop_na()

summer_model <- summer %>% 
  select(-c(X.Intercept., df, logLik, AICc, delta, weight)) %>%
  pivot_longer(cols = everything(), names_to = "variables", values_to = "coeficients") %>% 
  drop_na(coeficients) %>% 
  mutate(variables = str_replace(variables, "\\.", "*"))

independent_vars_summer <-paste(summer_model$variables, collapse = " + ")

summer_model <- coxph(as.formula(paste("survival::Surv(end_time, dead) ~", independent_vars_summer)), 
      data = cox_summer, x = TRUE, y = TRUE, model = TRUE)

save(summer_model, file =here("data", "models", "summer_model.rds"))
