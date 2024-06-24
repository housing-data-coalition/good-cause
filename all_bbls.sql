SELECT 
	p.bbl,
	p.address,
	p.borough,
	p.unitsres,
	p.yearbuilt,
	p.bldgclass,
	
	coalesce(nullif(r.uc2022, 0), nullif(r.uc2021, 0), nullif(r.uc2020, 0), nullif(r.uc2019, 0), 0) as rs_units,
	
	(nycha.bbl IS NOT NULL) AS is_nycha,
	
	p.yearbuilt IS NOT NULL AND p.yearbuilt < 2009 as eligible_year,
	
	p.unitsres > 10 AS eligible_bbl_units,
	
	(
		nullif(p.bldgclass, '') IS NOT NULL
		AND p.bldgclass !~*'^R' 
		AND p.bldgclass NOT IN ('C8', 'CC', 'D0', 'DC', 'R9')
	) as eligible_bldgclass,
	
	coalesce(
		nullif(r.uc2022, 0), 
		nullif(r.uc2021, 0), 
		nullif(r.uc2020, 0), 
		nullif(r.uc2019, 0), 0) = 0 AS eligible_rentstab,
		
	(nycha.bbl IS NULL) AS eligible_nycha
	
FROM pluto_latest AS p
LEFT JOIN rentstab_v2 AS r ON p.bbl = r.ucbbl
LEFT JOIN nycha_bbls_18 AS nycha USING(bbl)
  WHERE unitsres > 0