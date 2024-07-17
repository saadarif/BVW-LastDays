#getting data from GBIF
library(rgbif)
library(sf)
library(tidyverse)


myspecies <- c("Aporia crataegi")
# download GBIF occurrence data for this species; this takes time if there are many data points!
gbif_data <- occ_data(scientificName = myspecies, hasCoordinate = TRUE, country="GB")
gbif_data
# get the DOIs for citing these data properly:
gbif_citation(gbif_data)
names(gbif_data$data)

myspecies_coords <- gbif_data$data[ , c("decimalLongitude", "decimalLatitude", "individualCount", "occurrenceStatus", "coordinateUncertaintyInMeters", "institutionCode", "references", "year", "county")]
#filter out years after 1925
myspecies_coords <- myspecies_coords %>% filter(year < 1925)
#replace na occurences with 1 - at least one seen
myspecies_coords <- myspecies_coords %>% mutate_at(vars(individualCount), ~replace_na(., 1))
# Convert to simple feature object
point_sf <- st_as_sf(myspecies_coords, coords = c("decimalLongitude", "decimalLatitude"), crs = 4326)

#get geojson data with polygons for administative boundaries
# Geospatial data available at the geojson format
tmp_geojson <- tempfile(fileext = ".geojson")

download.file(
  "https://raw.githubusercontent.com/martinjc/UK-GeoJSON/master/json/administrative/gb/lad.json",
  tmp_geojson
)

my_sf <- read_sf(tmp_geojson)

# Use st_within
result <- st_within(point_sf, my_sf, sparse = FALSE)

# Calculate the total count of each polygon
# Store the result as a new column "Count" in world_sf
my_sf <- my_sf %>%
  mutate(Count = apply(result, 2, sum))

# Convert _sf to a data frame _df 
my_df <- my_sf
st_geometry(my_df) <- NULL
#creat data frame with only required columns
Occ <- data.frame(AREACD=my_df$LAD13CD, AREANM=my_df$LAD13NM, Count=my_df$Count)
#write to csv
write_csv(Occ, "../public/data/data_occ.csv")

