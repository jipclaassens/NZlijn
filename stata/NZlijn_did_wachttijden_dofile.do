clear
cd "D:\OneDrive\OneDrive - Objectvision\VU\Projects\202110-NZpaper" 

**# Bookmark #7

. import excel "Data\WN ToewijzingenWachttijd PC6 2017-2022Q2_edit.xlsx", sheet("Wachttijd PC6 2020-22 Q3") firstrow clear

// De originele data zijn in wide format. We zetten ze om naar long, met jaar als extra variabele. //
drop if PC6 == "" 
reshape long y, i(PC6) j(jaar 2020 2021 2022)

. rename y Gem_Wachttijd
. rename PC6 pc6
. label variable Gem_Wachttijd "Gemiddelde van Wachttijd aanbodmodel (ex. loting en bemiddeling)"
. order pc6 Stadsdeel Gem_Wachttijd, first

sa Temp/Wachttijden2020-2022.dta, replace

**# Bookmark #6

clear 

. import excel "Data\WN ToewijzingenWachttijd PC6 2017-2022Q2_edit.xlsx", sheet("Wachttijd PC6 2017-19") firstrow clear

drop if PC6 == "" 
reshape long y, i(PC6) j(jaar 2017 2018 2019)

. rename y Gem_Wachttijd
. rename PC6 pc6
. label variable Gem_Wachttijd "Gemiddelde van Wachttijd aanbodmodel (ex. loting en bemiddeling)"
. order pc6 Stadsdeel Gem_Wachttijd, first

sa Temp/Wachttijden2017-2019.dta, replace

**# Bookmark #12

append using Temp/Wachttijden2020-2022.dta, keep(pc6 jaar Stadsdeel Gem_Wachttijd)

sa Temp/Wachttijden2017-2022.dta, replace

**# Bookmark #13

. import delimited Data/PC6_TA-CA_areas_AMS_20240827.csv,  clear

ren pc6_name pc6
replace pc6 = subinstr(pc6,"'","",.)

sort pc6
sa Temp/PC6_TA-CA_areas_AMS.dta, replace

use Temp/Wachttijden2017-2022.dta, clear

sort pc6
merge pc6 using Temp/PC6_TA-CA_areas_AMS.dta
tab _merge

keep if _merge==3
drop _merge

sa Temp/Wachttijden2017-2022.dta, replace


** ///////////// TreatmentAreas obv abs bereikbaarheid 

use Temp/Wachttijden2017-2022.dta, clear

drop if Gem_Wachttijd == .

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

tab zone

drop if zone == .


/* short waiting times may indicate that dwellings have been assigned by priority. We delete these observations. Our assumption is that waiting times below 1 year may indicate priority assignment. */

drop if Gem_Wachttijd < 1

g all_ta = 0
g all_ca = 0



/* Analyse zonder pc6 characteristics */


local stations "noord noorderpark centraal rokin vijzelgracht depijp europaplein zuid all"
foreach s of local stations{ 
	replace all_ta = 1 if `s'_ta == 1
	replace all_ca = 1 if `s'_ca == 1
}


local stations "noord noorderpark centraal rokin vijzelgracht depijp europaplein zuid all"
foreach s of local stations{ 
		

		g treated = `s'_ta
		g treattime = jaar > 2018
		g did = treattime * treated

		
		g ca = `s'_ca + `s'_ta
		
		areg Gem_Wachttijd treated treattime did if ca == 1, r absorb(buurt_22_rel) 
		outreg2 using did_wachttijden_base_2, excel cttop (`s') label dec(3) addtext (Year FE, Yes, Neighbourhood FE, Yes) keep(treat* did*) 
	 drop treated treattime did ca
	}


	
/* Analyse met pc6 characteristics */

. destring fractie_app avg_opp_app median_bouwjaar_app, replace force

g d_constr_unknown = 0
replace d_constr_unknown = 1 if median_bouwjaar_app == .  
g d_constrlt1920 = 0
replace d_constrlt1920 = 1 if median_bouwjaar_app <= 1919 & median_bouwjaar_app ~= .  
g d_constr19201944 = 0 
replace d_constr19201944 = 1 if median_bouwjaar_app >= 1920 & median_bouwjaar_app <= 1944
g d_constr19451959 = 0 
replace d_constr19451959 = 1 if median_bouwjaar_app >= 1945 & median_bouwjaar_app <= 1959
g d_constr19601973 = 0 
replace d_constr19601973 = 1 if median_bouwjaar_app >= 1960 & median_bouwjaar_app <= 1973
g d_constr19741990 = 0 
replace d_constr19741990 = 1 if median_bouwjaar_app >= 1974 & median_bouwjaar_app <= 1990
g d_constr19911997 = 0 
replace d_constr19911997 = 1 if median_bouwjaar_app >= 1991 & median_bouwjaar_app <= 1997
g d_constrgt1997 = 0 
replace d_constrgt1997 = 1 if median_bouwjaar_app >= 1998 & median_bouwjaar_app ~= .

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

	
local stations "noord noorderpark centraal rokin vijzelgracht depijp europaplein zuid all"
foreach s of local stations{ 
		
		g treated = `s'_ta
		g treattime = jaar > 2018
		g did = treattime * treated

		g ca = `s'_ca + `s'_ta
		
		areg Gem_Wachttijd avg_opp_app b1.construction_period treated treattime did if ca == 1, r absorb(buurt_22_rel) 
		outreg2 using did_wachttijden_ext, excel cttop (`s') label dec(3) addtext (Property char., Yes, Year FE, Yes, Neighbourhood FE, Yes) keep(treat* did*)
	 drop treated treattime did ca
	}
	
// b1 stelt "Construction after 1998" (eerste categorie van construction_period) in als referentiecategorie
	
//descriptives

local stations "all"
foreach s of local stations{ 
		
		g treated = `s'_ta
		g treattime = jaar > 2018
		g did = treattime * treated

		g ca = `s'_ca + `s'_ta
		
		areg Gem_Wachttijd avg_opp_app b1.construction_period treated treattime did if ca == 1, r absorb(buurt_22_rel) 
		
		estpost sum Gem_Wachttijd avg_opp_app d_constr* 
		esttab using Output\sum_wachttijden.rtf, cells("count(fmt(0)) mean(fmt(2)) sd(fmt(2)) min(fmt(0)) max(fmt(0))") label nomtitle nonumber replace
		
		//outreg2 using did_wachttijden_ext2, excel cttop (`s') label dec(3) addtext (Year FE, Yes, Neighbourhood FE, Yes) //keep(treat* did*)
	 drop treated treattime did ca
	}


	

	
// Achtergrondanalyses	
	
/*
 gen lnwt = ln(Gem_Wachttijd)	

local stations "noord noorderpark centraal rokin vijzelgracht depijp europaplein zuid"
foreach s of local stations{ 
		

		g treated = `s'_ta
		g treattime = jaar >= 2018
		g did = treattime * treated

		
		g ca = `s'_ca + `s'_ta
		
		areg lnwt treated treattime did if ca == 1, r absorb(PC6_STADSDEEL) 
		outreg2 using trend_lnwt_base, excel cttop (`s') label dec(3) addtext (Year FE, Yes, Stadsdeel FE, Yes) keep(treat* did*) 
	 drop treated treattime did ca
	}
		
	
 gen lnsize = ln(avg_opp_app)	
	
local stations "noord noorderpark centraal rokin vijzelgracht depijp europaplein zuid"
foreach s of local stations{ 
		
		g treated = `s'_ta
		g treattime = jaar >= 2018
		g did = treattime * treated

		g ca = `s'_ca + `s'_ta
		
		areg lnwt count_app fractie_app lnsize b1.construction_period treated treattime did if ca == 1, r absorb(PC6_STADSDEEL) 
		outreg2 using trend_lnwt_ext, excel cttop (`s') label dec(3) addtext (Year FE, Yes, Stadsdeel FE, Yes) keep(treat* did*)
	 drop treated treattime did ca
	}
*/	


	
// Additionele panel-data regressie met vaste effecten voor elk postcodegebied (ontwikkeling wachttijden van dezelfde woning)	
encode pc6, generate(pc_num)
xtset pc_num jaar
xtdescribe

xtreg Gem_Wachttijd i.jaar 





