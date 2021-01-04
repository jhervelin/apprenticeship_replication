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


/* export vers sas et stata */

proc sort data=panel_generation out=panel.panel_generation; by generation ident date; run;
proc export data=panel.panel_generation outfile= "C:\Users\jeremy.hervelin\Desktop\CH19\panel_generation.dta" replace; run;
