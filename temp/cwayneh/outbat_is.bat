@echo off
set fn="..\dsout.%date:~5,2%%date:~8,2%.log"
set tgt="..\bin\Rscript.exe"
echo --------BEGIN at %date% %time% >>%fn%2>&1
cd ..
%tgt% imbalance_sampling.R --nsmp 415 --train train.csv --test test.csv --report output/performance.csv --amp 10 >>%fn%2>&1
%tgt% imbalance_sampling.R --nsmp 415 --train train.csv --test test.csv --report output/performance.csv --amp 100 >>%fn%2>&1
%tgt% imbalance_sampling.R --nsmp 415 --train train.csv --test test.csv --report output/performance.csv --amp 200 >>%fn%2>&1
%tgt% imbalance_sampling.R --nsmp 415 --train train.csv --test test.csv --report output/performance.csv --amp 300 >>%fn%2>&1
%tgt% imbalance_sampling.R --nsmp 100 --train train.csv --test test.csv --report output/performance.csv --amp 100 >>%fn%2>&1
%tgt% imbalance_sampling.R --nsmp 200 --train train.csv --test test.csv --report output/performance.csv --amp 100 >>%fn%2>&1
%tgt% imbalance_sampling.R --nsmp 250 --train train.csv --test test.csv --report output/performance.csv --amp 100 >>%fn%2>&1
%tgt% imbalance_sampling.R --nsmp 300 --train train.csv --test test.csv --report output/performance.csv --amp 100 >>%fn%2>&1
%tgt% imbalance_sampling.R --nsmp 100 --train train.csv --test test.csv --report output/performance.csv --amp 200 >>%fn%2>&1
%tgt% imbalance_sampling.R --nsmp 200 --train train.csv --test test.csv --report output/performance.csv --amp 200 >>%fn%2>&1
%tgt% imbalance_sampling.R --nsmp 250 --train train.csv --test test.csv --report output/performance.csv --amp 200 >>%fn%2>&1
%tgt% imbalance_sampling.R --nsmp 300 --train train.csv --test test.csv --report output/performance.csv --amp 200 >>%fn%2>&1
echo END at %date% %time%-------- >>%fn%2>&1
pause
