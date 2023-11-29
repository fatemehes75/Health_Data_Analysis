/*Step 1: import the data from Excel sheets*/

FILENAME REFFILE '/home/u63695526/HIST.xlsx';
proc import datafile=reffile
dbms=xlsx
out = Hist; /* if you want to make a copy on permanent lib you can add lib name, 
then make a copy from permanent lib to work*/
getnames=yes;
run;

FILENAME REFFILE '/home/u63695526/STAT.xlsx';
proc import datafile=reffile
dbms=xlsx
out = Stat; /* if you want to make a copy on permanent lib you can add lib name, 
then make a copy from permanent lib to work*/
getnames=yes;
run;

FILENAME REFFILE '/home/u63695526/STUDHT.xlsx';
proc import datafile=reffile
dbms=xlsx
out = Student_ht; /* if you want to make a copy on permanent lib you can add lib name, 
then make a copy from permanent lib to work*/
getnames=yes;
run;


/*Step 2: Stack data from STAT and HIST */
/* data step*/
data stack_hist_stat;
set Hist Stat;
run;

/* proc step*/
/*
proc append base = stack_hist_stat data = Hist;
run;
proc append base = stack_hist_stat data = Stat;
run;*/

/*sort*/
proc sort data=stack_hist_stat;
by name;
run;


/*Step 3: Merging the two tables*/


/* using data step */
/*
data Merged_data;
merge stack_hist_stat(in=A) Student_ht(in=B);
by name;
if A and B; /*inner join*/


/* using PROC SQL */
proc sql;
  create table Merged_data as
  select *
  from stack_hist_stat 
  inner join Student_ht 
  on stack_hist_stat.name = Student_ht.name;
quit;


/*Step 4: Convert the weight and height into Metric system units*/

data Merged_data;
set Merged_data;
weightkg = round(weight*0.454, 0.01);
Heightm = round((height*2.54)/100, 0.01);
drop weight Height;
run;

/*Step 5: Create new Variable*/

data Merged_data;
set Merged_data;
bmi= weightkg/ (heightm*heightm);


/*Step 6*/
if bmi < 18 then Status = 'Underweight';
else if 18 <= bmi <= 20 then Status = 'Healthy';
else if 20 < bmi < 22 then Status = 'Overweight';
else if bmi >= 22 then Status = 'Obese';



/*Step 7: Visualization*/

proc chart data = Merged_data;
pie Status;
run;

/* Step 8: Create a frequency distribution table for gender and status */

proc freq data=Merged_data;
  tables gender*status / out=myFreqtable norow nocol nopercent; /* Output dataset with frequencies */
run;


/*Step 9: format report values*/

data myfreqtable1;
set myfreqtable;
value = cat(count,'(',round(percent,.01),'%)');
drop count percent;
run;


/*Step 10: transpose origin var */

proc transpose data=myFreqtable1 out = t_myfreq;
by gender;
id status;
var value;
run;



title 'Report of Frequency Count and Percentage';
proc print data=t_myfreq (drop=_name_);
run;






/* Macro world */

%macro myStat(var1, var2);
  
  /* Step 11: Create a frequency distribution table for the specified variables */
  proc freq data=Merged_data;
    tables &var1*&var2 / out=myFreqtable_macro norow nocol nopercent; 
    /* Output dataset with frequencies */
  run;

  /* Step 12: Format report values */
  data myFreqtable_macro1;
    set myFreqtable_macro;
    value = cat(count, '(', round(percent, 0.01), '%)');
    drop count percent;
  run;

  /* Step 13: Transpose origin var */
  proc transpose data=myFreqtable_macro1 out=t_myfreq_macro;
    by &var1;
    id &var2;
    var value;
  run;

  /* Display the report of frequency count and percentage */
  title 'Report of Frequency Count and Percentage for &var1 and &var2';
  proc print data=t_myfreq_macro (drop=_name_);
  run;

%mend;

/* Call the macro with relevant input parameters (e.g., gender and status) */

%myStat(var1=gender, var2=status);
