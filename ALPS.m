dxx=readtable('/public/home/xxx/data/Dxx.txt','Delimiter',',');
dxx=table2array(dxx);
dyy=readtable('/public/home/xxx/data/Dyy.txt','Delimiter',',');
dyy=table2array(dyy);
dzz=readtable('/public/home/xxx/data/Dzz.txt','Delimiter',',');
dzz=table2array(dzz);

ALPS_left=((dxx(:,1)+dxx(:,3))/2)./((dyy(:,1)+dzz(:,3))/2);
ALPS_right=((dxx(:,2)+dxx(:,4))/2)./((dyy(:,2)+dzz(:,4))/2);

subj=readtable('/public/home/xxx/data/used_subjs.txt','ReadVariableNames',false,'Format','%s');
subj.ALPS_left=ALPS_left;
subj.ALPS_right=ALPS_right;
writetable(subj,'/public/home/xxx/data/ALPS_results.csv','Delimiter',',');