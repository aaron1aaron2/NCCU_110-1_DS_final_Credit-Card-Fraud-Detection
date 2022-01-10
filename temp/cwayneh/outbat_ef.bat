@echo off
set fn="..\dsout.%date:~5,2%%date:~8,2%.ef.log"
set tgt="..\R\R-3.6.3\bin\Rscript.exe"
echo --------BEGIN at %date% %time% >>%fn%2>&1
cd ..
%tgt% extremes_filter.R --method std --range -1,1 --target 2:30 --train train.csv --test test.csv --report output/performance.ef.csv >>%fn%2>&1
%tgt% extremes_filter.R --method IQR --range -1,1 --target 2:30 --train train.csv --test test.csv --report output/performance.ef.csv >>%fn%2>&1
%tgt% extremes_filter.R --method std --range -1,1 --target 2:29 --train train.csv --test test.csv --report output/performance.ef.csv >>%fn%2>&1
%tgt% extremes_filter.R --method IQR --range -1,1 --target 2:29 --train train.csv --test test.csv --report output/performance.ef.csv >>%fn%2>&1

%tgt% extremes_filter.R --method std --range -2,2 --target 2:30 --train train.csv --test test.csv --report output/performance.ef.csv >>%fn%2>&1
%tgt% extremes_filter.R --method IQR --range -2,2 --target 2:30 --train train.csv --test test.csv --report output/performance.ef.csv >>%fn%2>&1
%tgt% extremes_filter.R --method std --range -2,2 --target 2:29 --train train.csv --test test.csv --report output/performance.ef.csv >>%fn%2>&1
%tgt% extremes_filter.R --method IQR --range -2,2 --target 2:29 --train train.csv --test test.csv --report output/performance.ef.csv >>%fn%2>&1

%tgt% extremes_filter.R --method std --range -2.5,2.5 --target 2:30 --train train.csv --test test.csv --report output/performance.ef.csv >>%fn%2>&1
%tgt% extremes_filter.R --method IQR --range -2.5,2.5 --target 2:30 --train train.csv --test test.csv --report output/performance.ef.csv >>%fn%2>&1
%tgt% extremes_filter.R --method std --range -2.5,2.5 --target 2:29 --train train.csv --test test.csv --report output/performance.ef.csv >>%fn%2>&1
%tgt% extremes_filter.R --method IQR --range -2.5,2.5 --target 2:29 --train train.csv --test test.csv --report output/performance.ef.csv >>%fn%2>&1

%tgt% extremes_filter.R --method std --range -3,3 --target 2:30 --train train.csv --test test.csv --report output/performance.ef.csv >>%fn%2>&1
%tgt% extremes_filter.R --method IQR --range -3,3 --target 2:30 --train train.csv --test test.csv --report output/performance.ef.csv >>%fn%2>&1
%tgt% extremes_filter.R --method std --range -3,3 --target 2:29 --train train.csv --test test.csv --report output/performance.ef.csv >>%fn%2>&1
%tgt% extremes_filter.R --method IQR --range -3,3 --target 2:29 --train train.csv --test test.csv --report output/performance.ef.csv >>%fn%2>&1

%tgt% extremes_filter.R --method std --range -3.5,3.5 --target 2:30 --train train.csv --test test.csv --report output/performance.ef.csv >>%fn%2>&1
%tgt% extremes_filter.R --method IQR --range -3.5,3.5 --target 2:30 --train train.csv --test test.csv --report output/performance.ef.csv >>%fn%2>&1
%tgt% extremes_filter.R --method std --range -3.5,3.5 --target 2:29 --train train.csv --test test.csv --report output/performance.ef.csv >>%fn%2>&1
%tgt% extremes_filter.R --method IQR --range -3.5,3.5 --target 2:29 --train train.csv --test test.csv --report output/performance.ef.csv >>%fn%2>&1

%tgt% extremes_filter.R --method std --range -4,4 --target 2:30 --train train.csv --test test.csv --report output/performance.ef.csv >>%fn%2>&1
%tgt% extremes_filter.R --method IQR --range -4,4 --target 2:30 --train train.csv --test test.csv --report output/performance.ef.csv >>%fn%2>&1
%tgt% extremes_filter.R --method std --range -4,4 --target 2:29 --train train.csv --test test.csv --report output/performance.ef.csv >>%fn%2>&1
%tgt% extremes_filter.R --method IQR --range -4,4 --target 2:29 --train train.csv --test test.csv --report output/performance.ef.csv >>%fn%2>&1

%tgt% extremes_filter.R --method std --range -3,3 --target 29:29 --train train.csv --test test.csv --report output/performance.ef.csv >>%fn%2>&1
%tgt% extremes_filter.R --method IQR --range -3,3 --target 29:29 --train train.csv --test test.csv --report output/performance.ef.csv >>%fn%2>&1
%tgt% extremes_filter.R --method std --range -3,3 --target 4:4 --train train.csv --test test.csv --report output/performance.ef.csv >>%fn%2>&1
%tgt% extremes_filter.R --method IQR --range -3,3 --target 4:4 --train train.csv --test test.csv --report output/performance.ef.csv >>%fn%2>&1
%tgt% extremes_filter.R --method std --range -3,3 --target 8:8,10:10 --train train.csv --test test.csv --report output/performance.ef.csv >>%fn%2>&1
%tgt% extremes_filter.R --method IQR --range -3,3 --target 8:8,10:10 --train train.csv --test test.csv --report output/performance.ef.csv >>%fn%2>&1
%tgt% extremes_filter.R --method std --range -3,3 --target 15:15 --train train.csv --test test.csv --report output/performance.ef.csv >>%fn%2>&1
%tgt% extremes_filter.R --method IQR --range -3,3 --target 15:15 --train train.csv --test test.csv --report output/performance.ef.csv >>%fn%2>&1

%tgt% extremes_filter.R --method std --range -3,3 --target 2:14,16:29 --train train.csv --test test.csv --report output/performance.ef.csv >>%fn%2>&1
%tgt% extremes_filter.R --method IQR --range -3,3 --target 2:14,16:29 --train train.csv --test test.csv --report output/performance.ef.csv >>%fn%2>&1
%tgt% extremes_filter.R --method std --range -3,3 --target 2:14,16:30 --train train.csv --test test.csv --report output/performance.ef.csv >>%fn%2>&1
%tgt% extremes_filter.R --method IQR --range -3,3 --target 2:14,16:30 --train train.csv --test test.csv --report output/performance.ef.csv >>%fn%2>&1

%tgt% extremes_filter.R --method std --range -3,3 --target 4:7,23:26 --train train.csv --test test.csv --report output/performance.ef.csv >>%fn%2>&1
%tgt% extremes_filter.R --method IQR --range -3,3 --target 3:8,16:19,24:27 --train train.csv --test test.csv --report output/performance.ef.csv >>%fn%2>&1
%tgt% extremes_filter.R --method std --range -3,3 --target 11:14,19:30 --train train.csv --test test.csv --report output/performance.ef.csv >>%fn%2>&1
%tgt% extremes_filter.R --method IQR --range -3,3 --target 12:14,21:25,28:30 --train train.csv --test test.csv --report output/performance.ef.csv >>%fn%2>&1

echo END at %date% %time%-------- >>%fn%2>&1
pause


GOTO comment
::for /l %i in (1,1,30) do %tgt% extremes_filter.R --method std --range -2.5,2.5 --target %i:%i --train train.csv --test test.csv --report output/performance.ef.csv >>%fn%2>&1
:comment
