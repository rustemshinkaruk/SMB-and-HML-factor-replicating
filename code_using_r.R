
  
#  Problem 1

#Here I download CRSP and find size deciles:

library(data.table)
library(zoo)
library(plyr)

x=as.data.table(read.csv("C:\\Users\\Rustem\\Desktop\\Quantitative Asset Management, Bernard\\hw1\\crsp.csv", header = TRUE, sep = ","))


x[[2]]=as.character(x[[2]])
x[[2]]=as.Date(x[[2]],format="%Y%m%d")
#cleaning
x=x[which(x$SHRCD==10 | x$SHRCD==11),]
x=x[which(x$EXCHCD==1 | x$EXCHCD==2 | x$EXCHCD==3),]
x$PRC=abs(x$PRC)

index=which(x$RET=="C")
x$RET=as.numeric(as.character(x$RET))
x$DLRET=as.numeric(as.character(x$DLRET))
x$RET[index] <- 0#this one says that first return of the company on the day of creation is zero

index3=which(!is.na(x$DLRET))
ff=x$DLRET[index3]
dd=x$RET
dd[dd=index3] <- ff
x$RET=dd

x=x[-which(is.na(x$SHROUT))]

index3=which(!is.na(x$DLRET))
dd=x$PRC
dd[dd=index3] <- dd[index3-1]*(1+x$RET[index3])
x$PRC=dd

x=x[-which(is.na(x$PRC))]
setkey(x,PERMNO,date)
x[,mktcap:=abs(PRC)*SHROUT]

#setting order of the data

setkey(x,PERMNO,date)
vec=c('PERMNO','date')
setorderv(x,vec)

#create lagged mkt cap of each stock at each date
x[,mktcap.lag:=shift(mktcap),by=PERMNO]



#============================================================================
#============================================================================
#============================================================================

x[,Year:=year(date)]
x[,month:=month(date)]
x[,key:=paste(Year,month)]
x=x[,SHRCD:=NULL]
x=x[,DLRET:=NULL]
x=x[,PRC:=NULL]
x=x[,SHROUT:=NULL]



#create variable for SMB ranking. We define lagged market cap as a ranking variable
x=na.omit(x)  
# x[, `:=`(decile_month, cut(mktcap.lag, breaks = quantile(mktcap.lag[which(EXCHCD==1)],probs = c(0,0.5,1), na.rm = TRUE), include.lowest = TRUE, labels = FALSE)),by = key]
# 
# x[, `:=`(decile_month_help, cut(mktcap.lag, breaks = quantile(mktcap.lag,probs = c(0,0.5,1), na.rm = TRUE), include.lowest = TRUE, labels = FALSE)),by = key]
# 
# 
# x[,decile_month2:=ifelse(is.na(decile_month) & decile_month_help==1,1,ifelse(is.na(decile_month) & decile_month_help==2,2,decile_month))]
# 
# 
# x=x[,decile_month:=NULL]
# x=x[,decile_month_help:=NULL]
# 
# smb_deciles=copy(x)

#```



#Now lets try to aggregate the return of firms that have several permnos
#```{r,eval=TRUE}

#Aggreagate return of firm that has several securities traded
x[,permno_weight:=mktcap.lag/sum(mktcap.lag),by=.(PERMCO,key)]
x[,ret:=sum(permno_weight*RET),by=.(PERMCO,key)]
x[,mktcap.lag:=sum(mktcap.lag),by=.(PERMCO,key)]
x=unique(x[,.(PERMCO,date,EXCHCD,mktcap,mktcap.lag,ret,key,Year,month)],by=c("PERMCO","key"))
setorder(x,PERMCO,key)


#Linking
#Step 1. link crsp to link table
link=as.data.table(read.csv('link.csv'))
link$LINKDT=as.Date(strptime(link$LINKDT,format="%Y%m%d"))
link$LINKENDDT=as.Date(strptime(link$LINKENDDT,format="%Y%m%d"))

merged=merge(x,link,by.x="PERMCO",by.y="LPERMCO",allow.cartesian = T)
setkey(merged)
merged=merged[(is.na(LINKDT) | date>=LINKDT) & (is.na(LINKENDDT) | date<=LINKENDDT)]
setorder(merged,gvkey,date)


#============================================================================
#============================================================================
#============================================================================
#Multiple GVkeys per PERMCO
#First if LC not LC linktype
merged[,prob:=.N>1,by=.(PERMCO,date)]
merged[,Good_match:=sum(LINKTYPE=='LC'),by=.(PERMCO,date)]
merged=merged[!(prob==T & Good_match==T & LINKTYPE!='LC')]

#Second, if P and not P linkprim
merged[,prob:=.N>1,by=.(PERMCO,date)]
merged[,Good_match:=sum(LINKTYPE=='P'),by=.(PERMCO,date)]
merged=merged[!(prob==T & Good_match==T & LINKTYPE!='P')]

#Third, if 1 and not 1 liid 
merged[,prob:=.N>1,by=.(PERMCO,date)]
merged[,Good_match:=sum(LIID==1),by=.(PERMCO,date)]
merged=merged[!(prob==T & Good_match==T & LIID!=1)]

#Fourth, use the link that's current
merged[,prob:=.N>1,by=.(PERMCO,date)]
merged[,Good_match:=sum(is.na(LINKENDDT)),by=.(PERMCO,date)]
merged=merged[!(prob==T & Good_match==T & !is.na(LINKENDDT))]

#Fifth, use the link that's been around the longest
merged[,prob:=.N>1,by=.(PERMCO,date)]
merged[,Good_match:=NULL]
merged[is.na(LINKENDDT),LINKENDDT:=as.Date('2017-01-31','%Y-%m-%d')]
merged[,Date_diff:=as.integer(LINKENDDT-LINKDT)]
setorder(merged,PERMCO,date,Date_diff)
merged[prob==T,Good_match:=Date_diff==Date_diff[.N],by=.(PERMCO,date)]
merged=merged[!(prob==T & Good_match!=T)]

#SIxth, use GVKEY that's around the longest
merged[,prob:=.N>1,by=.(PERMCO,date)]
merged[,Good_match:=NULL]
setorder(merged,gvkey,LINKDT)
merged[prob==T,start_Date:=LINKDT[1],by=.(gvkey)]
setorder(merged,gvkey,LINKENDDT)
merged[prob==T,end_Date:=LINKENDDT[.N],by=.(gvkey)]
merged[,Date_diff:=as.integer(end_Date-start_Date)]
setorder(merged,PERMCO,date,Date_diff)
merged[prob==T,Good_match:=Date_diff==Date_diff[.N],by=.(PERMCO,date)]
merged=merged[!(prob==T & Good_match!=T)]

#Seventh
setorder(merged,PERMCO,date,gvkey)
merged=unique(merged,by=c('PERMCO','date'))

#Clean-up
if(nrow(unique(merged,by=c('gvkey','date'))) !=nrow(merged) | nrow(unique(merged,by=c('PERMCO','date'))) !=nrow(merged)) {stop ('1. Monthly firm level returns.R: There is an issue with your merge between CRSP/Compustat')} 
#mergedlink=merged[,.(gvkey,date,EXCHCD,lag_mkt_cap,return,Date_diff)]
mergedlink=copy(merged)
mergedlink[,conm:=NULL]
mergedlink[,LINKPRIM:=NULL]
mergedlink[,LIID:=NULL]
mergedlink[,LINKTYPE:=NULL]
mergedlink[,LINKDT:=NULL]
mergedlink[,LINKENDDT:=NULL]
mergedlink[,prob:=NULL]
mergedlink[,Date_diff:=NULL]
mergedlink[,start_Date:=NULL]
mergedlink[,end_Date:=NULL]
mergedlink[,Good_match:=NULL]
mergedlink[,special_key:=(mergedlink$Year+mergedlink$month/100)]


#============================================================================
#============================================================================
#============================================================================



#merge with compustat
compustat=as.data.table(read.csv('compustat.csv',stringsAsFactors = FALSE))
compustat$datadate=as.Date(strptime(compustat$datadate,format="%Y%m%d"))

compustat[,Year:=year(datadate)]
compustat[,month:=month(datadate)]
compustat[,key:=paste(Year,month)]

pension=as.data.table(read.csv('pension.csv',stringsAsFactors = FALSE))
pension=pension[,c('gvkey','datadate','prba')]
pension$datadate=as.Date(strptime(pension$datadate,format="%Y%m%d"))

pension[,Year:=year(datadate)]
pension[,month:=month(datadate)]
pension[,key:=paste(Year,month)]

setkey(compustat,key)
setkey(pension,key)

compustat[,special_key:=(compustat$Year+compustat$month/100)]
pension[,special_key:=(pension$Year+pension$month/100)]


xx=merge(compustat,pension,by=c('gvkey','key'),all.x=TRUE)
xx[,Year.x:=NULL]
xx[,month.x:=NULL]
xx[,Year.y:=NULL]
xx[,month.y:=NULL]
xx[,datadate.y:=NULL]
xx[,special_key.y:=NULL]



x=merge(mergedlink,xx,by=c('gvkey','key'),all.x=TRUE)
setorderv(x,c("gvkey","special_key"))
#```




#SHE
x[,SHE:=ifelse(!is.na(seq),seq,ifelse(!is.na(ceq+pstk),ceq+pstk,ifelse(!is.na(at+lt+mib),at-lt-mib,at-lt)))]
#DT
x[,DT:=ifelse(!is.na(txditc),txditc,ifelse(!is.na(itcb+txdb),itcb+txdb,ifelse(!is.na(itcb),itcb,ifelse(!is.na(txdb),txdb,0))))]


#PS
x[,PS:=ifelse(!is.na(pstkrv),pstkrv,ifelse(!is.na(pstkl),pstkl,pstk))]
#BE
x[,prba1:=ifelse(!is.na(prba),prba,0)]
x[,prba:=NULL]
x[,BE:=SHE-PS+DT-prba1]


x=x[,c("gvkey","key","date","EXCHCD","mktcap","mktcap.lag","ret","Year","month","special_key","BE")]
#```


Here I also define 10 decile for size portfolio

#```{r,eval=TRUE}

ff=as.data.table(read.csv("C:\\Users\\Rustem\\Desktop\\Quantitative Asset Management, Bernard\\hw1\\fama.csv", header = FALSE, sep = ","))
ff=ff[-1,]
ff=ff[-1,]
colnames(ff)=c("date","mktrf","SMB","HML","RF")
ff=ff[-1,]
ff=ff[-(1111:length(ff[[1]])),]
for(i in 2:5){
ff[[i]]=as.numeric(as.character(ff[[i]]))
}
ff[[1]]=as.character(ff[[1]])
ff[[1]]=as.Date(paste(ff[[1]],"01",sep=""),format="%Y%m%d")
setnames(ff,"date","date")
setkey(ff,date)
ff[,Year:=year(date)]
ff[,month:=month(date)]
ff[,key:=paste(Year,month)]
ff[,`mktrf`:=`mktrf`/100]
ff[,SMB:=SMB/100]
ff[,HML:=HML/100]
ff[,RF:=RF/100]

setkey(x,key)
setkey(ff,key)
a=merge(x,ff,by="key",all.x=TRUE)
setorderv(a,c("gvkey","special_key"))

a[,date.y:=NULL]
a[,mktrf:=NULL]
a[,HML:=NULL]
a[,SMB:=NULL]
a[,month.y:=NULL]
a[,Year.y:=NULL]

a[,ret_rf:=ret-RF]

x=copy(a)

x=x[, if (.N > 12) .SD, by = gvkey]
library(zoo)
library(plyr)
func <- function(z){
return(prod(1+z[1:12])-1)
}

x[, rank_ret := rollapplyr(ret_rf, width = 13, FUN = func, fill = NA,align="left"), by = gvkey]


#```


#```{r,eval=TRUE}
library(e1071)
x[, `:=`(decile_month, cut(mktcap, breaks = quantile(mktcap[which(EXCHCD==1)],probs = c(0,0.5,1), na.rm = TRUE), include.lowest = TRUE, labels = FALSE)),by = key]

x[, `:=`(decile_month_help, cut(mktcap, breaks = quantile(mktcap,probs = c(0,0.5,1), na.rm = TRUE), include.lowest = TRUE, labels = FALSE)),by = key]


x[,smb_decile:=ifelse(is.na(decile_month) & decile_month_help==1,1,ifelse(is.na(decile_month) & decile_month_help==2,2,decile_month))]


x=x[,decile_month:=NULL]
x=x[,decile_month_help:=NULL]

setnames(x,"date.x","date")
setnames(x,"Year.x","Year")
setnames(x,"month.x","month")


x[,smb_june_decile:=ifelse(month==6,smb_decile,NA)]#is it month 7 or month 6? check later

#create lagged BE
new=x[,c("gvkey","key","date","EXCHCD","mktcap.lag","ret","BE","Year","month")]
new=na.omit(new)
new[,lagged_BE_by_year:=shift(BE),by=gvkey]
new=new[,c("gvkey","key","Year","EXCHCD","lagged_BE_by_year")]

#x=merge(x,new,by=c('gvkey','key'),all.x=TRUE)
#setorderv(x,c("gvkey","special_key"))

#create december ME
# x[,lagged_december_ME:=shift(mktcap.lag),by=.(gvkey,Year)]
# x[,lagged_december_ME:=NULL]
new2=x[month==12,c("gvkey","key","date","EXCHCD","mktcap.lag","ret","Year","month")]
new2[,lagged_december_ME:=shift(mktcap.lag),by=gvkey]
new2=new2[,c("gvkey","key","Year","EXCHCD","lagged_december_ME")]
#new2=na.omit(new2)

new3=x[month==6,c("gvkey","key","Year","rank_ret","smb_decile","EXCHCD","mktcap","mktcap.lag")]


# x=merge(x,new,by=c('gvkey','key'),all.x=TRUE)
# setorderv(x,c("gvkey","special_key"))

# backup3=copy(x)
# 
# x=copy(backup3)

t=merge(new,new2,by=c('gvkey','Year'))
t[,key.y:=NULL]
setorderv(t,c("gvkey","Year"))
t[,lagged_BE_by_year:=lagged_BE_by_year*1000]
t[,BM:=lagged_BE_by_year/lagged_december_ME]
t=na.omit(t)

#merge
setnames(t,"key.x","key")
t=merge(t,new3,by=c('gvkey','Year'))
t=na.omit(t)
setorderv(t,c("gvkey","Year"))

t[,lagged_BE_by_year:=NULL]
t[,lagged_december_ME:=NULL]
t[,key.x:=NULL]
setnames(t,"key.y","key")
setnames(t,"smb_decile","size_decile")
t[,EXCHCD.x:=NULL]
t[,EXCHCD.y:=NULL]



t[, `:=`(bm_decile, cut(BM, breaks = quantile(BM[which(EXCHCD==1)],probs = c(0,0.3,0.7,1), na.rm = TRUE), include.lowest = TRUE, labels = FALSE)),by = key]
t=na.omit(t)
#exclude negative BE
t=t[which(BM>0),]
#subset by Year
t=t[Year>=1973,]

tt=copy(t)

#```


#Here I calculate 10 deciles for BM portfolios
#```{r,eval=TRUE}
t=copy(tt)
t[, `:=`(decile_month, cut(BM, breaks = quantile(BM[which(EXCHCD==1)],probs = c(0:10)/10, na.rm = TRUE), include.lowest = TRUE, labels = FALSE)),by = key]
t[, `:=`(decile_month_help, cut(BM, breaks = quantile(BM,probs = c(0:10)/10, na.rm = TRUE), include.lowest = TRUE, labels = FALSE)),by = key]
t[,new_BM_decile:=ifelse(is.na(decile_month) & decile_month_help<=5,1,ifelse(is.na(decile_month) & decile_month_help>5,10,decile_month))]
t=t[,decile_month:=NULL]
t=t[,decile_month_help:=NULL]




xx=t[,c("gvkey","key","EXCHCD","mktcap","mktcap.lag","rank_ret","Year","new_BM_decile")]
xx=na.omit(xx)
xx[,weight := mktcap/sum(mktcap), by = .(key,new_BM_decile)]

setkey(xx,key)
z=xx[, weighted.mean(rank_ret,weight), by = .(key,new_BM_decile,Year)]

setorderv(z,c("Year","new_BM_decile"))


setnames(z,"V1","return_decile")

fin1=matrix(0,nrow=4,ncol=10)
table=z
table_bm=table
for (i in 1:10){
fin1[1,i]=mean(table$return_decile[which(table$new_BM_decile==i)])
fin1[2,i]=sd(table$return_decile[which(table$new_BM_decile==i)])
fin1[3,i]=fin1[1,i]/fin1[2,i]
fin1[4,i]=skewness(table$return_decile[which(table$new_BM_decile==i)])
}

rownames(fin1)=c('mean','sigma','SR','SK(m)')
colnames(fin1)=c(paste0('Decile ',seq(1,10,1)))
fin1
#```


#```{r,eval=TRUE}
t=copy(tt)
t[, `:=`(decile_month, cut(mktcap, breaks = quantile(mktcap[which(EXCHCD==1)],probs = c(0:10)/10, na.rm = TRUE), include.lowest = TRUE, labels = FALSE)),by = key]
t[, `:=`(decile_month_help, cut(mktcap, breaks = quantile(mktcap,probs = c(0:10)/10, na.rm = TRUE), include.lowest = TRUE, labels = FALSE)),by = key]
t[,new_size_decile:=ifelse(is.na(decile_month) & decile_month_help<=5,1,ifelse(is.na(decile_month) & decile_month_help>5,10,decile_month))]
t=t[,decile_month:=NULL]
t=t[,decile_month_help:=NULL]

xx=t[,c("gvkey","key","EXCHCD","mktcap","mktcap.lag","rank_ret","Year","new_size_decile")]
xx=na.omit(xx)
xx[,weight := mktcap/sum(mktcap), by = .(key,new_size_decile)]

setkey(xx,key)
z=xx[, weighted.mean(rank_ret,weight), by = .(key,new_size_decile,Year)]

setorderv(z,c("Year","new_size_decile"))


setnames(z,"V1","return_decile")

fin11=matrix(0,nrow=4,ncol=10)
table=z
table_me=table
for (i in 1:10){
fin11[1,i]=mean(table$return_decile[which(table$new_size_decile==i)])
fin11[2,i]=sd(table$return_decile[which(table$new_size_decile==i)])
fin11[3,i]=fin11[1,i]/fin11[2,i]
fin11[4,i]=skewness(table$return_decile[which(table$new_size_decile==i)])
}

rownames(fin11)=c('mean','sigma','SR','SK(m)')
colnames(fin11)=c(paste0('Decile ',seq(1,10,1)))
fin11


#```

#Create 6 portfolios
#```{r,eval=TRUE}
t=copy(tt)

t[,weight := mktcap/sum(mktcap), by = .(key,Year,size_decile,bm_decile)]
#check that weights are summing up to 1
#dd=t[,sum(weight),by=.(size_decile,bm_decile,Year)]
setkey(t,key)
z=t[, weighted.mean(rank_ret,weight), by = .(key,Year,size_decile,bm_decile)]
setnames(z,"V1","return_decile")
setorderv(z,c("Year","size_decile","bm_decile"))

w=copy(z)

z=z[,mean(return_decile),by=.(size_decile,bm_decile)]
rownames(z) <- c("small_growth","small_neutral","small_value","big_growth","big_neutral","big_value")
z
#```

#Find HML and SMB
#```{r,eval=TRUE}
#working with w that has 270 observations (annual data)
w[,port:="c"]
for(i in 1:270){
if(w$size_decile[i]==1 & w$bm_decile[i]==1){
w$port[i]="SL"
}
if(w$size_decile[i]==1 & w$bm_decile[i]==2){
w$port[i]="SM"
}
if(w$size_decile[i]==1 & w$bm_decile[i]==3){
w$port[i]="SH"
}
if(w$size_decile[i]==2 & w$bm_decile[i]==1){
w$port[i]="BL"
}
if(w$size_decile[i]==2 & w$bm_decile[i]==2){
w$port[i]="BM"
}
if(w$size_decile[i]==2 & w$bm_decile[i]==3){
w$port[i]="BH"
}
}

R_SL=w$return_decile[which(w$port=="SL")]
R_SM=w$return_decile[which(w$port=="SM")]
R_SH=w$return_decile[which(w$port=="SH")]
R_BL=w$return_decile[which(w$port=="BL")]
R_BM=w$return_decile[which(w$port=="BM")]
R_BH=w$return_decile[which(w$port=="BH")]


RS=(1/3)*(R_SL+R_SM+R_SH)
RB=(1/3)*(R_BL+R_BM+R_BH)
SMB=RS-RB

RH=0.5*(R_SH+R_BH)
RL=0.5*(R_SL+R_BL)
HML=RH-RL






fin111=matrix(0,nrow=4,ncol=8)
table=data.frame(R_SL,R_SM,R_SH,R_BL,R_BM,R_BH,SMB,HML)
table_six=table
for (i in 1:8){
fin111[1,i]=mean(table[[i]])
fin111[2,i]=sd(table[[i]])
fin111[3,i]=fin111[1,i]/fin111[2,i]
fin111[4,i]=skewness(table[[i]])
}


rownames(fin111)=c('mean','sigma','SR','SK(m)')
colnames(fin111)=c(colnames(table))
fin111
#```


#correlation
#```{r,eval=TRUE}


library(readxl)
fama_size_deciles=as.data.table(read_excel("C:\\Users\\Rustem\\Desktop\\Quantitative Asset Management, Bernard\\hw4\\size_deciles.xlsx"))
fama_size_deciles=fama_size_deciles[X__1>=1973 & X__1<2018,]
fama_size_deciles=fama_size_deciles[,c(11:20)]
fama_size_deciles=fama_size_deciles/100


fin131=matrix(0,nrow=1,ncol=10)

for (i in 1:10){
fin131[1,i]=cor(table_me$return_decile[which(table_me$new_size_decile==i)],fama_size_deciles[[i]])

}

colnames(fin131)=c(paste0('Decile ',seq(1,10,1)))
fin131
#```



#```{r,eval=TRUE}
fama_bm_deciles=as.data.table(read_excel("C:\\Users\\Rustem\\Desktop\\Quantitative Asset Management, Bernard\\hw4\\bm_deciles.xlsx"))
fama_bm_deciles=fama_bm_deciles[X__1>=1973 & X__1<2018,]
fama_bm_deciles=fama_bm_deciles[,c(11:20)]
fama_bm_deciles=fama_bm_deciles/100


fin1331=matrix(0,nrow=1,ncol=10)

for (i in 1:10){
fin1331[1,i]=cor(table_bm$return_decile[which(table_bm$new_BM_decile==i)],fama_bm_deciles[[i]])

}

colnames(fin1331)=c(paste0('Decile ',seq(1,10,1)))
fin1331

#```

#```{r,eval=TRUE}
six_port=as.data.table(read_excel("C:\\Users\\Rustem\\Desktop\\Quantitative Asset Management, Bernard\\hw4\\six_port.xlsx"))
six_port=six_port[X__1>=1973 & X__1<2018,]
six_port=six_port[,c(2:7)]
six_port=six_port/100

fin11331=matrix(0,nrow=1,ncol=6)

for (i in 1:6){
fin11331[1,i]=cor(table_six[[i]],six_port[[i]])

}
colnames(fin11331) <- c("R_SL","R_SM","R_SH","R_BL","R_BM","R_BH")
fin11331
#```

#```{r,eval=TRUE}
fama_bm_deciles=as.data.table(read_excel("C:\\Users\\Rustem\\Desktop\\Quantitative Asset Management, Bernard\\hw4\\bm_deciles.xlsx"))
fama_bm_deciles=fama_bm_deciles[X__1>=2010,]
fama_bm_deciles=fama_bm_deciles[,c(11:20)]
fama_bm_deciles=fama_bm_deciles/100
fama_size_deciles=as.data.table(read_excel("C:\\Users\\Rustem\\Desktop\\Quantitative Asset Management, Bernard\\hw4\\size_deciles.xlsx"))
fama_size_deciles=fama_size_deciles[X__1>=2010,]
fama_size_deciles=fama_size_deciles[,c(11:20)]
fama_size_deciles=fama_size_deciles/100
vec1=colMeans(fama_size_deciles)
vec2=colMeans(fama_bm_deciles)
names(vec1)=c(paste0('Decile ',seq(1,10,1)))
names(vec2)=c(paste0('Decile ',seq(1,10,1)))
vec1
vec2
aa=matrix(0,nrow=2,ncol=10)
aa[1,]=vec1
aa[2,]=vec2
colnames(aa)=c(paste0('Decile ',seq(1,10,1)))

aa
#


#```{r,eval=TRUE}

fama_factors=as.data.table(read_excel("C:\\Users\\Rustem\\Desktop\\Quantitative Asset Management, Bernard\\hw4\\annual factors.xlsx"))

fama_factors=fama_factors[X__1>=1973 & X__1<2018,]
fama_factors=fama_factors[,c(3:4)]
fama_factors=fama_factors/100

fin1411=matrix(0,nrow=4,ncol=2)
table=data.frame(SMB,HML)
for (i in 1:2){
fin1411[1,i]=mean(table[[i]])
fin1411[2,i]=sd(table[[i]])
fin1411[3,i]=fin111[1,i]/fin111[2,i]
fin1411[4,i]=skewness(table[[i]])
}

rownames(fin1411)=c('mean','sigma','SR','SK(m)')
colnames(fin1411)=c(colnames(table))
fin1411


vec=c(cor(fama_factors$SMB,table$SMB),cor(fama_factors$HML,table$HML))
names(vec)=c("SMB","HML")
vec
#```



#```{r,eval=TRUE}

fama_factors=as.data.table(read_excel("C:\\Users\\Rustem\\Desktop\\Quantitative Asset Management, Bernard\\hw4\\annual factors.xlsx"))

fama_factors=fama_factors[X__1>=1943,]
d=fama_factors$X__1
fama_factors=fama_factors[,c(2:4)]
fama_factors=fama_factors/100
plot(d,cumsum(fama_factors$`Mkt-RF`),type="l")
lines(d,cumsum(fama_factors$SMB),type="l",col="blue")
lines(d,cumsum(fama_factors$HML),type="l",col="red")


#```





