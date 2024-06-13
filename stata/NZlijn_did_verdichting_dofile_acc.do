capture log close
cd "D:\OneDrive\OneDrive - Objectvision\VU\Projects\202110-NZpaper\"
log using Temp/nzlijn_did_verdichting_log.txt, text replace

global filedate = 20240530
global acc_range = 30
global TAsize = 12
global CAsize = 24

///////////////////////////////////////
**# DATA PREPAREREN
///////////////////////////////////////

import delimited data/DiD_Verdichting_${acc_range}min_${TAsize}_${CAsize}min_${filedate}.csv, delimiter(";") clear   

save Temp\DMS_verdichting_raw.dta, replace
use Temp\DMS_verdichting_raw.dta, clear

drop x_coord y_coord nl_grid_domain_rel

local replaceNullList = "gemeente_rel buurt_rel"
foreach x of local replaceNullList{
	replace `x' = "" if `x' == "null"
	destring `x', replace
}

rename won2000 won2000
rename won2001 won2001
rename won2002 won2002
rename won2003 won2003
rename won2004 won2004
rename won2005 won2005
rename won2006 won2006
rename won2007 won2007
rename won2008 won2008
rename won2009 won2009
rename won2010 won2010
rename won2011 won2011
rename won2012p won2012
rename won2013 won2013
rename won2014 won2014
rename won2015 won2015
rename won2016 won2016
rename won2017 won2017
rename won2018 won2018
rename won2019 won2019
rename won2020 won2020
rename won2021 won2021
rename won2022 won2022

g ever_inhabited = 0
replace ever_inhabited = 1 if won2000 > 0
replace ever_inhabited = 1 if won2001 > 0
replace ever_inhabited = 1 if won2002 > 0
replace ever_inhabited = 1 if won2003 > 0
replace ever_inhabited = 1 if won2004 > 0
replace ever_inhabited = 1 if won2005 > 0
replace ever_inhabited = 1 if won2006 > 0
replace ever_inhabited = 1 if won2007 > 0
replace ever_inhabited = 1 if won2008 > 0
replace ever_inhabited = 1 if won2009 > 0
replace ever_inhabited = 1 if won2010 > 0
replace ever_inhabited = 1 if won2011 > 0
replace ever_inhabited = 1 if won2012 > 0
replace ever_inhabited = 1 if won2013 > 0
replace ever_inhabited = 1 if won2014 > 0
replace ever_inhabited = 1 if won2015 > 0
replace ever_inhabited = 1 if won2016 > 0
replace ever_inhabited = 1 if won2017 > 0
replace ever_inhabited = 1 if won2018 > 0
replace ever_inhabited = 1 if won2019 > 0
replace ever_inhabited = 1 if won2020 > 0
replace ever_inhabited = 1 if won2021 > 0
replace ever_inhabited = 1 if won2022 > 0

reshape long won, i(id) j(year)

save Temp/DMS_verdichting_reshaped.dta, replace
use Temp/DMS_verdichting_reshaped.dta, clear

drop amsterdam_rel
g amsterdam_rel = 0
replace amsterdam_rel = 1 if gemeente_name == "'Amsterdam'"

drop if amsterdam_rel ==  0
drop if ever_inhabited == 0

rename station_stationcentraal_reistijd station_centraal_reistijd
rename station_depijp_reistijds station_depijp_reistijds
rename station_stationzuid_reistijds station_zuid_reistijds

g lnwon = ln(won)

local stations "noord noorderpark centraal rokin vijzelgracht depijp europaplein zuid"
foreach s of local stations{ 
	g tt_`s'_min = station_`s'_reistijd / 60
}



save "temp/DMS_did_verdichting_base.dta", replace



///////////////////////////////////////
**# /////REGRESSIES
///////////////////////////////////////
use "temp/DMS_did_verdichting_base.dta", clear

g trans_year_month = string(year) + "/01"
g trans_date = date(trans_year_month, "YM")

g all_ta = 0
g all_ca = 0
local stations "noord noorderpark centraal rokin vijzelgracht depijp europaplein zuid"
foreach s of local stations{ 
	replace all_ta = 1 if `s'_ta == 1
	replace all_ca = 1 if `s'_ca == 1
}

local stations "noord noorderpark centraal rokin vijzelgracht depijp europaplein zuid all"
foreach s of local stations{ 
	local dates "22042003 01082009 08072016 21072018"
	foreach d of local dates{
		g treated = `s'_ta
		g treattime = trans_date >= td(`d')
		g did = treattime * treated
		
		g ca = `s'_ca + `s'_ta
		
		
		areg lnwon treated treattime did i.year if ca == 1, r absorb(buurt_rel)
		outreg2 using output/verdichting/did_windows_indiv_AccBased_${acc_range}min_buurt_${TAsize}_${CAsize}min_${filedate}, excel cttop (`s', `d') label dec(3) addtext (Year FE, Yes, Neighbourhood FE, Yes) keep(treat* did*) 
		
		drop did* treated treattime* ca
	}
}


**# Bookmark #4

estpost sum won year diff_spits_abs tt_* 
esttab using output/sum_verdichting.rtf, cells("count(fmt(0)) mean(fmt(3)) sd(fmt(3)) min(fmt(0)) max(fmt(0))") label nomtitle nonumber replace











