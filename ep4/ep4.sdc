derive_pll_clocks
derive_clock_uncertainty

create_clock -name clock50 -period 20.000 [get_ports clock50]

#et_false_path -from {reset}
set_false_path -to   {sync*}
set_false_path -to   {rgb*}
set_false_path -to   {led*}
