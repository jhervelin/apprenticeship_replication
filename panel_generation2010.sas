libname panel "C:\Users\jeremy.hervelin\Desktop\CH19";
libname gene2010 "C:\Users\jeremy.hervelin\Desktop\CH19\G2010";

/* ------------------------------
Creation du panel generation 2010
------------------------------ */

data panel;
	set gene2010.indiv10vf2;
	/* filtre */
	if q16 = "2"; /*interruption des études avant 2010 = non*/
	if q34 = "2"; /*orientation après la 3è = CAP-BEP*/
	if capbe = "1"; /*sortant de cap-bep = oui*/
	if substr(phinsee, 1, 1) = "5"; /*plus haut diplôme obtenu = cap-bep*/
	/* remplissage selon le timing de l'enquête
	if mois43 = "   ." then mois43 = mois42;
	if mois44 = "   ." then mois44 = mois42;
	if mois45 = "   ." then mois45 = mois42;
	selection des dimensions pour le panel : i (individus), j (temps)*/
	keep ident mois1-mois42;
run; /*2,476 obs*/

proc transpose data=panel out=panel prefix=mois; by ident; var mois1-mois42; run; /*103,992 obs obs*/

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
run; /*103,992 obs obs*/

proc sql;
	create table panel as
	select a.ident, d.pondef, a.date, a.date_label, a.sequence, a.situation, b.duree as duree_nonemploi,
			c.duree as duree_emploi, c.natentr, c.ep11, c.ep12, c.ep13b, c.ep13c, c.ep13d, c.ep15t,
			c.contrat_emb, c.contrat_fin, c.idnc, c.salprsdeb, c.salprsfin, c.revdeb, c.revfin, c.ep49, c.ep54, c.idnt,
			c.ep71, c.ep80a, c.ep80b, c.ep80c, c.ep82b, c.ep83, c.naf, c.pcs_emb,
			d.cfa, d.impsp, d.q1, d.q2, d.q3, d.q7b, d.q20, d.q31,
			d.fp1, d.fp1a, d.fp2b, d.fp3, d.fp3b, d.fp4, d.fp10, d.fp12, d.fp18,
			d.sixiemestatutuu, d.q33, d.q34s, d.q34a, d.regetab, d.q34bc, d.q34e, d.os2, d.os3, d.etr1b,
			d.op2, d.op6, d.op7, d.p03c, d.p03d, d.ca24, d.ca0adep,
			d.per1, d.per2aa, d.lieunper, d.lieunmer, d.ca7, d.ca8, d.ca8b1, d.ca8b2, d.ca8b3, d.sitpere, d.sitmere,
			d.ca11, d.ca12, d.ca13, d.ca23a, d.ca23d, d.tapi
	from panel as a
	left join gene2010.nonempl10vf as b
		on a.ident = b.ident and a.sequence = b.nseq
	left join gene2010.seqentr10vf as c
		on a.ident = c.ident and a.sequence = c.nseq
	left join gene2010.indiv10vf2 as d
		on a.ident = d.ident
	order by ident, date;
quit; /*103,992 obs obs*/

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
		if idnt = "" then temps_travail = ep49;
		else do;
			if date < input(idnt, 2.) then temps_travail = ep49;
			else temps_travail = ep54;
		end;
		/*-*/
		if temps_travail = "1" then temps_complet = 1;
		else temps_complet = 0;
	end;

	/* remuneration */
	if situation = "Emploi" then do;
		if idnt = "" and idnc = "" then do;
			remuneration = salprsdeb;
			if remuneration = . then remuneration = revdeb;
		end; else if idnt ^= "" and idnc = "" then do;
			if date < input(idnt, 2.) then do;
				remuneration = salprsdeb;
				if remuneration = . then remuneration = revdeb;
			end; else do;
				remuneration = salprsfin;
				if remuneration = . then remuneration = revfin;
			end;
		end; else if idnt = "" and idnc ^= "" then do;
			if date < input(idnc, 2.) then do;
				remuneration = salprsdeb;
				if remuneration = . then remuneration = revdeb;
			end; else do;
				remuneration = salprsfin;
				if remuneration = . then remuneration = revfin;
			end;
		end; else do;
			if input(idnc, 2.) < input(idnt, 2.) then do;
				if date < input(idnc, 2.) then do;
					remuneration = salprsdeb;
					if remuneration = . then remuneration = revdeb;
				end; else do;
					remuneration = salprsfin;
					if remuneration = . then remuneration = revfin;
				end;
			end; else do;
				if date < input(idnc, 2.) then do;
					remuneration = salprsdeb;
					if remuneration = . then remuneration = revdeb;
				end; else do;
					remuneration = salprsfin;
					if remuneration = . then remuneration = revfin;
				end;
			end;
		end;

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
		if ep15t ^= "" then do;
			format connaissance_embauche $32.;
			if ep15t in ("1", "2", "3", "4") then connaissance_embauche = "Structure publique";
			else if ep15t = "5" then connaissance_embauche = "Relation privee";
			else if ep15t in ("6", "7") then connaissance_embauche = "Annonce ou candidature spontanee";
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
	if fp1 = "1" then stages = 1;
	else if fp1 = "2" then stages = 0;
	else stages = .;

	/* nombre de stages */
	nb_stages = input(fp1a, 1.);

	/* durée du dernier stage */
	duree_travail_formation = input(fp2b, 2.);

	/* aide pour trouver le dernier stage */
	format aide_stage $20.;
	if fp3 = "1" then aide_stage = "college";
	else if fp3 in ("2", "3") then aide_stage = "famille ou amis";
	else if fp3 = "4" then aide_stage = "soi-meme";
	else if fp3 = "5" then do;
		if fp3b in ("1", "2", "3") then aide_stage = "autre aide publique";
		else aide_stage = "autre";
	end;
	else aide_stage = "";

	/* caractère obligatoire du stage */
	if fp10 = "1" then obligation_stage = 1;
	else if fp10 = "2" then obligation_stage = 0;
	else obligation_stage = .;

	/* stage lié à la formation */
	if fp12 = "1" then stage_formation = 1;
	else if fp12 = "2" then stage_formation = 0;
	else stage_formation = .;

	/* premier emploi après stage */
	if fp18 = "1" then stage_premier_emploi = 1;
	else if fp18 ^= "" then stage_premier_emploi = 0;
	else stage_premier_emploi = .;


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
			else if q34e = "3" then raison_non_apprenti = "autre";
		end;
		else if q34e = "12" or q34e = "21" then raison_non_apprenti = "pas de cfa, ni d'employeur";
		else raison_non_apprenti = "";
	end;

	/* obtention du diplome */
	if q7b = "1" then diplome = 1;
	else diplome = 0;

	/* âge a la sortie de formation */
		/* date de naissance */
	 	jour = 1;
		mois = input(q2, 2.);
		annee = input(compress("19"!!q3), 4.);
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

	/* département de résidence à la date de l'enquête */
	rename ca0adep = dep_residence;

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

	/* bourse sur criteres sociaux */
	if os2 = "1" then bourse_college = 1;
		else bourse_college = 0;
	if os3 = "2" then bourse_lycee = 1;
		else bourse_lycee = 0;

	/* voyage scolaire */
	if etr1b = "1" then voyage_scolaire = 1;
	else voyage_scolaire = 0;
	
	/* satisfaction par rapport a la situation actuelle a la date de l'enquête */
	if op2 = "1" then satisfait = 1;
	else if op2 = "2" then satisfait = 0;
	else satisfait = .;

	/* optimisme sur le futur */
	if op6 = "1" then optimisme = 1;
	else if op6 = "2" then optimisme = 0;
	else optimisme = .; 

	/* envisage de se mettre independant */
	if op7 = "1" then independant = 1;
	else if op7 = "2" then independant = 0;
	else independant = .; 

	/* envisage de quitter la region dans les cinq ans */
	if p03c = "1" then quitter_region = 1;
	else if p03c = "2" then quitter_region = 0;
	else quitter_region = .; 

	/* envisage de changer de metier dans les cinq ans */
	if p03d = "1" then changer_metier = 1;
	else if p03d = "2" then changer_metier = 0;
	else changer_metier = .;

	/* a connu des discriminations a l'embauche */
	if ca24 = "1" then discrimination = 1;
	else if ca24 = "2" then discrimination = 0;
	else discrimination = .;

	/* permis de conduire */
	if per1 = "1" and input(per2aa, 2.) <= age_sortie_formation then permis = 1;
	else if per1 = "1" and input(per2aa, 2.) > age_sortie_formation then permis = 0;
	else if per1 = "2" then permis = 0;
	else if per1 = "" then permis = .;

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

	/* français parle par le pere */
	if ca8b1 = "1" then langue_pere = 1;
	else if ca8b1 = "2" then langue_pere = 0;
	else langue_pere = .;
	if pays_naissance_pere = "France" and langue_pere = . then langue_pere = 1;

	/* français parle par la mere */
	if ca8b2 = "1" then langue_mere = 1;
	else if ca8b2 = "2" then langue_mere = 0;
	else langue_mere = .;
	if pays_naissance_mere = "France" and langue_mere = . then langue_mere = 1;

	/* français parle dans la famille */
	if ca8b3 = "1" then langue_famille = 1;
	else if ca8b3 = "2" then langue_famille = 0;
	else langue_famille = .;
	if langue_pere = 1 and langue_mere = 1 and langue_famille = . then langue_famille = 1;

	/* le pere travaille */
	if sitpere = "1" then emploi_pere = 1;
	else if sitpere in ("2", "3", "4", "5", "6", "7") then emploi_pere = 0;
	else emploi_pere = .;

	/* la mere travaille */
	if sitmere = "1" then emploi_mere = 1;
	else if sitmere in ("2", "3", "4", "5", "6", "7") then emploi_mere = 0;
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

	/* freres et soeurs */
	if ca13 = "1" then siblings = 1;
	else if ca13 = "2" then siblings = 0;
	else siblings = .;

	/* handicap */
	if ca23a = "1" and ca23d in ("1", "2", "3") then handicap = 1;
	else handicap = 0;

	/* duree pour obtenir un premier cdi */
	duree_pour_cdi = tapi;

	/* duree de la formation initiale */
	if situation = "Formation initiale" and duree = . then duree = age_sortie_formation - 6;

	/* source des données */
	generation = "G2010";

	/* -- SUPRESSION DES VARIABLES INITIALES -- */
	drop duree_nonemploi duree_emploi contrat_emb contrat_fin idnc ep49 ep54 temps_travail salprsdeb salprsfin revdeb revfin idnt
		natentr ep11 ep12 ep13b ep13c ep13d ep15t ep71 ep80a ep80b ep80c ep82b ep83
		fp1 fp1a fp2b fp3 fp3b fp4 fp10 fp12 fp18 pcs_emb
		cfa regetab q34s q7b q2 q3 q20 jour mois annee date_naissance mois_sortie annee_sortie jour_sortie date_sortie q1
		q31 sixiemestatutuu q33 q34a q34bc q34e os2 os3 etr1b op2 op6 op7 p03c p03d ca24 per1 per2aa
		lieunper lieunmer ca7 ca8 ca8b1 ca8b2 ca8b3 sitpere sitmere ca11 ca12 ca13 ca23a ca23d tapi;
run; /*103,992 obs*/


/* specialite du diplome */
proc import out=diplome datafile="C:\Users\jeremy.hervelin\Desktop\CH19\Annexes\specialite_diplome.xlsx" dbms=excelcs replace;
range="Spécialités$"; run;

proc sql;
	create table panel.panel_generation2010 as
	select a.generation, a.ident, a.pondef, a.date, a.date_label, a.seq, a.situation, a.duree, a.femme, a.permis,
			a.siblings, a.langue_famille, a.pays_naissance_pere, a.nationalite_pere, a.langue_pere, a.emploi_pere, a.niveau_pere,
			a.pays_naissance_mere, a.nationalite_mere, a.langue_mere, a.emploi_mere, a.niveau_mere, a.handicap,
			a.zone_commune, a.redoublement, a.troisieme_generale, a.premier_voeu, a.bourse_college, a.bourse_lycee, a.voyage_scolaire,
			a.centre_apprentissage, a.region_etablissement, a.apprentissage, a.souhait_apprentissage, a.raison_non_apprenti, b.naf10 as specialite_naf10, b.naf38 as specialite_naf38, a.diplome, a.age_sortie_formation,
			a.stages, a.nb_stages, a.duree_travail_formation, a.aide_stage, a.obligation_stage, a.stage_formation, a.stage_premier_emploi,
			a.duree_pour_cdi, a.temps_complet, a.remuneration, a.remuneration_debut, a.remuneration_fin, a.pcs, a.naf, a.secteur_prive,
			a.multi_etablissement, a.taille_entreprise,
			a.travail_anterieur_entreprise, a.type_travail_anterieur, a.connaissance_salarie_entreprise, a.type_connaissance_salarie, a.connaissance_embauche,
			a.formation_debut, a.raison_depart, a.motif_demission, a.volonte_rester, a.satisfait, a.optimisme, a.discrimination, a.independant, a.quitter_region, a.changer_metier, a.dep_residence
	from panel as a
	left join diplome as b
	on a.ident = b.ident
	order by ident, date;
quit; /*103,992 obs*/
