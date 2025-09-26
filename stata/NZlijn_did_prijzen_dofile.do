capture log close
cd "D:\OneDrive\OneDrive - Objectvision\VU\Projects\202110-NZpaper\" //LAPTOP
cd "C:\Users\Jip Claassens\OneDrive - Objectvision\VU\Projects\202110-NZpaper" //OVSRV06
cd "C:\Users\JipClaassens\OneDrive - Objectvision\VU\Projects\202110-NZpaper" //OVSRV08
cd "C:\Users\jcs220\OneDrive - Objectvision\VU\Projects\202110-NZpaper" //Azure 
log using temp\nzlijn_did_prijzen_log.txt, text replace

global filedate = 20250925 // 20240926  20240530 20241003  20241107
global acc_range = 30
global TAsize = 12
global CAsize = 24

// import delimited data/SourceData_NVM_points_${filedate}.csv, clear
// import delimited data/DiD_Prijzen_${filedate}.csv, clear 


///////////////////////////////////////
**# DATA PREPAREREN
///////////////////////////////////////

import delimited data/DiD_Prijzen_${acc_range}min_${TAsize}_${CAsize}min_${filedate}.csv, delimiter(";") clear   
save data/DMS_did_prijzen_${acc_range}min_${TAsize}_${CAsize}min_${filedate}_raw.dta, replace
use data/DMS_did_prijzen_${acc_range}min_${TAsize}_${CAsize}min_${filedate}_raw.dta, clear

drop geometry* nl_grid_domain*

rename v5 lon

local replaceNullList = "bouwjaar bouwjaar_bag buurt_rel crimeindex schoolquality"
foreach x of local replaceNullList{
	replace `x' = "" if `x' == "null"
	destring `x', replace
}

rename station_stationcentraal_reistijd station_centraal_reistijds
rename station_stationzuid_reistijd station_zuid_reistijds

// replace lotsize = 1 if lotsize < 1
// g lnlotsize = ln(lotsize) if lotsize > 1
g lnprice = ln(price) 
g lnsize = ln(size)

g amsterdam_rel = 0
replace amsterdam_rel = 1 if gemeente_name == "'Amsterdam'"

replace bouwjaar = . if bouwjaar == 0 | bouwjaar == 9999
replace bouwjaar = 1600 if bouwjaar < 1600 & bouwjaar != .
replace bouwjaar_baggeom = . if bouwjaar_baggeom == 0 | bouwjaar_baggeom == 9999
replace bouwjaar_baggeom = 1600 if bouwjaar_baggeom < 1600 & bouwjaar_baggeom != .
replace bouwjaar = bouwjaar_baggeom if bouwjaar == .
drop bouwjaar_baggeom

// g age = trans_year - bouwjaar_augm
// g age = trans_year - bouwjaar
// replace age = . if age < 0

g d_constr_unknown = 0
replace d_constr_unknown = 1 if bouwjaar == .  
g d_constrlt1920 = 0
replace d_constrlt1920 = 1 if bouwjaar <= 1919 & bouwjaar != .  
g d_constr19201944 = 0 
replace d_constr19201944 = 1 if bouwjaar >= 1920 & bouwjaar <= 1944
g d_constr19451959 = 0 
replace d_constr19451959 = 1 if bouwjaar >= 1945 & bouwjaar <= 1959
g d_constr19601973 = 0 
replace d_constr19601973 = 1 if bouwjaar >= 1960 & bouwjaar <= 1973
g d_constr19741990 = 0 
replace d_constr19741990 = 1 if bouwjaar >= 1974 & bouwjaar <= 1990
g d_constr19911997 = 0 
replace d_constr19911997 = 1 if bouwjaar >= 1991 & bouwjaar <= 1997
g d_constrgt1997 = 0 
replace d_constrgt1997 = 1 if bouwjaar >= 1998 & bouwjaar != .

g construction_period_label = ""
replace construction_period_label = "Construction before 1920" if d_constrlt1920 == 1
replace construction_period_label = "Construction between 1920 and 1944" if d_constr19201944 == 1
replace construction_period_label = "Construction between 1945 and 1959" if d_constr19451959 == 1
replace construction_period_label = "Construction between 1960 and 1973" if d_constr19601973 == 1
replace construction_period_label = "Construction between 1974 and 1990" if d_constr19741990 == 1
replace construction_period_label = "Construction between 1991 and 1997" if d_constr19911997 == 1
replace construction_period_label = "Construction after 1998" if d_constrgt1997 == 1
replace construction_period_label = "Construction unknown" if d_constr_unknown == 1
encode construction_period_label, generate(construction_period)

g building_type_label = ""
replace building_type_label = "Terraced" if d_terraced == 1
replace building_type_label = "Semi-detached" if d_semidetached == 1
replace building_type_label = "Detached" if d_detached == 1
replace building_type_label = "Apartment" if d_apartment == 1
encode building_type_label, generate(building_type)

g trans_year_month = string(trans_year) + "/" + string(trans_month)
g trans_date = date(trans_year_month, "YM")

// replace nbath = 1 if nbath == .


local stations "noord noorderpark centraal rokin vijzelgracht depijp europaplein zuid"
foreach s of local stations{ 
	g tt_`s'_min = station_`s'_reistijd / 60
}

replace postcode = "" if postcode == "'1000'"
replace postcode = "" if postcode == "'1000!!'"
replace postcode = "" if postcode == "'0000'"
replace postcode = "" if postcode == "'0000AA'"
replace postcode = "" if postcode == "'1000AA'"
replace postcode = "" if postcode == "'1000AB'"
replace postcode = "" if postcode == "'1000II'"
replace postcode = "" if postcode == "'1000JJ'"
replace postcode = "" if postcode == "'1000ZZ'"
replace postcode = "" if postcode == "'1010'"
replace postcode = "" if postcode == "'1010AA'"
replace postcode = "" if postcode == "'1011'"
replace postcode = "" if postcode == "'9999XX'"
replace postcode = "" if postcode == "'1234AA'"

encode postcode, generate(pc6_code)

g all_ta = 0
g all_ca = 0
local stations "noord noorderpark centraal rokin vijzelgracht depijp europaplein zuid"
foreach s of local stations{ 
	replace all_ta = 1 if `s'_ta == 1
	replace all_ca = 1 if `s'_ca == 1
}

////Aantal waarnemingen per zone, per periode
g zone_label = ""
replace zone_label = "n_ta" if noord_ta == 1
replace zone_label = "np_ta" if noorderpark_ta == 1
replace zone_label = "c_ta" if centraal_ta == 1
replace zone_label = "r_ta" if rokin_ta == 1
replace zone_label = "v_ta" if vijzelgracht_ta == 1
replace zone_label = "p_ta" if depijp_ta == 1
replace zone_label = "e_ta" if europaplein_ta == 1
replace zone_label = "z_ta" if zuid_ta == 1
replace zone_label = "n_ca" if noord_ca == 1
replace zone_label = "np_ca" if noorderpark_ca == 1
replace zone_label = "c_ca" if centraal_ca == 1
replace zone_label = "r_ca" if rokin_ca == 1
replace zone_label = "v_ca" if vijzelgracht_ca == 1
replace zone_label = "p_ca" if depijp_ca == 1
replace zone_label = "e_ca" if europaplein_ca == 1
replace zone_label = "z_ca" if zuid_ca == 1
encode zone_label, generate(zone)

drop if zone == .


save "data/DMS_did_prijzen_base_${acc_range}min_${TAsize}_${CAsize}min_${filedate}.dta", replace


//////////////////////////////////////////////////////////////////////
**# ////////////////////////// ANALYSES //////////////////////////////
//////////////////////////////////////////////////////////////////////

use "data/DMS_did_prijzen_base_${acc_range}min_${TAsize}_${CAsize}min_${filedate}.dta", clear

drop if trans_year < 1996
drop if amsterdam_rel == 0
fvset base 1 construction_period
// drop if trans_year > 2021



**# ///////////// TreatmentAreas obv abs bereikbaarheid 

// gen buurt_rel_augm = .


gen ym = mofd(trans_date)
format ym %tm

// local stations "noorderpark"
local stations "noord noorderpark centraal rokin vijzelgracht depijp europaplein zuid all"
foreach s of local stations{ 
// 	local dates "22042003 01082009 08072016 21072018"
	local dates "21072018"
	foreach d of local dates{
		
		display "================================"
		display "Start calculation of Station `s', for date `d'"
		display "================================"
	
		g treated = `s'_ta
		g post = trans_date >= td(`d')
// 		g post = trans_date >= td(21jul2018)   // of exact jouw openingsdag
		g did = post * treated
		
		g ca = `s'_ca + `s'_ta
		
		* Within-residuals t.o.v. buurt + jaar + maand. Dummy vars hoeven niet mee te doen.
		quietly reghdfe lnprice if ca==1, absorb(buurt_rel ym) resid
		predict double y_w if e(sample), resid

		quietly reghdfe did            if ca==1, absorb(buurt_rel ym) resid
		predict double did_w   if e(sample), resid

		quietly reghdfe lnsize    if ca==1, absorb(buurt_rel ym) resid
		predict double lnsize_w if e(sample), resid

		quietly reghdfe nrooms    if ca==1, absorb(buurt_rel ym) resid
		predict double nrooms_w if e(sample), resid

		quietly reghdfe crimeindex    if ca==1, absorb(buurt_rel ym) resid
		predict double crimeindex_w if e(sample), resid

		quietly reghdfe schoolquality    if ca==1, absorb(buurt_rel ym) resid
		predict double schoolquality_w if e(sample), resid

		* VIF op within-varianten
		quietly reg y_w did_w c.lnsize_w c.nrooms_w c.crimeindex_w c.schoolquality_w if ca==1
		estat vif

		* Aux: R²(did | X + FE)  → VIF_did
		quietly reghdfe did c.lnsize_w c.nrooms_w d_maintgood b1.building_type b1.construction_period c.crimeindex_w c.schoolquality_w if ca==1, absorb(buurt_rel ym)

		* Robuust de juiste R² ophalen (within-R² als die bestaat)
		scalar R2w = .
		scalar R2w = e(r2_within)
		scalar VIF_did = 1/(1 - R2w)
		display "Within R2(did | X + FE) = " %6.3f R2w
		display "VIF_did (given FE)     = " %6.2f VIF_did	
		
		* Maak mooie strings (of "n/a") en voeg die met addtext toe
		local vif_str = cond(missing(VIF_did), "n/a", strofreal(VIF_did,"%6.2f"))
		local r2w_str = cond(missing(R2w),    "n/a", strofreal(R2w,   "%6.3f"))	
		
	// 	VIF ≈ 1–3 → geen zorg.
	// 	VIF > 5 (≈ R2>0.80) → opletten; collineariteit merkbaar.
	// 	VIF > 10 (≈ R2>0.90) → probleem: SE's zwellen sterk (SE ≈ sqrt(VIF)​ keer groter).
	// 	VIF > 20 (≈ R2>0.95) → zeer zwak geïdentificeerd.
					
		areg lnprice i.treated i.did c.lnsize c.nrooms c.crimeindex c.schoolquality i.d_maintgood i.building_type b1.construction_period i.ym if ca == 1, absorb(buurt_rel) vce(cluster pc6_code) //post weglaten, want perfecte multicollineartiy met i.ym. Dus voegt niks toe.
		outreg2 using output/prijzen/did_windows_indiv_AccBased_${acc_range}min_buurt_${TAsize}_${CAsize}min_${filedate}_vce_sept25_2, excel cttop (`s', `d') label dec(3) addtext (Year FE, Yes, Month FE, Yes, Neighbourhood FE, Yes,"VIF_did (within)","`vif_str'","Within R2(did|X+FE)","`r2w_str'") 

		drop treated post did ca y_w did_w lnsize_w nrooms_w crimeindex_w schoolquality_w _reghd* 
	}
}

///zonder property chars
local stations "noord"
foreach s of local stations{ 
	local dates "21072018"
	foreach d of local dates{
		g treated = `s'_ta
		g treattime = trans_date >= td(`d')
		g did = treattime * treated
		
		g ca = `s'_ca + `s'_ta
		
		areg lnprice treated treattime did if ca == 1, r absorb(buurt_rel)
		
		drop did* treated treattime* ca
	}
}



//descriptives
estpost sum price trans_year trans_month  size nrooms bouwjaar d_maintgood d_ap d_ter d_sem d_det d_constr* tt_*  
esttab using output/sum_prijzen_${acc_range}min_${TAsize}_${CAsize}min_${filedate}.rtf, cells("count(fmt(0)) mean(fmt(2)) sd(fmt(2)) min(fmt(0)) max(fmt(0))") label nomtitle nonumber replace




// gen double lat_d = lat
// gen double lon_d = lon
//
// duplicates report lat_d lon_d, inspect
// duplicates tag lat_d lon_d, gen(tag)
// set seed 10000
// gen double shuffle1 = runiform(0.0000001,0.0000002)
// replace lat_d = lat_d +shuffle1 if tag>0
// replace lon_d = lon_d +shuffle1 if tag>0
// drop tag shuffle1
// duplicates report lat_d lon_d, inspect
// spset obsid, coord(lon_d lat_d) coordsys(latlong) 

spset, clear
spset obsid, coord(x y) 


// spmatrix create idistance W, vtruncate(1) replace
// spmatrix save W using Data/SPmat_sub.dta, replace
// spmatrix export W using Data/SPmat_sub, replace

spmatrix drop W
spmatrix import W using Data/SPmat_geodms, replace


spmat idistance W x_coord y_coord, id(identificatie) dfunction(euclidean) replace
spmat save W using Data/SPmat_sub.dta, replace

predict residuals, resid
spregress moran residuals, spmat(W)

spregress lnprice treated treattime did lnsize nrooms d_maintgood i.building_type b1.construction_period i.trans_year i.trans_month if ca == 1, gs2sls errorlag(W) force

save, replace


spmat idistance W x y, id(obsid) dfunction(euclidean) replace
spmat save W using Data/SPmat.dta, replace





spmatrix create contiguity W if year == 2000



areg lnprice treated treattime did lnsize nrooms d_maintgood i.building_type b1.construction_period i.trans_year i.trans_month if ca == 1, r absorb(buurt_rel)





////// TEST FOR PARALLEL TREND ASSUMPTION
use "data/DMS_did_prijzen_base_${acc_range}min_${TAsize}_${CAsize}min_${filedate}.dta", clear

drop if trans_year < 1996
drop if amsterdam_rel == 0
fvset base 1 construction_period
fvset base 2017 trans_year

g all_ta = 0
g all_ca = 0
local stations "noord noorderpark centraal rokin vijzelgracht depijp europaplein zuid"
foreach s of local stations{ 
	replace all_ta = 1 if `s'_ta == 1
	replace all_ca = 1 if `s'_ca == 1
}

local stations "noorderpark"
// local stations "noord noorderpark centraal rokin vijzelgracht depijp europaplein zuid all"
foreach s of local stations{ 
// 	local dates "22042003 01082009 08072016 21072018"
	local dates "21072018"
	foreach d of local dates{
		g treated = `s'_ta
		g treattime = trans_date >= td(`d')
		g did = treattime * treated
		
		g ca = `s'_ca + `s'_ta
		
// 		areg lnprice lnsize nrooms i.d_maintgood i.building_type i.construction_period i.trans_month i.treated##i.trans_year if ca == 1, r absorb(buurt_rel) allbaselevels
		areg lnprice lnsize nrooms i.d_maintgood i.building_type i.construction_period i.trans_month i.trans_year if `s'_ca == 1, r absorb(buurt_rel) allbaselevels 
// 		outreg2 using output/prijzen/did_windows_indiv_AccBased_${acc_range}min_buurt_${TAsize}_${CAsize}min_${filedate}_PtrendCorr7_ta, excel cttop (`s', `d') label dec(3) addtext (Year FE, Yes, Month FE, Yes, Neighbourhood FE, Yes) ci_low ci_high //nose noaster
		outreg2 using output/prijzen/did_windows_indiv_AccBased_${acc_range}min_buurt_${TAsize}_${CAsize}min_${filedate}_PtrendCorr6_ca, st(coef pval ci_low ci_high) noaster noparen excel append cttop (`s', `d') label dec(3) addtext (Year FE, Yes, Month FE, Yes, Neighbourhood FE, Yes) wide
		

		drop did* treated treattime* ca
	}
}



preserve
keep if ca == 1
collapse (mean) price, by(trans_year treated) 
lgraph price trans_year, by(treated) xline(2018)
restore















**# CREATE PARALLEL TREND PLOTS
use "data/DMS_did_prijzen_base_${acc_range}min_${TAsize}_${CAsize}min_${filedate}.dta", clear

drop if trans_year < 1996
drop if amsterdam_rel == 0
fvset base 1 construction_period
fvset base 2017 trans_year

global station_name = "all" // noord noorderpark centraal rokin vijzelgracht depijp europaplein zuid all
// Step 1.1: Run the regression with fixed time effects (TREATED SET)
areg lnprice lnsize nrooms i.d_maintgood i.building_type i.construction_period i.trans_month i.trans_year if ${station_name}_ta == 1, r absorb(buurt_rel) allbaselevels

// Step 1.2: Create a new dataset with the year range
clear
input trans_year
1996
1997
1998
1999
2000
2001
2002
2003
2004
2005
2006
2007
2008
2009
2010
2011
2012
2013
2014
2015
2016
2017
2018
2019
2020
2021
2022
end


// Step 1.3: Generate variables to store the coefficients and confidence intervals
gen coef_treated = .
gen lb_treated = .    // Lower bound of CI
gen ub_treated = .    // Upper bound of CI

// Step 1.4: Loop through each year to extract the coefficients and CIs using lincom
local i = 1
foreach year of numlist 1996/2022 {
    lincom _b[`year'.trans_year]
    replace coef_treated = exp(r(estimate))*100 in `i'
    replace lb_treated = exp(r(lb))*100 in `i'
    replace ub_treated = exp(r(ub))*100 in `i'
    local i = `i' + 1
}

// Step 1.5: save results to temp file
save "temp/did_prijzen_yearcoeff_treated_${station_name}.dta", replace

// Step 2.0: reopen prepped data for regression
use "data/DMS_did_prijzen_base.dta", clear

drop if trans_year < 1996
drop if amsterdam_rel == 0
fvset base 1 construction_period
fvset base 2017 trans_year

// Step 2.1: Run the regression with fixed time effects (CONTROL SET)
areg lnprice lnsize nrooms i.d_maintgood i.building_type i.construction_period i.trans_month i.trans_year if ${station_name}_ca == 1, r absorb(buurt_rel) allbaselevels 

// Step 2.2: Create a new dataset with the year range
clear
input trans_year
1996
1997
1998
1999
2000
2001
2002
2003
2004
2005
2006
2007
2008
2009
2010
2011
2012
2013
2014
2015
2016
2017
2018
2019
2020
2021
2022
end


// Step 2.3: Generate variables to store the coefficients and confidence intervals
gen coef_control = .
gen lb_control = .    // Lower bound of CI
gen ub_control = .    // Upper bound of CI

// Step 2.4: Loop through each year to extract the coefficients and CIs using lincom
local i = 1
foreach year of numlist 1996/2022 {
    lincom _b[`year'.trans_year]
    replace coef_control = exp(r(estimate))*100 in `i'
    replace lb_control = exp(r(lb))*100 in `i'
    replace ub_control = exp(r(ub))*100 in `i'
    local i = `i' + 1
}

// Step 2.5: merge treated data with control data
merge 1:1 trans_year using temp/did_prijzen_yearcoeff_treated_${station_name}.dta
drop _merge 

// Step 2.6: Plot the coefficients with confidence intervals
twoway ///
    (rarea lb_treated ub_treated trans_year, color(gs12%50)) ///
    (rarea lb_control ub_control trans_year, color(gs7%50)) ///
    (line coef_treated trans_year, lcolor(blue) lwidth(medium)) ///
    (line coef_control trans_year, lcolor(red) lwidth(medium)) ///
	,xline(2017, lcolor(black) lwidth(thin) lpattern(dash)) ///
    title("Parallel trends: ${station_name}") ///
    ytitle("exp(coefficient)*100") ///
    xlabel(1996(2)2022) legend(order(1 "95% CI (Treated)" 2 "95% CI (Control)" 3 "Treated" 4 "Control")) ///
    plotregion(style(none))	
	
graph export "Output\paralleltrend_plot_${station_name}.png", replace width(1800) height(1200)





**# CREATE PARALLEL TREND PLOTS (SUGGESTION JAN of JANUARY 2025)
use "data/DMS_did_prijzen_base_${acc_range}min_${TAsize}_${CAsize}min_${filedate}.dta", clear

drop if trans_year < 1996
drop if amsterdam_rel == 0
fvset base 1 construction_period
fvset base 2017 trans_year

global station_name = "all" // noord noorderpark centraal rokin vijzelgracht depijp europaplein zuid all

// Step 1.1: Run the regression with fixed time effects (TREATED SET)
g treated = ${station_name}_ta
g studyarea = ${station_name}_ca + ${station_name}_ta

areg lnprice i.trans_year i.treated i.trans_year#i.treated if studyarea == 1, r absorb(buurt_rel)  
// outreg2 using output/prijzen/parallel_trend_${acc_range}min_buurt_${TAsize}_${CAsize}min_${filedate}, st(coef pval ci_low ci_high) noaster noparen excel append cttop (${station_name}) label dec(3) addtext (Neighbourhood FE, Yes) wide

		
		
// Step 1.2: Create a new dataset with the year range
clear
input trans_year
1996
1997
1998
1999
2000
2001
2002
2003
2004
2005
2006
2007
2008
2009
2010
2011
2012
2013
2014
2015
2016
2017
2018
2019
2020
2021
2022
end


// Step 1.3: Generate variables to store the coefficients and confidence intervals
gen coef_treated = .
gen lb_treated = .    // Lower bound of CI
gen ub_treated = .    // Upper bound of CI

// Step 1.4: Loop through each year to extract the coefficients and CIs using lincom
local i = 1
foreach year of numlist 1996/2022 {
    lincom _b[`year'.trans_year#1.treated], level(95)
    replace coef_treated = r(estimate) in `i'
    replace lb_treated = r(lb) in `i'
    replace ub_treated = r(ub) in `i'
    local i = `i' + 1
}

replace lb_treated = 0 if trans_year == 2017
replace ub_treated = 0 if trans_year == 2017

// Step 1.5: Plot the coefficients with confidence intervals
twoway ///
	(rarea lb_treated ub_treated trans_year, color(gs12%50) lpattern(solid) legend(label(1 "95% CI (Treated)"))) ///
	(line coef_treated trans_year, lcolor(blue) lwidth(medium) legend(label(2 "Treated"))) ///
	, ///
	xline(2018, lcolor(black) lwidth(thin) lpattern(dash)) ///
	yline(0, lcolor(black) lwidth(thin) lpattern(dot)) ///
    title("Parallel trends: ${station_name}") ///
    xtitle("") ///
    ytitle("Treated year coefficients") ///
    xlabel(1996(2)2022) ///
	legend(order(1 2)) ///
	note("areg lnprice i.trans_year i.treated i.trans_year#i.treated, r absorb(buurt_rel) allbaselevels" ///
	"for AccRange:${acc_range}min TAsize:${TAsize} CAsize:${CAsize}min Filedate:${filedate}") ///
    plotregion(style(none))	
	
graph export "Output\paralleltrend_plot_Jan_${station_name}.png", replace width(1800) height(1200)

