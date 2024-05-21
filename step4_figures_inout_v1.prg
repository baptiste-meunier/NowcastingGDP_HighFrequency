'%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
' Graphs for the paper
'%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


'=========================================================
' Cumulative Sum of Squared Forecast Errors (CSSFED)
'=========================================================

' Modele benchmark = Modele 2

' CSSFED out-of-sample
pageselect quarter
smpl @all
 for %month m1 m2 m3
	for %mod mod4 mod5 mod6
		series temp_{%mod}_{%month}_out = br_{meth}_mod2_{%month}_s - br_{meth}_{%mod}_{%month}_s
		series CSSFED_out_{%mod}_{%month} = @cumsum(temp_{%mod}_{%month}_out)
	next
next

smpl "2005Q1" "2019Q4"
for %month m1 m2 m3
	delete(noerr) zz_CSSFED_out_{meth}_{%month}
	graph zz_CSSFED_out_{meth}_{%month}.line CSSFED_out_mod4_{%month} CSSFED_out_mod5_{%month} CSSFED_out_mod6_{%month}
	zz_CSSFED_out_{meth}_{%month}.name(1) Model 2
	zz_CSSFED_out_{meth}_{%month}.name(2) Model 3
	zz_CSSFED_out_{meth}_{%month}.name(3) AR model
	zz_CSSFED_out_{meth}_{%month}.axis overlap
	zz_CSSFED_out_{meth}_{%month}.axis(t) font(Palatino Linotype,12,-b,-i,-u,-s)
	zz_CSSFED_out_{meth}_{%month}.legend font(Palatino Linotype,12,-b,-i,-u,-s)
	zz_CSSFED_out_{meth}_{%month}.setfont legend(Palatino Linotype,12,-b,-i,-u,-s) text(Palatino Linotype,12,-b,-i,-u,-s) obs(Palatino Linotype,12,-b,-i,-u,-s) axis(Palatino Linotype,12,-b,-i,-u,-s)
	zz_CSSFED_out_{meth}_{%month}.setfont obs(Palatino Linotype,12,-b,-i,-u,-s)
	zz_CSSFED_out_{meth}_{%month}.textdefault font(Palatino Linotype,12,-b,-i,-u,-s)
	zz_CSSFED_out_{meth}_{%month}.options -gridl -gridr -gridt
	zz_CSSFED_out_{meth}_{%month}.options gridnone
next

smpl "2019Q4" "2021Q1"
for %month m1 m2 m3
	delete(noerr) zz_CSSFED_out_{meth}_{%month}_covid
	graph zz_CSSFED_out_{meth}_{%month}_covid.line CSSFED_out_mod4_{%month} CSSFED_out_mod5_{%month} CSSFED_out_mod6_{%month}
	zz_CSSFED_out_{meth}_{%month}_covid.name(1) Model 2 (LHS)
	zz_CSSFED_out_{meth}_{%month}_covid.name(2) Model 3 (LHS)
	zz_CSSFED_out_{meth}_{%month}_covid.name(3) AR model (RHS)
	zz_CSSFED_out_{meth}_{%month}_covid.axis overlap
	zz_CSSFED_out_{meth}_{%month}_covid.setelem(3) axis(r)
	zz_CSSFED_out_{meth}_{%month}_covid.axis(t) font(Palatino Linotype,12,-b,-i,-u,-s)
	zz_CSSFED_out_{meth}_{%month}_covid.legend font(Palatino Linotype,12,-b,-i,-u,-s)
	zz_CSSFED_out_{meth}_{%month}_covid.setfont legend(Palatino Linotype,12,-b,-i,-u,-s) text(Palatino Linotype,12,-b,-i,-u,-s) obs(Palatino Linotype,12,-b,-i,-u,-s) axis(Palatino Linotype,12,-b,-i,-u,-s)
	zz_CSSFED_out_{meth}_{%month}_covid.setfont obs(Palatino Linotype,12,-b,-i,-u,-s)
	zz_CSSFED_out_{meth}_{%month}_covid.textdefault font(Palatino Linotype,12,-b,-i,-u,-s)
	zz_CSSFED_out_{meth}_{%month}_covid.options -gridl -gridr -gridt
	zz_CSSFED_out_{meth}_{%month}_covid.options gridnone
	zz_CSSFED_out_{meth}_{%month}_covid.datelabel format("YYYY[Q]Q")
next


'=======================================================
' Monthly factor
'=======================================================

pageselect month

copy(link) quarter\gdp_wd_qoq month\gdp_wd_qoq
copy quarter\meth month\meth
copy quarter\fin_est month\fin_est
copy quarter\opt_mod2_m_* month\opt_mod2_m_*

for %month m1 m2 m3
	delete(noerr) g_{%month}
	delete(noerr) graph_{%month}
	group g_{%month}  gdp_wd_qoq f1_{meth}_{%month}_{opt_mod2_m_{%month}}_{fin_est}
	smpl 2001m01 2021m03
	freeze(graph_{%month}) g_{%month}.line
	graph_{%month}.setelem(2) axis(r)
	graph_{%month}.name(1) World GDP q-o-q growth (LHS)
	graph_{%month}.name(2) Monthly factor (RHS)
	graph_{%month}.axis overlap
	graph_{%month}.axis(t) font(Palatino Linotype,12,-b,-i,-u,-s)
	graph_{%month}.legend font(Palatino Linotype,12,-b,-i,-u,-s)
	graph_{%month}.setfont legend(Palatino Linotype,12,-b,-i,-u,-s) text(Palatino Linotype,12,-b,-i,-u,-s) obs(Palatino Linotype,12,-b,-i,-u,-s) axis(Palatino Linotype,12,-b,-i,-u,-s)
	graph_{%month}.setfont obs(Palatino Linotype,12,-b,-i,-u,-s)
	graph_{%month}.textdefault font(Palatino Linotype,12,-b,-i,-u,-s)
	graph_{%month}.axis(l) range(-8,8)
	graph_{%month}.options -gridl -gridr -gridt
	graph_{%month}.axis(l) -zeroline
	graph_{%month}.options gridnone
next

'=======================================================
' Weekly factor
'=======================================================

pageselect week

copy(link) quarter\gdp_wd_qoq week\gdp_wd_qoq
copy quarter\meth week\meth
copy quarter\fin_est week\fin_est
copy quarter\opt_mod2_w_* week\opt_mod2_w_*

for %month m1 m2 m3
	genr f1_{meth}_{%month}_{opt_mod2_w_{%month}}_{fin_est}_ma = @movav(f1_{meth}_{%month}_{opt_mod2_w_{%month}}_{fin_est},13)
	delete(noerr) g_{%month}
	delete(noerr) graph_{%month}
	group g_{%month}  gdp_wd_qoq f1_{meth}_{%month}_{opt_mod2_w_{%month}}_{fin_est} f1_{meth}_{%month}_{opt_mod2_w_{%month}}_{fin_est}_ma
	smpl 2001 2021
	freeze(graph_{%month}) g_{%month}.line
	graph_{%month}.setelem(2) axis(r)
	graph_{%month}.setelem(3) axis(r)
	graph_{%month}.name(1) World GDP q-o-q growth (LHS)
	graph_{%month}.name(2) Weekly factor (RHS)
	graph_{%month}.name(3) Weekly factor, 13-week moving average (RHS)
	graph_{%month}.axis overlap
	graph_{%month}.axis(t) font(Palatino Linotype,12,-b,-i,-u,-s)
	graph_{%month}.legend font(Palatino Linotype,12,-b,-i,-u,-s)
	graph_{%month}.setfont legend(Palatino Linotype,12,-b,-i,-u,-s) text(Palatino Linotype,12,-b,-i,-u,-s) obs(Palatino Linotype,12,-b,-i,-u,-s) axis(Palatino Linotype,12,-b,-i,-u,-s)
	graph_{%month}.setfont obs(Palatino Linotype,12,-b,-i,-u,-s)
	graph_{%month}.textdefault font(Palatino Linotype,12,-b,-i,-u,-s)
	graph_{%month}.axis(l) range(-8,8)
	graph_{%month}.axis(r) range(-20,15)
	graph_{%month}.options -gridl -gridr -gridt
	graph_{%month}.axis(l) -zeroline
	graph_{%month}.options gridnone
next


