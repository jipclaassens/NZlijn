clear
cd "D:\OneDrive\OneDrive - Objectvision\VU\Projects\202110-NZpaper" //laptop
cd "C:\Users\Jip Claassens\OneDrive - Objectvision\VU\Projects\202110-NZpaper" //OVSRV06
cd "C:\Users\JipClaassens\OneDrive - Objectvision\VU\Projects\202110-NZpaper" //OVSRV08

// cd "C:\Users\Jip Claassens\OneDrive - Objectvision\VU\Projects\202110-NZpaper" //ovsrv6

// import excel "C:\Users\mln740\OneDrive - Vrije Universiteit Amsterdam\NZL_privatehuur\Huurtransacties_clean.xlsx", sheet("Brondata_WatsonHolmes_Huurtrans") firstrow
//
// sa "NZL_data_privatehuur.dta", replace
//
// . import delimited "C:\Users\mln740\OneDrive - Vrije Universiteit Amsterdam\NZL_privatehuur\pc6hnr20210801_gwb.csv"
//
// keep if gemeente2021==363
// sort pc6 
// . duplicates drop pc6 buurt2021, force
// . keep pc6 buurt2021
//
// sa "buurt_rel.dta", replace

use Data/NZL_data_privaterents.dta, clear


drop transactiedatum 
drop zone_label zone



// removing double entries in variables, i.e. words written with/without capitals

replace huurprijsspecificatie="Exclusief servicekosten" if huurprijsspecificatie=="exclusief servicekosten"
replace huurprijsspecificatie="Geindexeerd" if huurprijsspecificatie=="geindexeerd"
replace huurprijsspecificatie="Gemeubileerd" if huurprijsspecificatie=="gemeubileerd"
replace huurprijsspecificatie="Gestoffeerd" if huurprijsspecificatie=="gestoffeerd"
replace huurprijsspecificatie="Inclusief servicekosten" if huurprijsspecificatie=="inclusief servicekosten"


replace bouwvorm="Bestaande bouw" if bouwvorm=="bestaande bouw"
replace bouwvorm="Nieuwbouw" if bouwvorm=="nieuwbouw"
replace bouwvorm= "." if bouwvorm == "NULL" | bouwvorm == "N.v.t."
 
// tab bouwvorm

gen nieuwbouw = 0 
replace nieuwbouw = . if bouwvorm  == "."
replace nieuwbouw = 1 if bouwvorm == "Nieuwbouw"
// tab nieuwbouw


gen date=date(transactiedatumondertekeningakte,"MDY")
format date %td
gen trans_year = year(date)
gen trans_month = month(date)
g trans_year_month = string(trans_year) + "/" + string(trans_month)
g trans_date = date(trans_year_month, "YM")



replace energielabel= "." if energielabel == "NULL"
replace energielabel= "." if energielabel == ""
gen elabelA = 0 if energielabel~="."
replace elabelA = 1 if strpos(energielabel, "A") 
replace energielabel= "Aplus" if energielabel =="A+" | energielabel =="A++" | energielabel =="A+++" | energielabel =="A++++" | energielabel =="A+++++"  
replace elabelA = 1 if strpos(energielabel, "Aplus")

// tab elabelA

// Variabelen gemeubileerd en gestoffeerd zijn nog niet ingevuld voor data < 2021 ...  In 'huurprijsspecificatie' en 'bijzonderheden' zit info over stoffering of meubilering.
replace gemeubileerd = 1 if huurprijsspecificatie=="Gemeubileerd" | strpos(bijzonderheden, "Gemeubileerd")	
replace gestoffeerd = 1 if huurprijsspecificatie=="Gestoffeerd" | strpos(bijzonderheden, "Gestoffeerd")


// tab huurprijsconditie
replace huurprijs=huurprijs/12 if huurprijsconditie=="per jaar"
//sum huurprijs 
replace huurprijsconditie="per maand" if huurprijsconditie=="per jaar"



gen app=0
replace app=1 if typeobject=="Appartement"


sum servicekosten
replace servicekosten=. if servicekosten>=9999999


// kaleverhuur zit alleen in de nieuwe data, niet in de oude reeks. Daarom volgende aanpassingen

. replace kaleverhuur = 0 if kaleverhuur == . & (gemeubileerd == 1 | gestoffeerd == 1) // Volgens nieuwe data W+H: als gestoffeerd of gemeubileerd = 1, kaleverhuur = 0.  
replace kaleverhuur =1 if kaleverhuur == . &  gemeubileerd == 0 & gestoffeerd ==0  // 

// . tab gestoffeerd kaleverhuur
// . tab gemeubileerd kaleverhuur


/*
gen hp = huurprijs
replace hp = huurprijs - servicekosten if huurprijsspecificatie=="Inclusief servicekosten" & servicekosten ~= 0 // berekenen huurprijs hp exclusief servicekosten (3,368 real changes made) 
. gen test=huurprijs-hp
. label variable test "controle huurprijs - hp= servicekosten"
replace huurprijsspecificatie="Exclusief servicekosten" if huurprijsspecificatie =="Inclusief servicekosten" & servicekosten ~= 0 // aanpassen van het label voor hp van inclusief naar exclusief */





// sum inhoud

// sum gebruiksoppervlakte
drop if gebruiksoppervlakte<10
gen hoogte=inhoud/gebruiksoppervlakte
drop if hoogte<2
drop if hoogte>10
// reg inhoud gebruiksoppervlakte

sa Data/NZL_data_privaterents_edit.dta, replace


** ///////////// Analysis specifically for NZL.  

use Data/NZL_data_privaterents_edit.dta, clear

drop zuid_ca noord_ta noord_ca noorderpark_ta noorderpark_ca centraal_ta centraal_ca rokin_ta rokin_ca vijzelgracht_ta vijzelgracht_ca depijp_ta depijp_ca europaplein_ta europaplein_ca zuid_ta zuid_ca

ren postcode pc6
destring pc6, generate(pcadjust) force
keep if pcadjust==. //4-cijferige postcodes (224 obs) gooien we weg. 
drop pcadjust
sort pc6

merge pc6 using Temp/PC6_TA-CA_areas_AMS.dta
tab _merge

keep if _merge==3
drop _merge

sa Temp/NZL_data_privaterents_newTACA.dta, replace

**# Bookmark #2
use Temp/NZL_data_privaterents_newTACA.dta, clear

gen lnhp=ln(huurprijs)
gen lnsize=ln(gebruiksoppervlakte)
ren aantalkamers nkamers

g amsterdam_rel = 0
replace amsterdam_rel = 1 if gemeente == "Amsterdam"
drop if amsterdam_rel == 0


. duplicates drop huurprijs inhoud gebruiksoppervlakte aanmelddatum transactiedatumondertekeningakte bouwjaar latitude_n longitude_n, force //dubbele waarnemingen eruit

// merge pc6 using "C:\Users\Maureen\OneDrive - Vrije Universiteit Amsterdam\NZL_privatehuur\buurt_rel"
// tab _merge
//
// keep if _merge==3
// . duplicates drop huurprijs inhoud gebruiksoppervlakte aanmelddatum transactiedatumondertekeningakte bouwjaar latitude_n longitude_n, force // 61 obs worden na merge gedupliceerd. Waarom? De dubbele entries worden verwijderd
//
// ren buurt2021 buurt_rel

/* gen pc5=substr(postcode,1,5)
gen pc4=substr(postcode,1,4)
destring pc4, replace  */



** ///////////// TreatmentAreas obv abs bereikbaarheid 

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


	
/* Analyse met housing characteristics */
g d_constr_unknown = 0
replace d_constr_unknown = 1 if bouwjaar == .  
g d_constrlt1920 = 0
replace d_constrlt1920 = 1 if bouwjaar <= 1919 & bouwjaar ~= .  
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
replace d_constrgt1997 = 1 if bouwjaar >= 1998 & bouwjaar ~= .

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


. label variable lnsize "Size sqm"
. label variable lnhp "Rent €/m"
. label variable nieuwbouw "Newly built"
. label variable kaleverhuur "Unfurnished"
. label variable app "Flats"
. label variable nkamers "Rooms"

encode pc6, generate(pc6_code)

keep lnhp huurprijs lnsize gebruiksoppervlakte nkamers app kaleverhuur nieuwbouw construction_period* trans_year trans_month buurt_22_rel pc6_code noord_ta noord_ca noorderpark_ta noorderpark_ca centraal_ta centraal_ca rokin_ta rokin_ca vijzelgracht_ta vijzelgracht_ca depijp_ta depijp_ca europaplein_ta europaplein_ca zuid_ta zuid_ca trans_date

g all_ta = 0
g all_ca = 0


// local stations "noord noorderpark centraal rokin vijzelgracht depijp europaplein zuid all"
local stations "noord noorderpark vijzelgracht depijp europaplein"
foreach s of local stations{ 
	replace all_ta = 1 if `s'_ta == 1
	replace all_ca = 1 if `s'_ca == 1
}


gen ym = mofd(trans_date)
format ym %tm

// met pc6 SE clustering
// local stations "noord noorderpark centraal rokin vijzelgracht depijp europaplein zuid all"  
local stations "noord noorderpark vijzelgracht depijp europaplein all"  
// local stations "noord"  
foreach s of local stations{ 
// 	local dates "22042003 01082009 08072016 21072018"
 	local dates "21072018"
	foreach d of local dates{

		display "================================"
		display "Start calculation of Station `s', for date `d'"
		display "================================"
	
		g treated = `s'_ta
		g post = trans_date >= td(`d')
		g did = post * treated
		
		g ca = `s'_ca + `s'_ta
		
		* Within-residuals t.o.v. buurt + jaar + maand. Dummy vars hoeven niet mee te doen.
		quietly reghdfe c.lnhp if ca==1, absorb(buurt_22_rel ym) resid
		predict double y_w if e(sample), resid

		quietly reghdfe did            if ca==1, absorb(buurt_22_rel ym) resid
		predict double did_w   if e(sample), resid

		quietly reghdfe c.lnsize    if ca==1, absorb(buurt_22_rel ym) resid
		predict double lnsize_w if e(sample), resid

		quietly reghdfe c.nkamers    if ca==1, absorb(buurt_22_rel ym) resid
		predict double nrooms_w if e(sample), resid

		* VIF op within-varianten
		quietly reg y_w did_w c.lnsize_w c.nrooms_w if ca==1
		estat vif

		* Aux: R²(did | X + FE)  → VIF_did
		quietly reghdfe did c.lnsize c.nkamers i.app i.kaleverhuur i.nieuwbouw b1.construction_period if ca==1, absorb(buurt_22_rel ym)

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
		
		reghdfe c.lnhp i.did i.treated c.lnsize c.nkamers i.app i.kaleverhuur i.nieuwbouw b1.construction_period if ca == 1, absorb(ym buurt_22_rel) vce(cluster pc6_code) 				
		outreg2 using Output\PrivateRents\did_rents_vce_okt25_reghfe, excel cttop (`s', `d') label dec(3) addtext (Year-Month FE, Yes, Neighbourhood FE, Yes,"VIF_did (within)","`vif_str'","Within R2(did|X+FE)","`r2w_str'") 
		
		drop treated post did ca y_w did_w lnsize_w nrooms_w _reghd* 
	}	  
}


// b1 stelt "Construction after 1998" (eerste categorie van construction_period) in als referentiecategorie






/* Analyse zonder housing characteristics */
local stations "noord noorderpark centraal rokin vijzelgracht depijp europaplein zuid all"
foreach s of local stations{ 
		
	local dates "21072018"
	foreach d of local dates{
		g treated = `s'_ta
		g treattime = trans_date >= td(`d')
		g did = treattime * treated
		
		g ca = `s'_ca + `s'_ta
		
		areg lnhp treated treattime did i.trans_year i.trans_month if ca == 1, r absorb(buurt_22_rel)
		outreg2 using output/did_rents_base, excel cttop (`s') label dec(3) addtext (Year FE, Yes, Month FE, Yes, Neighbourhood FE, Yes) keep(treat* did*) 
		
		drop did treated treattime ca
	}	  
}
// zonder pc6 SE clustering
local stations "noord noorderpark centraal rokin vijzelgracht depijp europaplein zuid all"  
foreach s of local stations{ 
 	local dates "21072018"
	foreach d of local dates{
		g treated = `s'_ta
		g treattime = trans_date >= td(`d')
		g did = treattime * treated
		
		g ca = `s'_ca + `s'_ta
		
		areg lnhp lnsize nkamers app kaleverhuur nieuwbouw b1.construction_period treated treattime did i.trans_year i.trans_month if ca == 1, absorb(buurt_22_rel) r
		outreg2 using Output\PrivateRents\did_rents, excel cttop (`s') label dec(3) addtext (Year FE, Yes, Month FE, Yes, Neighbourhood FE, Yes) keep(treat* did*)

		drop did treated treattime ca
	}	  
}



	
//descriptives
local stations "all"   
foreach s of local stations{ 
		
 	local dates "21072018"
	foreach d of local dates{
		g treated = `s'_ta
		g treattime = trans_date >= td(`d')
		g did = treattime * treated
		
		g ca = `s'_ca + `s'_ta
		
		areg lnhp lnsize nkamers app kaleverhuur nieuwbouw b1.construction_period treated treattime did i.trans_year i.trans_month if ca == 1, r absorb(buurt_22_rel) 
		
// 		estpost sum lnhp lnsize nkamers app kaleverhuur nieuwbouw d_constr* 
		estpost sum huurprijs gebruiksoppervlakte nkamers app kaleverhuur nieuwbouw d_constr* 
esttab using Output\sum_rents.rtf, cells("count(fmt(0)) mean(fmt(2)) sd(fmt(2)) min(fmt(0)) max(fmt(0))") label nomtitle nonumber replace
		//outreg2 using C:\Users\Maureen\did_rents_ext, excel cttop (`s') label dec(3) addtext (Year FE, Yes, Month FE, Yes, Neighbourhood FE, Yes) //keep(treat* did*)
		drop did treated treattime ca
	}	  
}
		
	
// ROBUUSTHEIDSANALYSE: eventueel nog elabelA toevoegen 
	
	
	
	
	
	
	