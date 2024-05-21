# install.packages("doParallel")

library(data.table)
library(tidyverse)
library(midasml)
library(readr)
library(magrittr)
library(lubridate)

# Hyperparameters (check consistency with EViews)
rm(list = ls())
setwd("E:/BdF - Baptiste/7-Nowcasting/Nowcasting_GDP_HF/3 - Results/3 - Tests - for JoF/In_out/data")
start_year = 2005
end_year = 2020


##############################################################################################
####################### Preparing data #######################################################
##############################################################################################

# Getting quarterly data
GDP <- read_delim("GDP.csv", "\t", escape_double = FALSE, trim_ws = TRUE)

# Getting monthly data
mth <- c("M1","M2","M3")
for (month in mth){
    namedata <- paste0("VAR_M_",month,".CSV")
    namedon <- paste0("VAR_M_",month)
    assign(namedon,
           read_delim(namedata, "\t", escape_double = FALSE, trim_ws = TRUE))
}

# Creating monthly data with lags (to get 4 lags in monthly data)
VAR_M_Ml3 <- VAR_M_M3[,-2] %>%
  mutate(across(-OBS, lag))
colnames(VAR_M_Ml3) <- sub("_M3", "_Ml3", colnames(VAR_M_Ml3))

VAR_M_Ml2 <- VAR_M_M2[,-2] %>%
  mutate(across(-OBS, lag))
colnames(VAR_M_Ml2) <- sub("_M2", "_Ml2", colnames(VAR_M_Ml2))

VAR_M_Ml1 <- VAR_M_M1[,-2] %>%
  mutate(across(-OBS, lag))
colnames(VAR_M_Ml1) <- sub("_M1", "_Ml1", colnames(VAR_M_Ml1))

# Concatenating monthly dataset (for m1, m2, and m3)
don_m_m3 <- bind_cols(VAR_M_M1[,-c(1,2)],
                      VAR_M_M2[,-c(1,2)],
                      VAR_M_M3[,-c(1,2)],
                      VAR_M_Ml3[,-1])
don_m_m3 <- don_m_m3[,order(colnames(don_m_m3))]
don_m_m3 <- cbind(GDP,don_m_m3)

don_m_m2 <- bind_cols(VAR_M_M1[,-c(1,2)],
                      VAR_M_M2[,-c(1,2)],
                      VAR_M_Ml3[,-1],
                      VAR_M_Ml2[,-1])
don_m_m2 <- don_m_m2[,order(colnames(don_m_m2))]
don_m_m2 <- cbind(GDP,don_m_m2)

don_m_m1 <- bind_cols(VAR_M_M1[,-c(1,2)],
                      VAR_M_Ml3[,-1],
                      VAR_M_Ml2[,-1],
                      VAR_M_Ml1[,-1])
don_m_m1 <- don_m_m1[,order(colnames(don_m_m1))]
don_m_m1 <- cbind(GDP,don_m_m1)

# Weekly data
WEEK <- read_delim("WEEK_DATA.CSV" , "\t", escape_double = FALSE, trim_ws = TRUE)
data_week <- WEEK %>%
  mutate(date=mdy(OBS),
         week=week(date),
         OBS=paste0(year(date),"Q",quarter(date)))

# Getting back to 13 weeks for all quarter
data_week %<>%
  mutate(date=replace(date, date==as.Date("1994-04-01"), as.Date("1994-03-31")),
         date=replace(date, date==as.Date("1994-07-01"), as.Date("1994-06-30")),
         date=replace(date, date==as.Date("2005-04-01"), as.Date("2005-03-31")),
         date=replace(date, date==as.Date("2005-07-01"), as.Date("2005-06-30")),
         date=replace(date, date==as.Date("2011-04-01"), as.Date("2011-03-31")),
         date=replace(date, date==as.Date("2011-07-01"), as.Date("2011-06-30"))) %>%
  mutate(week=week(date),
         OBS=paste0(year(date),"Q",quarter(date)))
  
test <- data_week %>%       # For control, should only have 14 weeks (no 12 weeks)
  select(date,OBS,week) %>% # If OK, can go to the next line of command
  group_by(OBS) %>%         # Otherwise need to adjust dates as above
  summarise(nb = n()) %>%
  filter(nb!=13)

weeks_nb <- select(data_week,date,OBS) %>%
  mutate(count=1) %>%
  group_by(OBS) %>%
  mutate(week_quarter=cumsum(count)) %>%
  ungroup()

data_week <- merge(data_week, select(weeks_nb,date,week_quarter), by="date") %>%
  filter(week_quarter!=14)

# Creating datasets for each of the weeks of the quarter
for (i in 1:13){
  temp <- data_week %>%
    filter(week_quarter==i) %>%
    select(-week,-week_quarter,-date) %>%
    rename_with(~paste0(.,"_W",i), -OBS)
  assign(paste0("VAR_W_W",i),temp)
}

# Concatenating weekly datasets (for m1, m2, and m3)
don_w_m3 <- bind_cols(VAR_W_W13,
                      VAR_W_W12[,-1],
                      VAR_W_W11[,-1],
                      VAR_W_W10[,-1],
                      VAR_W_W9[,-1],
                      VAR_W_W8[,-1],
                      VAR_W_W7[,-1],
                      VAR_W_W6[,-1])
don_w_m3 <- don_w_m3[,order(colnames(don_w_m3))]

don_w_m2 <- bind_cols(VAR_W_W12,
                      VAR_W_W11[,-1],
                      VAR_W_W10[,-1],
                      VAR_W_W9[,-1],
                      VAR_W_W8[,-1],
                      VAR_W_W7[,-1],
                      VAR_W_W6[,-1],
                      VAR_W_W5[,-1])
don_w_m2 <- don_w_m2[,order(colnames(don_w_m2))]

don_w_m1 <- bind_cols(VAR_W_W8,
                      VAR_W_W7[,-1],
                      VAR_W_W6[,-1],
                      VAR_W_W5[,-1],
                      VAR_W_W4[,-1],
                      VAR_W_W3[,-1],
                      VAR_W_W2[,-1],
                      VAR_W_W1[,-1])
don_w_m1 <- don_w_m1[,order(colnames(don_w_m1))]


##############################################################################################
################################ Variable ranking  ###########################################
##############################################################################################

# Getting rankings
frequencies <- c("W","M")
methods <- c("LARS", "sis", "tstat")
for (meth in methods){
  for (freq in frequencies){
    for (month in mth){
      for (ye in start_year:end_year){
        for(qu in 1:4){
          namedata <- paste0("table",meth,"_",freq,"_",month,"_",ye,"Q",qu,".CSV")
          namedon <- tolower(paste0(meth,"_",freq,"_",month,"_",ye,"Q",qu))
          assign(namedon,
                 read_csv(namedata, col_names = FALSE))
        }
      }
    }
  }
}  


##############################################################################################
################################### Getting RMSEs ############################################
##############################################################################################

# Hyperparameters
n_m <- 60
n_step_m <- 20
n_w <- 50
n_step_w <- 10

# Results table
n_tot <- (n_m/n_step_m)*(n_w/n_step_w)
rmse_in <- data.frame(rep(0,n_tot),0,0,0,0)
colnames(rmse_in) <- c("n_month","n_week","m1","m2","m3")
rmse_out <- data.frame(rep(0,n_tot),0,0,0,0)
colnames(rmse_out) <- c("n_month","n_week","m1","m2","m3")

# List of datasets
df_month <- list(don_m_m1,don_m_m2,don_m_m3)
df_week <- list(don_w_m1,don_w_m2,don_w_m3)
df_select_m <- list(rf_m_m1,rf_m_m2,rf_m_m3)
df_select_w <- list(rf_w_m1,rf_w_m2,rf_w_m3)

# Initiating counter
count <- 1

# For loops
for (m in seq(n_step_m,n_m,n_step_m)){
  for (w in seq(n_step_w,n_w,n_step_w)){
    for(k in 1:3){
    
      # Getting selected monthly data
      don_m <- df_month[[k]]
      var_m <- select(don_m,-c(1,2))
      dep_m <- select(don_m,c(1,2))
      
      select_m <- df_select_m[[k]]
      var_select <- select_m %>%
        mutate(name=sub("_CR.*", "", X1)) %>%
        head(m) %>%
        pull(name)
      
      list_col <- sub("_CR.*", "", colnames(var_m)) 
      resp <- list_col %in% var_select
      
      var_m %<>%
        as_tibble() %>%
        select_if(resp)
      
      final_m <- cbind(dep_m,var_m)
      
      # Idem for weekly data
      don_w <- df_week[[k]]
      var_w <- select(don_w,-OBS)
      dep_w <- select(don_w,OBS)

      select_w <- df_select_w[[k]]
      var_select <- select_w %>%
        mutate(name=sub("_W_.*", "", X1)) %>%
        head(w) %>%
        pull(name)
      
      list_col <- sub("_CR.*", "", colnames(var_w))
      resp <- list_col %in% var_select
      
      var_w %<>%
        as_tibble() %>%
        select_if(resp)
      
      final_w <- cbind(dep_w,var_w)
      
      # Preparing data 
      don <- merge(final_m,final_w,by="OBS")
      smpl <- don[complete.cases(don),]
      x <- as.matrix(smpl[,-c(1,2)])
      y <- as.matrix(smpl[,2])
      n_m <- m
      n_w <- w
      gindex = sort(c(rep(1:n_m,times=4),rep(1:n_w,times=8)))
      
      ########### In-sample
      
      # Regression with cross-validation to determine lambda (i.e. shrinkage parameter)
      eq <- cv.sglfit(x = x, 
                      y = y, 
                      gindex = gindex, 
                      gamma = 0,                     # 0 for group-Lasso, 1 for Lasso
                      standardize = FALSE,
                      intercept = TRUE)
      
      # Make predictions
      b0 <- t(as.matrix(eq$cv.fit$lam.min$b0))
      rownames(b0) <- "(Intercept)"
      nbeta <- c(b0, eq$cv.fit$lam.min$beta)
      nfit <- cbind(1, x) %*% nbeta
      
      # Compute RMSEs
      ssr <- (nfit[,1] - smpl[,2])^2
      rmse_in[count,1] <- m
      rmse_in[count,2] <- w
      rmse_in[count,k+2] <- sqrt(sum(ssr)/length(ssr))
      
      ########### Out-of-sample
      
      # Hyperparameters for out-of-sample
      n_start <- which(grepl("2005Q1", smpl$OBS))
      n_end <- nrow(smpl)-1  
      ssr_out <- select(smpl,OBS) %>%
        mutate(ssr=0)
      
      for (i in n_start:n_end){
      
        x_train = x[1:i,]
        y_train = y[1:i,]
        
        # Regression
        eq <- cv.sglfit(x = x_train, 
                        y = y_train, 
                        gindex = gindex, 
                        gamma = 0,                     # 0 for group-Lasso, 1 for Lasso
                        standardize = FALSE,
                        intercept = TRUE)
        
        x_test = x[i+1,]
        y_test = y[i+1,]
        
        # Make predictions
        b0 <- t(as.matrix(eq$cv.fit$lam.min$b0))
        rownames(b0) <- "(Intercept)"
        nbeta <- c(b0, eq$cv.fit$lam.min$beta)
        fit <- c(1, x_test) %*% nbeta
        
        ssr_out[i+1,2] <- (as.numeric(fit) - as.numeric(y_test))^2
      }
      
      # Compute out-of-sample RMSE
      rmse_out[count,1] <- m
      rmse_out[count,2] <- w
      rmse_out[count,k+2] <- sqrt(sum(ssr_out[,2])/(n_end - n_start))
      
    }
    count <- count + 1
  }
}

# Write the results in Excel
write.csv(rmse_in, file="lasso_rmse_rf_in.csv")
write.csv(rmse_out, file="lasso_rmse_rf_out.csv")

##############################################################################################
################################### Optimal model ########################################
##############################################################################################

# Hyperparameters list
opt_m <- c(20,20,20)
opt_w <- c(10,30,20)

# List of datasets
df_month <- list(don_m_m1,don_m_m2,don_m_m3)
df_week <- list(don_w_m1,don_w_m2,don_w_m3)
df_select_m <- list(sis_m_m1,sis_m_m2,sis_m_m3)
df_select_w <- list(sis_w_m1,sis_w_m2,sis_w_m3)

# For loop - out-of-sample results
for(k in 1:3){

  # Parameters
  n_m <- opt_m[k]
  n_w <- opt_w[k]
    
  # Getting selected monthly data
  don_m <- df_month[[k]]
  var_m <- select(don_m,-c(1,2))
  dep_m <- select(don_m,c(1,2))
  
  select_m <- df_select_m[[k]]
  var_select <- select_m %>%
    mutate(name=sub("_CR.*", "", X1)) %>%
    head(n_m) %>%
    pull(name)
  
  list_col <- sub("_CR.*", "", colnames(var_m)) 
  resp <- list_col %in% var_select
  
  var_m %<>%
    as_tibble() %>%
    select_if(resp)
  
  final_m <- cbind(dep_m,var_m)
  
  # Idem for weekly data
  don_w <- df_week[[k]]
  var_w <- select(don_w,-OBS)
  dep_w <- select(don_w,OBS)
  
  select_w <- df_select_w[[k]]
  var_select <- select_w %>%
    mutate(name=sub("_W_.*", "", X1)) %>%
    head(n_w) %>%
    pull(name)
  
  list_col <- sub("_CR.*", "", colnames(var_w))
  resp <- list_col %in% var_select
  
  var_w %<>%
    as_tibble() %>%
    select_if(resp)
  
  final_w <- cbind(dep_w,var_w)
  
  # Preparing data 
  don <- merge(final_m,final_w,by="OBS")
  smpl <- don[complete.cases(don),]
  x <- as.matrix(smpl[,-c(1,2)])
  y <- as.matrix(smpl[,2])
  gindex = sort(c(rep(1:n_m,times=4),rep(1:n_w,times=8)))
  
  # Hyperparameters for out-of-sample
  n_start <- which(grepl("2005Q1", smpl$OBS))
  n_end <- nrow(smpl)-1
  
  # Creating series of squared residuals
  if (k==1) {
    sqres_m1 <- select(smpl,OBS) %>%
      mutate(ssr=0)    
  }
  if (k==2) {
    sqres_m2 <- select(smpl,OBS) %>%
      mutate(ssr=0)    
  }
  if (k==3) {
    sqres_m3 <- select(smpl,OBS) %>%
      mutate(ssr=0)    
  }

  # Looping to get one-period ahead errors
  for (i in n_start:n_end){
    
    x_train = x[1:i,]
    y_train = y[1:i,]
    
    # Regression
    eq <- cv.sglfit(x = x_train, 
                    y = y_train, 
                    gindex = gindex, 
                    gamma = 0,                     # 0 for group-Lasso, 1 for Lasso
                    standardize = FALSE,
                    intercept = TRUE)
    
    x_test = x[i+1,]
    y_test = y[i+1,]
    
    # Make predictions
    b0 <- t(as.matrix(eq$cv.fit$lam.min$b0))
    rownames(b0) <- "(Intercept)"
    nbeta <- c(b0, eq$cv.fit$lam.min$beta)
    fit <- c(1, x_test) %*% nbeta

    # Computing errors
    if (k==1) {sqres_m1[i+1,2] <- (as.numeric(fit) - as.numeric(y_test))^2}
    if (k==2) {sqres_m2[i+1,2] <- (as.numeric(fit) - as.numeric(y_test))^2}
    if (k==3) {sqres_m3[i+1,2] <- (as.numeric(fit) - as.numeric(y_test))^2}
  }
}

# Write results in Excel
write.csv(sqres_m1, file="lasso_opt_res_m1.csv")
write.csv(sqres_m2, file="lasso_opt_res_m2.csv")
write.csv(sqres_m3, file="lasso_opt_res_m3.csv")

# In-sample fit
for(k in 1:3){
  
  # Parameters
  n_m <- opt_m[k]
  n_w <- opt_w[k]
  
  # Getting selected monthly data
  don_m <- df_month[[k]]
  var_m <- select(don_m,-c(1,2))
  dep_m <- select(don_m,c(1,2))
  
  select_m <- df_select_m[[k]]
  var_select <- select_m %>%
    mutate(name=sub("_CR.*", "", X1)) %>%
    head(n_m) %>%
    pull(name)
  
  list_col <- sub("_CR.*", "", colnames(var_m)) 
  resp <- list_col %in% var_select
  
  var_m %<>%
    as_tibble() %>%
    select_if(resp)
  
  final_m <- cbind(dep_m,var_m)
  
  # Idem for weekly data
  don_w <- df_week[[k]]
  var_w <- select(don_w,-OBS)
  dep_w <- select(don_w,OBS)
  
  select_w <- df_select_w[[k]]
  var_select <- select_w %>%
    mutate(name=sub("_W_.*", "", X1)) %>%
    head(n_w) %>%
    pull(name)
  
  list_col <- sub("_CR.*", "", colnames(var_w))
  resp <- list_col %in% var_select
  
  var_w %<>%
    as_tibble() %>%
    select_if(resp)
  
  final_w <- cbind(dep_w,var_w)
  
  # Preparing data 
  don <- merge(final_m,final_w,by="OBS")
  smpl <- don[complete.cases(don),]
  x <- as.matrix(smpl[,-c(1,2)])
  y <- as.matrix(smpl[,2])
  gindex = sort(c(rep(1:n_m,times=4),rep(1:n_w,times=8)))
  
  # Regression
  eq <- cv.sglfit(x = x, 
                  y = y, 
                  gindex = gindex, 
                  gamma = 0,                     # 0 for group-Lasso, 1 for Lasso
                  standardize = FALSE,
                  intercept = TRUE)
  
  # Make predictions
  b0 <- t(as.matrix(eq$cv.fit$lam.min$b0))
  rownames(b0) <- "(Intercept)"
  nbeta <- c(b0, eq$cv.fit$lam.min$beta)
  fit <- cbind(1, x) %*% nbeta
  
  # Computing errors
  if (k==1) {ssr_m1 <- (fit[,1] - smpl[,2])^2}
  if (k==2) {ssr_m2 <- (fit[,1] - smpl[,2])^2}
  if (k==3) {ssr_m3 <- (fit[,1] - smpl[,2])^2}
}

# Write results in Excel
write.csv(ssr_m1, file="lasso_opt_res_in_m1.csv")
write.csv(ssr_m2, file="lasso_opt_res_in_m2.csv")
write.csv(ssr_m3, file="lasso_opt_res_in_m3.csv")
