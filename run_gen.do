
vlib PoC

# Include files and compile them
vcom -work PoC "utils.vhdl"
vcom -work PoC "my_config.vhdl"
vcom -work PoC "my_project.vhdl"
vcom -work PoC "config.vhdl"
vcom -work PoC "strings.vhdl"
vcom -work PoC "vectors.vhdl"
vcom -work PoC "components.vhdl"
vcom -work PoC "arith.pkg.vhdl"
vcom -work PoC "arith_prefix_and.vhdl"
vcom -work PoC "sort_lru_cache.vhdl"
vcom -work PoC "cache_replacement_policy.vhdl"
vcom -work PoC "package.vhd"
vcom -work PoC "cache_tagunit_par.vhdl"
vcom -work PoC "mem.pkg.vhdl"
vcom -work PoC "physical.vhdl"

vlib work

vcom -2008 -work PoC "cache_cpu_trace_Genrator.vhdl"
#######AMSHAL

vcom -2008 -work PoC "fifo_glue.vhdl"
vcom -work PoC "fifo_cc_got.vhdl"
vcom -2008 -work PoC "cache_mem.vhdl"

vcom -2008 -work PoC "protected.v08.vhdl"
vcom -2008 -work PoC "fileio.v08.vhdl"

vcom -work PoC "sim_types.vhdl"

vcom -2008 -work PoC "sim_protected.v08.vhdl"

vcom -2008 -work PoC "sim_global.v08.vhdl"

vcom -2008 -work PoC "sim_simulation.v08.vhdl"

vcom -2008 -work PoC "sim_waveform.vhdl"


vcom -2008 -work PoC "cache_cpu_traceGen_tb.vhdl"

vsim -assertdebug -vopt -debugDB PoC.cache_cpu_traceGen_tb
#vsim PoC.cache_cpu_tb -voptargs=+acc=bcglnprst+security
#vsim -assertdebug PoC.cache_cpu_tb PoC.cache_cpu_v_wrapper
set StdArithNoWarnings 1
set NumericStdNoWarnings 1