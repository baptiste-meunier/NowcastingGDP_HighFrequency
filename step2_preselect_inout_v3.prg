'%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
' Pre-selection methods
'%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

wfopen "E:\BdF - Baptiste\7-Nowcasting\Nowcasting_GDP_HF\3 - Results\3 - Tests - for JoF\wf_data_2021m04.wf1"

'=======================================================
' Scaling of series
'=======================================================

pageselect month
pagecreate(page=freq_sis) m {datedebut} {datefin}
copy freq\*_sa_* freq_sis\*_sa_*

smpl 2001 @last
group sta_all *sta*
for !i=1 to sta_all.@count
	%name = sta_all.@seriesname(!i)
	genr {%name}_cr=({%name}-@mean({%name}))/@stdev({%name})
next


'=======================================================
' All series to quarterly frequency
'=======================================================

pageselect quarter
pagecreate(page=sis) q {y_datedebut} {y_datefin}

copy quarter\gdp_wd_qoq sis\*

copy(g=d, c=a)  freq_sis\*_cr sis\*_cr_m3
copy(g=d, c=f)  freq_sis\*_cr sis\*_cr_m1
copy(g=d, c=l)  freq_sis\*_cr sis\*_cr

group temp *_cr
for !i=1 to temp.@count
	%name = temp.@seriesname(!i)
	genr {%name}_m2 = (3*{%name}_m3 - {%name})/2
next

delete(noerr) temp
delete(noerr) *_cr

genr gdp_wd_qoq_cr=(gdp_wd_qoq-@mean(gdp_wd_qoq))/@stdev(gdp_wd_qoq) 


'=======================================================
' Correlations with target variable (gdp_wd_qoq) - Fan and Lv (2008)
'=======================================================

' Tables for monthly and weekly data - separately
pageselect sis

string debut_est = "2005q1"
string fin_est = "2020q4"
scalar fin = @dtoo(fin_est) - @dtoo(debut_est)
scalar nb_debut = @dtoo(debut_est)

' Copy to page "quarter"
copy sis\debut_est quarter\debut_est
copy sis\fin_est quarter\fin_est
copy sis\fin quarter\fin
copy sis\nb_debut quarter\nb_debut

for !obs=0 to fin
	%datel = @otod(nb_debut + !obs)
	smpl 2001q1 %datel

	for %freq m w
		for %month m1 m2 m3
			delete(noerr) tablesis_{%freq}_{%month}_{%datel}
			table tablesis_{%freq}_{%month}_{%datel}
	
			delete(noerr) var_{%freq}_cr_{%month}
			group var_{%freq}_cr_{%month} *_{%freq}_cr_{%month}
	
			for !i=1 to var_{%freq}_cr_{%month}.@count
				%name = var_{%freq}_cr_{%month}.@seriesname(!i)
				tablesis_{%freq}_{%month}_{%datel}(!i,2) = @abs(@cor({%name},gdp_wd_qoq_cr))
				tablesis_{%freq}_{%month}_{%datel}(!i,1) = %name
			next
	
			string colab="a1:b"+@str(var_{%freq}_cr_{%month}.@count)
			tablesis_{%freq}_{%month}_{%datel}.sort({colab}) -b
	
		next
	next
next
	
' Tables for both
smpl @all
scalar index_m = var_m_cr_m1.@count + 1 
scalar index_tot = var_m_cr_m1.@count + var_w_cr_m1.@count 
string colab="a1:b"+@str({index_tot})
for !obs=0 to fin
	%datel = @otod(nb_debut + !obs)
	for %month m1 m2 m3
		delete(noerr) tablesis_both_{%month}_{%datel}
		table tablesis_both_{%month}_{%datel}
		tablesis_m_{%month}_{%datel}.copytable tablesis_both_{%month}_{%datel} 1 1
		tablesis_w_{%month}_{%datel}.copytable tablesis_both_{%month}_{%datel} {index_m} 1
		tablesis_both_{%month}_{%datel}.sort({colab}) -b
	next
next


'=======================================================
' T-statistic with target variable (gdp_wd_qoq) - Bai and Ng (2008)
'=======================================================

' Tables for monthly and weekly data - separately
pageselect sis
smpl @all

for !obs=0 to fin
	%datel = @otod(nb_debut + !obs)
	smpl 2001q1 %datel

	for %freq m w
		for %month m1 m2 m3
			delete(noerr) tabletstat_{%freq}_{%month}_{%datel}
			table tabletstat_{%freq}_{%month}_{%datel}
	
			delete(noerr) var_{%freq}_cr_{%month}
			group var_{%freq}_cr_{%month} *_{%freq}_cr_{%month}
	
			for !i=1 to var_{%freq}_cr_{%month}.@count
				%name = var_{%freq}_cr_{%month}.@seriesname(!i)
				equation temp.ls gdp_wd_qoq_cr c gdp_wd_qoq_cr(-1) gdp_wd_qoq_cr(-2) gdp_wd_qoq_cr(-3) gdp_wd_qoq_cr(-4) {%name}
				tabletstat_{%freq}_{%month}_{%datel}(!i,2) = @abs(temp.@tstats(6))
				tabletstat_{%freq}_{%month}_{%datel}(!i,1) = %name
			next
	
			string colab="a1:b"+@str(var_{%freq}_cr_{%month}.@count)
			tabletstat_{%freq}_{%month}_{%datel}.sort({colab}) -b
	
		next
	next 
next
	
' Tables for both
smpl @all
scalar index_m = var_m_cr_m1.@count + 1 
scalar index_tot = var_m_cr_m1.@count + var_w_cr_m1.@count 
string colab="a1:b"+@str({index_tot})
for !obs=0 to fin
	%datel = @otod(nb_debut + !obs)
	for %month m1 m2 m3
		delete(noerr) tabletstat_both_{%month}_{%datel}
		table tabletstat_both_{%month}_{%datel}
		tabletstat_m_{%month}_{%datel}.copytable tabletstat_both_{%month}_{%datel} 1 1
		tabletstat_w_{%month}_{%datel}.copytable tabletstat_both_{%month}_{%datel} {index_m} 1
		tabletstat_both_{%month}_{%datel}.sort({colab}) -b
	next
next


'=======================================================
' LARS ordering (results from R program) - Bai and Ng (2008)
'=======================================================

' Prepare inputs to R program
pageselect sis
smpl @all
cd "E:\BdF - Baptiste\7-Nowcasting\Nowcasting_GDP_HF\3 - Results\3 - Tests - for JoF\In_out\data"
for %freq m w
	for %month m1 m2 m3
		write(t=txt, dates) var_{%freq}_{%month}.csv gdp_wd_qoq_cr var_{%freq}_cr_{%month}
	next
next

' Retrieve outputs from R program
pageselect sis
smpl @all
cd "E:\BdF - Baptiste\7-Nowcasting\Nowcasting_GDP_HF\3 - Results\3 - Tests - for JoF\In_out\data"
for !obs=0 to fin
	%datel = @otod(nb_debut + !obs)
	for %freq m w both
		for %month m1 m2 m3
		string nametable_in = "tableLARS_"+%freq+"_"+%month+"_"+%datel+".csv"
		string nametable_out = "tablelars_"+%freq+"_"+%month+"_"+%datel
		importtbl(name={nametable_out}) {nametable_in} ftype=ascii rectype=crlf skip=0 fieldtype=delimited delim=comma firstobs=1 eoltype=pad badfield=NA
		next
	next
next
	

'=======================================================
' Prepare computation for Lasso-MIDAS (Babii et al., 2021)
'=======================================================

cd "E:\BdF - Baptiste\7-Nowcasting\Nowcasting_GDP_HF\3 - Results\3 - Tests - for JoF\In_out\data"
pageselect quarter
write(t=txt, dates) GDP.csv gdp_wd_qoq

pageselect week
smpl @all
sta_all.add *_tcn_sta_sa
for !i=1 to sta_all.@count
	%name = sta_all.@seriesname(!i)
	genr {%name}_cr=({%name}-@mean({%name}))/@stdev({%name})
next

group sta_cr *_cr
write(t=txt, dates) week_data.csv sta_cr

pageselect sis
for !obs=0 to fin
	%datel = @otod(nb_debut + !obs)
	for %meth sis tstat
		for %freq w m
			for %month m1 m2 m3
				string temp_out = "table_"+%meth+"_"+%freq+"_"+%month+"_"+%datel+".csv"
				table{%meth}_{%freq}_{%month}_{%datel}.save(t=csv,n="NaN") {temp_out}
			next
		next
	next
next	


'=======================================================
' Loop over variables to create factors
'=======================================================

pageselect sis
smpl @all
for !obs=0 to fin
	%datel = @otod(nb_debut + !obs)
	for %month m1 m2 m3
		for %meth sis tstat lars
			copy sis\table{%meth}_m_{%month}_{%datel} month\table{%meth}_m_{%month}_{%datel}
			copy sis\table{%meth}_w_{%month}_{%datel} week\table{%meth}_w_{%month}_{%datel}
			copy sis\table{%meth}_both_{%month}_{%datel} freq\table{%meth}_both_{%month}_{%datel}
		next
	next
next

' Step for N (month)
pageselect month
scalar n_step_m = 20
scalar n_var_m = sta_all.@count
scalar count = 1

' Step for N (week)
pageselect week
scalar n_step_w = 10
scalar n_var_w = sta_all.@count
scalar count = 1

' Step for N (both)
pageselect freq
scalar n_step_both = 30
scalar n_var_both = sta_all.@count
scalar count = 1

' Loop over different methods and number of variables
pageselect sis
smpl @all

for !obs=0 to fin

	pageselect sis
	string datel = @otod(nb_debut + !obs)
	copy sis\datel week\datel
	copy sis\datel month\datel
	copy sis\datel freq\datel

	for %meth sis tstat lars
		for %p month week freq
		
			pageselect {%p}
			smpl @all
		
			if %p="month" then %freq = "m" 
				else if %p="week" then %freq = "w"  
					else %freq = "both"
				endif
			endif	
		
			for %month m1 m2 m3

				string tabletemp_name = "table"+%meth+"_"+%freq+"_"+%month+"_"+datel
				table tabletemp = {tabletemp_name}

				delete(noerr) temp
				group temp
				if %p="week" then
					delete(noerr) temp_real
					group temp_real
					delete(noerr) temp_fin
					group temp_fin
				endif
				count = 1
				for !i=n_step_{%freq} to sta_all.@count step n_step_{%freq}	
					for !j=count to !i
						string temp_name = tabletemp(!j,1)
						if %p="freq" then string temp_name2 = @left(temp_name,@length(temp_name)-6) else string temp_name2 = @left(temp_name,@length(temp_name)-8)
						endif
						if %p="week" then 
							if @instr(temp_name2,"DIV")=1 then temp_real.add {temp_name2} else temp_fin.add {temp_name2}
							endif
						endif
						temp.add {temp_name2}                                                                                                                                                                                                                                                                                   
					next
					count = count + n_step_{%freq}
					temp.makepcomp f1_{%meth}_{%month}_{!i}_{datel}
					if %p="week" then
						if temp_real.@count=0 then genr f1_{%meth}_{%month}_{!i}_{datel}_real = 0 else temp_real.makepcomp f1_{%meth}_{%month}_{!i}_{datel}_real
						endif
						if temp_fin.@count=0 then genr f1_{%meth}_{%month}_{!i}_{datel}_fin else temp_fin.makepcomp f1_{%meth}_{%month}_{!i}_{datel}_fin
						endif
					endif
				next
			next
		next
	next	
next


'=======================================================
' Getting RMSFEs
'=======================================================

copy month\n_step_m quarter\n_step_m
copy month\n_var_m quarter\n_var_m
copy week\n_step_w quarter\n_step_w
copy week\n_var_w quarter\n_var_w
copy freq\n_step_both quarter\n_step_both
copy freq\n_var_both quarter\n_var_both
pageselect quarter

' Overwrite maximum number of variables to be tested
n_var_m = 100				' Should be a multiple of 20
n_var_w = 100				' Should be a multiple of 10
n_var_both = 150			' Should be a multiple of 30

' Hyperparameters - max number of lags
scalar nb_m = 4
scalar nb_w = 12

' Creating tables for RMSFEs
for %meth sis tstat lars
	for %test mod2 mod4 mod5
		for %month m1 m2 m3
			for !obs = 1 to fin
				%datel = @otod(nb_debut + !obs) 
				delete(noerr) t_{%meth}_{%test}_{%month}_{%datel}
				table t_{%meth}_{%test}_{%month}_{%datel}
			next
		next
	next
next

for %month m1 m2 m3
	genr temp_{%month}_s = 0
next

' Looping over factors and methods - model 5
for %meth sis tstat lars
	for !i = n_step_m to n_var_m step n_step_m
		for !obs = 1 to fin
			smpl @all
			temp_m1_s = 0
			temp_m2_s = 0
			temp_m3_s = 0
			%datel = @otod(nb_debut + !obs)


			for !train = 0 to !obs - 1
				%datel2 = @otod(nb_debut + !train)
				smpl 2001q1 %datel2
	
				equation  eq_mod5_m1.midas(maxlag =nb_m, lag=auto) gdp_wd_qoq c @ month\f1_{%meth}_m1_{!i}_{%datel}(-2)
				equation  eq_mod5_m2.midas(maxlag =nb_m, lag=auto) gdp_wd_qoq c @ month\f1_{%meth}_m2_{!i}_{%datel}(-1)
				equation  eq_mod5_m3.midas(maxlag =nb_m, lag=auto) gdp_wd_qoq c @ month\f1_{%meth}_m3_{!i}_{%datel}

				%datef=@otod(nb_debut + !train + 1)
				smpl %datef %datef
				for %month m1 m2 m3
					eq_mod5_{%month}.fit(e, g) gdp_wd_qoqf
					temp_{%month}_s = (gdp_wd_qoq - gdp_wd_qoqf)^2
				next
			next

		for %month m1 m2 m3
			smpl @all
			t_{%meth}_mod5_{%month}_{%datel}(!i / n_step_m,1) = {!i}
			t_{%meth}_mod5_{%month}_{%datel}(!i / n_step_m,2) = @sqrt(@sum(temp_{%month}_s))/@sqrt(!obs)
		next
		next

	next
next

' Looping over factors and methods - model 2
for %meth tstat 'lars sis 
	scalar count = 1
	for !i = n_step_m to n_var_m step n_step_m
		for !k = n_step_w to n_var_w step n_step_w
			for !obs = 1 to fin
				smpl @all
				temp_m1_s = 0
				temp_m2_s = 0
				temp_m3_s = 0				

				%datel = @otod(nb_debut + !obs)
				smpl 2001q1 %datel
			
				for !train = 0 to !obs - 1
					%datel2 = @otod(nb_debut + !train)
					smpl 2001q1 %datel2
			
					equation eq_mod2_m1.midas(maxlag =nb_m nb_w, lag=auto) gdp_wd_qoq c @ month\f1_{%meth}_m1_{!i}_{%datel}(-2) week\f1_{%meth}_m1_{!k}_{%datel}(-5)
					equation eq_mod2_m2.midas(maxlag =nb_m nb_w, lag=auto) gdp_wd_qoq c @ month\f1_{%meth}_m2_{!i}_{%datel}(-1) week\f1_{%meth}_m2_{!k}_{%datel}(-1)
					equation eq_mod2_m3.midas(maxlag =nb_m nb_w, lag=auto) gdp_wd_qoq c @ month\f1_{%meth}_m3_{!i}_{%datel} week\f1_{%meth}_m3_{!k}_{%datel}

					%datef = @otod(nb_debut + !train + 1)
					smpl %datef %datef
					for %month m1 m2 m3
						eq_mod2_{%month}.fit(e, g) gdp_wd_qoqf
						temp_{%month}_s = (gdp_wd_qoq - gdp_wd_qoqf)^2
					next
				next
	
				for %month m1 m2 m3
					smpl @all
					t_{%meth}_mod2_{%month}_{%datel}(count,1) = {!i}
					t_{%meth}_mod2_{%month}_{%datel}(count,2) = {!k}
					t_{%meth}_mod2_{%month}_{%datel}(count,3) = @sqrt(@sum(temp_{%month}_s))/@sqrt(!obs)
				next
			next
			count = count + 1 
		next
	next
next

' Looping over factors and methods - model 4
for %meth sis tstat lars
	for !i = n_step_both to n_var_both step n_step_both
		for !obs = 1 to fin
			smpl @all
			temp_m1_s = 0
			temp_m2_s = 0
			temp_m3_s = 0
			%datel = @otod(nb_debut + !obs)


			for !train = 0 to !obs - 1
				%datel2 = @otod(nb_debut + !train)
				smpl 2001q1 %datel2

				equation  eq_mod4_m1.midas(maxlag =nb_m, lag=auto) gdp_wd_qoq c @ freq\f1_{%meth}_m1_{!i}_{%datel}(-2)
				equation  eq_mod4_m2.midas(maxlag =nb_m, lag=auto) gdp_wd_qoq c @ freq\f1_{%meth}_m2_{!i}_{%datel}(-1)
				equation  eq_mod4_m3.midas(maxlag =nb_m, lag=auto) gdp_wd_qoq c @ freq\f1_{%meth}_m3_{!i}_{%datel}

				%datef=@otod(nb_debut + !train + 1)
				smpl %datef %datef
				for %month m1 m2 m3
					eq_mod4_{%month}.fit(e, g) gdp_wd_qoqf
					temp_{%month}_s = (gdp_wd_qoq - gdp_wd_qoqf)^2
				next
			next

		for %month m1 m2 m3
			smpl @all
			t_{%meth}_mod4_{%month}_{%datel}(!i / n_step_both,1) = {!i}
			t_{%meth}_mod4_{%month}_{%datel}(!i / n_step_both,2) = @sqrt(@sum(temp_{%month}_s))/@sqrt(!obs)
		next
		next

	next
next


'=======================================================
' Create best model with varying number of selected regressors
'=======================================================

pageselect quarter
smpl @all

' Creating series for RMSFEs
for %meth sis tstat lars
	delete(noerr) b_tablermsfe_{%meth}
	table b_tablermsfe_{%meth}
	for %month m1 m2 m3
		for %mod mod2 mod4 mod5 mod2nops 
			delete(noerr) br_{%meth}_{%mod}_{%month}_s
			genr br_{%meth}_{%mod}_{%month}_s = 0
	
			delete(noerr) t_br_{%meth}_{%mod}_{%month}
			table t_br_{%meth}_{%mod}_{%month}
		next
	next
next

' Cumulated sum to select best model and take the one-period ahead FE 
for %meth sis tstat lars
	scalar temp_row = 2

	for !obs = 1 to fin
		%datel = @otod(nb_debut + !obs)
		for %month m1 m2 m3
			for %mod mod2 mod4 mod5
			  	t_br_{%meth}_{%mod}_{%month}(!obs + 1,1) = %datel
			next
		next

		' mod5
		string colab="a1:b"+@str(n_var_m / n_step_m)
		for %month m1 m2 m3
			t_{%meth}_mod5_{%month}_{%datel}.sort({colab}) b
			scalar temp_nb_br = @val(t_{%meth}_mod5_{%month}_{%datel}(1,1))
			string temp_b_mod5_{%month} = "f1_"+%meth+"_"+%month+"_"+@str(temp_nb_br,"f.0")+"_"+%datel
			t_br_{%meth}_mod5_{%month}(!obs + 1,2) = @str(temp_nb_br)
		next

		smpl 2001q1 %datel
		
		equation  eq_mod5_m1.midas(maxlag =nb_m, lag=auto) gdp_wd_qoq c @ month\{temp_b_mod5_m1}(-2)
		equation  eq_mod5_m2.midas(maxlag =nb_m, lag=auto) gdp_wd_qoq c @ month\{temp_b_mod5_m2}(-1)
		equation  eq_mod5_m3.midas(maxlag =nb_m, lag=auto) gdp_wd_qoq c @ month\{temp_b_mod5_m3}

		%datef = @otod(nb_debut + !obs + 1)
		smpl %datef %datef
		for %month m1 m2 m3
			eq_mod5_{%month}.fit(e, g) gdp_wd_qoqf
			br_{%meth}_mod5_{%month}_s = (gdp_wd_qoq - gdp_wd_qoqf)^2
		next

		' mod2
		string colab="a1:c"+@str((n_var_m / n_step_m)*(n_var_w / n_step_w))
		for %month m1 m2 m3
			t_{%meth}_mod2_{%month}_{%datel}.sort({colab}) c
			scalar temp_nb_br_m = @val(t_{%meth}_mod2_{%month}_{%datel}(1,1))
			scalar temp_nb_br_w = @val(t_{%meth}_mod2_{%month}_{%datel}(1,2))
			string temp_b_mod2_{%month}_m = "f1_"+%meth+"_"+%month+"_"+@str(temp_nb_br_m,"f.0")+"_"+%datel
			string temp_b_mod2_{%month}_w = "f1_"+%meth+"_"+%month+"_"+@str(temp_nb_br_w,"f.0")+"_"+%datel
			t_br_{%meth}_mod2_{%month}(!obs + 1,2) = @str(temp_nb_br_m)
			t_br_{%meth}_mod2_{%month}(!obs + 1,3) = @str(temp_nb_br_w)
		next

		smpl 2001q1 %datel
		
		equation eq_mod2_m1.midas(maxlag =nb_m nb_w, lag=auto) gdp_wd_qoq c @ month\{temp_b_mod2_m1_m}(-2) week\{temp_b_mod2_m1_w}(-5)
		equation eq_mod2_m2.midas(maxlag =nb_m nb_w, lag=auto) gdp_wd_qoq c @ month\{temp_b_mod2_m2_m}(-1) week\{temp_b_mod2_m2_w}(-1)
		equation eq_mod2_m3.midas(maxlag =nb_m nb_w, lag=auto) gdp_wd_qoq c @ month\{temp_b_mod2_m3_m} week\{temp_b_mod2_m3_m}

		%datef = @otod(nb_debut + !obs + 1)
		smpl %datef %datef
		for %month m1 m2 m3
			eq_mod2_{%month}.fit(e, g) gdp_wd_qoqf
			br_{%meth}_mod2_{%month}_s = (gdp_wd_qoq - gdp_wd_qoqf)^2
		next

		' mod 2 (no pre_selection)
		smpl 2001q1 %datel
		
		equation eq_mod2nops_m1.midas(maxlag =nb_m nb_w, lag=auto) gdp_wd_qoq c @ month\f1_all(-2) week\f1_all(-5)
		equation eq_mod2nops_m2.midas(maxlag =nb_m nb_w, lag=auto) gdp_wd_qoq c @ month\f1_all(-1) week\f1_all(-1)
		equation eq_mod2nops_m3.midas(maxlag =nb_m nb_w, lag=auto) gdp_wd_qoq c @ month\f1_all week\f1_all

		%datef = @otod(nb_debut + !obs + 1)
		smpl %datef %datef
		for %month m1 m2 m3
			eq_mod2nops_{%month}.fit(e, g) gdp_wd_qoqf
			br_{%meth}_mod2nops_{%month}_s = (gdp_wd_qoq - gdp_wd_qoqf)^2
		next

		' mod4
		string colab="a1:b"+@str(n_var_both / n_step_both)
		for %month m1 m2 m3
			t_{%meth}_mod4_{%month}_{%datel}.sort({colab}) b
			scalar temp_nb_br = @val(t_{%meth}_mod4_{%month}_{%datel}(1,1))
			string temp_b_mod4_{%month} = "f1_"+%meth+"_"+%month+"_"+@str(temp_nb_br,"f.0")+"_"+%datel
			t_br_{%meth}_mod4_{%month}(!obs + 1,2) = @str(temp_nb_br)
		next

		smpl 2001q1 %datel
		
		equation  eq_mod4_m1.midas(maxlag =nb_m, lag=auto) gdp_wd_qoq c @ freq\{temp_b_mod4_m1}(-2)
		equation  eq_mod4_m2.midas(maxlag =nb_m, lag=auto) gdp_wd_qoq c @ freq\{temp_b_mod4_m2}(-1)
		equation  eq_mod4_m3.midas(maxlag =nb_m, lag=auto) gdp_wd_qoq c @ freq\{temp_b_mod4_m3}

		%datef = @otod(nb_debut + !obs + 1)
		smpl %datef %datef
		for %month m1 m2 m3
			eq_mod4_{%month}.fit(e, g) gdp_wd_qoqf
			br_{%meth}_mod4_{%month}_s = (gdp_wd_qoq - gdp_wd_qoqf)^2
		next
	next

	smpl @all	
	for %month m1 m2 m3
			scalar temp_col = 2
		for %mod mod2 mod4 mod5 mod2nops
			b_tablermsfe_{%meth}(temp_row,1) = %month
			b_tablermsfe_{%meth}(1,temp_col) = %mod
			b_tablermsfe_{%meth}(temp_row,temp_col) = @sqrt(@sum(br_{%meth}_{%mod}_{%month}_s))/@sqrt(fin)
			temp_col = temp_col + 1
		next
		temp_row = temp_row + 1
	next
next

					
' Averaging over months
pageselect quarter
for %meth sis tstat lars
	for !j = 2 to 5
		b_tablermsfe_{%meth}(5,1) = "Avg."
		b_tablermsfe_{%meth}(5,!j) = 1/3*(@val(b_tablermsfe_{%meth}(2,!j)) + @val(b_tablermsfe_{%meth}(3,!j)) + @val(b_tablermsfe_{%meth}(4,!j)))
	next
next

