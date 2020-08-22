cscript

local date = "07-30-2020"
import delimited "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_daily_reports/`date'.csv", clear

drop if fips >= .

/* merge the files and calculate adjusted counts */
merge 1:1 fips using usacounties.dta
keep if _merge == 3
drop _merge

drop if fips >= .

/* mereg into census population data */
merge 1:1 fips using census_popn
*　keep if _merge == 3

generate confirmed_adj = 100000*(confirmed/popestimate2019)
label var confirmed_adj "Cases per 100,000"
format %16.0fc confirmed_adj

save covid19_adj, replace

grmap, activate
drop if province_state == "Alaska" | province_state == "Hawaii" | _ID >= .
spset, modify shpfile(usacounties_shp)
grmap confirmed_adj, clnumber(7)

graph export covid_map.svg, replace
