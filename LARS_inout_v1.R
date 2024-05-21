# install.packages("xlsx")

library(data.table)
library(tidyverse)
library(glmnet)
library(readr)
library(lars)
library(writexl)
library(magrittr)

# Hyperparameters (check consistency with EViews)
rm(list = ls())
setwd("E:/BdF - Baptiste/7-Nowcasting/Nowcasting_GDP_HF/3 - Results/3 - Tests - for JoF/In_out/data")
start_year = 2005
end_year = 2020

# List of months and weeks
mth <- c("M1","M2","M3")
frq <- c("M","W")

# For monthly and weekly separated
for (month in mth){
  for (freq in frq){

    # Getting data
    namedata <- paste0("VAR_",freq,"_",month,".CSV")
    don_base <- read_delim(namedata, "\t", escape_double = FALSE, trim_ws = TRUE) %>%
      mutate(year=as.numeric(str_sub(OBS,1,4)),
             quarter=as.numeric(str_sub(OBS,6,6)))
    
    for (ye in start_year:end_year){
      for(qu in 1:4){

        # Selecting in-sample
        don <- don_base %>% 
          filter(year < ye | (year==ye & quarter<=qu)) %>%
          select(-year,-quarter)
        
        # Getting parameters
        smpl <- don[complete.cases(don),]
        n_var <- length(smpl)-2
    
        # Initiating for LARS loop
        count <- 0
        batch <- smpl
        order <- data.frame(V1=c(0))
    
        while (count < n_var) {
    
          # Running LARS equation
          x <- as.matrix(batch[,-c(1,2)])
          y <- as.matrix(batch[,2])
          eq <- lars(x,y, type="lar")
    
          # Ordering the variables
          out <- as.data.frame(coef(eq)) %>%
            summarise_each(~sum(.==0)) %>%
            t() %>%
            as.data.frame() %>%
            rownames_to_column('name') %>%
            arrange(V1) %>%
            group_by(V1) %>%
            filter(n()==1) %>%
            column_to_rownames('name')

          order <- rbind(order,out)
          
          # Deleting variables already ordered from the sample
          var <- row.names(out)
          batch %<>%
            select(!all_of(var))
          
          # Checking if nrow(out) = 0 to avoid infinite loops
          if (nrow(out)==0){
            # Putting all remaining variables at the end
            x <- batch[,-c(1,2)]
            n_end <- ncol(x)
            out <- data.frame(V1=rep(1,n_end))
            rownames(out) <- colnames(x)
            order <- rbind(order,out)
            count <- count + n_end
            print(paste0("Using special procedure for ",month," in ",freq," and at ",ye,"Q",qu))
          }else{
            # Just updating the count      
            count <- count + nrow(out)
          } 
        }
  
        # Getting ordered variables in an Excel file (for a particular freq and month)
        order %<>%
          filter(V1!=0)
        nameout <- paste0("tableLARS_",freq,"_",month,"_",ye,"Q",qu,".csv")
        if (nrow(order)==n_var){
          write.csv(order, nameout)
        }else{
          print(paste0("Inconsistent number of variables in ",ye,"Q",qu))
          exit()
        }
      }
    }
  }
}


# For both monthly and weekly
for (month in mth){

  # Getting data
  namedata_m <- paste0("VAR_M_",month,".CSV")
  don_m <- read_delim(namedata_m, "\t", escape_double = FALSE, trim_ws = TRUE)
  namedata_w <- paste0("VAR_W_",month,".CSV")
  don_w <- read_delim(namedata_w, "\t", escape_double = FALSE, trim_ws = TRUE) %>%
    select(-GDP_WD_QOQ_CR)
  don_base <- merge(don_m,don_w,by="OBS") %>%
    mutate(year=as.numeric(str_sub(OBS,1,4)),
           quarter=as.numeric(str_sub(OBS,6,6)))
  
  for (ye in start_year:end_year){
    for(qu in 1:4){
      
      # Selecting in-sample
      don <- don_base %>% 
        filter(year < ye | (year==ye & quarter<=qu)) %>%
        select(-year,-quarter)
    
      # Getting parameters
      smpl <- don[complete.cases(don),]
      n_var <- length(smpl)-2
      
      # Initiating for LARS loop
      count <- 0
      batch <- smpl
      order <- data.frame(V1=c(0))
      
      while (count < n_var) {
        
        # Running LARS equation
        x <- as.matrix(batch[,-c(1,2)])
        y <- as.matrix(batch[,2])
        eq <- lars(x,y, type="lar", use.Gram=FALSE)
        
        # Ordering the variables
        out <- as.data.frame(coef(eq)) %>%
          summarise_each(~sum(.==0)) %>%
          t() %>%
          as.data.frame() %>%
          rownames_to_column('name') %>%
          arrange(V1) %>%
          group_by(V1) %>%
          filter(n()==1) %>%
          column_to_rownames('name')
        
        order <- rbind(order,out)
        
        # Deleting variables already ordered from the sample
        var <- row.names(out)
        batch %<>%
          select(!all_of(var))
        
        # Checking if nrow(out) = 0 to avoid infinite loops
        if (nrow(out)==0){
          # Putting all remaining variables at the end
          x <- batch[,-c(1,2)]
          n_end <- ncol(x)
          out <- data.frame(V1=rep(1,n_end))
          rownames(out) <- colnames(x)
          order <- rbind(order,out)
          count <- count + n_end
          print(paste0("Using special procedure for ",month," in both and at ",ye,"Q",qu))
        }else{
          # Just updating the count      
          count <- count + nrow(out)
        }
      }
        
      # Getting ordered variables in an Excel file (for a particular freq and month)
      order %<>%
        filter(V1!=0)
      nameout <- paste0("tableLARS_both_",month,"_",ye,"Q",qu,".csv")
      if (nrow(order)==n_var){
        write.csv(order, nameout)
      }else{
        print(paste0("Inconsistent number of variables in ",ye,"Q",qu))
        exit()
      }
    }
  }
}
