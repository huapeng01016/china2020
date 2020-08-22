/*
	http://gddata.gd.gov.cn/data/dataSet/toDataDetails/29000_01300008
*/
version 16

cscript

frame create fileinfo str500 file long(date rows cols) str2000 header 
frame fileinfo : format %td date


local files : dir "../data/广东数据" files "*.xlsx"
foreach file in `files' {
			qui import excel "../data/广东数据/`file'", clear
				
			/* find out the date */
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
			
			/* remove all uncessary row/cols vars */
			drop A
			drop in 1/2
			drop in 4
			
			/* remove all vars with all missing obs */
			qui desc
			local varno = `r(k)'
			qui ds
			local varlist = "`r(varlist)'"
			forval i=1/`varno' {
				local var : word `i' of `varlist'
				cap assert `var' >= .
				if _rc == 0 {
					qui drop `var'
				}
			}
			
			/* get header */
			/* data starts at obs 4*/			
			qui desc			
			local varno = `r(k)'
			local obsno = `r(N)'
			qui ds
			local varlist = "`r(varlist)'"

			local header = ""
			forval obs = 1/3 {
				forval i=1/`varno' {
					local varname : word `i' of `varlist'
					local header = "`header'" + "`obs'" + strtrim(`varname'[`obs'])	
				}
			}
			
			qui frame post fileinfo ("`file'") (`date') (`obsno') (`varno') ("`header'")		
}

frame fileinfo : save ../data/fileinfo.dta, replace

use ../data/fileinfo.dta, clear
sort cols rows header
qui by cols rows header : keep if _n==1
qui desc
assert r(N) == 1

/* now all is well, import data */
use ../data/fileinfo.dta, clear
qui desc
local obsno = `r(N)'

clear
set obs 0
gen int date = 0
format %td date
gen str20 地市 = ""
gen int 确诊病例_累计 = 0
gen int 确诊病例_境外输入 = 0
gen int 确诊病例_境内 = 0
gen int 在院病例_新增 = 0
gen int 在院病例_在院总数 = 0
gen int 在院病例_危重重症 = 0

save ../data/广东数据.dta, replace

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

use ../data/广东数据.dta, clear
sort 地市 date 
save ../data/广东数据.dta, replace

exit
