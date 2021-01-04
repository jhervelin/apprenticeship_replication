libname panel "";
libname gene2004 "";

/* ------------------------------
Creation du panel generation 2004
------------------------------ */

data panel;
	set gene2004.individu_completvge;
	/* filtre */
	/*if q16 = "2"; interruption des études avant 2010 = non -> pas disponible : attention à échantillon*/
	if q34 in ("2", "3", "4", "5"); /*orientation après la 3è = CAP-BEP*/
	if capbe = "1"; /*sortant de cap-bep = oui*/
	if niveau in ("5", "5b"); /*plus haut diplôme obtenu = cap-bep*/
	/* remplissage selon le timing de l'enquête
	if mois43 = "   ." then mois43 = mois42;
	if mois44 = "   ." then mois44 = mois42;
	if mois45 = "   ." then mois45 = mois42;
	selection des dimensions pour le panel : i (individus), j (temps)*/
	keep ident mois1-mois42;
run; /*5,774 obs*/

proc transpose data=panel out=panel prefix=mois; by ident; var mois1-mois42; run; /*242,508 obs obs*/

data panel;
	set panel;
	rename _LABEL_ = date_label;
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
	drop _NAME_ mois1;
run; /*242,508 obs obs*/

proc sql;
	create table panel as
	select a.ident, d.pondef, a.date, a.date_label, a.sequence, a.situation, b.duree as duree_nonemploi,
			c.duree as duree_emploi, c.natentr, c.ep11, c.ep12, c.ep13b, c.ep13c, c.ep13d, c.ep15,
			c.stat_emb, c.stat_fin, c.idnc, c.salprdeb, c.salprfin, c.ep49, c.ep54,
			c.ep71, c.ep80a, c.ep80b, c.ep80c, c.ep82b, c.ep83, c.nes, c.pcs_emb,
			d.cfa, d.impsp, d.q1, d.q7b, d.q31, d.age04,
			d.q44, d.q45, d.q48f,
			d.q33, d.q34a, d.regetab, d.q34, d.ca24,
			d.lieunper1, d.lieunmer1, d.ca7, d.ca8, d.sitpere, d.sitmere, d.ca23a, d.ca23d, d.tape,
			d.ap2a, d.ap2c, d.ap5a, d.ap8, d.ap16, d.ap17, d.depinter
	from panel as a
	left join gene2004.nonempl_completvge as b
		on a.ident = b.ident and a.sequence = b.nseq
	left join gene2004.seqentr_completvge as c
		on a.ident = c.ident and a.sequence = c.nseq
	left join gene2004.individu_completvge as d
		on a.ident = d.ident
	order by ident, date;
quit; /*242,508 obs obs*/


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

	/* type d'entreprise */
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
		if ep13b ^= "" then do;
			travail_anterieur_entreprise = 1;
			format type_travail_anterieur $13.;
			if ep13b = "1" then type_travail_anterieur = "Stage(s)";
			else if ep13b = "2" then type_travail_anterieur = "Apprentissage";
			else type_travail_anterieur = "Autre";
		end; else travail_anterieur_entreprise = 0;
	end;

	/* connaissance anterieure d'un salarie dans l'entreprise */
	if situation = "Emploi" then do;
		if ep13c ^= "" then do;
			connaissance_salarie_entreprise = 1;
			format type_connaissance_salarie $29.;
			if ep13d = "1" then type_connaissance_salarie = "Reseau professionnel";
			else if ep13d = "2" then type_connaissance_salarie = "Reseau prive";
			else if ep13d = "3" then type_connaissance_salarie = "Reseau prive et professionnel";
			else type_connaissance_salarie = "Autre";
		end; else connaissance_salarie_entreprise = 0;
	end;

	/* connaissance embauche dans entreprise */
	if situation = "Emploi" then do;
		if ep15 ^= "" then do;
			format connaissance_embauche $32.;
			if ep15 in ("1", "2", "3", "4") then connaissance_embauche = "Structure publique";
			else if ep15 = "5" then connaissance_embauche = "Relation privee";
			else if ep15 in ("6", "7") then connaissance_embauche = "Annonce ou candidature spontanee";
			else connaissance_embauche = "Autre";
		end; else connaissance_embauche = "";
	end;

	/* formation par entreprise */
	if situation = "Emploi" then do;
		if ep71 = "1" then formation_debut = 1;
		else formation_debut = 0;
	end;

	/* depart de l'entreprise */
	if situation = "Emploi" then do;
		format raison_depart $14.;
		if ep80a = "" and ep80b = "" and ep80c = "" then raison_depart = "";
		else if ep80a = "2" or ep80b = "2" or ep80c = "1" then raison_depart = "Demission";
		else if ep80a = "3" or ep80c = "2" then raison_depart = "Licenciement";
		else if ep80a = "4" or ep80b = "1" then raison_depart = "Mutation";
		else if ep80c = "3" then raison_depart = "Fin du contrat";
		else raison_depart = "Autre";
	end;

	/* motif de demission */
	if raison_depart = "Demission" then do;
		format motif_demission $38.;
		if ep83 = "1" then motif_demission = "Un travail plus interessant";
		if ep83 = "2" then motif_demission = "Des conditions de travail moins penible";
		if ep83 = "3" then motif_demission = "Un travail a temps plein";
		if ep83 = "4" then motif_demission = "Un meilleur salaire (horaire)";
		if ep83 = "5" then motif_demission = "Arreter de travailler";
		if ep83 = "6" then motif_demission = "Pour une autre raison";
	end;

	/* souhait de rester dans l'entreprise malgre depart */
	if situation = "Emploi" and raison_depart ^= "" then do;
		if ep82b = "1" then volonte_rester = 1;
		else volonte_rester = 0;
	end;

	/* -- VARIABLES DE STAGES -- */
	
	/* stages */
	if q44 = "1" then stages = 1;
	else if q44 = "2" then stages = 0;
	else stages = .;

	/* nombre de stages */
	nb_stages = input(q45, 1.);

	/* -- VARIABLES GENERALES -- */

	/* raffinement de la situation */
	if situation = "Emploi" then do;
		if idnc = "" then do;
			if stat_emb = "01" then situation = "Independant";
			else if stat_emb in ("03", "04") then situation = "Emploi permanent";
			else situation = "Emploi temporaire";
		end; else do;
			if date < input(idnc, 2.) then do;
			if stat_emb = "01" then situation = "Independant";
			else if stat_emb in ("03", "04") then situation = "Emploi permanent";
				else situation = "Emploi temporaire";
			end; else do;
			if stat_emb = "01" then situation = "Independant";
			else if stat_emb in ("03", "04") then situation = "Emploi permanent";
				else situation = "Emploi temporaire";
			end;
		end;
	end;

	/* etablissement de formation */
	if cfa = "1" then centre_apprentissage = 1;
	else centre_apprentissage = 0;

	/* region de l'etablissement */
	region_etablissement = regetab;

	/* formation par apprentissage */
	if q34 in ("2", "4") then do;
		apprentissage = 1;
		stages = .;
		duree_travail_formation = 24;
	end;
	else do;
		if cfa = "1" then apprentissage = 1;
		else apprentissage = 0;
	end;

	/* -- VARIABLES D'APPRENTISSAGE -- */
	
	if apprentissage = 1 then do;
		/* recherche de l'entreprise de formation */
		format entreprise_apprentissage $20.;
		if ap2a = "2" then entreprise_apprentissage = "cfa";
		else if ap2a = "1" then do;
			if substr(ap2c, 1, 1) in ("1", "2") then entreprise_apprentissage = "autre aide publique";
			else if substr(ap2c, 1, 1) = "4" then entreprise_apprentissage = "college";
			else if substr(ap2c, 1, 1) = "5" then entreprise_apprentissage = "famille ou amis";
			else if substr(ap2c, 1, 1) in ("6", "7") then entreprise_apprentissage = "soi-meme";
		end;
		else if ap2a = "3" then do;
			if substr(ap2c, 1, 1) in ("1", "2") then entreprise_apprentissage = "autre aide publique";
			else if substr(ap2c, 1, 1) = "4" then entreprise_apprentissage = "college";
			else if substr(ap2c, 1, 1) = "5" then entreprise_apprentissage = "famille ou amis";
			else if substr(ap2c, 1, 1) in ("6", "7") then entreprise_apprentissage = "autre";
		end;
		else entreprise_apprentissage = "";

		/* départ entreprise */
		if ap5a = "1" then depart_entr_apprentissage = 1;
		else if ap5a = "2" then depart_entr_apprentissage = 0;
		else depart_entr_apprentissage = .;

		/* tuteur */
		if ap8 = "1" then tuteur_apprentissage = 1;
		else if ap8 = "2" then tuteur_apprentissage = 0;
		else tuteur_apprentissage = .;

		/* embauche par l'entreprise */
		if ap16 = "1" then embauche_entr_appr = 1;
		else if ap16 = "2" then embauche_entr_appr = 0;
		else embauche_entr_appr = .;

		/* travaille plus tard dans l'entreprise */
		if ap17 = "1" then embauche_tard_entr_appr = 1;
		else if ap17 = "2" then embauche_tard_entr_appr = 0;
		else embauche_tard_entr_appr = .;
	end;

	/* obtention du diplome */
	if q7b = "1" then diplome = 1;
	else diplome = 0;

	/* âge a la sortie de formation */
	age_sortie_formation = age04;

	/* sexe */
	if q1 = "2" then femme = 1;
	else femme = 0;

	/* lieu de résidence à la date de l'enquête */
	rename depinter = dep_residence;

	/* redoublement avant la 6e */
	if q31 in ("04", "05", "06") then redoublement = 1;
	else if q31 in ("01", "02", "03") then redoublement = 0;
	else redoublement = .;

	/* classe de 3e suivie */
	if q33 = "1" then troisieme_generale = 1;
	else if q33 in ("2", "3", "4") then troisieme_generale = 0;
	else troisieme_generale = .;

	/* premier voeu d'orientation */
	if q34a = "1" then premier_voeu = 1;
	else premier_voeu = 0;

	/* a connu des discriminations a l'embauche */
	if ca24 = "1" then discrimination = 1;
	else if ca24 = "2" then discrimination = 0;
	else discrimination = .;

	/* pays de naissance du pere */
	format pays_naissance_pere $11.;
	if lieunper1 = "00" then pays_naissance_pere = "France";
	else if lieunper1 in ("01", "02", "03", "04", "05") then pays_naissance_pere = "Europe";
	else if lieunper1 = "09" then pays_naissance_pere = "Asie";
	else if lieunper1 = "08" then pays_naissance_pere = "Afrique";
	else if lieunper1 = "10" then pays_naissance_pere = "Amérique";
	else if lieunper1 in ("06", "07") then pays_naissance_pere = "Pays arabes";
	else pays_naissance_pere = "";

	/* pays de naissance de la mere */
	format pays_naissance_mere $11.;
	if lieunmer1 = "00" then pays_naissance_mere = "France";
	else if lieunmer1 in ("01", "02", "03", "04", "05") then pays_naissance_mere = "Europe";
	else if lieunmer1 = "09" then pays_naissance_mere = "Asie";
	else if lieunmer1 = "08" then pays_naissance_mere = "Afrique";
	else if lieunmer1 = "10" then pays_naissance_mere = "Amérique";
	else if lieunmer1 in ("06", "07") then pays_naissance_mere = "Pays arabes";
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
	if sitpere = "1" then emploi_pere = 1;
	else if sitpere in ("2", "3", "4", "5", "6", "7") then emploi_pere = 0;
	else emploi_pere = .;

	/* la mere travaille */
	if sitmere = "1" then emploi_mere = 1;
	else if sitmere in ("2", "3", "4", "5", "6", "7") then emploi_mere = 0;
	else emploi_mere = .;

	/* handicap */
	if ca23a = "1" and ca23d in ("1", "2", "3") then handicap = 1;
	else handicap = 0;

	/* duree pour obtenir un premier cdi */
	duree_pour_emploi = tape;

	/* duree de la formation initiale */
	if situation = "Formation initiale" and duree = . then duree = age_sortie_formation - 6;

	/* source des données */
	generation = "G2004";

	/* -- SUPRESSION DES VARIABLES INITIALES -- */
	drop duree_nonemploi duree_emploi stat_emb stat_fin idnc ep49 ep54 temps_travail salprdeb salprfin
		natentr ep11 ep12 ep13b ep13c ep13d ep15 ep71 ep80a ep80b ep80c ep82b ep83
		cfa regetab q34 q7b q1 q31 q33 q34a ca24 sequence q44 q45 q48f ap2a ap2c ap5a ap8 ap16 ap17
		lieunper1 lieunmer1 ca7 ca8 sitpere sitmere ca23a ca23d tape age04 pcs_emb nes;
run; /*242,508 obs*/


/* specialite du diplome */
proc import out=diplome datafile="C:\Users\jeremy.hervelin\Desktop\CH19\Annexes\specialite_diplome.xlsx" dbms=excelcs replace;
range="Spécialités$"; run;

proc sort data=diplome nodupkey; by impsp; run;

proc sql;
	create table panel.panel_generation2004 as
	select a.generation, a.ident, a.pondef, a.date, a.date_label, a.seq, a.situation, a.duree, a.femme,
			a.pays_naissance_pere, a.nationalite_pere, a.emploi_pere, a.pays_naissance_mere, a.nationalite_mere, a.emploi_mere, a.handicap,
			a.redoublement, a.troisieme_generale, a.premier_voeu,
			a.centre_apprentissage, a.region_etablissement, a.apprentissage, a.entreprise_apprentissage, a.depart_entr_apprentissage,
			a.tuteur_apprentissage, a.embauche_entr_appr, a.embauche_tard_entr_appr,
			b.naf10 as specialite_naf10, b.naf38 as specialite_naf38, a.diplome, a.age_sortie_formation,
			a.stages, a.nb_stages, a.duree_travail_formation,
			a.duree_pour_emploi, a.temps_complet, a.remuneration, a.remuneration_debut, a.remuneration_fin,
			a.pcs, a.naf, a.secteur_prive, a.multi_etablissement, a.taille_entreprise,
			a.travail_anterieur_entreprise, a.type_travail_anterieur, a.connaissance_salarie_entreprise, a.type_connaissance_salarie, a.connaissance_embauche,
			a.formation_debut, a.raison_depart, a.motif_demission, a.volonte_rester, a.discrimination, a.dep_residence
	from panel as a
	left join diplome as b
	on a.impsp = b.impsp
	order by ident, date;
quit; /*242,508 obs*/
