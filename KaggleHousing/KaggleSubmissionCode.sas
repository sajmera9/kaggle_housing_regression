/* this code is to help take our models that we have made and use them  on the test set so we can submit for a Kaggle score*/

/*JJ*/
/*Importing the test CSV*/
%web_drop_table(WORK.IMPORT);


FILENAME REFFILE '/folders/myshortcuts/SASUniversityEdition/Stats project/test.csv';

PROC IMPORT DATAFILE=REFFILE
	DBMS=CSV
	OUT=Test;
	GETNAMES=YES;
	Guessingrows= MAX;
RUN;

PROC CONTENTS DATA=Test; RUN;


%web_open_table(Test);



/*Importing the train CSV*/
%web_drop_table(WORK.IMPORT);


FILENAME REFFILE '/folders/myshortcuts/SASUniversityEdition/Stats project/train.csv';

PROC IMPORT DATAFILE=REFFILE
	DBMS=CSV
	OUT=Train;
	GETNAMES=YES;
	Guessingrows= MAX;
RUN;

PROC CONTENTS DATA=Train; RUN;


%web_open_table(Train);

/*Tidying the data that both tables can join */
data Trainfixed;
   set Train (rename=(BsmtFinSF1=accountnum));
   length BsmtFinSF1 $ 4.;
   BsmtFinSF1= put(accountnum,f4. -L);
   drop accountnum;
run;
data Trainfixed2;
   set Trainfixed (rename=(BsmtFinSF2=accountnum));
   length BsmtFinSF2 $ 4.;
   BsmtFinSF2= put(accountnum,f4. -L);
   drop accountnum;
run;
data Trainfixed3;
   set Trainfixed2 (rename=(BsmtUnfSF=accountnum));
   length BsmtUnfSF $ 4.;
   BsmtUnfSF= put(accountnum,f4. -L);
   drop accountnum;
run;
data Trainfixed4;
   set Trainfixed3 (rename=(TotalBsmtSF=accountnum));
   length TotalBsmtSF $ 4.;
   TotalBsmtSF= put(accountnum,f4. -L);
   drop accountnum;
run;
data Trainfixed5;
   set Trainfixed4 (rename=(BsmtFullBath=accountnum));
   length BsmtFullBath $ 2.;
   BsmtFullBath= put(accountnum,f2. -L);
   drop accountnum;
run;
data Trainfixed6;
   set Trainfixed5 (rename=(BsmtHalfBath=accountnum));
   length BsmtHalfBath $ 2.;
   BsmtHalfBath= put(accountnum,f2. -L);
   drop accountnum;
run;
data Trainfixed7;
   set Trainfixed6 (rename=(GarageCars=accountnum));
   length GarageCars $ 2.;
   GarageCars= put(accountnum,f2. -L);
   drop accountnum;
run;
data Trainfixed8;
   set Trainfixed7 (rename=(GarageArea=accountnum));
   length GarageArea $ 4.;
   GarageArea= put(accountnum,f4. -L);
   drop accountnum;
run;

/*Checking the data set*/
proc compare data=Test(obs=0) compare=Trainfixed8(obs=0);
run;

proc print  data=Test ;
run;

proc print  data=Train ;
run;

/* Adding a sales price column for thge train set  */
data Test;
Set Test;
SalePrice = . ;
;
 


/* Join the two datasets  */
data Train2;
set Trainfixed8 Test;
Run;

 /* Log the data  */

data Train3;
set Train2;
lsaleprice=log(SalePrice);
lgrlivarea=log(GrLivArea);
run;

/* Using the model to predict the values  */
/* Forward model  */
proc glm  data = train3 plots= all;
Class Neighborhood;
model lsalePrice = lgrlivarea YearBuilt BedroomAbvGr Fireplaces Neighborhood;
output  out = results p =predict;
run;

/* cleaning up the zero values And unlogging the values*/
data results2;
set results;
if predict > 0 then SalePrice = Exp(Predict);
if predict < 0 then SalePrice = 40000;
Keep id Saleprice;
where  id >  1460;
;

Proc means data  = results2;
var Saleprice;
run;

proc export data=results2 DBMS=CSV

   outfile="/folders/myshortcuts/SASUniversityEdition/Stats project/forwardneighbortestkagglelogged1002.CSV" replace;

run;
/* Using the model to predict the values  */
/* Backward model  */
proc glm  data = train3 plots= all;
Class Neighborhood GarageCars;
model lsalePrice = YearBuilt BedroomAbvGr GarageCars Fireplaces lgrlivarea Neighborhood MiscVal;
output  out = resultsbackward p =predict1;
run;

/* cleaning up the zero values And unlogging the values*/
data resultsbackward2;
set resultsbackward;
if predict1 > 0 then SalePrice = Exp(predict1);
if predict1 < 0 then SalePrice = 40000;
Keep id Saleprice;
where  id >  1460;
;

Proc means data  = resultsbackward2;
var Saleprice;
run;

proc export data=resultsbackward2 DBMS=CSV

   outfile="/folders/myshortcuts/SASUniversityEdition/Stats project/Backwardneighbortestkagglelogged.CSV"replace;

run;
/* Using the model to predict the values  */
/* Stepwise model  */
proc glm  data = train3 plots= all;
Class Neighborhood;
model lsalePrice = YearBuilt BedroomAbvGr Fireplaces lgrlivarea Neighborhood;
output  out = resultsstepwise p =predict2;
run;

/* cleaning up the zero values And unlogging the values*/
data resultsstepwise2;
set resultsstepwise;
if predict2 > 0 then SalePrice = Exp(predict2);
if predict2 < 0 then SalePrice = 40000;
Keep id Saleprice;
where  id >  1460;
;

Proc means data  = resultsstepwise2;
var Saleprice;
run;

proc export data=resultsstepwise2 DBMS=CSV

   outfile="/folders/myshortcuts/SASUniversityEdition/Stats project/stepwiseneighbortestkagglelogged.CSV";

run;
 