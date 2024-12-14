import pandas as pd
import geopandas as gpd
import os
from helpers import load_all_bbls

all_bbls = load_all_bbls()

subsidized_raw = pd.read_csv(os.path.join('data', 'FC_SHD_bbl_analysis_2023-05-14.csv'), dtype={'bbl': str})

subsidized = subsidized_raw[
    subsidized_raw[['data_hpd', 'data_hcrlihtc', 'data_hpdlihtc', 'data_hudcon', 'data_hudfin', 'data_ml', 'data_nycha']].any(axis=1)
].drop_duplicates(subset=['bbl']).assign(is_subsidized=True)

all_bbls_eligibility = all_bbls.merge(subsidized[['bbl', 'is_subsidized']], on='bbl', how='left').fillna({'is_subsidized': False})

gce_bbls = all_bbls_eligibility[
    (all_bbls_eligibility['eligible_bbl_units']) &
    (all_bbls_eligibility['eligible_year']) &
    (all_bbls_eligibility['eligible_bldgclass']) &
    (all_bbls_eligibility['eligible_rentstab']) &
    (all_bbls_eligibility['eligible_nycha']) &
    (~all_bbls_eligibility['is_subsidized'])
].assign(wow_link=lambda df: df['bbl'].apply(lambda bbl: f"https://whoownswhat.justfix.org/bbl/{bbl}"))

gce_bbls_selected = gce_bbls[[
    'bbl', 'address', 'borough', 'unitsres', 'rs_units', 'yearbuilt', 'bldgclass', 'ownername', 'wow_link', 'latitude', 'longitude'
]]

# Save to CSV
all_bbls_eligibility.to_csv(os.path.join('data', 'all-bbls-eligibility_2024-06-24.csv'), index=False, na_rep='')
gce_bbls_selected.to_csv(os.path.join('data', 'likely-gce-bbls_2024-06-24.csv'), index=False, na_rep='')

# Convert to GeoDataFrame and save as GeoJSON
gce_bbls_gdf = gpd.GeoDataFrame(
    gce_bbls_selected.dropna(subset=['latitude', 'longitude']),
    geometry=gpd.points_from_xy(gce_bbls_selected.dropna(subset=['latitude', 'longitude'])['longitude'], gce_bbls_selected['latitude']),
    crs="EPSG:4326"
)[['bbl', 'address', 'borough', 'unitsres', 'yearbuilt']].rename(columns={'unitsres': 'units', 'yearbuilt': 'year_built'})

gce_bbls_gdf.to_file(os.path.join('data', 'gce-bbls.geojson'), driver='GeoJSON')
