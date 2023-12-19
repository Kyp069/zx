derive_pll_clocks
derive_clock_uncertainty

create_clock -name clock50 -period 20.000 [get_ports clock50]
create_clock -name spiCk   -period 41.666 [get_ports spiCk]

set_clock_groups -asynchronous \
	-group [get_clocks pll0|altpll_component|auto_generated|pll1|clk[0]] \
	-group [get_clocks pll1|altpll_component|auto_generated|pll1|clk[0]] \
	-group [get_clocks clock50] \
	-group [get_clocks spiCk]

set_false_path -to   {led}
set_false_path -to   {i2s*}
set_false_path -to   {rgb*}
set_false_path -to   {dram*}
#et_false_path -to   {midi*}
set_false_path -to   {sync*}

set_false_path -from {ear}
#et_false_path -from {midi}
set_false_path -from {dram*}
