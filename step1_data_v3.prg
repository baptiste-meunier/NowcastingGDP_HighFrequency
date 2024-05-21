'%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
' Data processing
'%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%REPinput = "E:\BdF - Baptiste\7-Nowcasting\Nowcasting_GDP_HF\1 - Data\1-Data_all"

%debut = "1990m01"			' Starting date for monthly data
%fin = "2021m04"				' End date for monthly data
%cut_off = "2001m01" 		' Cut-off date (series starting after are excluded)

%w_debut = "1/05/1990"		' Starting date for weekly data
%w_fin = "2021"				' End date for weekly data
%w_cut_off = "1/05/2001" 	' Cut-off date for weekly frequency

%y_debut = "1990"				' Starting date for weekly data
%y_fin = "2024"					' End date for weekly data


'=======================================================
' Importing quarterly series (Excel)
'=======================================================

cd %REPinput

%y_debut = "1990"		' Starting date for weekly data
%y_fin = "2024"			' End date for weekly data

wfcreate(wf=WF_data, page=quarter) q %y_debut %y_fin

string y_datedebut = %y_debut
string y_datefin = %y_fin

import "GDP_Data_FAME.xlsx" range="GDP"!$B$1:$I$999 colhead=3 namepos=first na="#N/A" @freq Q @id @date(year,quarter) @destid @date @smpl @all

for %v aes aesnoea ea eme wd wdnoea
	genr gdp_{%v}_lev = NA	
	smpl "1995Q1" "1995Q1"
	gdp_{%v}_lev = 100
	smpl "1995Q2" @last
	gdp_{%v}_lev = gdp_{%v}_lev(-1)*(1+gdp_{%v}_qoq/100)
next

smpl @all
for %v aes aesnoea ea eme wd wdnoea
	genr gdp_{%v}_yoy = @pcy(gdp_{%v}_lev)	
next


'=======================================================
' Importing monthly data (Excel)
'=======================================================

pagecreate(page=m_inputs) m %debut %fin

string datedebut = %debut
string cut_off = %cut_off
string datefin = %fin

' From data_inputs (master file Ferrara & Marsilli, 2019)

for %var TCR MM2 HOU CAR RET EMP UNR PRO CPI PPI CNF 'TCN SMI IRL IR3 (not these latters because are part of the weekly dataset) 
	import "Data_inputs.xls" range={%var}!$B$3:$AL$999 colhead=6 namepos=first na="#N/A" @freq M {datedebut} @smpl @all
next

import "Data_inputs.xls" range="DIV"!$B$3:$J$999 colhead=6 namepos=first na="#N/A" @freq M {datedebut} @smpl @all

delete(noerr) wd_brt wd_wti wd_dub wd_bdi wd_vix ' Because are included in the weekly dataset

' From PMI data

import "PMIS_all.xlsx" range="Monthly PMIs"!$A$2:$LH$999 colhead=7 namepos=first na="#N/A" @freq M @id @date(earliest_top) @destid @date @smpl @all

rename pmi_hk_whe_ni pmi_hk_man_ni
rename pmi_hk_whe_ob pmi_hk_man_ob
rename pmi_hk_whe_pm pmi_hk_man_pm

import "PMIS_all.xlsx" range=US-ISM colhead=7 namepos=first na="#N/A" @freq M @id @date(date) @destid @date @smpl @all

import "PMIS_all.xlsx" range=China_NBS colhead=7 namepos=first na="#N/A" @freq M @id @date(date) @destid @date @smpl @all


' From EPU data

import "All_Country_Data.xlsx" range=EPU colhead=1 na="#N/A" @freq M @id @date(year,month) @destid @date @smpl @all

rename gepu_current epu_global_cur
rename gepu_ppp epu_global_ppp
rename Australia epu_aus
rename Brazil epu_bra
rename Canada epu_can
rename Chile epu_chl
rename Hybrid_China epu_chn_hyb
rename Colombia epu_col	
rename France epu_fra
rename Germany epu_deu
rename Greece epu_gre
rename India epu_ind
rename Ireland epu_ire
rename Italy epu_ita
rename Japan epu_jap
rename Korea epu_kor
rename Netherlands epu_net
rename Russia epu_rus
rename Spain epu_esp
rename Singapore epu_sgp
rename UK epu_gb
rename US epu_us
rename SCMP_China epu_chn_scmp	
rename Mainland_China epu_chn_main	
rename Sweden epu_swe
rename Mexico epu_mex


'=======================================================
' Managing special cases (and reprolating country PMIs for emerging)
'=======================================================

pageselect m_inputs

' Special case for IT_CNF (break in 2020m04)
smpl @all
equation eq_it_cnf.ls it_cnf_sa c pmi_it_com_he
smpl "2020m4" "2020m4"
it_cnf_sa = eq_it_cnf.@coefs(1) + eq_it_cnf.@coefs(2)*pmi_it_com_he

' Special case for KO_CAR (break in 2020m09)
smpl @all
equation eq_ko_car.ls ko_car c pmi_kr_man_pm
smpl "2020m9" "2020m9"
ko_car = eq_ko_car.@coefs(1) + eq_ko_car.@coefs(2)*pmi_kr_man_pm

' Special case for TH_EMP and TH_UNR (breaks in 2020m04-2020m06)
smpl @all
equation eq_th_emp.ls th_emp c pmi_th_man_pm
equation eq_th_unr.ls th_unr c pmi_th_man_pm
smpl "2020m4" "2020m6"
th_emp = eq_th_emp.@coefs(1) + eq_th_emp.@coefs(2)*pmi_th_man_pm
th_unr = eq_th_unr.@coefs(1) + eq_th_unr.@coefs(2)*pmi_th_man_pm

' Special case for CB_CNF (expressed as diffusion indices, recentred around 50)
smpl @all
cb_cnf = cb_cnf + 50

' Special case for RM_EMP (sample break in 1992-1993)
smpl "1990m1" "1991m12"
rm_emp = na

' Special case for HN_MM2 (sample break in 1997m10 and 1997m12)
smpl "1997m10" "1997m10"
hn_mm2 = hn_mm2(-1)
smpl "1997m12" "1997m12"
hn_mm2 = hn_mm2(-1)

' Special case for SI_MM2 (annual before 1993)
smpl "1990m12" "1990m12"
si_mm2 = na
smpl "1991m12" "1991m12"
si_mm2 = na

' Delete pmi_mz_whe_ne (all NA)
delete(noerr) pmi_mz_whe_ne

' Delete in_cnf_sa (bimensual)
delete(noerr) in_cnf_sa

' Adjusting world PMI series
smpl @all
for %w ser com
	if @isobject("pmi_gl_"+%w+"_he")=1 then
		if @isobject("pmi_gl_man_pm")=1 then
			equation eq_gl_{%w}_he.ls pmi_gl_{%w}_he c pmi_gl_man_pm
		endif
	endif
next

smpl "1998m1" "1998m6"
for %w ser com
	if @isobject("pmi_gl_"+%w+"_he")=1 then
		if @isobject("pmi_gl_man_pm")=1 then
			pmi_gl_{%w}_he = eq_gl_{%w}_he.@coefs(1) + eq_gl_{%w}_he.@coefs(2)*pmi_gl_man_pm
		endif
	endif
next

' Equations on world PMI 
smpl @all
for %v BR IN CN KR ES FR JP RU HK
	for %w man ser com
		for %x ne ni he ob pm sd
			if @isobject("pmi_"+%v+"_"+%w+"_"+%x)=1 then
				if @isobject("pmi_gl_"+%w+"_"+%x)=1 then
					equation eq_{%v}_{%w}_{%x}.ls pmi_{%v}_{%w}_{%x} c pmi_gl_{%w}_{%x}
				else
					equation eq_{%v}_{%w}_{%x}.ls pmi_{%v}_{%w}_{%x} c pmi_gl_{%w}_he
				endif
			endif
		next
	next
next

' Brazil manufacturing
smpl "1998m1" "2006m1"
for %v BR
	for %w man
		for %x ne ni he ob pm sd
			if @isobject("pmi_"+%v+"_"+%w+"_"+%x)=1 then
				if @isobject("pmi_gl_"+%w+"_"+%x)=1 then
					pmi_{%v}_{%w}_{%x} = eq_{%v}_{%w}_{%x}.@coefs(1) + eq_{%v}_{%w}_{%x}.@coefs(2)*pmi_gl_{%w}_{%x}
				else
					pmi_{%v}_{%w}_{%x} = eq_{%v}_{%w}_{%x}.@coefs(1) + eq_{%v}_{%w}_{%x}.@coefs(2)*pmi_gl_{%w}_he	
				endif
			endif
		next
	next
next 

' Brazil services and composite
smpl "1998m1" "2007m2"
for %v BR
	for %w ser com
		for %x ne ni he ob pm sd
			if @isobject("pmi_"+%v+"_"+%w+"_"+%x)=1 then
				if @isobject("pmi_gl_"+%w+"_"+%x)=1 then
					pmi_{%v}_{%w}_{%x} = eq_{%v}_{%w}_{%x}.@coefs(1) + eq_{%v}_{%w}_{%x}.@coefs(2)*pmi_gl_{%w}_{%x}
				else
					pmi_{%v}_{%w}_{%x} = eq_{%v}_{%w}_{%x}.@coefs(1) + eq_{%v}_{%w}_{%x}.@coefs(2)*pmi_gl_{%w}_he	
				endif
			endif
		next
	next
next 

' India manufacturing
smpl "1998m1" "2005m2"
for %v IN
	for %w man
		for %x ne ni he ob pm sd
			if @isobject("pmi_"+%v+"_"+%w+"_"+%x)=1 then
				if @isobject("pmi_gl_"+%w+"_"+%x)=1 then
					pmi_{%v}_{%w}_{%x} = eq_{%v}_{%w}_{%x}.@coefs(1) + eq_{%v}_{%w}_{%x}.@coefs(2)*pmi_gl_{%w}_{%x}
				else
					pmi_{%v}_{%w}_{%x} = eq_{%v}_{%w}_{%x}.@coefs(1) + eq_{%v}_{%w}_{%x}.@coefs(2)*pmi_gl_{%w}_he	
				endif
			endif
		next
	next
next 

' India services and composite
smpl "1998m1" "2005m11"
for %v IN
	for %w ser com
		for %x ne ni he ob pm sd
			if @isobject("pmi_"+%v+"_"+%w+"_"+%x)=1 then
				if @isobject("pmi_gl_"+%w+"_"+%x)=1 then
					pmi_{%v}_{%w}_{%x} = eq_{%v}_{%w}_{%x}.@coefs(1) + eq_{%v}_{%w}_{%x}.@coefs(2)*pmi_gl_{%w}_{%x}
				else
					pmi_{%v}_{%w}_{%x} = eq_{%v}_{%w}_{%x}.@coefs(1) + eq_{%v}_{%w}_{%x}.@coefs(2)*pmi_gl_{%w}_he	
				endif
			endif
		next
	next
next 

' China & Korea
smpl "1998m1" "2004m3"
for %v CN KR
	for %w man
		for %x ne ni he ob pm sd
			if @isobject("pmi_"+%v+"_"+%w+"_"+%x)=1 then
				if @isobject("pmi_gl_"+%w+"_"+%x)=1 then
					pmi_{%v}_{%w}_{%x} = eq_{%v}_{%w}_{%x}.@coefs(1) + eq_{%v}_{%w}_{%x}.@coefs(2)*pmi_gl_{%w}_{%x}
				else
					pmi_{%v}_{%w}_{%x} = eq_{%v}_{%w}_{%x}.@coefs(1) + eq_{%v}_{%w}_{%x}.@coefs(2)*pmi_gl_{%w}_he	
				endif
			endif
		next
	next
next 

' China services & composite
smpl "1998m1" "2005m10"
for %v CN
	for %w com ser
		for %x ne ni he ob pm sd
			if @isobject("pmi_"+%v+"_"+%w+"_"+%x)=1 then
				if @isobject("pmi_gl_"+%w+"_"+%x)=1 then
					pmi_{%v}_{%w}_{%x} = eq_{%v}_{%w}_{%x}.@coefs(1) + eq_{%v}_{%w}_{%x}.@coefs(2)*pmi_gl_{%w}_{%x}
				else
					pmi_{%v}_{%w}_{%x} = eq_{%v}_{%w}_{%x}.@coefs(1) + eq_{%v}_{%w}_{%x}.@coefs(2)*pmi_gl_{%w}_he	
				endif
			endif
		next
	next
next


' China services & composite
smpl "1998m1" "2001m9"
for %v RU
	for %w com ser
		for %x he
			if @isobject("pmi_"+%v+"_"+%w+"_"+%x)=1 then
				if @isobject("pmi_gl_"+%w+"_"+%x)=1 then
					pmi_{%v}_{%w}_{%x} = eq_{%v}_{%w}_{%x}.@coefs(1) + eq_{%v}_{%w}_{%x}.@coefs(2)*pmi_gl_{%w}_{%x}
				else
					pmi_{%v}_{%w}_{%x} = eq_{%v}_{%w}_{%x}.@coefs(1) + eq_{%v}_{%w}_{%x}.@coefs(2)*pmi_gl_{%w}_he	
				endif
			endif
		next
	next
next

' Spain composite & services
smpl "1998m1" "1999m7"
for %v ES
	for %w ser com
		for %x he
			if @isobject("pmi_"+%v+"_"+%w+"_"+%x)=1 then
				if @isobject("pmi_gl_"+%w+"_"+%x)=1 then
					pmi_{%v}_{%w}_{%x} = eq_{%v}_{%w}_{%x}.@coefs(1) + eq_{%v}_{%w}_{%x}.@coefs(2)*pmi_gl_{%w}_{%x}
				else
					pmi_{%v}_{%w}_{%x} = eq_{%v}_{%w}_{%x}.@coefs(1) + eq_{%v}_{%w}_{%x}.@coefs(2)*pmi_gl_{%w}_he	
				endif
			endif
		next
	next
next 

' Spain manufacturing
smpl "1998m1" "1998m1"
for %v ES
	for %w man
		for %x ne ni ob pm
			if @isobject("pmi_"+%v+"_"+%w+"_"+%x)=1 then
				if @isobject("pmi_gl_"+%w+"_"+%x)=1 then
					pmi_{%v}_{%w}_{%x} = eq_{%v}_{%w}_{%x}.@coefs(1) + eq_{%v}_{%w}_{%x}.@coefs(2)*pmi_gl_{%w}_{%x}
				else
					pmi_{%v}_{%w}_{%x} = eq_{%v}_{%w}_{%x}.@coefs(1) + eq_{%v}_{%w}_{%x}.@coefs(2)*pmi_gl_{%w}_he	
				endif
			endif
		next
	next
next 

' France composite & services
smpl "1998m1" "1998m4"
for %v FR
	for %w ser com
		for %x he
			if @isobject("pmi_"+%v+"_"+%w+"_"+%x)=1 then
				if @isobject("pmi_gl_"+%w+"_"+%x)=1 then
					pmi_{%v}_{%w}_{%x} = eq_{%v}_{%w}_{%x}.@coefs(1) + eq_{%v}_{%w}_{%x}.@coefs(2)*pmi_gl_{%w}_{%x}
				else
					pmi_{%v}_{%w}_{%x} = eq_{%v}_{%w}_{%x}.@coefs(1) + eq_{%v}_{%w}_{%x}.@coefs(2)*pmi_gl_{%w}_he	
				endif
			endif
		next
	next
next 

' France manufacturing
smpl "1998m1" "1998m3"
for %v FR
	for %w man
		for %x ne ni ob pm
			if @isobject("pmi_"+%v+"_"+%w+"_"+%x)=1 then
				if @isobject("pmi_gl_"+%w+"_"+%x)=1 then
					pmi_{%v}_{%w}_{%x} = eq_{%v}_{%w}_{%x}.@coefs(1) + eq_{%v}_{%w}_{%x}.@coefs(2)*pmi_gl_{%w}_{%x}
				else
					pmi_{%v}_{%w}_{%x} = eq_{%v}_{%w}_{%x}.@coefs(1) + eq_{%v}_{%w}_{%x}.@coefs(2)*pmi_gl_{%w}_he	
				endif
			endif
		next
	next
next 

' Japan manufacturing
smpl "1998m1" "2001m10"
for %v JP
	for %w man
		for %x ne ni ob pm
			if @isobject("pmi_"+%v+"_"+%w+"_"+%x)=1 then
				if @isobject("pmi_gl_"+%w+"_"+%x)=1 then
					pmi_{%v}_{%w}_{%x} = eq_{%v}_{%w}_{%x}.@coefs(1) + eq_{%v}_{%w}_{%x}.@coefs(2)*pmi_gl_{%w}_{%x}
				else
					pmi_{%v}_{%w}_{%x} = eq_{%v}_{%w}_{%x}.@coefs(1) + eq_{%v}_{%w}_{%x}.@coefs(2)*pmi_gl_{%w}_he	
				endif
			endif
		next
	next
next 

' Hong Kong
smpl "1998m1" "1998m6"
for %v HK
	for %w man ser com
		for %x ne ni he ob pm sd
			if @isobject("pmi_"+%v+"_"+%w+"_"+%x)=1 then
				if @isobject("pmi_gl_"+%w+"_"+%x)=1 then
					pmi_{%v}_{%w}_{%x} = eq_{%v}_{%w}_{%x}.@coefs(1) + eq_{%v}_{%w}_{%x}.@coefs(2)*pmi_gl_{%w}_{%x}
				else
					pmi_{%v}_{%w}_{%x} = eq_{%v}_{%w}_{%x}.@coefs(1) + eq_{%v}_{%w}_{%x}.@coefs(2)*pmi_gl_{%w}_he	
				endif
			endif
		next
	next
next


'=======================================================
' Deleting series starting after cut-off date
'=======================================================

pageselect m_inputs

for %pays FR DE IT ES NL UK US JP CN SD SW NW DK CH IN ID KO TW TH HK MY SP BR AG MX CB PO CZ RM HN LV LN BL RS TK SA SI
	for %var TCR MM2 HOU CAR RET EMP UNR PRO CPI PPI CNF 
		if @isobject(%pays+"_"+%var)=1 then
			if @isna(@elem({%pays}_{%var}, cut_off))=1 then
				delete(noerr) {%pays}_{%var}
			endif
		endif
	next
next

for %pays FR DE IT ES NL UK US JP CN SD SW NW DK CH IN ID KO TW TH HK MY SP BR AG MX CB PO CZ RM HN LV LN BL RS TK SA SI
	for %var TCR MM2 HOU CAR RET EMP UNR PRO CPI PPI CNF 
		if @isobject(%pays+"_"+%var+"_sa")=1 then
			if @isna(@elem({%pays}_{%var}_sa, cut_off))=1 then
				delete(noerr) {%pays}_{%var}_sa
			endif
		endif
	next
next


'=======================================================
' Seasonal adjustment for monthly series (X12 method)
'=======================================================
' Census X12 method: the procedure requires at least 3 full years of data and can adjust up to 600 observations (50 years of monthly data or 150 years of quarterly data).

pageselect m_inputs

smpl @all
for %var  WD_ENP WD_ORP 'WD_IMP WD_EXP (those two series are seasonally adjusted)
	{%var}.X12
next

smpl @all
for %pays FR DE IT ES NL UK US JP CN SD SW NW DK CH IN ID KO TW TH HK MY SP BR AG MX CB PO CZ RM HN LV LN BL RS TK SA SI
	for %var TCR MM2 HOU CAR RET EMP UNR PRO CPI PPI CNF
		if @isobject(%pays+"_"+%var)=1 then
			if @elem({%pays}_{%var}, datedebut)=="$$ER: E100,INVALID CODE OR EXPRESSION ENTERED" then delete(noerr) {%pays}_{%var}
				else if @elem({%pays}_{%var}, datedebut)=="$$ER E601, DATA FOR CANNOT BE RETRIEVED AT REQUESTED FREQUENCY" then delete(noerr) {%pays}_{%var}
 				else
				smpl @all						
				{%pays}_{%var}.X12
				endif
			endif
		endif
	next
next

' NB: for EPUs and PMIs, this step is also used for deleting series starting after 2001m1
' NB2: PMIs are already seasonnally adjusted

group epu epu_*
for !i=1 to epu.@count
	%name = epu.@seriesname(!i)
	if @isna(@elem({%name}, cut_off))=0 then {%name}.x12
	endif
next

group pmi pmi_* 
for !i=1 to pmi.@count
	%name = pmi.@seriesname(!i)
	if @isna(@elem({%name}, cut_off))=0 then genr {%name}_sa = {%name}
	endif
next

'=======================================================
' Translation of series
'=======================================================
' Based on the vertical re-alignment method (Altissimo et al., 2006); other methods exist (e.g. EM algorithm as in Stock and Watson, 2002) but the results are somewhat equivalent (Marcellino and Schumacher, 2010)

pagecreate(page=extrap1) m {datedebut} {datefin}
copy m_inputs\*_sa extrap1\*_sa
copy m_inputs\date* extrap1\date*

delete(noerr) *_adj  'Removing (if any) already processed series

' Main series (seasonally adjusted)
scalar count = 0
smpl @all
for %pays FR DE IT ES NL UK US JP CN SD SW NW DK CH IN ID KO TW TH HK MY SP BR AG MX CB PO CZ RM HN LV LN BL RS TK SA SI
	for %var TCR MM2 HOU CAR RET EMP UNR PRO CPI PPI CNF
		%tlast = datefin
		count = 0
		if @isobject(%pays+"_"+%var+"_sa")=1 then
			While @elem({%pays}_{%var}_sa,%tlast)=NA
				%tlast=@otod(@dtoo(%tlast)-1)
				count = count + 1
			wend
			if count > 12 then delete(noerr) {%pays}_{%var}_sa
			else genr {%pays}_{%var}_sa_adj = {%pays}_{%var}_sa(-count)
			endif
		endif
	next
next

' WD series
smpl @all
for %var  WD_ENP WD_ORP WD_IMP WD_EXP
	%tlast = datefin
	count = 0
	if @isobject(%var+"_sa")=1 then
		While @elem({%var}_sa,%tlast)=NA
			%tlast=@otod(@dtoo(%tlast)-1)
			count = count + 1
		wend
		if count > 12 then delete(noerr) {%var}_sa
		else genr {%var}_sa_adj = {%var}_sa(-count)
		endif
	endif
next

' EPUs
group epu epu_*
for !i=1 to epu.@count
	%name = epu.@seriesname(!i) 
	%tlast = datefin
	count = 0
	while @elem({%name},%tlast)=NA
		%tlast=@otod(@dtoo(%tlast)-1)
		count = count + 1
	wend
	if count <= 12 then genr {%name}_adj = {%name}(-count)
	endif
next

' PMIs
group pmi pmi_*
for !i=1 to pmi.@count
	%name = pmi.@seriesname(!i) 
	%tlast = datefin
	count = 0
	while @elem({%name},%tlast)=NA
		%tlast=@otod(@dtoo(%tlast)-1)
		count = count + 1
	wend
	if count <= 12 then genr {%name}_adj = {%name}(-count)
	endif
next


'=======================================================
' Stationarity of monthly series
'=======================================================

pagecreate(page=month) m {datedebut} {datefin}
copy extrap1\*_adj month\*_adj
copy extrap1\date* month\date*

delete(noerr) *_sta 'Removing (if any) already processed series

' Month-on-month percent change
for %w TCR MM2 HOU CAR RET EMP PRO CPI PPI
	for %v FR DE IT ES NL UK US JP CN SD SW NW DK CH IN ID KO TW TH HK MY SP BR AG MX CB PO CZ RM HN LV LN BL RS TK SA SI
		if @isobject(%v+"_"+%w+"_sa_adj")=1 then
			genr {%v}_{%w}_sa_adj_sta = @pc({%v}_{%w}_sa_adj)
		endif
	next
next

' Month-on-month difference
scalar nb = 1 ' Number of months
for %w UNR CNF 
	for %v FR DE IT ES NL UK US JP CN SD SW NW DK CH IN ID KO TW TH HK MY SP BR AG MX CB PO CZ RM HN LV LN BL RS TK SA SI
		if @isobject(%v+"_"+%w+"_sa_adj")=1 then
			genr {%v}_{%w}_sa_adj_sta = d({%v}_{%w}_sa_adj, nb)
		endif
	next
next

' WD series
smpl @all
for %var WD_ENP WD_ORP WD_IMP WD_EXP
	genr {%var}_sa_adj_sta = @pc({%var}_sa_adj)
next

' EPUs (month-on-month change)
group epu epu_*
for !i=1 to epu.@count
	%name = epu.@seriesname(!i) 
	genr {%name}_sta = @pc({%name})
next

'PMIs (already stationary - expressed as month-on-month changes)
group pmi pmi_*
for !i=1 to pmi.@count
	%name = pmi.@seriesname(!i) 
	genr {%name}_sta = {%name}
next


'=======================================================
' Monthly factor with all series
'=======================================================

pageselect month

group sta_all *_sta
sta_all.makepcomp f1_all

copy(link) quarter\gdp_wd_yoy month\gdp_wd_yoy
group g  gdp_wd_yoy f1_all
freeze(graph) g.line
graph.setelem(2) axis(r)
graph.setelem(2) axis(r)
graph.axis overlap
show graph


'=======================================================
' Importing weekly data (Excel)
'=======================================================

pagecreate(page=w_inputs) w %w_debut %w_fin

string w_datedebut = %w_debut
string w_cut_off = %w_cut_off
string w_datefin = %w_fin

for %var TCN IRL IR3 SMI SPR Other
	import "Data_week_v3.xlsx" range={%var} colhead=7 namepos=first na="#N/A" @freq W(Fri) @id @date(date) @destid @date @smpl @all
next


'=======================================================
' Special cases
'=======================================================

' IN_IR3, AG_IR3 and DIV_CRB (discontinued)
delete(noerr) in_ir3
delete(noerr) ag_ir3
delete(noerr) div_crb


'=======================================================
' Stationarity of weekly series - and deleting series after cut-off
'=======================================================

pageselect w_inputs

smpl @all

' For TCN and SMI
for %pays FR DE IT ES NL UK US JP CN SD SW NW DK CH IN ID KO TW TH HK MY SP BR AG MX CB PO CZ RM HN LV LN BL RS TK SA SI
	for %var TCN SMI 
		if @isobject(%pays+"_"+%var)=1 then
			if @elem({%pays}_{%var}, w_datedebut)=="$$ER E601, DATA FOR CANNOT BE RETRIEVED AT REQUESTED FREQUENCY" then delete(noerr) {%pays}_{%var}
 			else
				if @isna(@elem({%pays}_{%var}, w_cut_off))=1 then delete(noerr) {%pays}_{%var}
				else
					smpl @all						
					genr {%pays}_{%var}_sta = @movsum(({%pays}_{%var}/{%pays}_{%var}(-1)-1)*100,4)
				endif
			endif
		endif
	next
next

' For IRL, IR3, and SPR (NB: are already stationary)
for %pays FR DE IT ES NL UK US JP CN SD SW NW DK CH IN ID KO TW TH HK MY SP BR AG MX CB PO CZ RM HN LV LN BL RS TK SA SI
	for %var IRL IR3 SPR
		if @isobject(%pays+"_"+%var)=1 then
			if @elem({%pays}_{%var}, w_datedebut)=="$$ER E601, DATA FOR CANNOT BE RETRIEVED AT REQUESTED FREQUENCY" then delete(noerr) {%pays}_{%var}
			else
				if @isna(@elem({%pays}_{%var}, w_cut_off))=1 then delete(noerr) {%pays}_{%var}
				else
					smpl @all						
					genr {%pays}_{%var}_sta = {%pays}_{%var}
				endif
 			endif
		endif
	next
next

' For "div" series
group div div_*
div.drop div_ch_ces div_us_ads div_us_bar div_us_fci div_us_vix ' Already stationary
for !i=1 to div.@count
	%name = div.@seriesname(!i)
	if @isna(@elem({%name}, w_cut_off))=0 then genr {%name}_sta = @movsum(({%name}/{%name}(-1)-1)*100,4)
	endif
next

for %v div_ch_ces div_us_ads div_us_bar div_us_fci div_us_vix ' Already stationary
	if @isna(@elem({%name}, w_cut_off))=0 then genr sta_{%v} = {%v}
	endif
next


'=======================================================
' Seasonnally adjustment (with dummies)
'=======================================================

pagecreate(page=week) w {w_datedebut} {w_datefin}
copy w_inputs\*_sta week\*_sta
copy w_inputs\w_date* week\w_date*

smpl @all

series month1=(@month(resid)=1)
series month2=(@month(resid)=2)
series month3=(@month(resid)=3)
series month4=(@month(resid)=4)
series month5=(@month(resid)=5)
series month6=(@month(resid)=6)
series month7=(@month(resid)=7)
series month8=(@month(resid)=8)
series month9=(@month(resid)=9)
series month10=(@month(resid)=10)
series month11=(@month(resid)=11)
series month12=(@month(resid)=12)

group sta *_sta

' Estimating equations
smpl {w_datedebut} 2019
for !i=1 to sta.@count
	%name = sta.@seriesname(!i)
	equation eq_{%name}.ls {%name} c month1 month2 month3 month4 month5 month6 month7 month8 month9 month10 month11
	genr {%name}_sa = {%name} - eq_{%name}.@coefs(1) - eq_{%name}.@coefs(2)*month1 - eq_{%name}.@coefs(3)*month2 - eq_{%name}.@coefs(4)*month3 - eq_{%name}.@coefs(5)*month4 - eq_{%name}.@coefs(6)*month5 - eq_{%name}.@coefs(7)*month6 - eq_{%name}.@coefs(8)*month7 - eq_{%name}.@coefs(9)*month8 - eq_{%name}.@coefs(10)*month9 - eq_{%name}.@coefs(11)*month10 - eq_{%name}.@coefs(12)*month11
next

' Creating series
smpl @all
for !i=1 to sta.@count
	%name = sta.@seriesname(!i)
	genr {%name}_sa = {%name} - eq_{%name}.@coefs(1) - eq_{%name}.@coefs(2)*month1 - eq_{%name}.@coefs(3)*month2 - eq_{%name}.@coefs(4)*month3 - eq_{%name}.@coefs(5)*month4 - eq_{%name}.@coefs(6)*month5 - eq_{%name}.@coefs(7)*month6 - eq_{%name}.@coefs(8)*month7 - eq_{%name}.@coefs(9)*month8 - eq_{%name}.@coefs(10)*month9 - eq_{%name}.@coefs(11)*month10 - eq_{%name}.@coefs(12)*month11
next

'=======================================================
' Creating weekly factors
'=======================================================

pageselect week

' Financial factor
smpl @all
group sta_fin *_smi_sta_sa *_ir3_sta_sa *_irl_sta_sa *_spr_sta_sa *_tcn_sta_sa
sta_fin.makepcomp f1_fin

' Real economy factor
smpl @all
group sta_real div_*_sa
sta_real.makepcomp f1_real

' Total factor
group sta_all sta_real sta_fin
sta_all.makepcomp f1_all

' Graph with all three factors
delete(noerr) graph_all
copy(link) quarter\gdp_wd_yoy week\gdp_wd_yoy
group g_factors gdp_wd_yoy f1_fin f1_real f1_all
freeze(graph_all) g_factors.line
graph_all.setelem(2) axis(r)
graph_all.setelem(3) axis(r)
graph_all.setelem(4) axis(r)
graph_all.axis overlap
show graph_all


'=======================================================
' Monthly factor incorporating weekly series
'=======================================================

pageselect month
pagecreate(page=freq) m {datedebut} {datefin}
copy month\*_sta freq\*_sta_m
copy(c=a) week\*_sa freq\*_sa_w

smpl @all
group sta_all *sta*
sta_all.makepcomp f1_all

copy(link) quarter\gdp_wd_yoy freq\gdp_wd_yoy
group g  gdp_wd_yoy f1_all
freeze(graph) g.line
graph.setelem(2) axis(r)
graph.axis overlap
show graph


'%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
' A back-up file is saved in the data folder
'%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

