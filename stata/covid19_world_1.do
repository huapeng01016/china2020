version 16

cscript

local date = "01-29-2020"
import delimited "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_daily_reports/`date'.csv", ///
	encoding(utf-8) clear

capture confirm variable country_region
if _rc > 0 {
	capture confirm variable countryregion
	if _rc > 0 {
di as error "variable countr_region or countryregion required" 		
	}
	
	rename countryregion country_region
}
	
keep country_region confirmed	
sort country_region
by country_region : gen confirmed_total = sum(confirmed)
by country_region : keep if _n == _N

keep country_region confirmed_total
export delimited _confirmed_world_`date'.csv, replace 

_pctile confirmed_total, percentiles(25 75)
local r25 = int(r(r1)) 
local r75 = int(r(r2)) 

python:
import numpy as np
import pandas as pd
df = pd.read_csv("_confirmed_world_`date'.csv")
df.head()
end

python:
from urllib.request import urlopen
import numpy as np
import json
with urlopen('https://raw.githubusercontent.com/plotly/datasets/master/geojson-counties-fips.json') as response:
    counties = json.load(response)


import plotly.express as px
fig = px.choropleth(df, geojson=counties, locations='country_region', 
						locationmode='country names',
						color='confirmed_total',
						hover_data=['country_region', 'confirmed_total'],
						color_continuous_scale='ylorrd',
						range_color = [`r25', `r75'],
						scope="world",
						labels={
							'country_region':'country region',
							'confirmed_total':'confirmed cases'
						}
					)


fig.update_layout(margin={"r":0,"t":0,"l":0,"b":0})
fig.show()
# fig.write_html("../output/`date'-world.html")
end

cap erase _confirmed_world_`date'.csv
