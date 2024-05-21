# install.packages("boot")

library(data.table)
library(tidyverse)
library(readr)
library(writexl)
library(magrittr)
library(MCS)
library(boot)
library(forecast)

rm(list = ls())
setwd("C:/Users/meunieb/Desktop")

# Getting data for FA-MIDAS and Lasso
mth <- c("M1","M2","M3")
for (month in mth){
  namedata <- paste0("BR_",month,".CSV")
  namedon <- paste0("don_",month)
  assign(namedon,
         read_delim(namedata, "\t", escape_double = FALSE, trim_ws = TRUE))
}

# Preparing data for M1
don_M1 %<>%
  select(starts_with("BR_LARS")) %>%
  filter(BR_LARS_MOD6_M1_S!=0)

# Preparing data for M2
don_M2 %<>%
  select(starts_with("BR_LARS")) %>%
  filter(BR_LARS_MOD6_M2_S!=0)

# Preparing data for M3
don_M3 %<>%
  select(starts_with("BR_LARS")) %>%
  filter(BR_LARS_MOD6_M3_S!=0)

# Ad-hoc function for MCS test
mcs=function(Loss,R,l){
  LbarB=tsboot(Loss,colMeans,R=R,sim="fixed",l=l)$t
  Lbar=colMeans(Loss)
  zeta.Bi=t(t(LbarB)-Lbar)
  save.res=c()
  for(j in 1:(ncol(Loss)-1)){
    Lbardot=mean(Lbar)
    zetadot=rowMeans(zeta.Bi)
    vard=colMeans((zeta.Bi-zetadot)^2)
    t.stat=(Lbar-Lbardot)/sqrt(vard)
    t.max=max(t.stat)
    model.t.max=which(t.stat==t.max)
    t.stat.b=t(t(zeta.Bi-zetadot)/sqrt(vard))
    t.max.b=apply(t.stat.b,1,max)
    p=length(which(t.max<t.max.b))/R
    save.res=c(save.res,p)
    names(save.res)[j]=names(model.t.max)
    Lbar=Lbar[-model.t.max]
    zeta.Bi=zeta.Bi[,-model.t.max]
  }
  save.res=c(save.res,1)
  names(save.res)[j+1]=names(Lbar)
  save.p=save.res
  for(i in 2:(length(save.res)-1)){
    save.p[i]=max(save.res[i-1],save.res[i])
  }
  aux=match(colnames(Loss),names(save.p))
  save.p=save.p[aux]
  save.res=save.res[aux]
  return(list(test=save.p,individual=save.res))
}

# Getting results for MCS
test <- mcs(as.matrix(don_M2[,-2]), 
            R = 5000, 
            l = 3)

# Diebold-Mariano test
e1 <- don_M2$BR_LARS_MOD2_M2_S
e2 <- don_M2$BR_LARS_MOD2NOPS_M2_S

dm.test(
  e1,
  e2,
  alternative = "less",
  h = 1,
  power = 1
)
  