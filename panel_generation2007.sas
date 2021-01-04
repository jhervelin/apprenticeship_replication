libname panel "";
libname gene2007 "";

/* ------------------------------
Creation du panel generation 2010
------------------------------ */

data panel;
	set gene2007.g07individus06sspi;
	/* filtre */
	if q16 = "2"; /*interruption des études avant 2010 = non*/
	if q34 in ("2", "3", "4", "5"); /*orientation après la 3è = CAP-BEP*/
	if capbe = "1"; /*sortant de cap-bep = oui*/
	if niveau in ("5", "5b"); /*plus haut diplôme obtenu = cap-bep*/
	keep ident mois1-mois42;
run; /*2,139 obs*/

proc transpose data=panel out=panel prefix=mois; by ident; var mois1-mois42; run; /*89,838 obs obs*/

data panel;
	set panel;
	date_label = scan(_LABEL_, 3, " ");
	/* date */
	date = input(substr(_NAME_, 5, 2), 2.);
	/* sequence */
	format sequence $2.;
	sequence = substr(mois1, 3, 2);
	seq = input(sequence, 2.);
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
run; /*89,838 obs obs*/

proc sql;
	create table panel as
	select a.ident, d.pondef_bref as pondef, a.date, a.date_label, a.sequence, a.situation, b.duree as duree_nonemploi,
			c.duree as duree_emploi, c.natentr, c.ep11, c.ep12, c.ep15A, c.nes, c.pcs_emb,
			c.stat_emb, c.stat_fin, c.salprdeb, c.salprfin, c.ep49, c.ep54,
			d.cfa, d.impsp, d.q1, d.q2, d.q7b, d.q20, d.q31, d.nb_stages,
			d.q31, d.q34, d.lieunper, d.lieunmer, d.ca9, d.regetab, d.depinter
	from panel as a
	left join gene2007.g07nonemp05sspi as b
		on a.ident = b.ident and a.seq = b.nseq
	left join gene2007.g07seqentr07sspi as c
		on a.ident = c.ident and a.seq = c.nseq
	left join gene2007.g07individus06sspi as d
		on a.ident = d.ident
	order by ident, date;
quit; /*89,838 obs obs*/


/* creation des variables */

data panel;
	set panel;

	/* numéro de la séquence */
	seq = input(sequence, 2.);
	if seq = . then seq = 0;

	/* duree de la situation */
	duree = duree_nonemploi;
	if duree = . then duree = duree_emploi;

	/* -- VARIABLES D'EMPLOI -- */

	/* temps de travail */
	if situation = "Emploi" then do;
		temps_travail = ep49;
		if temps_travail = "" then temps_travail = ep54;
		if temps_travail = "1" then temps_complet = 1;
		else temps_complet = 0;
	end;

	/* remuneration */
	if situation = "Emploi" then do;
		remuneration = salprdeb;
		if remuneration = . then remuneration = salprfin;
		remuneration_debut = salprdeb;
		remuneration_fin = salprfin;
	end;

	/* catégorie à l'embauche */
	if situation = "Emploi" then do;
		pcs = pcs_emb;
	end;

	/* secteur d'activité */
	if situation = "Emploi" then do;
		naf = nes;
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

	/* connaissance embauche dans entreprise */
	if situation = "Emploi" then do;
		if ep15a ^= "" then do;
			format connaissance_embauche $32.;
			if ep15a in ("1", "2", "3", "4") then connaissance_embauche = "Structure publique";
			else if ep15a in ("5", "6") then connaissance_embauche = "Relation privee";
			else if ep15a in ("7", "8") then connaissance_embauche = "Annonce ou candidature spontanee";
			else connaissance_embauche = "Autre";
		end; else connaissance_embauche = "";
	end;
	
	/* nombre de stages */
	nb_stages = nb_stages;

	/* -- VARIABLES GENERALES -- */

	/* raffinement de la situation */
	if situation = "Emploi" then do;
		if stat_emb = "01" then situation = "Indepedant";
		else if stat_emb in ("03", "04") then situation = "Emploi permanent";
		else situation = "Emploi temporaire";
	end;

	/* etablissement de formation */
	if cfa = "1" then centre_apprentissage = 1;
	else centre_apprentissage = 0;

	/* region de l'etablissement */
	region_etablissement = regetab;

	/* formation par apprentissage */
	if q34 in ("2", "4") then do;
		apprentissage = 1;
		nb_stages = .;
	end;
	else do;
		if cfa = "1" then apprentissage = 1;
		else apprentissage = 0;
	end;

	/* obtention du diplome */
	if q7b = "1" then diplome = 1;
	else diplome = 0;

	/* âge a la sortie de formation */
		/* date de naissance */
	 	jour = 1;
		mois = 1;
		annee = input(compress("19"!!q2), 4.);
		date_naissance = mdy(mois, jour, annee);
		/* date de sortie de formation */
		if q20 in ("10", "11", "12", "13", "14") then do;
			mois_sortie = input(q20, 2.) - 2;
			annee_sortie = 2010;
		end; else do;
			mois_sortie = input(q20, 2.) - 14;
			annee_sortie = 2011;
		end;
		if q20 in ("10", "12", "14", "15", "17", "19", "21", "22", "24") then jour_sortie = 31;
			else if q20 = "16" then jour_sortie = 28;
			else jour_sortie = 30;
		date_sortie = mdy(mois_sortie, jour_sortie, annee_sortie);
	age_sortie_formation = int((intck('month',date_naissance,date_sortie)-(day(date_naissance)>day(date_sortie)))/12); /* age_sortie = date sortie formation - date naissance */

	/* sexe */
	if q1 = "2" then femme = 1;
	else femme = 0;

	/* lieu de résidence à la date de l'enquête */
	rename depinter = dep_residence;

	/* redoublement avant la 6e */
	if q31 in ("04", "05", "06") then redoublement = 1;
	else if q31 in ("01", "02", "03") then redoublement = 0;
	else redoublement = .;

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

	/* le pere travaille */
	if ca9 = "1" then emploi_pere = 1;
	else if ca9 in ("2", "3") then emploi_pere = 0;
	else emploi_pere = .;

	/* duree de la formation initiale */
	if situation = "Formation initiale" and duree = . then duree = age_sortie_formation - 6;

	/* source des données */
	generation = "G2007";

	/* -- SUPRESSION DES VARIABLES INITIALES -- */
	drop duree_nonemploi duree_emploi ep49 ep54 temps_travail sequence
		natentr ep11 ep12 q31 lieunper lieunmer ca9 ep15a stat_emb stat_fin salprdeb salprfin nes pcs_emb
		cfa regetab q34 q7b q2 q20 jour mois annee date_naissance mois_sortie annee_sortie jour_sortie date_sortie q1;
run; /*89,838 obs*/


/* specialite du diplome */
proc import out=diplome datafile="C:\Users\jeremy.hervelin\Desktop\CH19\Annexes\specialite_diplome.xlsx" dbms=excelcs replace;
range="Spécialités$"; run;

proc sort data=diplome nodupkey; by impsp; run;

proc sql;
	create table panel.panel_generation2007 as
	select a.generation, a.ident, a.pondef, a.date, a.date_label, a.seq, a.situation, a.duree, a.femme,
			a.pays_naissance_pere, a.emploi_pere, a.pays_naissance_mere, a.redoublement,
			a.centre_apprentissage, a.region_etablissement, a.apprentissage, b.naf10 as specialite_naf10, b.naf38 as specialite_naf38, a.diplome,
			a.age_sortie_formation, a.nb_stages, a.temps_complet, a.remuneration, a.remuneration_debut, a.remuneration_fin, a.pcs, a.naf,
			a.secteur_prive, a.multi_etablissement, a.taille_entreprise, a.connaissance_embauche, a.dep_residence
	from panel as a
	left join diplome as b
	on a.impsp = b.impsp
	order by ident, date;
quit; /*89,838 obs*/
