#getting data from GBIF
library(rgbif)
library(sf)
library(tidyverse)


myspecies <- c("Aporia crataegi")
mycountry <- c("GB")
# download GBIF occurrence data for this species; this takes time if there are many data points!
gbif_data <- occ_data(scientificName = myspecies, hasCoordinate = TRUE, country=mycountry)
#This has not data from OUNHM, perhaps add that for more info.
#gbif_data
# get the DOIs for citing these data properly:
#gbif_citation(gbif_data)
names(gbif_data$data)

myspecies_coords <- gbif_data$data[ , c("decimalLongitude", "decimalLatitude", "individualCount", 
                                        "occurrenceStatus", "coordinateUncertaintyInMeters", "institutionCode", 
                                        "references", "year", "county", "eventDate")]
#filter out years after 1925
myspecies_coords <- myspecies_coords %>% filter(year >1925)
#get records after 1925
#myspecies_coords1925 <- myspecies_coords %>% filter(!is.na(year))
#replace na occurrences with 1 - at least one seen
myspecies_coords <- myspecies_coords %>% mutate_at(vars(individualCount), ~replace_na(., 1))
#myspecies_coords1925 <- myspecies_coords1925 %>% mutate_at(vars(individualCount), ~replace_na(., 1))
# Convert to simple feature object
point_sf <- st_as_sf(myspecies_coords, coords = c("decimalLongitude", "decimalLatitude"), crs = 4326)
#point_sf1925 <- st_as_sf(myspecies_coords1925, coords = c("decimalLongitude", "decimalLatitude"), crs = 4326)
#get geojson data with polygons for administative boundaries
# Geospatial data available at the geojson format

download.file(
  "https://raw.githubusercontent.com/martinjc/UK-GeoJSON/master/json/administrative/gb/lad.json",
  destfile = "../public/data/lad.json"
)

#also download the topo file, this might be rquired for bounds
download.file(
  "https://raw.githubusercontent.com/martinjc/UK-GeoJSON/master/json/administrative/gb/topo_lad.json",
  destfile = "../public/data/topo_lad.json"
)


my_sf <- read_sf( "../public/data/lad.json")

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
Occ <- my_df %>% select(c(LAD13CD, LAD13NM, Count))
Occ$year <- myspecies_coords$year
#filter any zero records
#Occ <- Occ %>% filter(Count > 0)
#write to csv
write_csv(Occ, "../public/data/data_occ.csv")

