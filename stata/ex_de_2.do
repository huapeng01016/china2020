cscript

local date = "01-29-2020"
import delimited "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_daily_reports/`date'.csv", ///
	encoding(utf-8) clear
describe
edit
