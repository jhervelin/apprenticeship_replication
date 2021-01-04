** définition des chemins et accès

global chemindata = "/Users/jhervelin/Documents/Doctorat/Articles/Cahuc_Hervelin/Data/Database"
global cheminprog = "/Users/jhervelin/Documents/Doctorat/Articles/Cahuc_Hervelin/Data/Program"
global cheminout = "/Users/jhervelin/Documents/Doctorat/Articles/Cahuc_Hervelin/Data/Outputs"

*global chemindata="/Users/pierrecahuc/Dropbox/Testing/Testing_Formations/Cahuc_Hervelin/Data/Database"
*global cheminprog="/Users/pierrecahuc/Dropbox/Testing/Testing_Formations/Cahuc_Hervelin/Data/Program"
*global cheminout="/Users/pierrecahuc/Dropbox/Testing/Testing_Formations/Cahuc_Hervelin/Data/Outputs/alternate"


** ouverture de la table du testing 

use $chemindata/bdd_testing, clear

set more off


** agrégation des profils et sélection des profils

cap drop profil
gen profil = "CFA" if ProfilCandidature == "CFA_AM_D" | ProfilCandidature == "CFA_ANM_D"
replace profil = "LP" if ProfilCandidature == "LP_SM_D" | ProfilCandidature == "LP_SNM_D"
drop if profil == ""


** tests de puissance

* avant expérimentation (anticipé)
power twoproportions .07, diff(.03) alpha(0.05) oneside

* après expérimentation (réel)
power twoproportions .27, diff(.04) alpha(0.05) oneside


** définition de deux variables expliquées principales

cap drop positive_callback
gen positive_callback = (Reponse != "0" & Reponse != "1")

cap drop proposition_callback
gen proposition_callback = (Reponse == "7" | Reponse == "8" | Reponse == "9")


** définition de la variable d'intérêt

cap drop apprentissage
gen apprentissage = (profil == "CFA")


** table de statistiques descriptives sur les tailles d'échantillon et les taux de rappel (Table 3)

* ensemble
table apprentissage, co(freq mean positive_callback sem positive_callback mean proposition_callback sem proposition_callback)
ttest positive_callback, by(apprentissage)
ttest proposition_callback, by(apprentissage)

* cuisiniers
table apprentissage if Metier == "CU", co(freq mean positive_callback sem positive_callback  mean proposition_callback sem proposition_callback)
ttest positive_callback if Metier == "CU", by(apprentissage)
ttest proposition_callback if Metier == "CU", by(apprentissage)

* maçons
table apprentissage if Metier == "MA", co(freq mean positive_callback sem positive_callback  mean proposition_callback sem proposition_callback)
ttest positive_callback if Metier == "MA", by(apprentissage)
ttest proposition_callback if Metier == "MA", by(apprentissage)


** création des effets fixes et variables de contrôle
* following Athey & Imbens (2017) : demeaned dummy transformations

cap drop petite_entreprise
gen petite_entreprise = (TailleEntreprise == "Microentreprise")
replace petite_entreprise = . if missing(TailleEntreprise)

cap drop contrat_permanent
gen contrat_permanent = (Contrat == "CDI")
replace contrat_permanent = . if missing(Contrat)

cap drop temps_complet
gen temps_complet = (TempsContrat == "TC")
replace temps_complet = . if missing(TempsContrat)

cap drop ans_experience
gen ans_experience = (ExperienceRequise >= 2)
replace ans_experience = . if missing(ExperienceRequise)

cap drop homme_recruteur
gen homme_recruteur = (SexeRecruteur == "H")
replace homme_recruteur = . if missing(SexeRecruteur)

cap drop moisenvoi
gen moisenvoi = month(DateEnvoi)
tab moisenvoi, gen(moisenvoi_)

cap drop departement_
tab departement, gen(departement_)

global nomiss "moisenvoi, departement"
global controls "moisenvoi_ departement_"

foreach control in $controls {
	
	if "`control'" == "moisenvoi_" {
		
		quietly forvalues i = 1(1)7 {
			
			egen m`control'`i' = mean(`control'`i') if !missing($nomiss)
			gen d`control'`i' = `control'`i' - m`control'`i' if !missing($nomiss)
			drop m`control'`i'
			
		}
		
	}
	
	else if "`control'" == "departement_" {
		
		quietly forvalues i = 1(1)96 {
			
			egen m`control'`i' = mean(`control'`i') if !missing($nomiss)
			gen d`control'`i' = `control'`i' - m`control'`i' if !missing($nomiss)
			drop m`control'`i'
			
		}
		
	}
	
}

global month_fe "dmoisenvoi_*"
global dep_fe "ddepartement_*"
global listoutcomes = "positive_callback proposition_callback"


** régressions du profil apprentis sur taux de rappel (Table 4)

foreach outcome in $listoutcomes {
	
	if "`outcome'" == "positive_callback" {
		local table "table_callback"
	}
	else {
		local table "table_proposition"
	}
	
	di "all occupations"
	table apprentissage if !missing($nomiss), co(freq mean `outcome' sem `outcome')
	
	quietly reg `outcome' apprentissage if !missing($nomiss), cluster(departement)
	estimate store `outcome'_1
	outreg2 using $cheminout/Testing/`table'.doc, replace tex ctitle("`outcome'") keep(apprentissage) addtext(Month FE, No, Department FE, No)
	
	quietly reg `outcome' apprentissage $month_fe if !missing($nomiss), cluster(departement)
	estimate store `outcome'_2
	outreg2 using $cheminout/Testing/`table'.doc, append tex ctitle("`outcome'") keep(apprentissage) addtext(Month FE, Yes, Department FE, No)
			
	quietly reg `outcome' apprentissage $month_fe $dep_fe if !missing($nomiss), cluster(departement)
	estimate store `outcome'_3
	outreg2 using $cheminout/Testing/`table'.doc, append tex ctitle("`outcome'") keep(apprentissage) addtext(Month FE, Yes, Department FE, Yes)
	
	di "Cook"
	table apprentissage if !missing($nomiss) & Metier == "CU", co(freq mean `outcome' sem `outcome')
	quietly reg `outcome' apprentissage $month_fe $dep_fe if !missing($nomiss) & Metier=="CU", cluster(departement)
	estimate store `outcome'_4
	outreg2 using $cheminout/Testing/`table'.doc, append tex ctitle("`outcome'") keep(apprentissage) addtext(Month FE, Yes, Department FE, Yes)
	
	di "Bricklayer"
	table apprentissage if !missing($nomiss) & Metier == "MA", co(freq mean `outcome' sem `outcome')
	quietly reg `outcome' apprentissage $month_fe $dep_fe if !missing($nomiss) & Metier=="MA", cluster(departement)
	estimate store `outcome'_5
	outreg2 using $cheminout/Testing/`table'.doc, append tex ctitle("`outcome'") keep(apprentissage) addtext(Month FE, Yes, Department FE, Yes)
	
	estout `outcome'_1 `outcome'_2 `outcome'_3 `outcome'_4 `outcome'_5, starlevels(* 0.10 ** 0.05 *** 0.01) /// 
	keep(apprentissage _cons) label wrap cells(b(star fmt(3)) se(par fmt(3))) stats(N r2)
	
}


** régressions du profil apprentis sur taux de rappel selon la taille de l'entreprise (Table 5)

* pour sortir les tables A.4.1.3 et A.4.2.3
* preserve
* keep if Metier == "CU" (table A.4.1.3)
* or
* keep if Metier == "MA (table A.4.2.3)
* restore

foreach outcome in $listoutcomes {
	
	if "`outcome'" == "positive_callback" {
		local table "table_callback_firm"
	}
	else {
		local table "table_proposition_firm"
	}

	forvalues x=0(1)1 {
		
		table apprentissage if !missing($nomiss) & petite_entreprise == `x', co(freq mean `outcome' sem `outcome')

		quietly reg `outcome' apprentissage if !missing($nomiss) & petite_entreprise == `x', cluster(departement)
		estimate store `outcome'_1
		outreg2 using $cheminout/Testing/`table'.doc, append tex ctitle("`outcome'") keep(apprentissage) addtext(Month FE, No, Department FE, No)
		
		quietly reg `outcome' apprentissage $month_fe if !missing($nomiss) & petite_entreprise == `x', cluster(departement)
		estimate store `outcome'_2
		outreg2 using $cheminout/Testing/`table'.doc, append tex ctitle("`outcome'") keep(apprentissage) addtext(Month FE, Yes, Department FE, No)
				
		quietly reg `outcome' apprentissage $month_fe $dep_fe if !missing($nomiss) & petite_entreprise == `x', cluster(departement)
		estimate store `outcome'_3
		outreg2 using $cheminout/Testing/`table'.doc, append tex ctitle("`outcome'") keep(apprentissage) addtext(Month FE, Yes, Department FE, Yes)
		
		estout `outcome'_1 `outcome'_2 `outcome'_3, starlevels(* 0.10 ** 0.05 *** 0.01) /// 
		keep(apprentissage _cons) label wrap cells(b(star fmt(3)) se(par fmt(3))) stats(N r2)
		
	}
	
}


** régressions du profil apprentis sur taux de rappel selon le type de contrat (Table 6)

* pour sortir les tables A.4.1.4 et A.4.2.4
* preserve
* keep if Metier == "CU" (table A.4.1.4)
* or
* keep if Metier == "MA (table A.4.2.4)
* restore

foreach outcome in $listoutcomes {
	
	if "`outcome'" == "positive_callback" {
		local table "table_callback_contract"
	}
	else {
		local table "table_proposition_contract"
	}

	forvalues x=0(1)1 {
		
		table apprentissage if !missing($nomiss) & contrat_permanent == `x', co(freq mean `outcome' sem `outcome')
		
		quietly reg `outcome' apprentissage if !missing($nomiss) & contrat_permanent == `x', cluster(departement)
		estimate store `outcome'_1
		outreg2 using $cheminout/Testing/`table'.doc, append tex ctitle("`outcome'") keep(apprentissage) addtext(Month FE, No, Department FE, No)
		
		quietly reg `outcome' apprentissage $month_fe if !missing($nomiss) & contrat_permanent == `x', cluster(departement)
		estimate store `outcome'_2
		outreg2 using $cheminout/Testing/`table'.doc, append tex ctitle("`outcome'") keep(apprentissage) addtext(Month FE, Yes, Department FE, No)
				
		quietly reg `outcome' apprentissage $month_fe $dep_fe if !missing($nomiss) & contrat_permanent == `x', cluster(departement)
		estimate store `outcome'_3
		outreg2 using $cheminout/Testing/`table'.doc, append tex ctitle("`outcome'") keep(apprentissage) addtext(Month FE, Yes, Department FE, Yes)
		
		estout `outcome'_1 `outcome'_2 `outcome'_3, starlevels(* 0.10 ** 0.05 *** 0.01) /// 
		keep(apprentissage _cons) label wrap cells(b(star fmt(3)) se(par fmt(3))) stats(N r2)
				
	}
	
}


** régression selon le tercile de taux de chômage au niveau de la zone d'emploi (Table 7)

global controls "petite_entreprise contrat_permanent temps_complet ans_experience homme_recruteur moisenvoi_ departement_"
global nomiss "TailleEntreprise, Contrat, TempsContrat, ExperienceRequise, SexeRecruteur"

foreach control in $controls {
	
	if "`control'" == "moisenvoi_" {
		
		quietly forvalues i = 1(1)7 {
			
			egen m`control'`i' = mean(`control'`i') if !missing($nomiss)
			cap drop d`control'`i'
			gen d`control'`i' = `control'`i' - m`control'`i' if !missing($nomiss)
			drop m`control'`i'
			
		}
		
	}
	
	else if "`control'" == "departement_" {
		
		quietly forvalues i = 1(1)96 {
			
			egen m`control'`i' = mean(`control'`i') if !missing($nomiss)
			cap drop d`control'`i'
			gen d`control'`i' = `control'`i' - m`control'`i' if !missing($nomiss)
			drop m`control'`i'
			
		}
		
	}
	
	else {
		
		egen m`control' = mean(`control') if !missing($nomiss)
		gen d`control' = `control' - m`control' if !missing($nomiss)
		drop m`control'
		
	}
	
}

global controls "dpetite_entreprise dcontrat_permanent dtemps_complet dans_experience dhomme_recruteur"
global fe "dmoisenvoi_* ddepartement_*"

cap drop meanunemp
bysort LIBZE2010: egen meanunemp = mean(TxChomageDep) if !missing($nomiss, TxChomageZE)
sum meanunemp, d
cap drop qunemp
xtile qunemp = meanunemp if !missing($nomiss, TxChomageZE), nq(3)
table qunemp, co(mean TxChomageDep min meanunemp max meanunemp)
table qunemp, co(mean positive_callback mean proposition_callback)

* pour sortir les tables A.4.1.5 et A.4.2.5
* preserve
* keep if Metier == "CU" (table A.4.1.5)
* or
* keep if Metier == "MA (table A.4.2.5)
* restore

foreach outcome in $listoutcomes {
	
	if "`outcome'" == "positive_callback" {
		local table "table_callback_unemp"
	}
	else {
		local table "table_proposition_unemp"
	}
	
	table apprentissage if !missing($nomiss, TxChomageZE), co(freq mean `outcome' sem `outcome')
	
	quietly reg `outcome' apprentissage $controls $fe if !missing($nomiss, TxChomageZE), cluster(departement)
	estimate store `outcome'_all
	outreg2 using $cheminout/Testing/`table'.doc, replace tex ctitle("`outcome'") keep(apprentissage) addtext(Firm \& Job Characteristics, Yes, Month \& Department FE, Yes)
	
	forvalues x=1(1)3 {
		
		table apprentissage if !missing($nomiss, TxChomageZE) & qunemp == `x', co(freq mean `outcome' sem `outcome')
		
		quietly reg `outcome' apprentissage $controls $fe if !missing($nomiss, TxChomageZE) & qunemp==`x', cluster(departement)
		estimate store `outcome'_`x'
		outreg2 using $cheminout/Testing/`table'.doc, append tex ctitle("`outcome'") keep(apprentissage) addtext(Firm \& Job Characteristics, Yes, Month \& Department FE, Yes)
	
	}
	
	estout `outcome'_all `outcome'_1 `outcome'_2 `outcome'_3, starlevels(* 0.10 ** 0.05 *** 0.01) /// 
	keep(apprentissage _cons) label wrap cells(b(star fmt(3)) se(par fmt(3))) stats(N r2)
	
}






** table annexe : effets marginaux Probit (Table A3)

foreach outcome in $listoutcomes {

global month_fe "moisenvoi_*"
global dep_fe "departement_*"
	
	if "`outcome'" == "positive_callback" {
		local table "table_callback_probit"
	}
	else {
		local table "table_proposition_probit"
	}
	
	quietly probit `outcome' apprentissage if !missing($nomiss), vce(cluster departement)
	mfx compute
	outreg2 using $cheminout/Testing/`table'.doc, replace tex mfx ctitle("`outcome'") keep(apprentissage) addtext(Month FE, No, Department FE, No)
	
	quietly probit `outcome' apprentissage $month_fe if !missing($nomiss), vce(cluster departement)
	mfx compute, var(apprentissage) force
	outreg2 using $cheminout/Testing/`table'.doc, append tex mfx ctitle("`outcome'") keep(apprentissage) addtext(Month FE, Yes, Department FE, No)
			
	quietly probit `outcome' apprentissage $month_fe $dep_fe if !missing($nomiss), vce(cluster departement)
	mfx compute, var(apprentissage) force
	outreg2 using $cheminout/Testing/`table'.doc, append tex mfx ctitle("`outcome'") keep(apprentissage) addtext(Month FE, Yes, Department FE, Yes)
	
	quietly probit `outcome' apprentissage $month_fe $dep_fe if !missing($nomiss) & Metier=="CU", vce(cluster departement)
	mfx compute, var(apprentissage) force
	outreg2 using $cheminout/Testing/`table'.doc, append tex mfx ctitle("`outcome'") keep(apprentissage) addtext(Month FE, Yes, Department FE, Yes)
	
	quietly probit `outcome' apprentissage $month_fe $dep_fe if !missing($nomiss) & Metier=="MA", vce(cluster departement)
	mfx compute, var(apprentissage) force
	outreg2 using $cheminout/Testing/`table'.doc, append tex mfx ctitle("`outcome'") keep(apprentissage) addtext(Month FE, Yes, Department FE, Yes)
	
}
