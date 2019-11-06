/*Michela Panarella
Oct and Nov 2019*/

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

/* seems the big languaes are english, french, german, and spanish - change this to the main languages
and label the rest as others. Also delete the numeric languages - likely typos*/

data books_clean;
set books;
if language_code in ("en-CA","en-GB", "en-US") then language_code = "eng"; 
if language_code in (97806, 97808, 97815, 97818) then delete;
if (language_code ne "eng") and (language_code ne "spa") and (language_code ne "ger") 
and (language_code ne "fre") then language_code = "other";
run; 

/*check the language changes are correct*/

proc freq data=books_clean;
tables language_code;
run;

proc freq order=freq data=books_clean;
tables authors;
run;
/* many authors are mentioned multiple times on the list - may have to consider author when analyzing popularity */ 

proc freq order=freq data=books_clean;
tables title;
run;

/*which book is most commonly rated - get the top 10*/

proc sort data=books_clean out=top_10 (obs=20);
by descending ratings_count;
Data top_10;
   set top_10 (obs=20);
   proc sort top_10;
   by descending ratings_count;
proc print data=top_10;
var title authors average_rating ratings_count	text_reviews_count; 
run;

proc sgplot data=top_10;
TITLE "The 20 most rated books on Goodreads";
   vbar title / response=ratings_count;
run;

/*Harry Potter, Twilight, LOTR dominate to the surprise of no one*/

proc sgplot data=books_clean;
   title 'Ratings vs. text ratings';
   label ratings_count = "Number of ratings";
   label text_reviews_count = "Number of text reviews";
   styleattrs datasymbols=(circlefilled);
   scatter x=ratings_count y=text_reviews_count ;

proc corr data=books_clean;
var ratings_count text_reviews_count;
run;

/* there is an association between rating count and text reviews(corr = 0.86347) - so create an interaction term to account for this association*/

data books_clean2;
set books_clean;
int_rating=ratings_count*text_reviews_count;
run;

/*plot a histogram of average rating to determine properties of the average rating */ 

proc univariate data=books_clean2;
label average_rating="Average rating"
var average_rating;
histogram;
run;
/* out of a possible 5 rating, the average rating is approximately 3.9 - which is quite high - suggests that people are more likely to review good books*/

/* run an ANOVA to determine which features are associated with book popularity */ 
proc glm data=books_clean2;
class language_code;
model average_rating = ratings_count text_reviews_count int_rating __num_pages language_code;
run;

/* association between ratings, number of pages, and the language with the average rating. I will now use plots to determine the direction of the association */

/* plot different features against the average rating to assess a visual association with these features and average rating */ 

proc sgplot data=books_clean2;
   title 'Average rating as a function of number of ratings';
   label ratings_count = "Number of ratings";
   label average_rating = "Average rating";
   styleattrs datasymbols=(circlefilled);
   scatter x=ratings_count y=average_rating ;

proc sgplot data=books_clean2;
   title 'Average rating as a function of text ratings';
   label ratings_count = "Number of ratings";
   label average_rating = "Rating";
   styleattrs datasymbols=(circlefilled);
   scatter x=text_reviews_count y=average_rating ;

proc sgplot data=books_clean2; 
TITLE "Boxplot of rating across languages";
label language_code ="Language";
label average_rating = "Rating";
vbox average_rating / category=language_code groupdisplay=cluster;

proc sgplot data=books_clean2; 
TITLE "Scatterplot of rating against page numbers";
label __num_pages ="Number of pages";
label average_rating = "Rating";
scatter x=__num_pages y=average_rating;
run;

/* now trying to do a cluster analysis - k means */
/* first standardize the data */
proc stdize data=books_clean2 out=books_stdize method=std;
var average_rating ratings_count text_reviews_count __num_pages;
run;

proc fastclus data=books_stdize out=clust maxclusters=5 maxiter=100;
var average_rating ratings_count text_reviews_count __num_pages;
run;

/* produces data that can be plotted; labels data bythe cluster class */
proc candisc data=clust out=Can noprint;
   class Cluster;
   var average_rating ratings_count text_reviews_count __num_pages;
run;

/*plots the different clusters*/
proc sgplot data=Can;
   scatter y=Can2 x=Can1 / group=cluster;
run;
