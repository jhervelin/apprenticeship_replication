libname panel "";
libname gene2013 "";

/* ------------------------------
Creation du panel generation 2010
------------------------------ */

data panel;
	set gene2013.G13individusvf;
	/* filtre */
	if q16 = "2"; /*interruption des études avant 2013 = non*/
	if q34 in ("2", "3", "4"); /*orientation après la 3è = CAP-BEP*/
	if capbe = "1"; /*sortant de cap-bep = oui*/
	if substr(phinsee, 1, 1) = "5"; /*plus haut diplôme obtenu = cap-bep*/
	/* remplissage selon le timing de l'enquête
	if mois43 = "   ." then mois43 = mois42;
	if mois44 = "   ." then mois44 = mois42;
	if mois45 = "   ." then mois45 = mois42;
	selection des dimensions pour le panel : i (individus), j (temps)*/
	keep ident mois1-mois42;
run; /*687 obs*/

proc transpose data=panel out=panel prefix=mois; by ident; var mois1-mois42; run; /*28,854 obs obs*/

data panel;
	set panel;
	date_label = scan(_LABEL_, 3, " ");
	/* date */
	date = input(substr(_NAME_, 5, 2), 2.);
	/* sequence */
	format sequence $2.;
	sequence = substr(mois1, 3, 2);
	/* situation */
	format situation $25.;
	if substr(mois1, 1, 2) in ("", "22") then situation = "Formation initiale";
	if substr(mois1, 1, 2) in ("01", "02", "03", "04", "20") then situation = "Emploi";
	if substr(mois1, 1, 2) in ("05", "06", "11", "12") then situation = "Chomage";
	if substr(mois1, 1, 2) in ("07", "08", "13", "14", "21") then situation = "Inactivite";
	if substr(mois1, 1, 2) in ("09", "10", "15", "16") then situation = "Formation continue";
	if substr(mois1, 1, 2) in ("17", "18") then situation = "Reprise d'etudes";
	/* suppression des variables initiales */
	drop _NAME_ _LABEL_ mois1;
run; /*28,854 obs obs*/

proc sql;
	create table panel as
	select a.ident, d.pondef, a.date, a.date_label, a.sequence, a.situation, b.duree as duree_nonemploi,
			c.duree as duree_emploi, c.natentr, c.ep11, c.ep12, c.ep13a, c.ep13b, c.naf, c.pcs_emb,
			c.contrat_emb, c.contrat_fin, c.idnc, c.salprsdeb, c.salprsfin, c.revdeb, c.revfin, c.ep49, c.ea53, c.dpm4,
			d.cfa, d.impsp, d.q1, d.age13, d.q7b, d.q20, d.q31,
			d.sixiemestatutuu, d.q33, d.q34s, d.q34a, d.regetab, d.q34bc, d.q34e,
			d.op2, d.op6, d.op7b, d.ca24, d.ca0adep,
			d.lieunper, d.lieunmer, d.ca7, d.ca8, d.ca9c, d.ca10c, d.ca11, d.ca12, d.tape
	from panel as a
	left join gene2013.g13nonempvf as b
		on a.ident = b.ident and a.sequence = b.nseq
	left join gene2013.g13seqentrvf as c
		on a.ident = c.ident and a.sequence = c.nseq
	left join gene2013.g13individusvf as d
		on a.ident = d.ident
	order by ident, date;
quit; /*28,854 obs obs*/

/* creation des variables */

data panel;
	set panel;

	/* numéro de la séquence */
	seq = input(sequence, 2.);
	if seq = . then seq = 0;

	/* duree de la situation */
	duree = input(duree_nonemploi, 2.);
	if duree = . then duree = input(duree_emploi, 2.);

	/* -- VARIABLES D'EMPLOI -- */

	/* temps de travail */
	if situation = "Emploi" then do;
		if idnc = "" then temps_travail = ep49;
		else temps_travail = ea53;
		/*-*/
		if temps_travail = "1" then temps_complet = 1;
		else temps_complet = 0;
	end;

	/* remuneration */
	if situation = "Emploi" then do;
		remuneration = salprsdeb;
		if remuneration = . then remuneration = revdeb;
		if remuneration = . then remuneration = salprsfin;
		if remuneration = . then remuneration = revfin;
		remuneration_debut = salprsdeb;
		remuneration_fin = salprsfin;
	end;

	/* catégorie à l'embauche */
	if situation = "Emploi" then do;
		pcs = pcs_emb;
	end;

	/* secteur d'activite */
	if situation = "Emploi" then do;
		if natentr = "40" then secteur_prive = 1;
		else secteur_prive = 0;
	end;

	/* multi-etablissement */
	if situation = "Emploi" then do;
		if ep11 = "1" then multi_etablissement = 1;
		else if ep11 = "2" then multi_etablissement = 0;
		else multi_etablissement = .;
	end;

	/* taille de l'entreprise */
	if situation = "Emploi" then do;
		format taille_entreprise $16.;
		if ep12 in ("1", "2", "3") then taille_entreprise = "Micro-entreprise";
		else if ep12 in ("4", "5", "6") then taille_entreprise = "PME";
		else if ep12 in ("7", "8") then taille_entreprise = "ETI-GE";
		else taille_entreprise = "";
	end;

	/* travail anterieur dans l'entreprise */
	if situation = "Emploi" then do;
		if ep13a ^= "" or ep13b ^= "" then do;
			travail_anterieur_entreprise = 1;
			format type_travail_anterieur $13.;
			if ep13a = "1" or ep13a = "2" then type_travail_anterieur = "Stage(s)";
			if ep13b = "1" then type_travail_anterieur = "Apprentissage";
		end; else travail_anterieur_entreprise = 0;
	end;

	/* formation par entreprise */
	if situation = "Emploi" then do;
		if ea53 = "1" then formation_debut = 1;
		else formation_debut = 0;
	end;

	/* souhait de rester dans l'entreprise malgre depart */
	if situation = "Emploi" then do;
		if dpm4 = "1" then volonte_rester = 1;
		else volonte_rester = 0;
	end;

	/* -- VARIABLES GENERALES -- */

	/* raffinement de la situation */
	if situation = "Emploi" then do;
		if idnc = "" then do;
			if substr(contrat_emb, 1, 2) = "01" then situation = "Independant";
			else if substr(contrat_emb, 1, 2) = "02" then situation = "Emploi permanent";
			else situation = "Emploi temporaire";
		end; else do;
			if date < input(idnc, 2.) then do;
				if substr(contrat_emb, 1, 2) = "01" then situation = "Independant";
				else if substr(contrat_emb, 1, 2) = "02" then situation = "Emploi permanent";
				else situation = "Emploi temporaire";
			end; else do;
				if substr(contrat_fin, 1, 2) = "01" then situation = "Independant";
				else if substr(contrat_fin, 1, 2) = "02" then situation = "Emploi permanent";
				else situation = "Emploi temporaire";
			end;
		end;
	end;

	/* lieu de résidence à la date de l'enquête */
	rename ca0adep = dep_residence;

	/* etablissement de formation */
	if cfa = "1" then centre_apprentissage = 1;
	else centre_apprentissage = 0;

	/* region de l'etablissement */
	region_etablissement = regetab;

	/* formation par apprentissage */
	if q34s = "1" then do;
		apprentissage = 1;
		stages = .;
		duree_travail_formation = 24;
	end;
	else do;
		if cfa = "1" then apprentissage = 1;
		else apprentissage = 0;
	end;

	/* aurait préféré faire un apprentissage */
	if apprentissage = 0 then do;
		if q34bc = "1" then souhait_apprentissage = 1;
		else if q34bc = "2" then souhait_apprentissage = 0;
		else souhait_apprentissage = .;
	end;

	/* raison du non apprentissage */
	if souhait_apprentissage = 1 then do;
		format raison_non_apprenti $30.;
		if lengthn(q34e) = 1 then do;
			if q34e = "1" then raison_non_apprenti = "pas de cfa";
			else if q34e = "2" then raison_non_apprenti = "pas d'employeur";
			else if q34e ^= "" and raisnon_non_apprenti = "" then raison_non_apprenti = "autre";
		end;
		else if q34e = "12" or q34e = "21" then raison_non_apprenti = "pas de cfa, ni d'employeur";
		else raison_non_apprenti = "";
	end;

	/* obtention du diplome */
	if q7b = "1" then diplome = 1;
	else diplome = 0;

	/* âge a la sortie de formation */
	age_sortie_formation = age13;

	/* sexe */
	if q1 = "2" then femme = 1;
	else femme = 0;

	/* redoublement avant la 6e */
	if q31 = "1" then redoublement = 1;
	else if q31 = "2" then redoublement = 0;
	else redoublement = .;

	/* zone de la commune de residence en 6e */
	format zone_commune $12.;
	if sixiemestatutuu = "C" then zone_commune = "Centre-ville";
	else if sixiemestatutuu = "B" then zone_commune = "Banlieue";
	else if sixiemestatutuu = "I" then zone_commune = "Ville isolee";
	else if sixiemestatutuu = "R" then zone_commune = "Rural";
	else zone_commune = "";

	/* classe de 3e suivie */
	if q33 = "1" then troisieme_generale = 1;
	else if q33 in ("2", "3", "4") then troisieme_generale = 0;
	else troisieme_generale = .;

	/* premier voeu d'orientation */
	if q34a = "1" then premier_voeu = 1;
	else premier_voeu = 0;

	/* satisfaction par rapport a la situation actuelle a la date de l'enquête */
	if op2 = "1" then satisfait = 1;
	else if op2 = "2" then satisfait = 0;
	else satisfait = .;

	/* optimisme sur le futur */
	if op6 = "1" then optimisme = 1;
	else if op6 = "2" then optimisme = 0;
	else optimisme = .; 

	/* envisage de se mettre independant */
	if op7b = "2" or op7b = "3" then independant = 1;
	else if op7b = "4" then independant = 0;
	else independant = .; 

	/* a connu des discriminations a l'embauche */
	if ca24 = "1" then discrimination = 1;
	else if ca24 = "2" then discrimination = 0;
	else discrimination = .;

	/* pays de naissance du pere */
	format pays_naissance_pere $11.;
	if lieunper = "00" then pays_naissance_pere = "France";
	else if lieunper in ("01", "02", "03", "04", "05") then pays_naissance_pere = "Europe";
	else if lieunper = "09" then pays_naissance_pere = "Asie";
	else if lieunper = "08" then pays_naissance_pere = "Afrique";
	else if lieunper = "10" then pays_naissance_pere = "Amérique";
	else if lieunper in ("06", "07") then pays_naissance_pere = "Pays arabes";
	else pays_naissance_pere = "";

	/* pays de naissance de la mere */
	format pays_naissance_mere $11.;
	if lieunmer = "00" then pays_naissance_mere = "France";
	else if lieunmer in ("01", "02", "03", "04", "05") then pays_naissance_mere = "Europe";
	else if lieunmer = "09" then pays_naissance_mere = "Asie";
	else if lieunmer = "08" then pays_naissance_mere = "Afrique";
	else if lieunmer = "10" then pays_naissance_mere = "Amérique";
	else if lieunmer in ("06", "07") then pays_naissance_mere = "Pays arabes";
	else pays_naissance_mere = "";

	/* nationalite du pere */
	if ca7 in ("1", "2", "4") then nationalite_pere = 1;
	else if ca7 = "3" then nationalite_pere = 0;
	else nationalite_pere = .;
	if pays_naissance_pere = "France" and nationalite_pere = . then nationalite_pere = 1;

	/* nationalite de la mere */
	if ca8 in ("1", "2", "4") then nationalite_mere = 1;
	else if ca8 = "3" then nationalite_mere = 0;
	else nationalite_mere = .;
	if pays_naissance_mere = "France" and nationalite_mere = . then nationalite_mere = 1;

	/* le pere travaille */
	if ca9c in ("1", "2", "3", "4", "5", "6") then emploi_pere = 1;
	else if ca9c in ("7", "8", "9") then emploi_pere = 0;
	else emploi_pere = .;

	/* la mere travaille */
	if ca10c in ("1", "2", "3", "4", "5", "6") then emploi_mere = 1;
	else if ca10c in ("7", "8", "9") then emploi_mere = 0;
	else emploi_mere = .;

	/* niveau d'etude du pere */
	format niveau_pere $9.;
	if ca11 = "1" then niveau_pere = "Niveau VI";
	else if ca11 = "2" then niveau_pere = "Niveau V";
	else if ca11 = "3" then niveau_pere = "Niveau IV";
	else if ca11 = "4" then niveau_pere = "Niveau III";
	else if ca11 = "5" then niveau_pere = "Niveau II";
	else if ca11 = "6" then niveau_pere = "Niveau I";
	else niveau_pere = "";

	/* niveau d'etude de la mere */
	format niveau_mere $9.;
	if ca12 = "1" then niveau_mere = "Niveau VI";
	else if ca12 = "2" then niveau_mere = "Niveau V";
	else if ca12 = "3" then niveau_mere = "Niveau IV";
	else if ca12 = "4" then niveau_mere = "Niveau III";
	else if ca12 = "5" then niveau_mere = "Niveau II";
	else if ca12 = "6" then niveau_mere = "Niveau I";
	else niveau_mere = "";

	/* duree pour obtenir un premier emploi */
	duree_pour_emploi = tape;

	/* duree de la formation initiale */
	if situation = "Formation initiale" and duree = . then duree = age_sortie_formation - 6;

	/* source des données */
	generation = "G2013";

	/* -- SUPRESSION DES VARIABLES INITIALES -- */
	drop duree_nonemploi duree_emploi contrat_emb contrat_fin idnc ep49 temps_travail salprsdeb salprsfin revdeb revfin
		natentr ep11 ep12 ep13a ep13b ea53 dpm4 pcs_emb
		cfa regetab q34s q7b q20 q1 age13 sequence
		q31 sixiemestatutuu q33 q34a q34bc q34e op2 op6 op7b ca24
		lieunper lieunmer ca7 ca8 ca9c ca10c ca11 ca12 tape;
run; /*28,854 obs*/


/* specialite du diplome */
proc import out=diplome datafile="C:\Users\jeremy.hervelin\Desktop\CH19\Annexes\specialite_diplome.xlsx" dbms=excelcs replace;
range="Spécialités$"; run;

proc sort data=diplome nodupkey; by impsp; run;

proc sql;
	create table panel.panel_generation2013 as
	select a.generation, a.ident, a.pondef, a.date, a.date_label, a.seq, a.situation, a.duree, a.femme,
			a.pays_naissance_pere, a.nationalite_pere, a.emploi_pere, a.niveau_pere,
			a.pays_naissance_mere, a.nationalite_mere, a.emploi_mere, a.niveau_mere,
			a.zone_commune, a.redoublement, a.troisieme_generale, a.premier_voeu,
			a.centre_apprentissage, a.region_etablissement, a.apprentissage, a.souhait_apprentissage, a.raison_non_apprenti, b.naf10 as specialite_naf10, b.naf38 as specialite_naf38, a.diplome, a.age_sortie_formation,
			a.duree_travail_formation, a.duree_pour_emploi, a.temps_complet, a.remuneration, a.remuneration_debut, a.remuneration_fin, a.pcs, a.naf,
			a.secteur_prive, a.multi_etablissement, a.taille_entreprise, a.travail_anterieur_entreprise, a.type_travail_anterieur,
			a.formation_debut, a.volonte_rester, a.optimisme, a.independant, a.discrimination, a.dep_residence
	from panel as a
	left join diplome as b
	on a.impsp = b.impsp
	order by ident, date;
quit; /*28,854 obs*/


