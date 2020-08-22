# 使用Stata获取与处理数据

##  [Hua Peng@StataCorp][hpeng]
### 2020 Stata 中国用户大会
### [https://huapeng01016.gitee.io/china2020/](https://huapeng01016.gitee.io/china2020/index.html)


# 数据的获取

## **import delimited**
````
<<dd_do>>
local date = "08-10-2020"
import delimited "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_daily_reports/`date'.csv", clear
describe
<</dd_do>>
````

## **import excel**

````
<<dd_do>>
import excel "./data/广东数据/广东省新冠肺炎疫情基本情况统计表_1595314944557.xlsx", clear
describe
<</dd_do>>
````

## **import spss**

````
<<dd_do>>
import spss using "./data/manipulate.sav", clear
list in 1/5
<</dd_do>>
````

## **import sas**

````
<<dd_do>>
import sas using "./data/psam_p30.sas7bdat", clear
describe
<</dd_do>>
````

## get data from pandas using **sfi**
````
<<dd_do>>
python:
import pandas as pd
data = pd.read_html("https://www.cdc.gov/coronavirus/2019-ncov/covid-data/covidview/index.html")
df = data[4]
df.head()
t = df.values.tolist()
end
<</dd_do>>
````

## 生成Stata dataset
<<dd_do: quietly>>
clear
quietly python:
from sfi import Data
Data.addObs(len(t))
stata: gen desc = ""
stata: gen indian = ""
stata: gen balck = ""
stata: gen hisp = ""
stata: gen asian = ""
stata: gen white = ""
Data.store(None, range(len(t)), t)
end
<</dd_do>>

````
clear
quietly python:
from sfi import Data
Data.addObs(len(t))
stata: gen desc = ""
stata: gen indian = ""
stata: gen balck = ""
stata: gen hisp = ""
stata: gen asian = ""
stata: gen white = ""
Data.store(None, range(len(t)), t)
end

<<dd_do>>
list, clean string(22)
<</dd_do>>
````

# Covid-19数据的获取与显示

## Covid-19数据
```
<<dd_do>>
local date = "07-30-2020"
import delimited "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_daily_reports/`date'.csv", clear
save ./data/covid_`date'.dta, replace
desc
<</dd_do>>
```

## 获得与生成US county shape data
````
cd data
copy https://www2.census.gov/geo/tiger/GENZ2018/shp/cb_2018_us_county_500k.zip ///
	cb_2018_us_county_500k.zip
unzipfile cb_2018_us_county_500k.zip

spshape2dta ./cb_2018_us_county_500k/cb_2018_us_county_500k.shp, 	/// 
	saving(usacounties) replace
use usacounties.dta, clear
generate fips = real(GEOID)
save usacounties.dta, replace
cd ..
````

<<dd_do:quietly>>
use ./data/usacounties.dta, clear
<</dd_do>>

## US county数据

```
<<dd_do>>
desc
list in 1/5
<</dd_do>>
```

## 人口数据
```
<<dd_do>>
import delimited https://www2.census.gov/programs-surveys/popest/datasets/2010-2019/counties/totals/co-est2019-alldata.csv, clear

generate fips = state*1000 + county
desc
* save ./data/census_popn.dta, replace
<</dd_do>>
```

## **merge**　数据
```
use ./data/covid_`date'.dta, clear
drop if fips >= .
merge 1:1 fips using data/usacounties.dta
keep if _merge == 3
drop _merge

merge 1:1 fips using data/census_popn

generate confirmed_adj = 100000*(confirmed/popestimate2019)
label var confirmed_adj "Cases per 100,000"
format %16.0fc confirmed_adj
```

## **grmap** 显示数据
```
grmap, activate
drop if province_state == "Alaska" | province_state == "Hawaii" | _ID >= .
spset, modify shpfile(usacounties_shp)
grmap confirmed_adj, clnumber(7)
```

## **grmap**结果

![covid19 map](./output/covid_map.svg)


# 使用Python获取与显示数据

## [World数据](./stata/covid19_world.do) 

```
local date = "07-29-2020"
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
```


## [数据改进](./stata/covid19_world_1.do) 

````
_pctile confirmed_total, percentiles(25 75)
local r25 = int(r(r1)) 
local r75 = int(r(r2)) 
````

## 显示World数据
```
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
# fig.write_html("test.html")
fig.show()
end
```

## World结果 

* [01-29-2020](./output/01-29-2020-world.html)
* [07-29-2020](./output/07-29-2020-world.html)

## 在[do-file](./stata/covid19_us.do)中使用参数 

````
local 0 ",`0'"
di "`0'"

syntax [anything] , [state(string asis) date(string asis) png(string asis) show]
````

## Stata中的日期

```
<<dd_do>>

display %td 0
display %td 0
display %tdDD/NN/CCYY 0

local year = 2020
local month = 7
local day = 30

local td = date("`month'/`day'/`year'", "MDY")
display `td'
display %td `td'
 
<</dd_do>>
```


# 美国数据

## 使用Python
````
<<dd_do>>
local date = "07-30-2020"
python:
import pandas as pd
import numpy as np
df = pd.read_csv("https://raw.githubusercontent.com/"\
	"CSSEGISandData/COVID-19/master/csse_covid_19_data/"\
	"csse_covid_19_daily_reports/`date'.csv",\
	dtype={"fips" : np.int32})
df.columns = df.columns.str.lower()
df = df.loc[df['country_region'] == "US"]
df.head()
end
<</dd_do>>
````

## 使用**plotly**显示数据
~~~~
python:
from urllib.request import urlopen
import numpy as np
import json
with urlopen("https://raw.githubusercontent.com/"\
	"plotly/datasets/master/geojson-counties-fips.json") as response:
	counties = json.load(response)

import pandas as pd
df = pd.read_csv("https://raw.githubusercontent.com/"\
	"CSSEGISandData/COVID-19/master/csse_covid_19_data/"\
	"csse_covid_19_daily_reports/`date'.csv",\
	dtype={"fips" : np.int32})
df.columns = df.columns.str.lower()
df = df.loc[df['country_region'] == "US"]
import plotly.express as px
fig = px.choropleth(df, geojson=counties, locations='fips', 
						color='confirmed',
						hover_data=['combined_key', 'confirmed'],
						color_continuous_scale='Inferno',
						range_color = [100, 5000],
						scope="usa",
						labels={
							'combined_key':'localtion',
							'confirmed':'confirmed cases'
						}
					)
fig.update_layout(margin={"r":0,"t":0,"l":0,"b":0})
fig.show()
# fig.write_html("./output/`date'-`state'.html")
end
~~~~

## US结果

* [07-30-2020](./output/07-30-2020-.html)
* [07-30-2020 New York](./output/07-30-2020-New York.html)
* [07-30-2020 Texas](./output/07-30-2020-Texas.html)

## 使用人口数据调整病例数

~~~~
<<dd_do>>
local date = "07-30-2020"

import delimited https://www2.census.gov/programs-surveys/popest/datasets/2010-2019/counties/totals/co-est2019-alldata.csv, clear
generate fips = state*1000 + county
save data/census_popn.dta, replace
import delimited "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_daily_reports/`date'.csv", clear
merge m:1 fips using data/census_popn.dta
keep if _merge==3
drop _merge
generate confirmed_adj = 100000*(confirmed/popestimate2019)
list combined_key confirmed_adj in 1/5

save data/covid19_pop_adj.dta, replace
<</dd_do>>
end
~~~~

## [显示人口数据调整病例数do-file](./stata/covid19_adj.do)

* [07-30-2020](./output/07-30-2020-_adj.html)
* [07-30-2020 New York](./output/07-30-2020-New York_adj.html)
* [07-30-2020 Texas](./output/07-30-2020-Texas_adj.html)


## 生成动画

```
version 16

cscript

local start =  date("04/01/2020", "MDY")
local end = date(c(current_date), "DMY") - 1

forval i = `start'/`end' {
	local date : di %tdNN-DD-CCYY `i'
	local j = `i' - `start'
	do covid19_us state(Texas) date(`date') png(t`j')
}

local count = `end' - `start'

python:
import imageio as io

with io.get_writer('../output/texas.gif', mode='I', duration=0.5) as writer:
	for i in range(0, `count', 1):
		image = io.imread("../output/t"+str(i)+".png")
		writer.append_data(image)
writer.close()
end
```

## Texas结果

![texas.gif](./output/texas.gif)


# 广东Covid-19数据

## Excel文件的格式问题

````
<<dd_do>>
import excel "./data/广东数据/广东省新冠肺炎疫情基本情况统计表_1595314944557.xlsx", clear
list in 1/5
<</dd_do>>
````

## 列举文件
```
local files : dir "./广东数据" files "*.xlsx"
foreach file in `files' {
		qui import excel "./广东数据/`file'", clear
		/* other steps */
}
```

## 中文日期

````
if ustrword(A[2], 4) == "年" {
	local year = ustrword(A[2], 3)	
}

if ustrword(A[2], 6) == "月" {
	local month = ustrword(A[2], 5)	
}

if ustrword(A[2], 8) == "日" {
	local day = ustrword(A[2], 7)	
}

if "`year'" == "" | "`month'" == "" | "`day'" == "" {
di as error "can not find date!"
exit 198
}

local date = date("`month'-`day'-`year'", "MDY")
````

## 遍历每个变量

```
ds
local varlist = "`r(varlist)'"
forval i=1/`varno' {
	local var : word `i' of `varlist'
	cap assert `var' >= .
	if _rc == 0 {
		qui drop `var'
	}
}
```

## 完整[do-file](./stata/广东数据.do)
```
quietly forval i=1/`obsno' {
	use ../data/fileinfo.dta, clear
	local date = date[`i']
	local file = file[`i']

	import excel "../data/广东数据/`file'", cellrange(B7:H27) clear
	gen int date =	`date'
	format %td date
	rename B 地市
	rename C 确诊病例_累计
	rename D 确诊病例_境外输入
	rename E 确诊病例_境内
	rename F 在院病例_新增
	rename G 在院病例_在院总数
	rename H 在院病例_危重重症
	
	append using ../data/广东数据.dta
	save ../data/广东数据.dta, replace
}
```

## 完整结果
```
<<dd_do>>
use ./data/广东数据.dta, clear
desc
list in 1/5
<</dd_do>>
```

# 谢谢!

# Post-credits...

- [import data][https://www.stata.com/manuals/dimport.pdf]
- [sfi details and examples][sfi]
- [Stata Python documentation][P python]
- The talk is made with [Stata markdown](https://www.stata.com/features/overview/markdown/) and [dynpandoc](https://ideas.repec.org/c/boc/bocode/s458455.html)
- [wordcloud do-file](./stata/words.do)


[hpeng]: hpeng@stata.com
[sfi]: https://www.stata.com/python/api16/
[P python]:https://www.stata.com/manuals/ppython.pdf

# TODO

* https://www.stata.com/training/webinar_series/covid-19/
