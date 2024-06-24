library(dplyr)
library(readr)
library(stringr)
library(DBI)
library(RPostgres)
library(fs)
library(dotenv)


# NYCDB credentials pulled from hidden file
load_dot_env(".env")

con <- dbConnect(
  Postgres(),
  host= Sys.getenv("NYCDB_HOST"),
  port = Sys.getenv("NYCDB_PORT"),
  dbname = Sys.getenv("NYCDB_DBNAME"),
  user = Sys.getenv("NYCDB_USER"),
  password = Sys.getenv("NYCDB_PASSWORD")
)

# Good Cause Criteria -----------------------------------------------------

# https://housingjusticeforall.org/kyr-good-cause/



# All Properties with Eligibility Variables -------------------------------

# Gets all properties (BBLs) with residential units, along with columns for each
# element of good cause eligibility


all_bbls <- dbGetQuery(con, read_file("all_bbls.sql")) |> tibble()

# Furman Center's Subsidized Housing Database -----------------------------

# https://furmancenter.org/coredata/userguide/data-downloads

subsidized_raw <- read_csv(path("data", "FC_SHD_bbl_analysis_2023-05-14.csv"), col_types = cols(bbl="c"))

subsidized <- subsidized_raw |> 
  filter(data_hpd | data_hcrlihtc | data_hpdlihtc | data_hudcon | data_hudfin | data_ml | data_nycha) |> 
  distinct(bbl) |> 
  transmute(
    bbl, 
    is_subsidized = TRUE
  )

all_bbls_eligibilty <- all_bbls |> 
  left_join(subsidized, by = "bbl") |> 
  mutate(is_subsidized = coalesce(is_subsidized, FALSE))

gce_bbls <- all_bbls_eligibilty |> 
  filter(
    eligible_bbl_units,
    eligible_year,
    eligible_bldgclass, 
    eligible_rentstab,
    eligible_nycha,
    !is_subsidized
  ) |> 
  mutate(wow_link = str_glue("https://whoownswhat.justfix.org/bbl/{bbl}")) |> 
  select(
    bbl, address, borough,
    unitsres, rs_units, yearbuilt, bldgclass,
    wow_link
  )

write_csv(gce_bbls, path("data", "likely-gce-bbls_2024-06-24.csv"), na="")
