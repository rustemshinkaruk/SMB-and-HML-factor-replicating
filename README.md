# SMB-and-HML-factor-replicating

I replicated SMB and HML factors from Fama French paper and used some visualitation tools to depict the performance of deciles and some additional graphs. Results at the end.

Problem 1,2,3.

Cleaning steps:

I downloaded 8 variables specified in the assignment from CRSP from Jan 1973 to Dec 2018. I used monthly data through this homework. 

I restrict the sample to common shares (share codes 10 and 11) and to securities traded in the New York Stock Exchange, American Stock Exchange, or the Nasdaq Stock Exchange (exchange codes 1, 2, and 3).

I take absolute value of prices because there are some negative prices. (they are negative because price was not available at that date and average of bid ask is taken with minus sign) so it is reasonable to take absolute values of them.

Then I assign zero return to the month when company was created. It is reasonable because if you buy company at the date of creation your return will be zero on that day if we assume price to be constant that day. This assumption can be argued but having the limited data this is best what I can think of.

I take into account delisting return. If return is missing on the delisting date, I insert delisting return instead and calculate the price for delisting date as previous price multiplied by one plus delisting return. If the previous price is not available, I exclude the entire row.  If both delisting returns and returns are not missing then I use for returns (1+ret)*(1+deltisting return)-1.

After I accounted for missing prices and delisting returns where it was possible (i.e. delisting return and previous price was available) I remove all rows with either missing prices, returns or shares outstanding. The reason for removing them is that there are periods when there are no data for several months in a row and it becomes hard to reasonably interpolate the data. 

By the time I start my output calculations I don't have any missing values in data set.

I calculate Market value by multiplying shares outstanding by price. 

Then I find total market capitalization for each month by summing market capitalizations of each individual firms for a particular month and lag it by 1 month.

I define lagged market capitalization as lagged by 1 month market capitalization.



Merging

At the beginning I deal with firms that have multiple traded securities. I value weight the return from different securities of the same firm and sum it up under the name of the same firm. 


Then I link my crsp data to linktable. Linktable is taken from wrds website in the section:

 Get DataCRSPAnnual UpdateCRSP/Compustat MergedCRSP/Compustat Merged Database - Linking Table.

Then I make sure that Linkdate is valid for my dataset and make sure that there are no several gvkey for the same company date. Steps are described in the code and in essence repeat every step from the TA session.

I downloaded all variables specified in the assignment from Compustat from Jan 1973 to Dec 2018. I used annual data. The variables are defined in the assignment and required to calculate Book value of the firms.

The path on wrds to the file:

Get DataCompustat - Capital IQCompustatNorth America - DailyCompustat Daily Updates - Fundamentals Annual

The variables are:
“…
1)Shareholders' equity (SHE): variable reported in Compustat is \Stockholders' Eq-
uity - Total" (SEQ). If not available, use \Common/Ordinary Equity - Total"
(CEQ) plus \Preferred/Preference Stock (Capital) - Total" (PSTK). If not avail-
able, use \Assets - Total" (AT) minus \Liabilities - Total" (LT) minus \Minority
Interest (Balance Sheet)" (MIB). If not available, use AT minus LT.
2)Deferred taxes and investment tax credit (DT): variable reported in Compustat
is \Deferred Taxes and Investment Tax Credit" TXDITC. If not available, use
\Investment Tax Credit (Balance Sheet)" (ITCB) plus \Deferred Taxes (Balance
Sheet)" (TXDB). If not available, sum what is not missing.
3)Book value of preferred stock (PS): Use redemption value, which is variable \Pre-
ferred Stock Redemption Value" (PSTKRV). If not available, use liquidation value,
which is \Preferred Stock Liquidating Value" (PSTKL). If not available, use par
value, which is \Preferred/Preference Stock (Capital) - Total" (PSTK).
4)De_ne book equity (BE) as: BE = SHE -PS + DT - PRBA (need value of
SHE to compute BE, other variables included if not missing). The last variable
is \Postretirement Benefit Asset" (PRBA), and you will have to get this variable
from Compustat's Pension Annual data: merge to Compustat using Compustat's
global variable key (GVKEY).
…”


Initially I merge compustat with pension data that is described above. Then I merge CRSP and Compustat. And then I also add file from with risk free return from Fama and French website. So far, I deal with monthly data everywhere. It is easier at the beginning and by the end I will aggregate to the annual data. 

The risk free rate series is the one-month Treasury bill rate that I include in output table and use it in order to calculate excess returns. From now an on I use everywhere excess returns.








Output Calculation

The following instructions are taken from Common risk factors in the returns on
stocks and bonds, Fama and French, 1992 and 1993.

I followed the following steps described in the paper:

In June of each year t, all NYSE stocks on CRSP are
ranked on size (price times shares). The median NYSE size is then used to
split NYSE, Amex. and (after 1972) NASDAQ stocks into two groups. small and
big (S and B). 

We also break NYSE, Amex, and NASDAQ stocks into three book-to-market
equity groups based on the breakpoints for the bottom 30% (Low),
middle 40% and top 30% (High) of the ranked values of BE/ME for
NYSE stocks. We define book common equity, BE. as the COMPUSTAT book
value of stockholders’ equity, plus balance-sheet deferred taxes and investment
tax credit (if available), minus the book value of preferred stock. Depending on
availability, we use the redemption, liquidation, or par value (in that order) to
estimate the value of preferred stock. Book-to-market equity, BE/ME. is then
book common equity for the fiscal year ending in calendar year t - 1, divided by
market equity at the end of December oft - 1. We do not use negative-BE firms,
which are rare before 1980, when calculating the breakpoints for BE/ME
or when forming the size-BE/ME portfolios. Also. only firms with ordinary
common equity (as classified by CRSP) are included in the tests. This means that
ADRs, REITs, and units of beneficial interest are excluded.

We construct six portfolios (S/L, S;,V, S/H. B/L, B,/M, B/H) from the intersections
of the two ME and the three BE/ME groups. For example. the S/L
portfolio contains the stocks in the small-ME group that are also in the
low-BE/ME group, and the BI’H portfolio contains the big-.CIE stocks that also
have high BE/MEs. Monthly value-weighted returns on the six portfolios are
calculated from July of year t to June of t + 1. and the portfolios are reformed in
June of t + 1. We calculate returns beginning in July of year t to be sure that
book equity for year t - 1 is known.

To be included in the tests, a firm must have CRSP stock prices for December
of year t - 1 and June of t and COMPUSTAT book common equity for year
t - 1. Moreover, to avoid the survival bias inherent in the way COMPUSTAT
adds firms to its tapes [Banz and Breen (1986)], we do not include firms until
they have appeared on COMPUSTAT for two years. 


I define the returns that are used in the portfolio construction (both for size and value) as following:
We form our portfolios at June, then the holding return will be calculated as geometric return from July of the current year to the June of the next year.

The holding period returns of the decile portfolios are the value-weighted returns of the firms in the portfolio over the one year holding period from the closing price last trading day in June through the last trading day of June. 

I find weights by dividing each firm's market capitalization lagged by 1 period by total market capitalization lagged by 1 period for each firm for each month. Then to find value weighted return in period t I use weights that were calculated using t-1 market capitalization. I multiply weights by return. Then I find sum of weights multiplied by returns for each month for each decile portfolio.

The first output is 10 decile portfolios for Book to market Value. Decile one is the lowest BM and Decile 10 is the highest BM value. We see the rising trend in Deciles which is what we would expect but it is not so smooth as I would like it to be. Later we will see the reason why. This are excess returns. Sample:1973.01-2018.12. Data: Annual.

![alt text](https://github.com/rustemshinkaruk/SMB-and-HML-factor-replicating/blob/master/table_1.png)


I report the following  statistics: annualized mean, annualized standard deviation, annualized sharpe ratio, skewness, and excess kurtosis

I used annual data to calculate all statistics that are presented below. I used all sample data that I have in calculations of kurtosis and skewness. To calculate all statistics I used R built in functions: mean(), sd(),skewness(),kurtosis(). Sharpe ratio was calculated as mean(excess return)/sd(excess return)

I calculate the first row as a mean return of the portfolios for a particular decile from 1 to 10 and special This is equal weighted mean. 

I calculate the second row as a standard deviation of portfolio returns for a particular decile from 1 to 10.

The correlation with Fama and French portfolios is:

![alt text](https://github.com/rustemshinkaruk/SMB-and-HML-factor-replicating/blob/master/table_2.png)

They are obviously not the best one could achieve. I followed the rules strictly as described above but it seems to me that there could me some bugs in code but this is still uncertain. 

The second output is 10 decile portfolios for Size. Decile one is the lowest size and Decile 10 is the highest size value. We see the falling trend in Deciles which is what we would expect but it is not so smooth as I would like it to be. Later we will see the reason why. This are excess returns. Sample:1973.01-2018.12. Data: Annual.

![alt text](https://github.com/rustemshinkaruk/SMB-and-HML-factor-replicating/blob/master/table_3.png)

I report the following  statistics: annualized mean, annualized standard deviation, annualized sharpe ratio, skewness, and excess kurtosis

I used annual data to calculate all statistics that are presented below. I used all sample data that I have in calculations of kurtosis and skewness. To calculate all statistics I used R built in functions: mean(), sd(),skewness(),kurtosis(). Sharpe ratio was calculated as mean(excess return)/sd(excess return)

I calculate the first row as a mean return of the portfolios for a particular decile from 1 to 10 and special This is equal weighted mean. 

I calculate the second row as a standard deviation of portfolio returns for a particular decile from 1 to 10.

The correlation with Fama and French portfolios is:


![alt text](https://github.com/rustemshinkaruk/SMB-and-HML-factor-replicating/blob/master/table_4.png)

Again, not the perfect result. The reason is unknown to me. Most likely that I missed something in the coding part.

The third output is 6 portfolios for 
SL=small size and low book to market, 
SM= small size and medium book to market, 
SH= small size and high book to market
BL=big size and low book to market, 
BM= big size and medium book to market, 
BH= big size and high book to market
SMB=(1/3)*(SL+SM+SH-BL-BM-BH)
HML=0.5*(SH+BH-SL-BL)
 
Decile one is the lowest size and Decile 10 is the highest size value. This are excess returns. Sample:1973.01-2018.12. Data: Annual.


![alt text](https://github.com/rustemshinkaruk/SMB-and-HML-factor-replicating/blob/master/table_5.png)

I report the following  statistics: annualized mean, annualized standard deviation, annualized sharpe ratio, skewness, and excess kurtosis

I used annual data to calculate all statistics that are presented below. I used all sample data that I have in calculations of kurtosis and skewness. To calculate all statistics I used R built in functions: mean(), sd(),skewness(),kurtosis(). Sharpe ratio was calculated as mean(excess return)/sd(excess return)

I calculate the first row as a mean return of the portfolios for a particular decile from 1 to 10 and special This is equal weighted mean. 

The correlation with Fama and French portfolios is:



![alt text](https://github.com/rustemshinkaruk/SMB-and-HML-factor-replicating/blob/master/table_6.png)


Again, not the perfect result. The reason is unknown to me. Most likely that I missed something in the coding part.



Problem 4.
To assess whether size and value worked before let’s look at the last 8 years of data. (from 2010.01 to 2018.12). Data is taken on decile portfolios for size and value from Fama and French website. 



The first row is size and the second row is value.


![alt text](https://github.com/rustemshinkaruk/SMB-and-HML-factor-replicating/blob/master/table_7.png)

The size shows reverse relationship to those that was find on the longer sample. Here if we take decile1-decile10 we will see negative return that goes against theory that small cap firms outperform big firms.
Value also does not seem to work. If we take decile 10 (high BM) minus decile 1 (low BM) we will observe negative return.

Problem 7.
SMB=(1/3)*(SL+SM+SH-BL-BM-BH)
HML=0.5*(SH+BH-SL-BL)
Sample:1973.01-2018.12. Data: Annual.


![alt text](https://github.com/rustemshinkaruk/SMB-and-HML-factor-replicating/blob/master/table_8.png)

If we will plot the cumulative returns from these factors (red – HML, blue-SMB, black-Market) we can observe some inconsistencies , for example in 2000, market went up and both factors went down and in the last decade factors were performing bad relative to the upward movement of market.

![alt text](https://github.com/rustemshinkaruk/SMB-and-HML-factor-replicating/blob/master/table_9.png)

Problem 6.
Factor portfolios returns can be fully attributed to the differences in their factor characteristics. It is not necessary that one factor explains the difference in portfolio returns. The efficient factor investing requires an understanding of how factor characteristics drive portfolio returns. When we split data in six portfolios by holding one factor constant and varying the other factor, in case of our paper we , for example, hold size constant and vary the book to market ratio, we can see some insight into how it changes and performs. 
To show graphically what I mean the following graphs can help, looking at them we can see the difference of the performance when we vary one factor and hold another (multiple characteristics):

![alt text](https://github.com/rustemshinkaruk/SMB-and-HML-factor-replicating/blob/master/table_10.png)

![alt text](https://github.com/rustemshinkaruk/SMB-and-HML-factor-replicating/blob/master/table_11.png)


