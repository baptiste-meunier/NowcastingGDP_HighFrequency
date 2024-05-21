'%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
' Model comparison
'%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

pageselect quarter

' REMINDER: hyperparameters for the out-of-sample exercise (debut_est, fin_est), and the max number of lags (nb_m, nb_w) are chosen in the step 2 (pre-selection)

' Chosen method
string meth = "lars"

' Number of targeted predictors (based on pre-selection step)
' This is only for in-sample - take the one at the end of t_br_{%meth}_{%mod}_{%month}
' Model 2
scalar opt_mod2_m_m1 = 40
scalar opt_mod2_w_m1 = 20
scalar opt_mod2_m_m2 = 20
scalar opt_mod2_w_m2 = 80
scalar opt_mod2_m_m3 = 20
scalar opt_mod2_w_m3 = 10
' Model 4
scalar opt_mod4_m1 = 120
scalar opt_mod4_m2 = 30
scalar opt_mod4_m3 = 30
' Model 5
scalar opt_mod5_m1 = 100
scalar opt_mod5_m2 = 100
scalar opt_mod5_m3 = 20

' End of in-sample
string fin_ins = "2021Q1"


'=======================================================
' In-sample estimations
'=======================================================

pageselect quarter
smpl "2001Q1" {fin_ins}

' Mod 2
equation eq_mod2_m1.midas(maxlag=nb_m nb_w,  lag=auto) gdp_wd_qoq c @ month\f1_{meth}_m1_{opt_mod2_m_m1}_{fin_est}(-2) week\f1_{meth}_m1_{opt_mod2_w_m1}_{fin_est}(-5)

equation eq_mod2_m2.midas(maxlag=nb_m nb_w,  lag=auto) gdp_wd_qoq c @ month\f1_{meth}_m2_{opt_mod2_m_m2}_{fin_est}(-1) week\f1_{meth}_m2_{opt_mod2_w_m2}_{fin_est}(-1)

equation eq_mod2_m3.midas(maxlag=nb_m nb_w,  lag=auto) gdp_wd_qoq c @ month\f1_{meth}_m3_{opt_mod2_m_m3}_{fin_est} week\f1_{meth}_m3_{opt_mod2_w_m3}_{fin_est}

' Mod 4
equation eq_mod4_m1.midas(maxlag=nb_m, lag=auto) gdp_wd_qoq c @ freq\f1_{meth}_m1_{opt_mod4_m1}_{fin_est}(-2)

equation eq_mod4_m2.midas(maxlag=nb_m, lag=auto) gdp_wd_qoq c @ freq\f1_{meth}_m2_{opt_mod4_m2}_{fin_est}(-1)

equation eq_mod4_m3.midas(maxlag=nb_m, lag=auto) gdp_wd_qoq c @ freq\f1_{meth}_m3_{opt_mod4_m3}_{fin_est}

' Mod 5
equation eq_mod5_m1.midas(maxlag=nb_m, lag=auto) gdp_wd_qoq c @ month\f1_{meth}_m1_{opt_mod5_m1}_{fin_est}(-2)

equation eq_mod5_m2.midas(maxlag=nb_m, lag=auto) gdp_wd_qoq c @ month\f1_{meth}_m2_{opt_mod5_m2}_{fin_est}(-1)

equation eq_mod5_m3.midas(maxlag=nb_m, lag=auto) gdp_wd_qoq c @ month\f1_{meth}_m3_{opt_mod5_m3}_{fin_est} 

' Mod 6 (AR)
equation eq_mod6_m1.ls gdp_wd_qoq c gdp_wd_qoq(-2)

equation eq_mod6_m2.ls gdp_wd_qoq c gdp_wd_qoq(-2)

equation eq_mod6_m3.ls gdp_wd_qoq c gdp_wd_qoq(-1)


'=======================================================
' In-sample RMSE
'=======================================================

pageselect quarter

' All sample
delete(noerr) rmse_in
table rmse_in
scalar i = 2
scalar j = 2
for %mod mod2 mod4 mod5 mod6
	j = 2
	rmse_in(1,i)=%mod
	for %month m1 m2 m3
		rmse_in(j,1) = %month
		rmse_in(j,i) = @sqrt(eq_{%mod}_{%month}.@ssr/eq_{%mod}_{%month}.@regobs)
		j = j+1
	next
	i = i+1
next

' Parameters for crisis vs. non-crisis
scalar nb_c = 12
scalar nb_nc = eq_mod6_m3.@regobs - nb_c

' Crisis vs. non-crisis
delete(noerr) rmse_in_c
table rmse_in_c
delete(noerr) rmse_in_nc
table rmse_in_nc

i = 2
for %mod mod2 mod4 mod5 mod6
	j = 2
	rmse_in_c(1,i)=%mod
	rmse_in_nc(1,i)=%mod
	for %month m1 m2 m3 	
		eq_{%mod}_{%month}.makeresids temp_c
		eq_{%mod}_{%month}.makeresids temp_nc
		smpl @first "2007Q3"
		temp_c=@recode(temp_c,0,temp_c)
		smpl "2007Q4" "2009Q2"
		temp_nc=@recode(temp_nc,0,temp_nc)
		smpl "2009Q3" "2019Q4"
		temp_c=@recode(temp_c,0,temp_c)
		smpl "2020Q1" @last
		temp_nc=@recode(temp_nc,0,temp_nc)
		smpl "2021Q2" @last
		temp_c=@recode(temp_c,0,temp_c)
		smpl @all
		rmse_in_c(j,1) = %month
		rmse_in_c(j,i) = @sqrt(@sumsq(temp_c) / nb_c)
		rmse_in_nc(j,1) = %month
		rmse_in_nc(j,i) = @sqrt(@sumsq(temp_nc) / nb_nc)
		j = j+1
	next
	i = i+1
next


'=======================================================
' Out-of-sample estimations
'=======================================================

pageselect quarter

' Preparing series for estimation results
smpl @all
for %mod mod1 mod2 mod3 mod4 mod5 mod6
	for %month m1 m2 m3 
		genr br_{meth}_mod6_{%month}_s = 0
	next
next

' Loop for out-of-sample (only for mod 6)
for !obs=0 to fin
	%datel = @otod(nb_debut + !obs)
	smpl 2001q1 %datel
	
	' Mod 6
	equation eq_mod6_m1.ls gdp_wd_qoq c gdp_wd_qoq(-2)
	
	equation eq_mod6_m2.ls gdp_wd_qoq c gdp_wd_qoq(-2)
	
	equation eq_mod6_m3.ls gdp_wd_qoq c gdp_wd_qoq(-1)

	' Out-of-sample squared errors			
	%datef=@otod(nb_debut + !obs + 1)
	smpl %datef %datef
	for %month m1 m2 m3
		eq_{%mod}_{%month}.fit(e, g) gdp_wd_qoqf
		br_{meth}_mod6_{%month}_s = (gdp_wd_qoq - gdp_wd_qoqf)^2
	next
next


'=======================================================
' Out-of-sample RMSEs
'=======================================================

pageselect quarter
smpl @all

' All sample
delete(noerr) rmse_out
table rmse_out
scalar i = 2
scalar j = 2
for %mod mod2 mod4 mod5 mod6
	j = 2
	rmse_out(1,i)=%mod
	for %month m1 m2 m3
		rmse_out(j,1) = %month
		rmse_out(j,i) = @sqrt(@sum(br_{meth}_{%mod}_{%month}_s))/@sqrt(fin)
		j = j+1
	next
	i = i+1
next

' Change of hyperparameter for non-crisis episodes
scalar nb_nc_oos = fin - nb_c

' Crisis vs. non-crisis
delete(noerr) rmse_out_c
table rmse_out_c
delete(noerr) rmse_out_nc
table rmse_out_nc

i = 2
for %mod mod2 mod4 mod5 mod6
	j = 2
	rmse_out_c(1,i) = %mod
	rmse_out_nc(1,i) = %mod
	for %month m1 m2 m3 	
		genr temp_c = br_{meth}_{%mod}_{%month}_s
		genr temp_nc = br_{meth}_{%mod}_{%month}_s
		smpl @first "2007Q3"
		temp_c=@recode(temp_c,0,temp_c)
		smpl "2007Q4" "2009Q2"
		temp_nc=@recode(temp_nc,0,temp_nc)
		smpl "2009Q3" "2019Q4"
		temp_c=@recode(temp_c,0,temp_c)
		smpl "2020Q1" @last
		temp_nc=@recode(temp_nc,0,temp_nc)
		smpl "2021Q2" @last
		temp_c=@recode(temp_c,0,temp_c)
		smpl @all
		rmse_out_c(j,1) = %month
		rmse_out_c(j,i) = @sqrt(@sum(temp_c) / nb_c)
		rmse_out_nc(j,1) = %month
		rmse_out_nc(j,i) = @sqrt(@sum(temp_nc) / nb_nc_oos)
		j = j+1
	next
	i = i+1
next


'=======================================================
' RMSE tables relative to the AR model
'=======================================================

for %tab rmse_in rmse_in_c rmse_in_nc rmse_out rmse_out_c rmse_out_nc
	for !i = 2 to 4
		for !j = 2 to 5
			{%tab}(!i,!j) = @val({%tab}(!i,!j)) / @val({%tab}(!i,5))
		next
	next
next


'=======================================================
' Output for the tests (Diebold-Mariano and MCS)
'=======================================================

cd "C:\Users\meunieb\Desktop"
pageselect quarter

for %month m1 m2 m3
	delete(noerr) br_{%month}
	group br_{%month} br_*_{%month}_s
	string temp_name = "br_"+%month+".csv"
	write(t=txt, dates) {temp_name} br_{%month}
next


