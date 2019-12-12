%inc "\\mst13\G_049_ONC_BLC2001\02_STAT\DBR_CSR\RE_CSR\Prod\ENVSETUP.sas";

******************************************************************************;
*Create ADaM - ADVS;
******************************************************************************;

data vs;
  merge a_in.advs(in=a) a_in.adsl;
  drop ablfl;
  by usubjid;
  if a;
run;

data ablfl;
  if _n_=1 then do;
    dcl hash h();
    h.definekey('usubjid','paramcd');
    h.definedata('min','seq');
    h.definedone();

    do until(eof);
      set vs end=eof;
      if .<input(vsdtc,yymmdd10.)<=ARFSTDT and index(VSSPID,'UNSCH')=0 then do;min=vsdtc;seq=vsseq;end;
      h.replace(); 
    end;
  end;

  set vs;
  if h.find()=0 and min=vsdtc and seq=vsseq then ablfl_='Y';

  keep usubjid paramcd vsdtc ablfl_ vsseq;
run;

data advs;
  set a_in.advs;
  keep usubjid paramcd vsdtc ablfl vsseq;
run;

data check;
  merge ablfl advs;
  by usubjid paramcd vsdtc vsseq;
  if ablfl_ ne ablfl;
run;
