capture log close
cd "D:\OneDrive\OneDrive - Objectvision\VU\Projects\202110-NZpaper\"
log using temp\nzlijn_did_prijzen_log.txt, text replace

global filedate = 20240530
global acc_range = 30
global TAsize = 12
global CAsize = 24

// import delimited data/SourceData_NVM_points_${filedate}.csv, clear
import delimited data/DiD_Prijzen_${filedate}.csv, clear 


///////////////////////////////////////
**# DATA PREPAREREN
///////////////////////////////////////

import delimited data/DiD_Prijzen_${acc_range}min_${TAsize}_${CAsize}min_${filedate}.csv, delimiter(";") clear   
// import delimited C:\GeoDMS\LocalData\NZlijn\Results\nzlijn\Analyse_DiD_Prijzen_20221005_6_12min.csv, delimiter(";") clear   
save data/DMS_did_prijzen_raw.dta, replace
use data/DMS_did_prijzen_raw.dta, clear

drop geometry nl_grid_domain*

local replaceNullList = "lotsize bouwjaar bouwjaar_augm buurt_rel"
foreach x of local replaceNullList{
	replace `x' = "" if `x' == "null"
	destring `x', replace
}

rename station_stationcentraal_reistijd station_centraal_reistijds
rename station_stationzuid_reistijds station_zuid_reistijds

replace lotsize = 1 if lotsize < 1
g lnlotsize = ln(lotsize) if lotsize > 1
g lnprice = ln(price) 
g lnsize = ln(size)

g amsterdam_rel = 0
replace amsterdam_rel = 1 if gemeente_name == "'Amsterdam'"

replace bouwjaar = . if bouwjaar == 0 | bouwjaar == 9999
replace bouwjaar = 1600 if bouwjaar < 1600 & bouwjaar != .
replace bouwjaar_augm = . if bouwjaar_augm == 0 | bouwjaar_augm == 9999
replace bouwjaar_augm = 1600 if bouwjaar_augm < 1600 & bouwjaar_augm != .

g age = trans_year - bouwjaar_augm
replace age = . if age < 0

g d_constr_unknown = 0
replace d_constr_unknown = 1 if bouwjaar_augm == .  
g d_constrlt1920 = 0
replace d_constrlt1920 = 1 if bouwjaar_augm <= 1919 & bouwjaar_augm != .  
g d_constr19201944 = 0 
replace d_constr19201944 = 1 if bouwjaar_augm >= 1920 & bouwjaar_augm <= 1944
g d_constr19451959 = 0 
replace d_constr19451959 = 1 if bouwjaar_augm >= 1945 & bouwjaar_augm <= 1959
g d_constr19601973 = 0 
replace d_constr19601973 = 1 if bouwjaar_augm >= 1960 & bouwjaar_augm <= 1973
g d_constr19741990 = 0 
replace d_constr19741990 = 1 if bouwjaar_augm >= 1974 & bouwjaar_augm <= 1990
g d_constr19911997 = 0 
replace d_constr19911997 = 1 if bouwjaar_augm >= 1991 & bouwjaar_augm <= 1997
g d_constrgt1997 = 0 
replace d_constrgt1997 = 1 if bouwjaar_augm >= 1998 & bouwjaar_augm != .

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

replace nbath = 1 if nbath == .


local stations "noord noorderpark centraal rokin vijzelgracht depijp europaplein zuid"
foreach s of local stations{ 
	g tt_`s'_min = station_`s'_reistijds / 60
}

save "data/DMS_did_prijzen_base.dta", replace


//////////////////////////////////////////////////////////////////////
**# ////////////////////////// ANALYSES //////////////////////////////
//////////////////////////////////////////////////////////////////////

use "data/DMS_did_prijzen_base.dta", clear

drop if trans_year < 1996
drop if amsterdam_rel == 0
fvset base 1 construction_period


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

tab trans_year zone

**# ///////////// TreatmentAreas obv abs bereikbaarheid 

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
// 	local dates "21072018"
	foreach d of local dates{
		g treated = `s'_ta
		g treattime = trans_date >= td(`d')
		g did = treattime * treated
		
		g ca = `s'_ca + `s'_ta
		
		areg lnprice treated treattime did lnsize nbath nrooms d_maintgood d_central d_kk d_isol_compl d_erfpacht d_privpark i.building_type b1.construction_period i.trans_year i.trans_month if ca == 1, r absorb(buurt_rel)
		outreg2 using output/prijzen/did_windows_indiv_AccBased_${acc_range}min_buurt_${TAsize}_${CAsize}min_${filedate}, excel cttop (`s', `d') label dec(3) addtext (Year FE, Yes, Month FE, Yes, Neighbourhood FE, Yes) keep(treat* did*)  
		
		drop did* treated treattime* ca
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
estpost sum price trans_year trans_month  size nrooms nbath bouwjaar_augm d_maintgood d_central d_kk d_isol_compl d_erfpacht d_privpark d_ap d_ter d_sem d_det d_constr* tt_*  
esttab using output/sum_prijzen_${acc_range}min_${TAsize}_${CAsize}min_${filedate}.rtf, cells("count(fmt(0)) mean(fmt(3)) sd(fmt(3)) min(fmt(0)) max(fmt(0))") label nomtitle nonumber replace



















