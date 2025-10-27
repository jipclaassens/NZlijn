capture log close
cd "D:\OneDrive\OneDrive - Objectvision\VU\Projects\202110-NZpaper\" //LAPTOP
cd "C:\Users\Jip Claassens\OneDrive - Objectvision\VU\Projects\202110-NZpaper" //OVSRV06
cd "C:\Users\JipClaassens\OneDrive - Objectvision\VU\Projects\202110-NZpaper" //OVSRV08
cd "C:\Users\jcs220\OneDrive - Objectvision\VU\Projects\202110-NZpaper" //Azure 
log using temp\nzlijn_did_prijzen_log.txt, text replace

global filedate = 20251017 // 20240926  20240530 20241003  20241107 20250925
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


* voorbeeld: nl_grid_domain_rel == "{106, 133}"
gen str s = nl_grid_domain_rel
replace s = subinstr(s,"{","",.)
replace s = subinstr(s,"}","",.)
replace s = subinstr(s," ","",.)     // spaties weg
split s, parse(",") gen(g)           // g1 = 106, g2 = 133
destring g1 g2, replace
egen cell_id = group(g1 g2), label
drop s g1 g2

drop geometry* nl_grid_domain*

// rename v5 lon
  
local replaceNullList = "bouwjaar bouwjaar_bag buurt_rel wijk_rel crimeindex schoolquality countpop_nonwestern countpop_workingage"
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
// local stations "noord noorderpark centraal rokin vijzelgracht depijp europaplein zuid"
local stations "noord noorderpark vijzelgracht depijp europaplein"
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

//drop if zone == .


save "data/DMS_did_prijzen_base_${acc_range}min_${TAsize}_${CAsize}min_${filedate}.dta", replace


//////////////////////////////////////////////////////////////////////
**# ////////////////////////// ANALYSES //////////////////////////////
//////////////////////////////////////////////////////////////////////

use "data/DMS_did_prijzen_base_${acc_range}min_${TAsize}_${CAsize}min_${filedate}.dta", clear

drop if trans_year < 1996
drop if amsterdam_rel == 0
fvset base 1 construction_period
// drop if trans_year > 2021

g inpairall = (all_ta==1 | all_ca==1)
reg lnprice ib1996.trans_year if inpairall

gen ym = mofd(trans_date)
format ym %tm

**# ///////////// TreatmentAreas obv abs bereikbaarheid 

// gen buurt_rel_augm = .



local stations "noorderpark"
local stations "all"
// local stations "noord noorderpark centraal rokin vijzelgracht depijp europaplein zuid all"
// local stations "noord noorderpark vijzelgracht depijp europaplein all"
foreach s of local stations{ 
// 	local dates "22042003 01082009 08072016 21072018 21072020"
	local dates "21072018"
	foreach d of local dates{
		
		display "================================"
		display "Start calculation of Station `s', for date `d'"
		display "================================"
	
		g treated = `s'_ta
		g post = trans_date >= td(`d')
		g did = post * treated

		g ca = `s'_ca + `s'_ta
		
/*	
// 		Within-residuals t.o.v. buurt + jaar + maand. Dummy vars hoeven niet mee te doen.
		quietly reghdfe lnprice if ca==1, absorb(buurt_rel ym) resid
		predict double y_w if e(sample), resid

		quietly reghdfe did            if ca==1, absorb(buurt_rel ym) resid
		predict double did_w   if e(sample), resid

		quietly reghdfe lnsize    if ca==1, absorb(buurt_rel ym) resid
		predict double lnsize_w if e(sample), resid

		quietly reghdfe nrooms    if ca==1, absorb(buurt_rel ym) resid
		predict double nrooms_w if e(sample), resid

		quietly reghdfe countwoning    if ca==1, absorb(buurt_rel ym) resid
		predict double countwoning_w if e(sample), resid

		quietly reghdfe schoolquality    if ca==1, absorb(buurt_rel ym) resid
		predict double schoolquality_w if e(sample), resid

		* VIF op within-varianten
		quietly reg y_w did_w c.lnsize_w c.nrooms_w c.countwoning_w c.schoolquality_w if ca==1
		estat vif

		* Aux: R²(did | X + FE)  → VIF_did
		quietly reghdfe did c.lnsize_w c.nrooms_w d_maintgood b1.building_type b1.construction_period c.countwoning_w c.schoolquality_w if ca==1, absorb(buurt_rel ym)

		* Robuust de juiste R² ophalen (within-R² als die bestaat)
		scalar R2w = .
		scalar R2w = e(r2_within)
		scalar VIF_did = 1/(1 - R2w)
		display "Within R2(did | X + FE) = " %6.3f R2w
		display "VIF_did (given FE)     = " %6.2f VIF_did	
		
		* Maak mooie strings (of "n/a") en voeg die met addtext toe
		local vif_str = cond(missing(VIF_did), "n/a", strofreal(VIF_did,"%6.2f"))
		local r2w_str = cond(missing(R2w),    "n/a", strofreal(R2w,   "%6.3f"))	
		
// 		VIF ≈ 1–3 → geen zorg.
// 		VIF > 5 (≈ R2>0.80) → opletten; collineariteit merkbaar.
// 		VIF > 10 (≈ R2>0.90) → probleem: SE's zwellen sterk (SE ≈ sqrt(VIF)​ keer groter).
// 		VIF > 20 (≈ R2>0.95) → zeer zwak geïdentificeerd.
*/
				
// 		reghdfe lnprice i.treated i.did c.lnsize c.nrooms i.d_maintgood c.schoolquality c.countwoning i.building_type b1.construction_period if ca == 1, absorb(ym cell_id) vce(cluster pc6_code) //post weglaten, want perfecte multicollineartiy met i.ym. Dus voegt niks toe. Samen met cell_id valt treated natuurlijk ook weg.
		reghdfe lnprice i.treated i.did#c.diff_spits_abs_30min c.lnsize c.nrooms i.d_maintgood c.schoolquality c.countwoning i.building_type b1.construction_period if ca == 1, absorb(ym buurt_rel) vce(cluster pc6_code) //post weglaten, want perfecte multicollineartiy met i.ym. Dus voegt niks toe. Samen met cell_id valt treated natuurlijk ook weg.
// 		outreg2 using output/prijzen/did_windows_indiv_AccBased_${acc_range}min_buurt_${TAsize}_${CAsize}min_${filedate}_vce_cellFE_all, excel cttop (`s', `d') label dec(3) addtext (Year-Month FE, Yes, Cell FE, Yes, "VIF_did (within)","`vif_str'","Within R2(did|X+FE)","`r2w_str'") 

// 		drop treated post did ca y_w did_w lnsize_w nrooms_w countwoning_w schoolquality_w _reghd* 
		drop treated post did ca  
	}
}


**# --------------------------------------------------------------------
* Event-study samenvatting per station (Noord/Zuidlijn)
* - Pre-trends (joint F)
* - Post-joint test
* - Lincoms: 2022-2019, 2021-2018H2
* - Post-opening slope (trend)
*--------------------------------------------------------------------

* Vereist: reghdfe (en ftools)
ssc install ftools, replace
ssc install reghdfe, replace

local openym = ym(2018,7)

* lijst met stations
local stations noord noorderpark centraal rokin vijzelgracht depijp europaplein zuid

* ======= Resultaatcontainer =======
tempname handle
postfile `handle' str20 station ///
    double pre_p double post_p ///
    double diff2022_2019 double p2022_2019 ///
    double diff2021_2018H2 double p2021_2018H2 ///
    double slope_p ///
    using results.dta, replace

foreach s of local stations {
	
    di as txt "---- Station: `s' ----"
    gen inpair = (`s'_ta==1 | `s'_ca==1)
    
	* =======================
	* A) PRE-trends (geen factor-notatie)
	* =======================
	* Kies rustige pre-vensters (pas zo nodig aan)
	gen pre_early = inrange(ym, ym(2014,1), ym(2015,12))                // 2014–15
	gen pre_2016  = (trans_year==2016)                                  // 2016
	gen pre_2017  = inrange(ym, ym(2017,1), ym(2018,6))                 // 2017–2018H1

	* Treated × pre-vensters
	gen TA_pre_early =  `s'_ta*pre_early
	gen TA_pre_2016  =  `s'_ta*pre_2016
	gen TA_pre_2017  =  `s'_ta*pre_2017

	* =======================
	* B) POST-dummies (halfjaar 2018H2 + jaren 2019–2022)
	* =======================
	gen post_2018H2 = inrange(ym, ym(2018,7), ym(2018,12))
	gen post_2019   = (trans_year==2019)
	gen post_2020   = (trans_year==2020)
	gen post_2021   = (trans_year==2021)
	gen post_2022   = (trans_year==2022)

	gen TA_2018H2 =  `s'_ta*post_2018H2
	gen TA_2019   =  `s'_ta*post_2019
	gen TA_2020   =  `s'_ta*post_2020
	gen TA_2021   =  `s'_ta*post_2021
	gen TA_2022   =  `s'_ta*post_2022

	* =======================
	* C) Regressie (micro) + tests
	* =======================
	quietly reghdfe lnprice ///
		TA_pre_early TA_pre_2016 TA_pre_2017 ///
		TA_2018H2 TA_2019 TA_2020 TA_2021 TA_2022 ///
		if inpair, absorb(cell_id ym) vce(cluster cell_id)

	* PRE-trends: H0 = alle pre-coëffs = 0
	quietly test TA_pre_early TA_pre_2016 TA_pre_2017
	local pre_p = r(p)
	
	* Gezamenlijke POST-effecten (optioneel)
	quietly test TA_2018H2 TA_2019 TA_2020 TA_2021 TA_2022
	local post_p = r(p)
	
	* Gevraagde LINCOMs (groei/gradualiteit)
	quietly lincom TA_2022 - TA_2019     // groei 2019 → 2022
	local diff2022_2019 = r(estimate)
	local p2022_2019    = r(p)
	
	quietly lincom TA_2021 - TA_2018H2   // direct na opening vs later
	local diff2021_2018H2 = r(estimate)
	local p2021_2018H2    = r(p)

	* =======================
	* D) Post-opening slope (gradueel effect als trend)
	* =======================
	gen t_post = ym - `openym'
	replace t_post = 0 if t_post < 0

	quietly reghdfe lnprice c.t_post##i.`s'_ta if inpair, absorb(cell_id ym) vce(cluster cell_id)

	* H0: geen groei na opening
	quietly test 1.`s'_ta#c.t_post
	local slope_p = r(p)
	
   * ---------- Wegschrijven ----------
    post `handle' ("`s'") ///
        (`pre_p') (`post_p') ///
        (`diff2022_2019') (`p2022_2019') ///
        (`diff2021_2018H2') (`p2021_2018H2') ///
        (`slope_p')
		
	drop inpair pre_early pre_2016 pre_2017 TA_pre_early TA_pre_2016 TA_pre_2017 post_2018H2 post_2019 post_2020 post_2021 post_2022 TA_2018H2 TA_2019 TA_2020 TA_2021 TA_2022 t_post
}

postclose `handle'

use results.dta, clear
format pre_p post_p p2022_2019 p2021_2018H2 slope_p %6.3f
list, clean noobs

export delimited using output/prijzen/Tests_${acc_range}min_buurt_${TAsize}_${CAsize}min_${filedate}.csv, delimiter(";") replace




**# /// =============== Test continue accessibility variabele ==================

g ln_acc30min = ln(diff_spits_abs_30min)
g inpair_all = (all_ta==1 | all_ca==1)
g post = trans_date >= td(21072018)

reghdfe lnprice c.lnsize c.nrooms i.d_maintgood i.building_type b1.construction_period ln_acc30min, absorb(ym buurt_rel) vce(cluster pc6_code) 
outreg2 using output/prijzen/continu_acc_${acc_range}min_${CAsize}min_${filedate}_all, excel cttop (AMS) label dec(3) addtext (Year-Month FE, Yes, Buurt FE, Yes, Wijk FE, No) 
reghdfe lnprice c.lnsize c.nrooms i.d_maintgood i.building_type b1.construction_period ln_acc30min, absorb(ym wijk_rel) vce(cluster pc6_code) 
outreg2 using output/prijzen/continu_acc_${acc_range}min_${CAsize}min_${filedate}_all, excel cttop (AMS) label dec(3) addtext (Year-Month FE, Yes, Buurt FE, No, Wijk FE, Yes) 
reghdfe lnprice c.lnsize c.nrooms i.d_maintgood i.building_type b1.construction_period ln_acc30min if inpair_all, absorb(ym buurt_rel) vce(cluster pc6_code) 
outreg2 using output/prijzen/continu_acc_${acc_range}min_${CAsize}min_${filedate}_all, excel cttop (NZL_${CAsize}min) label dec(3) addtext (Year-Month FE, Yes, Buurt FE, Yes, Wijk FE, No) 

reghdfe lnprice c.lnsize c.nrooms i.d_maintgood i.building_type b1.construction_period ln_acc30min if inpair_all, absorb(ym wijk_rel) vce(cluster pc6_code) 
outreg2 using output/prijzen/continu_acc_${acc_range}min_${CAsize}min_${filedate}_all, excel cttop (NZL_${CAsize}min) label dec(3) addtext (Year-Month FE, Yes, Buurt FE, No, Wijk FE, Yes) 

reghdfe lnprice c.lnsize c.nrooms i.d_maintgood i.building_type b1.construction_period i.post#c.ln_acc30min if inpair_all, absorb(ym wijk_rel) vce(cluster pc6_code) 
outreg2 using output/prijzen/continu_acc_${acc_range}min_${CAsize}min_${filedate}_all, excel cttop (NZL_${CAsize}min) label dec(3) addtext (Year-Month FE, Yes, Buurt FE, No, Wijk FE, Yes) 



// local stations "noorderpark"
local stations "noord noorderpark centraal rokin vijzelgracht depijp europaplein zuid all"
foreach s of local stations{ 
	display "================================"
	display "Start calculation of Station `s'"
	display "================================"

    gen inpair = (`s'_ta==1 | `s'_ca==1)
	
	reghdfe lnprice c.lnsize c.nrooms i.d_maintgood i.building_type b1.construction_period ln_acc30min if inpair, absorb(ym) vce(cluster pc6_code) 
	
// 		reghdfe lnprice c.lnsize c.nrooms i.d_maintgood c.schoolquality c.countwoning i.building_type b1.construction_period if ca == 1, absorb(ym cell_id) vce(cluster pc6_code) 
	outreg2 using output/prijzen/continu_acc_${acc_range}min_${CAsize}min_${filedate}, excel cttop (`s') label dec(3) addtext (Year-Month FE, Yes, Neighbourhood FE, Yes) 
	
	drop inpair  
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
keep if inpairall

estpost sum price trans_year trans_month size nrooms bouwjaar d_maintgood schoolquality countwoning d_ap d_ter d_sem d_det d_constr* 
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

