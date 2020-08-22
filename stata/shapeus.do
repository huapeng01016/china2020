version 15

cscript

spshape2dta ../data/cb_2018_us_county_500k/cb_2018_us_county_500k.shp,  saving(../data/usacounties) replace
use ../data/usacounties.dta, clear
generate fips = real(GEOID)
save ../data/usacounties.dta, replace
