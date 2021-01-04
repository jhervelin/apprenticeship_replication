libname panel "C:\Users\jeremy.hervelin\Desktop\CH19";
option mprint macrogen;


/* compilation des enquêtes générations nettoyées */

data panel_generation;
	set panel.panel_generation2004
		panel.panel_generation2007
		panel.panel_generation2010
		panel.panel_generation2013;
	if dep_residence not in ("97", "971", "972", "973", "974", "975", "976", "**", "DO", "ET");
run; /*459,774 obs*/



/* intégration des taux de chômage trimestriels par département */

proc import out=chomage
	datafile="C:\Users\jeremy.hervelin\Desktop\CH19\Annexes\chomage_dep_trimestres.xls"
	dbms=excelcs replace;
	sheet="Feuil1";
run; /*96 obs*/

proc sql;
	create table panel_generation as
	select a.*, b.t1_2003, b.t2_2003, b.t3_2003, b.t4_2003,
				b.t1_2004, b.t2_2004, b.t3_2004, b.t4_2004,
				b.t1_2005, b.t2_2005, b.t3_2005, b.t4_2005,
				b.t1_2006, b.t2_2006, b.t3_2006, b.t4_2006,
				b.t1_2007, b.t2_2007, b.t3_2007, b.t4_2007,
				b.t1_2008, b.t2_2008, b.t3_2008, b.t4_2008,
				b.t1_2009, b.t2_2009, b.t3_2009, b.t4_2009,
				b.t1_2010, b.t2_2010, b.t3_2010, b.t4_2010,
				b.t1_2011, b.t2_2011, b.t3_2011, b.t4_2011,
				b.t1_2012, b.t2_2012, b.t3_2012, b.t4_2012,
				b.t1_2013, b.t2_2013, b.t3_2013, b.t4_2013,
				b.t1_2014, b.t2_2014, b.t3_2014, b.t4_2014,
				b.t1_2015, b.t2_2015, b.t3_2015, b.t4_2015,
				b.t1_2016, b.t2_2016, b.t3_2016, b.t4_2016
	from panel_generation as a
	left join chomage as b
	on a.dep_residence = b.code;
quit; /*459,774 obs -> ok*/

%macro chomage();
data panel_generation;
	set panel_generation;
	%do i=2003 %to 2016;
		if date_label = "janvier-&i." then tx_chomage = t1_&i.;
		if date_label = "fevrier-&i." then tx_chomage = t1_&i.;
		if date_label = "mars-&i." then tx_chomage = t1_&i.;
		if date_label = "avril-&i." then tx_chomage = t2_&i.;
		if date_label = "mai-&i." then tx_chomage = t2_&i.;
		if date_label = "juin-&i." then tx_chomage = t2_&i.;
		if date_label = "juillet-&i." then tx_chomage = t3_&i.;
		if date_label = "aout-&i." then tx_chomage = t3_&i.;
		if date_label = "septembre-&i." then tx_chomage = t3_&i.;
		if date_label = "octobre-&i." then tx_chomage = t4_&i.;
		if date_label = "novembre-&i." then tx_chomage = t4_&i.;
		if date_label = "decembre-&i." then tx_chomage = t4_&i.;
	%end;
	drop t1_2003-t1_2016 t2_2003-t2_2016 t3_2003-t3_2016 t4_2003-t4_2016;
run;
%mend;

%chomage; /*459,774 obs*/



/* intégration des effectifs d'apprentis annuels (niveau V) par département */

libname ariane "C:\Users\jeremy.hervelin\Desktop\TRAJAM\Données\CA\Données\tables";

%macro nb_apprentices();

data ariane;
	length departement $3.;
run;

%do i=2005 %to 2016;
	
	%if &i. = 2005 or &i. = 2006 %then %do;
		%let table = m&i.12_rtt_pedataapr_donn_ent_1;
		%let id = noenreg;
		%let contrat = typcont;
		%let diplome = nivd;
		%let lieu = post;
		%let debut = adebcont;
		%let fin = afincont;
	%end;

	%else %if &i. = 2007 or &i. = 2008 or &i. = 2009 %then %do;
		%let table = m&i.12_rtt_pedataapr_donn_ent_1;
		%let id = dossier_no_enregistrement;
		%let contrat = nature_cont_avenant;
		%let diplome = etab_form_niveau;
		%let lieu = emp_adresse_code_postal;
		%let debut = cont_date_debut_annee;
		%let fin = cont_date_fin_annee;
	%end;

	%else %if &i. = 2010 or &i. = 2011 %then %do;
		%let table = Fich_&i._&i._final;
		%let id = dossier_no_enregistrement;
		%let contrat = nature_cont_avenant;
		%let diplome = etab_form_niveau;
		%let lieu = emp_adresse_code_postal;
		%let debut = cont_date_debut_annee;
		%let fin = cont_date_fin_annee;
	%end;

	%else %if &i. = 2012 %then %do;
		%let table = Fich_2012_2012_final_2015_12_21;
		%let id = NumeroEnregistrement;
		%let contrat = TypeContrat;
		%let diplome = niv_prep;
		%let lieu = Emp_CodePostal;
		%let debut = Cont_DateDebut_a;
		%let fin = Cont_DateFin_a;
	%end;

	%else %if &i. = 2013 or &i. = 2014 or &i. = 2015 or &i. = 2016 %then %do;
		%let table = Fich_2013_2018_final_2018_05_28;
		%let id = NumeroEnregistrement;
		%let contrat = TypeContrat;
		%let diplome = substr(Etab_CodeDiplomeVise, 1, 1);
		%let lieu = Emp_CodePostal;
		%let debut = Cont_DateDebut_a;
		%let fin = Cont_DateFin_a;
	%end;

	data ariane&i.;
		set ariane.&table.;
		if input(&debut., 4.) <= &i. <= input(&fin., 4.);
		if &contrat. in ("11", "12", "21", "22", "23");
		if &diplome. = "5";
		departement = substr(&lieu., 1, 2);
		keep &id. departement;
	run;

	proc sql;
		create table ariane&i. as
		select departement, count(&id.) as nb_apprentis_&i.
		from ariane&i.
		group by departement;
	quit;

	data ariane;
		merge ariane ariane&i.;
		by departement;
		if lengthn(departement) = 2;
		if departement not in ("00", "96", "97", "98", "99");
		if substr(departement, 1, 1) not in ("A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q",
			"R", "S", "T", "U", "V", "W", "X", "Y", "Z") and substr(departement, 2, 1) not in ("A", "B", "C", "D", "E", "F", "G",
			"H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z");
	run;

	proc datasets libname=work; delete ariane&i.; run; quit;

%end;

%mend;

%nb_apprentices;

proc sql;
	create table panel_generation as
	select a.*, b.nb_apprentis_2005, b.nb_apprentis_2006, b.nb_apprentis_2007,b.nb_apprentis_2008, b.nb_apprentis_2009, b.nb_apprentis_2010,
			b.nb_apprentis_2011, b.nb_apprentis_2012, b.nb_apprentis_2013, b.nb_apprentis_2014, b.nb_apprentis_2015, b.nb_apprentis_2016
	from panel_generation as a
	left join ariane as b
	on a.dep_residence = b.departement;
quit; /* 459,774 obs -> ok*/

%macro apprentis();
data panel_generation;
	set panel_generation;
	%do i=2005 %to 2016;
		if input(scan(date_label, 2, "-"), 4.) = &i. then nb_apprentis = nb_apprentis_&i.;
	%end;
	drop nb_apprentis_2005-nb_apprentis_2016;
run;
%mend;

%apprentis; /* 459,774 obs*/



/* export vers sas et stata */

proc sort data=panel_generation out=panel.panel_generation; by generation ident date; run;
proc export data=panel.panel_generation outfile= "C:\Users\jeremy.hervelin\Desktop\CH19\panel_generation.dta" replace; run;
