FILENAME reffile '/folders/myfolders/books.csv';

PROC IMPORT DATAFILE=reffile
	DBMS=CSV
	OUT=books;
	GETNAMES=YES;
RUN;

proc print data=books;
run;

proc freq data=books;
tables language_code;
run;

data books_clean;
set books;
if language_code = "en-CA" then language_code = "eng";
if language_code = "en-GB" then language_code = "eng";
if language_code = "en-US" then language_code = "eng"; 
if language_code = 97806 then delete;
if language_code = 97808 then delete;
if language_code = 97815 then delete;
if language_code = 97818 then delete;
run; 

proc freq data=books_clean;
tables language_code;
run;

/* seems the big languaes are english, french, german, and spanish - change this to the main languages
and label the rest as others*/


data books_clean2;
set books_clean;
if (language_code ne "eng") and (language_code ne "spa") and (language_code ne "ger") 
and (language_code ne "fre") then language_code = "other";
run; 

proc freq order=freq data=books_clean2;
tables language_code;
run;


proc freq order=freq data=books_clean2;
tables authors;
run;
/* many authors are mentioned multiple times on the list - may have to consider author when analyzing popularity */ 
proc print data=books_clean2;
run;

proc sgplot data=books_clean2;
   title 'Ratings vs. text ratings';
   label ratings_count = "Number of ratings";
   label text_reviews_count = "Number of text reviews";
   styleattrs datasymbols=(circlefilled);
   scatter x=ratings_count y=text_reviews_count ;

proc sgplot data=books_clean2;
   title 'Ratings vs. text ratings';
   label ratings_count = "Number of ratings";
   label average_rating = "Rating";
   styleattrs datasymbols=(circlefilled);
   scatter x=text_reviews_count y=average_rating ;
run;

/* there is an association between rating count and text reviews(corr = 0.86347) - so create an interaction term to account for this association*/

proc corr data=books_clean3;
var ratings_count text_reviews_count;
run;

proc univariate data=books_clean2;
var average_rating;
histogram;
run;
/* out of a possible 5 rating, the average rating is approximately 3.9 - which is quite high - suggests that people are more likely to review good books*/



data books_clean3;
set books_clean2;
int_rating=ratings_count*text_reviews_count;
run;


proc print data=books_clean3;
run;


/* run an ANOVA to determine which features are associated with book popularity */ 
proc glm data=books_clean3;
class language_code;
model average_rating = ratings_count text_reviews_count int_rating __num_pages language_code;
run;

proc sgplot data=books_clean3; 
TITLE "Boxplot of rating across languages";
label language_code ="Language";
label average_rating = "Rating";
vbox average_rating / category=language_code groupdisplay=cluster;
run;

proc sgplot data=books_clean3; 
TITLE "Boxplot of rating across languages";
label __num_pages ="Number of pages";
label average_rating = "Rating";
scatter x=__num_pages y=average_rating;
run;
