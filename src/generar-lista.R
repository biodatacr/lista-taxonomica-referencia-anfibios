# This script processes an input checklist with species names and generates as outputs:
#
# 1. A checklist with cleaned species names FOUND in GBIF Backbone Taxonomy.
#    It also contains authors, taxonomy and other DwC fields from GBIF Backbone Taxonomy.
# 2. A checklist of species names NOT FOUND in GBIF Backbone Taxonomy.
# 3. A dataset with occurrences of species in output checklist of species names 
#    FOUND in GBIF Backbone Taxonomy.
#
# Checklists and occurrences dataset are generated with GBIF API and rgbif library.
# Checklists are directly generated by this script.
# Occurrences dataset is generated as a download request for the GBIF portal.


library(dplyr)
library(readr)
library(stringr)
library(stringi)
library(rgbif)


INPUT_CHECKLIST <- "data/interim/anfibios_2022.csv"
OUTPUT_CHECKLIST <- "data/processed/lista-taxonomica-referencia-anfibios.csv"
OUTPUT_NOTFOUND_CHECKLIST <- "data/processed/lista-taxonomica-referencia-anfibios-nombres-no-encontrados.csv"


# This function returns a binomial species name (genus + species)
# cleaned by removing unnecessary whitespaces, special characters
# and additional words of an input species name
get_cleaned_species_name <- function(species_name) {
  # Remove leading, trailing and extra internal whitespaces
  cleaned_species_name <- str_squish(species_name)
  
  # Get first two words
  cleaned_species_name <- word(cleaned_species_name, start=1, end=2, sep=fixed(" "))
  
  # Remove special characters
  cleaned_species_name <- str_replace_all(cleaned_species_name, "[^A-Za-z ]", "")
  
  # General text transformation
  cleaned_species_name <- stri_trans_general(cleaned_species_name, id = "Latin-ASCII")
  
  return(cleaned_species_name)
}

# MAIN PROCESSING

# Read CSV with input checklist into dataframe
input_checklist <- read_csv(INPUT_CHECKLIST)

# Clean species names in input checklist using the get_cleaned_species_name() function
# Cleaned species name is stored in the "name" column of the input_checklist dataframe
input_checklist <- 
  input_checklist |>
  mutate(name = get_cleaned_species_name(especie))

# Get upper taxonomy and other attributes of the cleaned species names
# using the rgbif::name_backbone_checklist() function
checklist <- 
  name_backbone_checklist(input_checklist)

# Get output checklist of names found in GBIF Backbone Taxonomy
output_checklist <- 
  checklist |>
  filter(!(matchType == "NONE" | matchType == "HIGHERRANK"))

# Get output checklist of names NOT found in GBIF Backbone Taxonomy
output_notfound_checklist <- 
  checklist |>
  filter(matchType == "NONE" | matchType == "HIGHERRANK")

# Export output checklist to CSV
write_csv(output_checklist, OUTPUT_CHECKLIST)

# Export checklist with not found names to CSV
write_csv(output_notfound_checklist, OUTPUT_NOTFOUND_CHECKLIST)

# Get taxon keys of output checklist
taxon_keys <- 
  output_checklist |>
  pull(usageKey)

# Create download request of occurrences dataset in GBIF API
# Note: environment variables GBIF_USER, GBIF_PWD and GBIF_EMAIL need to be defined
# The dowloaded dataset is stored in 
# data/processed/lista-taxonomica-referencia-mammalia-cr-registros.csv
occ_download(
  pred_in("taxonKey", taxon_keys),
  pred("country", "CR"),
  pred("hasCoordinate", TRUE),
  pred("hasGeospatialIssue", FALSE),
  format = "SIMPLE_CSV"
)