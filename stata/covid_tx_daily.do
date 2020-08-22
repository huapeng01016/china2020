version 16

cscript

local start =  date("05/07/2020", "MDY")
local end = date(c(current_date), "DMY") - 1

forval i = `start'/`end' {
    local date : di %tdNN-DD-CCYY `i'
	local j = `i' - `start'
    do covid19_us state(Texas) date(`date') png(t`j')
}

