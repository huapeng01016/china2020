/* 
	Author: 	Hua Peng
	Date:		Jun 17, 2019
	Purpose:	Build reveal.js slides deck
*/

local path = ""
if "`c(os)'" == "MacOSX" {
	dynpandoc stdata.md, 	/// 
		sav(index.html)	/// 
		replace 	/// 
		to(revealjs) 	/// 
		path(/Users/hpeng01016/anaconda3/bin/pandoc)	///		
		pargs(-s --template=revealjs.html  	/// 
		--self-contained	/// 
		--section-divs	/// 
		--variable theme="stata"	/// 
		)
}
else {
	dynpandoc stdata.md, 	/// 
		sav(index.html)	/// 
		replace 	/// 
		to(revealjs) 	/// 
		pargs(-s --template=revealjs.html  	/// 
		--self-contained	/// 
		--section-divs	/// 
		--variable theme="stata"	/// 
		)
}

exit

