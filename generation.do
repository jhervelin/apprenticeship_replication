** définition des chemins et accès

global chemindata "/Users/jhervelin/Documents/Doctorat/Articles/Cahuc_Hervelin/Data/Database"
global cheminprog "/Users/jhervelin/Documents/Doctorat/Articles/Cahuc_Hervelin/Data/Program"
global cheminout "/Users/jhervelin/Documents/Doctorat/Articles/Cahuc_Hervelin/Data/Outputs"


global chemindata="/Users/pierrecahuc/Dropbox/Testing/Testing_Formations/Cahuc_Hervelin/Data/Database"
global cheminprog="/Users/pierrecahuc/Dropbox/Testing/Testing_Formations/Cahuc_Hervelin/Data/Program"
global cheminout="/Users/pierrecahuc/Dropbox/Testing/Testing_Formations/Cahuc_Hervelin/Data/Outputs/alternate"



use $chemindata/panel_generation.dta, clear

set more off

*keep if specialite_naf38 == "IZ" /* cuisinier */
*keep if specialite_naf38 == "FZ" /* maçon */
*keep if generation == "G2010" | generation == "G2013"


** statistiques descriptives

tab apprentissage [aw=pondef]

global listvar "homme handicap permis zone_commune siblings langue_famille pays_naissance_pere pays_naissance_mere niveau_pere niveau_mere emploi_pere emploi_mere redoublement troisieme_generale souhait_apprentissage raison_non_apprenti stages tuteur_apprentissage nb_stages aide_stage entreprise_apprentissage diplome"

foreach var in $listvar {
	
	if "`var'" == "stages" | "`var'" == "nb_stages" | "`var'" == "aide_stage" {
		tab `var' apprentissage if generation != "G2004" [aw=pondef], column
	}
	
	else if "`var'" == "entreprise_apprentissage" {
		tab `var' apprentissage if generation == "G2004" [aw=pondef], column
	}
	
	else {
		tab `var' apprentissage [aw=pondef], column
	}
	
}

bysort apprentissage: sum age_sortie_formation [aw=pondef]


** évolution du taux de chômage et du taux d'emploi dans le temps suivant la formation

* création de la variable d'emploi
cap drop emploi
gen emploi = (situation == "Emploi permanent" | situation == "Emploi temporaire" | situation == "Independant")
label var emploi "=1 si l'individu est en emploi à une date donnée"

* création de la variable chômage
cap drop chomage
gen chomage = (situation == "Chomage")
label var chomage "=1 si l'individu est au chômage à une date donnée"

* pour tous les profils
preserve
collapse (mean) chomage_appr = chomage (mean) emploi_appr = emploi if apprentissage == 1 [pweight=pondef], by(date)
save $chemindata/evolution, replace
restore

preserve

collapse (mean) chomage_lycee = chomage (mean) emploi_lycee = emploi if apprentissage == 0 [pweight=pondef], by(date)
merge 1:1 date using $chemindata/evolution
drop _merge

label var emploi_appr "Apprentices"
label var chomage_appr "Apprentices"
label var chomage_lycee "Students"
label var emploi_lycee "Students"

gen date_ = date-10
label var date_ "Elapsed duration (months) since leaving school "

line emploi_appr emploi_lycee date_ if date_ > 0, ///
lpattern(solid dash) lcolor(maroon dknavy) leg(off) ///
ytitle("Employment rate") xtitle("") title("All specializations") graphregion(color(white))
graph save $cheminout/Generation/employment_all.gph, replace
graph export $cheminout/Generation/employment_all.png, replace

line chomage_appr chomage_lycee date_ if date_ > 0, ///
lpattern(solid dash) lcolor(maroon dknavy) ///
ytitle("Unemployment rate") graphregion(color(white))
graph save $cheminout/Generation/unemployment_all.gph, replace
graph export $cheminout/Generation/unemployment_all.png, replace

*graph combine $cheminout/Generation/employment_all.gph $cheminout/Generation/unemployment_all.gph, col(1)
*graph export $cheminout/Generation/unemployment_all.png, replace

restore

erase $chemindata/evolution.dta


** transitions chômage -> emploi

* embauche dans entreprise de formation
cap drop type_transition
gen type_transition = "Meme entreprise" if travail_anterieur_entreprise == 1
replace type_transition = "Nouvelle entreprise" if travail_anterieur_entreprise == 0
replace type_transition = "Pas d'entreprise" if missing(type_transition)

cap drop tretention_entreprise
gen tretention_entreprise = (type_transition == "Meme entreprise" & date <14)
cap drop retention_entreprise
bysort ident: egen retention_entreprise = max(tretention_entreprise) 

tab retention_entreprise apprentissage , column

* Autre façon de calculer embauche dans entreprise de formation

sum travail_anterieur_entreprise if apprentissage==1 & situation[_n-1]=="Formation initiale" & (situation=="Emploi permanent" | situation=="Emploi temporaire")

* création des variables de contrôle pour les régressions
tab age_sortie_formation, gen(age_sortie_formation_)
tab niveau_pere, gen(niveau_pere_)
tab niveau_mere, gen(niveau_mere_)
tab pays_naissance_pere, gen(pays_naissance_pere_)
tab pays_naissance_mere, gen(pays_naissance_mere_)
tab dep_residence, gen(dep_residence_)
tab region_etablissement, gen(region_etablissement_)
tab specialite_naf38, gen(specialite_naf38_)
tab date, gen(date_)
gen annee_sortie = substr(date_label,-4,.)
tab annee_sortie, gen(annee_sortie_)

* soustraction de la moyenne aux variables de contrôles pour ne pas modifier la constante
global controls "retention_entreprise homme age_sortie_formation handicap permis diplome niveau_pere niveau_mere pays_naissance_pere pays_naissance_mere dep_residence region_etablissement specialite_naf38 date annee_sortie"
global nomiss "retention_entreprise, homme, age_sortie_formation, handicap, permis, diplome, niveau_pere, niveau_mere, pays_naissance_pere, pays_naissance_mere, dep_residence, region_etablissement, specialite_naf38, date, annee_sortie"

quietly foreach control in $controls {
	
	if "`control'" == "age_sortie_formation" {
		
		quietly forvalues i = 1(1)21 {
			
			egen m`control'_`i' = mean(`control'_`i') if !missing($nomiss)
			gen d`control'_`i' = `control'_`i' - m`control'_`i' if !missing($nomiss)
			drop `control'_`i' m`control'_`i'
			
		}
		
	}
	
	else if "`control'" == "niveau_pere" | "`control'" == "niveau_mere" {
		
		quietly forvalues i = 1(1)5 {
			
			egen m`control'_`i' = mean(`control'_`i') if !missing($nomiss)
			gen d`control'_`i' = `control'_`i' - m`control'_`i' if !missing($nomiss)
			drop `control'_`i' m`control'_`i'
			
		}
		
	}
	
	else if "`control'" == "pays_naissance_pere" | "`control'" == "pays_naissance_mere" {
		
		quietly forvalues i = 1(1)6 {
			
			egen m`control'_`i' = mean(`control'_`i') if !missing($nomiss)
			gen d`control'_`i' = `control'_`i' - m`control'_`i' if !missing($nomiss)
			drop `control'_`i' m`control'_`i'
			
		}
		
	}
	
	else if "`control'" == "zone_commune" {
		
		quietly forvalues i = 1(1)4 {
			
			egen m`control'_`i' = mean(`control'_`i') if !missing($nomiss)
			gen d`control'_`i' = `control'_`i' - m`control'_`i' if !missing($nomiss)
			drop `control'_`i' m`control'_`i'
			
		}
		
	}
	
	else if "`control'" == "dep_residence" {
		
		quietly forvalues i = 1(1)96 {
			
			egen m`control'_`i' = mean(`control'_`i') if !missing($nomiss)
			gen d`control'_`i' = `control'_`i' - m`control'_`i' if !missing($nomiss)
			drop `control'_`i' m`control'_`i'
			
		}
		
	}
	
	else if "`control'" == "region_etablissement" {
		
		quietly forvalues i = 1(1)23 {
			
			egen m`control'_`i' = mean(`control'_`i') if !missing($nomiss)
			gen d`control'_`i' = `control'_`i' - m`control'_`i' if !missing($nomiss)
			drop `control'_`i' m`control'_`i'
			
		}
		
	}
	
	else if "`control'" == "specialite_naf38" {
		
		quietly forvalues i = 1(1)27 {
			
			egen m`control'_`i' = mean(`control'_`i') if !missing($nomiss)
			gen d`control'_`i' = `control'_`i' - m`control'_`i' if !missing($nomiss)
			drop `control'_`i' m`control'_`i'
			
		}
		
	}
	
	else if "`control'" == "date" {
		
		quietly forvalues i = 1(1)42 {
			
			egen m`control'_`i' = mean(`control'_`i') if !missing($nomiss)
			gen d`control'_`i' = `control'_`i' - m`control'_`i' if !missing($nomiss)
			drop `control'_`i' m`control'_`i'
			
		}
		
	}
	
	else if "`control'" == "annee_sortie" {
		
		quietly forvalues i = 1(1)14 {
			
			egen m`control'_`i' = mean(`control'_`i') if !missing($nomiss)
			gen d`control'_`i' = `control'_`i' - m`control'_`i' if !missing($nomiss)
			drop `control'_`i' m`control'_`i'
			
		}
		
	}
	
	
	else {
		
		egen m`control' = mean(`control') if !missing($nomiss)
		gen d`control' = `control' - m`control' if !missing($nomiss)
		drop m`control'
		
	}
	
}

* nombre d'années après la sortie de formation
cap drop annee
gen annee = 1 if inrange(date, 11, 22)
replace annee = 2 if inrange(date, 23, 34)
replace annee = 3 if date > 35

* déclaration des macros
global controls "dhomme dage_sortie_formation_* dhandicap dpermis ddiplome dniveau_pere_* dniveau_mere_* dpays_naissance_pere_* dpays_naissance_mere_* ddep_residence_* dregion_etablissement_* dspecialite_naf38_* ddate_* dannee_sortie_*"
global nomiss "homme, age_sortie_formation, handicap, permis, diplome, niveau_pere, niveau_mere, pays_naissance_pere, pays_naissance_mere, dep_residence, region_etablissement, specialite_naf38, date, annee_sortie"
global keepvar1 "dhomme dpermis ddiplome"
global keepvar2 "dhomme dpermis ddiplome dretention_entreprise"
global condition "seq > 0"
global condition2 "annee == 3"
global outcomes "emploi chomage"

* régressions de l'emploi et du chômage sur apprentissage et caractéristiques du jeune
foreach outcome in $outcomes {
	
	if "`outcome'" == "emploi" {
		local table "reg_emploi"
	}
	else {
		local table "reg_chomage"
	}
	
	quietly reg `outcome' apprentissage if $condition & !missing($nomiss) [pweight=pondef], ro
	estimate store `outcome'1 
	outreg2 using $cheminout/Generation/`table'.doc, replace tex ctitle(`outcome') keep(apprentissage) addtext(Control Variables, No)
	
	quietly reg `outcome' apprentissage $controls if $condition & !missing($nomiss) [pweight=pondef], ro
	estimate store `outcome'2
	outreg2 using $cheminout/Generation/`table'.doc, append tex ctitle(`outcome') keep(apprentissage $keepvar1) addtext(Control Variables, Yes)
	
	quietly reg `outcome' apprentissage dretention_entreprise $controls if $condition & !missing($nomiss) [pweight=pondef], ro
	estimate store `outcome'3
	outreg2 using $cheminout/Generation/`table'.doc, append tex ctitle(`outcome') keep(apprentissage $keepvar2) addtext(Control Variables, Yes)
	
	quietly reg `outcome' apprentissage if $condition & $condition2 & !missing($nomiss) [pweight=pondef], ro
	estimate store `outcome'_unemp1
	outreg2 using $cheminout/Generation/`table'.doc, append tex ctitle(`outcome') keep(apprentissage) addtext(Control Variables, No)
	
	quietly reg `outcome' apprentissage $controls if $condition & $condition2 & !missing($nomiss) [pweight=pondef], ro
	estimate store `outcome'_unemp2
	outreg2 using $cheminout/Generation/`table'.doc, append tex ctitle(`outcome') keep(apprentissage $keepvar1) addtext(Control Variables, Yes)
	
	quietly reg `outcome' apprentissage dretention_entreprise $controls if $condition & $condition2 & !missing($nomiss) [pweight=pondef], ro
	estimate store `outcome'_unemp3
	outreg2 using $cheminout/Generation/`table'.doc, append tex ctitle(`outcome') keep(apprentissage $keepvar2) addtext(Control Variables, Yes)
		
	estout `outcome'1 `outcome'2 `outcome'3 `outcome'_unemp1 `outcome'_unemp2 `outcome'_unemp3, starlevels(* 0.10 ** 0.05 *** 0.01) /// 
	keep(_cons apprentissage $keepvar2) label wrap cells(b(star fmt(3)) se(par fmt(3))) stats(N) title("`var' ")
	
}


** Modele durée pour transitions non-emploi | chomage -> emploi (Table 4)

preserve

* elimination des personnes qui reprennent leurs études ou sont en formation continue
cap drop rep
bysort ident: gen rep=(situation=="Reprise d'etudes" | situation=="Formation continue")
cap drop idrep
bysort ident: egen idrep=max(rep)
drop if idrep==1

* elimination des annees d'étude
drop if situation=="Formation initiale"

* elimination des personnes employees dans entreprise où ils ont fait leurs études
drop if retention_entreprise==1

* definition des episodes de non-emploi et d'emploi
capture drop noemp
gen noemp=(situation=="Chomage" | situation=="Inactivite")

* time=0 pour la première date d'observation de chaque individu
bysort ident: egen t0=min(date)
bysort ident: gen time=date-t0

* Pour la censure, on remplace la derniere date par . pour les episodes de non-emploi
replace time=. if date==42 & noemp==1
stset time, failure(noemp==0) id(ident)
sts graph if time < 30, surv ci by(apprentissage) xtitle("Unemployment spell") 
sts graph if time < 30, haz ci by(apprentissage)

* Régressions de Cox
stcox apprentissage if !missing($nomiss)
stcox apprentissage $controls if !missing($nomiss)

restore


**** Modele durée pour transition chomage -> emploi

preserve

* elimination des personnes qui reprennent leurs études ou sont en formation continue
cap drop rep
bysort ident: gen rep=(situation=="Reprise d'etudes" | situation=="Formation continue")
cap drop idrep
bysort ident: egen idrep=max(rep)
drop if idrep==1

* elimination des annees d'étude
drop if situation=="Formation initiale"

* elimination des personnes employees dans entreprise où ils ont fait leurs études
drop if retention_entreprise==1

* elimination des personnes qui deviennent inactives 
bysort ident: gen ina=(situation=="Inactivite")
bysort ident: egen idina=max(ina)
drop if idina==1

* definition des episodes de chomage
capture drop noemp
gen noemp=(situation=="Chomage")

* time=0 pour la première date d'observation de chaque individu
bysort ident: egen t0=min(date)
bysort ident: gen time=date-t0

* Pour la censure, on remplace la derniere date par . pour les episodes de non-emploi
replace time=. if date==42 & noemp==1

stset time,failure(noemp==0) id(ident)

sts graph if time < 30, surv ci by(apprentissage)

sts graph if time < 30, haz ci by(apprentissage)

* Pas de difference de probabilité de transition non-emploi emploi avec modèle de hazard proportionnel en controlant pour les observables
stcox apprentissage if !missing($nomiss)
stcox apprentissage $controls if !missing($nomiss)

restore
