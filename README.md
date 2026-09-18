# Piru Habitat Suitability

Code and data accompanying:

> Dewees, S., Saglimbeni, C., Anderegg, L., Molinari, N., & D'Antonio, C.
> **Plant functional traits explain survival, growth and environmental responses
> in an arid shrubland restoration study.** *Ecological Applications* 2026.

**DOI:** https://doi.org/10.5281/zenodo.22836904
**Repository:** https://github.com/sdewees0523/Piru_Habitat_Suitability
**Contact:** Shane Dewees, University of California, Santa Barbara — sdewees@ucsb.edu

---

## Overview

This repository contains the full analysis pipeline for a shrubland restoration
study near Piru, California (Los Padres National Forest), examining how leaf
economic and hydraulic traits of ten chaparral and coastal sage scrub species
relate to their survival, growth, and microclimate responses across a
topographically variable planting landscape.

The pipeline:

1. Builds fine-scale topographic and microclimate layers for the site,
2. Cleans field-collected survival, growth, and plant-trait data,
3. Fits random forests to predict daily soil moisture, temperature, and vapor
   pressure deficit (VPD) at every planting location,
4. Reduces nine leaf traits to a leaf economic spectrum (LES) via PCA,
5. Uses `MuMIn::dredge()` multi-model selection to identify which
   trait × environment interactions best explain Cox proportional-hazards
   survival models and linear growth models, across several candidate time
   windows, and
6. Produces all manuscript figures and tables from those fitted models.
## Repository structure

```
├── 1.1–1.8   Topographic, environmental, survival/growth, and trait data
│             cleaning; environmental random forests; trait PCA
├── 2.1–2.4   Survival curves, hazard ratios, and MuMIn::dredge() model
│             selection for the trait/environment survival and growth models
├── 2.3.1, 2.4.1   Builds the final survival/growth models from the selected
│             dredge candidates (see "Model selection" below)
├── 3.1–3.5   All manuscript and appendix figures
├── data/
│   ├── raw_data/      As collected; not modified by any script
│   ├── clean_data/    Written by 1.1–1.8; read by everything downstream
│   └── models/        Fitted model objects and dredge selection tables
├── figures/    Manuscript and appendix figures
```

## Running the pipeline

Scripts are numbered in run order. `1.1`–`1.8` must run in sequence (each
writes files the next one reads); `2.1`–`2.4` and `3.1`–`3.5` depend on the
`1.x` outputs but not on each other in most cases, other than `2.3`/`2.4`
feeding `2.3.1`/`2.4.1`, and `3.x` scripts reading the final model objects.

| Order | Script | Produces |
|---|---|---|
| 1 | `1.1_topography_variable_creation.Rmd` | Topographic rasters (elevation, aspect, slope, heat load, TPI, TRI, etc.) |
| 2 | `1.2_survival_height_data_cleaning.Rmd` | Cleaned survival and height/growth census data |
| 3 | `1.3_environmental_data_cleaning.Rmd` | Cleaned soil moisture, temperature, and humidity logger data |
| 4 | `1.4_landscape_environmental_modeling.Rmd` | Random forests predicting daily soil moisture/temperature/VPD; `predicted_environmental.csv` |
| 5 | `1.5_environmental_models_pdps.qmd` | Partial dependence plots for the environmental random forests (Appendix S2) |
| 6 | `1.6_landscape_region_creation.qmd` | Four-way landscape classification (favorable/unfavorable soil moisture × VPD) used in Figure 7 |
| 7 | `1.7_plant_trait_cleaning.Rmd` | Species-level trait means (`plant_traits_clean.csv`) |
| 8 | `1.8_trait_pca.rmd` | Leaf economic spectrum PCA; `cox_plant_traits.csv` |
| 9 | `2.1_species_survival_curves.Rmd` | Species-level Kaplan-Meier survival curves (Figure 2) |
| 10 | `2.2_species_hazard_rates.Rmd` | Species-level hazard ratios |
| 11 | `2.3_trait_model_selection.Rmd` | `MuMIn::dredge()` selection over trait × environment survival models, across candidate time windows; writes filtered dredge tables to `data/models/dredge_tables/` |
| 12 | `2.3.1_trait_model_creation.R` | Builds the final Cox models from the selected dredge candidates; saves `early_spring_model.rds`, `summer_model.rds` |
| 13 | `2.4_growth_model_selection.Rmd` | Same dredge selection process for the growth (height increment) models |
| 14 | `2.4.1_growth_model_creation.R` | Builds the final growth models; saves `late_spring_growth_model.rda`, `late_summer_growth_model.rda` |
| 15 | `3.1_weather_station_graph.Rmd` | Weather station figure (Appendix S1) |
| 16 | `3.2_trait_pca_graph.Rmd` | Trait PCA biplot (Appendix S3) |
| 17 | `3.3_trait_model_visualizations.Rmd` | Survival model partial dependence plots (Figures 3–4) |
| 18 | `3.4_growth_model_visualizations.Rmd` | Growth model partial dependence plots (Figures 5–6) |
| 19 | `3.5_topography_survival_pca_visualization.Rmd` | Trait × topography landscape matching (Figure 7) |

### Model selection

For both survival (`2.3`) and growth (`2.4`), a global model with all
trait × environment interactions is fit for each of several candidate time
windows (e.g. planting→July, an early- and late-spring split of that same
window, and July→autumn similarly split), and `MuMIn::dredge()` performs
exhaustive model selection under marginality constraints across each. The
resulting candidate set is filtered to models within 2 AICc units of the top
model, then to the model(s) with the fewest parameters among those; the
filtered table is written to `data/models/dredge_tables/`.

`2.3.1` and `2.4.1` then read those filtered tables and build the final model
formula programmatically from the surviving (non-`NA`) terms, rather than
retyping a formula by hand — so the fitted model and the dredge output stay
in sync by construction.

## Notes on figures

Figures produced by a script are listed in the run-order table above and
`ggsave()`d directly to `figures/`. **Figure 1** (site map) and the
topographic basemap layer under **Figure 7** are assembled in GIS software
from `data/clean_data/hillshade` and are not scripted here.

## Data

See `data/raw_data/` and `data/clean_data/` for the underlying data, and the
Appendices for full field and lab methods. Column-level documentation for
every file is provided in `data/metadata.txt`.

Note that `data/clean_data/predicted_environmental.csv` mixes units across
columns (a within-date z-score for soil moisture; °F for temperature; kPa for
VPD) because it is a direct random forest output — all three are
subsequently re-standardized within date before entering the survival and
growth models in `2.3`/`2.4`.

## Software

Analyses were run in R (version 4.5.2)

Model selection in `2.3`/`2.4` uses parallel cluster workers via `snow`; on a
machine with fewer cores this will take proportionally longer. The
`MuMIn::dredge()` calls are the most computationally expensive step in the
pipeline.

## Citation

If you use this code or data, please cite the associated publication (full
citation to be finalized upon publication) and this repository's Zenodo DOI.

## License

MIT License

Copyright (c) 2026 Shane Dewees

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
