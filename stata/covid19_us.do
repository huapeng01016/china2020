/*
	usage :
		
		do covid19_us [ state(name) date(MM-DD-YYYY) show png]
		
		date default to current date minus one if date is not specified
		graph entire US if state is not specified
		save to html if show and png are not specificed
		save to png if show is not specificed and png is specified
*/

version 16

cscript

local 0 ",`0'"
di "`0'"

syntax [anything] , [state(string asis) date(string asis) png(string asis) show]

if "`date'" == "" {
	local td = date(c(current_date), "DMY") - 1
	local date : di %tdNN-DD-CCYY `td'	
}

import delimited "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_daily_reports/`date'.csv", ///
	encoding(utf-8) clear
		
capture confirm variable country_region
if _rc > 0 {
	capture confirm variable countryregion
	if _rc > 0 {
di as error "variable countr_region or countryregion required" 		
exit 198	
	}
	
	rename countryregion country_region
}
	
keep if country_region == "US"	

capture confirm variable fips
if _rc > 0 {
di as error "variable fips required" 		
exit 198
}

if "`state'" != "" {
	keep if province_state == "`state'"
}

keep fips country_region combined_key confirmed	
export delimited "_confirmed_`state'_`date'.csv", replace 

if "`state'" == "" {
		local state = "us"
}

python:
import numpy as np
import pandas as pd
df = pd.read_csv("_confirmed_`state'_`date'.csv")

from urllib.request import urlopen
import numpy as np
import json
with urlopen('https://raw.githubusercontent.com/plotly/datasets/master/geojson-counties-fips.json') as response:
    counties = json.load(response)


import plotly.express as px
fig = px.choropleth(df, geojson=counties, locations='fips', 
						color='confirmed',
						hover_data=['combined_key', 'confirmed'],
						color_continuous_scale='ylorrd',
						range_color = [100, 5000],
						scope='usa',
						labels={
							'combined_key':'location',
							'confirmed':'confirmed cases'
						}
					)

from sfi import Macro
if Macro.getLocal('state'): 						  
	fig.update_geos(fitbounds="locations", visible=False)
	
fig.update_layout(margin={"r":0,"t":0,"l":0,"b":0})

if Macro.getLocal('show'): 						  
	fig.show()
elif Macro.getLocal('png'):
	fig.write_image("../output/`png'.png")
else: 
	fig.write_html("../output/`date'-`state'.html")
end
