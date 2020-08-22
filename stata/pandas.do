/*
	http://gddata.gd.gov.cn/data/dataSet/toDataDetails/29000_01300008
*/
version 16

cscript

python:
import pandas as pd
data = pd.read_html("https://www.cdc.gov/coronavirus/2019-ncov/covid-data/covidview/index.html")
df = data[4]
t = df.values.tolist()

from sfi import Data
Data.addObs(len(t))
stata: gen desc = ""
stata: gen indian = ""
stata: gen black = ""
stata: gen hisp = ""
stata: gen asian = ""
stata: gen white = ""
Data.store(None, range(len(t)), t)
end

format %10s desc
label var desc Description
label var indian "Non-Hispanic American Indian or Alaska Native"
label var black "Non-Hispanic Black"
label var hisp "Hispanic or Latino"
label var asian "Non-Hispanic Asian or Pacific Islander"
label var white "Non-Hispanic White"

* save ../data/covid_prop.dta, replace
list, clean
