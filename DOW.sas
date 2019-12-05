*suppxx/DOW;
data suppcm;
  do until(last.idvarval);
  set sdtm.suppcm;
  by usubjid idvarval;
  if qnam="ATC" THEN ATC=QVAL;
  if qnam="ATC3" then ATC3=QVAL;
  end;
  cmseq=input(idvarval,best.);
run;

proc sort data=suppcm;by usubjid cmseq;run;

proc sql noprint;
  select distinct qnam into:qnam separated by '|' from sdtm.suppcm;
quit;

%put &qnam;

%let i=1;

%macro supp;
data suppcm;
  do until(last.idvarval);
  set sdtm.suppcm;
  by usubjid idvarval;
  %do %until(%scan(&qnam,&i,'|')= );
  if qnam="%scan(&qnam,&i)" then %scan(&qnam,&i)=qval;
  %let i=&i+1;
  %end;
  end;
  cmseq=input(idvarval,best.);
run;
%mend;

%supp;

*suppxx/sql;
*1(Not recommended, beacuse it delete row from cm where not in suppcm);
proc sql noprint;
  create table cm as
  select a.*,b.qval as atc
  from sdtm.cm as a,sdtm.suppcm as b
  where a.usubjid=b.usubjid and a.cmseq=input(b.idvarval,best.) and b.qnam='ATC';
  ;
quit;
*2(Not recommended,tongshang);
proc sql noprint;
  create table cm as
  select a.*,b.qval as atc
  from sdtm.cm as a,sdtm.suppcm(where=(qnam='ATC')) as b
  where a.usubjid=b.usubjid and a.cmseq=input(b.idvarval,best.);
  ;
quit;
*3(too much time);
proc sql noprint;
  create table cm as
  select a.*,(select qval from sdtm.suppcm where qnam='ATC' and usubjid=a.usubjid and input(idvarval,best.)=a.cmseq) as atc
  from sdtm.cm as a
  ;
quit;


*****paramcd;
data vs;
  do until(last.usubjid);
  set sdtm.vs;
  where vsblfl="Y";
  by usubjid;
  if VSTESTCD='HEIGHT' then htbl=vsstresn;
  if vstestcd='WEIGHT' then wtbl=vsstresn;
  end;
  if nmiss(wtbl,htbl)=0 then bmibl=wtbl/(htbl/100)**2;
run;


*flag;
data flag;
  do until(last.usubjid);
  set sdtm.ex sdtm.ds sdtm.dm;
  by usubjid;
  saff=max(saff,exdose>0);
  itt=max(itt,dsstdtc>'' and dsdecod='RANDOMIZED');
  end;
  saffl=ifc(saff,'Y','N');
  ittfl=ifc(itt,'Y','N');
run;


*baseline flag/base value;
proc sort data=sdtm.vs out=vs;by usubjid vstestcd;run;
data vs1;
  do until(last.vstestcd);
    set vs;
    by usubjid vstestcd;
    if vsblfl='Y' then base=vsstresn;
    else if nmiss(vsstresn,base)=0 then chg=vsstresn-base;
    output;
  end;
run;

*LOCF;
data vs2;
  do until(last.usubjid);
    set vs;
    by usubjid;
    if vsstresn ne . then locf=vsstresn;
    output;
  end;
run;


proc sql noprint;
  create table cm as
  select qval as act,a.*
  from sdtm.cm as a,sdtm.suppcm(where=(qnam='ACT')) as b
  where b.usubjid=a.usubjid and a.cmseq=input(b.idvarval,best.);
quit;

*last alive date/sv.svstdtc;
proc sql noprint;
  create table ss as
  select usubjid,ssdtc
  from sdtm.ss
  where usubjid=(select usubjid from sdtm.suppss where qnam='LIENDAT') and ssseq=(select input(IDVARVAL,best.) from sdtm.suppss where qnam='LIENDAT');
quit;

data lstalvdt;
  do until(last.usubjid);
  set sdtm.dm sdtm.sv sdtm.ds(where=(dscat='DISPOSITION EVENT')) sdtm.ex(where=(exdose ne .)) sdtm.ae sdtm.mh sdtm.cm sdtm.pr sdtm.lb 
  sdtm.qs sdtm.pc sdtm.rp sdtm.zb sdtm.tu sdtm.tr sdtm.rs sdtm.eg sdtm.vs sdtm.pc ss;
  by usubjid;
  lstalvdt=max
  (lstalvdt,
    ifn(length(svstdtc)>=10,input(svstdtc,anydtdte10.),0),
    ifn(length(svendtc)>=10,input(svendtc,anydtdte10.),0),
    ifn(length(dsstdtc)>=10,input(dsstdtc,anydtdte10.),0),
    ifn(length(exstdtc)>=10,input(exstdtc,anydtdte10.),0),
    ifn(length(exendtc)>=10,input(exendtc,anydtdte10.),0),
    ifn(length(aestdtc)>=10,input(aestdtc,anydtdte10.),0),
    ifn(length(aeendtc)>=10,input(aeendtc,anydtdte10.),0),
    ifn(length(mhendtc)>=10,input(mhendtc,anydtdte10.),0),
    ifn(length(cmstdtc)>=10,input(cmstdtc,anydtdte10.),0),
    ifn(length(cmendtc)>=10,input(cmendtc,anydtdte10.),0),
    ifn(length(prstdtc)>=10,input(prstdtc,anydtdte10.),0),
    ifn(length(prendtc)>=10,input(prendtc,anydtdte10.),0),
    ifn(length(lbdtc)>=10,input(lbdtc,anydtdte10.),0),
    ifn(length(qsdtc)>=10,input(qsdtc,anydtdte10.),0),
    ifn(length(pcdtc)>=10,input(pcdtc,anydtdte10.),0),
    ifn(length(rpdtc)>=10,input(rpdtc,anydtdte10.),0),
    ifn(length(zbdtc)>=10,input(zbdtc,anydtdte10.),0),
    ifn(length(tudtc)>=10,input(tudtc,anydtdte10.),0),
    ifn(length(trdtc)>=10,input(trdtc,anydtdte10.),0),
    ifn(length(rsdtc)>=10,input(rsdtc,anydtdte10.),0),
    ifn(length(egdtc)>=10,input(egdtc,anydtdte10.),0),
    ifn(length(vsdtc)>=10,input(vsdtc,anydtdte10.),0),
    ifn(length(pcdtc)>=10,input(pcdtc,anydtdte10.),0),
    ifn(length(ssdtc)>=10,input(ssdtc,anydtdte10.),0)
  );
  end;
  if lstalvdt=0 then delete;
  format lstalvdt date9.;
  keep usubjid lstalvdt;
run;
************;

proc sort data=a_in.adae out=adae;  where trtemfl='Y' and saffl='Y' and aetoxgr ne '';by usubjid aebodsys aedecod AETOXGR;run;

data aetoxgr;
  do until(last.usubjid);
  set adae;
  by usubjid aebodsys aedecod AETOXGR;
  aetoxgr1=max(aetoxgr1,input(aetoxgr,best.));
  ord=1;
  end;
run;

*hash;
proc sql noprint;
  create table paramcd as
  select distinct paramcd
  from adam.adlb;
quit;

data grade;
  if _n_=1 then do;
    declare hash g(dataset:'paramcd');
    g.definekey('paramcd');
    g.definedone();
  end;
  set adam.adlb;
  if g.find()=0;
run;

data adlb;
  merge sdtm.lb(in=a) sdtm.dm(keep=usubjid rfstdtc);
  by usubjid;
  if a;
run;

data BL_Flag; 
  if _n_=1 then do; 
    declare hash h(); 
    h.defineKey('usubjid','lbtestcd'); 
    h.defineData('_min');
    h.defineDone(); 
    do until(EOF); 
     set adlb end=EOF; 
     if h.find() then call missing(_min); 
     if input(rfstdtc,b8601dt.)<input(lbdtc,b8601dt.) then do; 
       h.replace(); /* See NOTE below */ continue; 
     end; 
     if missing(lbstresn)=0 then do; 
       if h.find() then _min=input(rfstdtc,b8601dt.)-input(lbdtc,b8601dt.); 
       else _min=min(_min,input(rfstdtc,b8601dt.)-input(lbdtc,b8601dt.)); 
     end; 
     h.replace(); 
    end; 
  end; 
  set adlb; 
  delta_time=ifn(missing(lbstresn)=0 & rfstdtc>=lbdtc, input(rfstdtc,b8601dt.)-input(lbdtc,b8601dt.), constant("bigint") );
  h.find(); /* fills in minimum for each key */ 
  LBBLFL=char(" Y",(delta_time=_min)+1); 
run;

data a;
infile datalines;
input name $ date:yymmdd10. value;
format date yymmdd10.;
datalines;
A 20070101 1
A 20070102 2
A 20070103 3
A 20070104 4
A 20070105 5
A 20070106 6
A 20070107 7
B 20070101 8
B 20070102 9
;
run;

data b;
infile datalines;
input name $ sdate:yymmdd10. edate:yymmdd10.;
format sdate edate yymmdd10.;
datalines;
A 20070102 20070106
A 20070101 20070104
B 20070101 20070102
;
run;

data c;
if 0 then set a;
if _n_=1 then do;
   declare hash share(dataset:'work.a', ordered:'ascending');
   share.definekey ('name', 'date');
   share.definedata(all:'yes');
   share.definedone();
end;

set b;
rc=share.find(key:name, key:sdate);
svalue=value;
rc=share.find(key:name, key:edate);
evalue=value;
tvalue=0;

do i=sdate to edate;
   rc=share.find(key:name, key:i);
   tvalue+value;
end;
keep name sdate edate svalue evalue tvalue;
run;


*Failed;
data cm1;
if _n_=1 then do;
  dcl hash h();
  h.definekey('usubjid','cmseq');
  h.definedata('usubjid','cmseq','atc','atc3');
  h.definedone();
end;
  do until(last.idvarval);
    set suppcm;
    by usubjid idvarval;
    if qnam='ATC' then atc=qval;
    if qnam='ATC3' then atc3=qval;
  end;
  cmseq=input(idvarval,best.);
  h.add();


  set cm;
  call missing(atc,atc3);
  rc=h.find();

  keep usubjid cmseq atc atc3 ;
run;


*success!;
data cm;
    if _N_=1 then do;
        dcl hash h(multidata:'Y');
        h.definekey('usubjid', 'cmseq');
        h.definedata('qnam', 'qval');
        h.definedone();

        do until(eof);
          set sdtm.suppcm end=eof;
          cmseq=input(idvarval,best.);
          rc=h.add();
        end;
    end;

    set sdtm.cm;

   h.output(dataset:'dd');

    keep usubjid cmseq atc atc3 ;
run;



*one to many;
proc sql noprint;
    create table x as select distinct make
    from sashelp.cars;
quit;

data x;
    set x (obs = 10);
    if make = "GMC" then make = "XYZ";
run;


data hx (drop = rc);

if 0 then set sashelp.cars(keep = make model);
if _n_ = 1 then do;
    declare hash hhh(dataset: 'sashelp.cars(keep = make model)', multidata:'y');
    hhh.DefineKey('make');
    hhh.DefineData('model');
    hhh.DefineDone();
end;

set x;
rc = hhh.find();
if rc ne 0 then do;
  call missing(model);
  output;
end;
else
do while(rc = 0);
    output;
    rc = hhh.find_next();
end;
run;
********;

