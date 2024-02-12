
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

vcom -work PoC "ocram_sp.vhdl"
vcom -work PoC "cache_par2.vhdl"

vlog -sv -work PoC "bindings.sva"
# vlog -sv -work PoC "../jaspergold/direct_mapped_cache_properties.sva"
vlog -sv -work PoC "direct_mapped_cache_properties_form2.sva"
# vlog -sv -work PoC "../jaspergold/set_associative_cache_properties.sva"

vcom -2008 -work PoC "cache_cpu.vhdl"

#######AMSHAL
vcom -2008 -work PoC "SCAAT_pkg.vhdl"
#vlog -sv -work PoC "sram_13_64_freepdk45.v"
#vcom -2008 -work PoC "SCAAT_mem.vhdl"
vcom -2008 -work PoC "SCAAT_mem2.vhdl"
vcom -2008 -work PoC "SCAAT_mem3.vhdl"
vcom -2008 -work PoC "SCAAT_mem5.vhdl"
vcom -2008 -work PoC "Rand_Gen_LFSR.vhdl"
vcom -2008 -work PoC "SCAAT_unit2_R.vhdl"
vcom -2008 -work PoC "SCAAT_unit2.vhdl"
vcom -2008 -work PoC "SCAAT_unit.vhdl"
vcom -2008 -work PoC "cache_cpu_SCAAT.vhdl"
#######AMSHAL


# vcom -2008 -work PoC "cache_cpu.vhdl" -pslfile "../jaspergold/direct_mapped_cache_properties.psl"
# vcom -2008 -work PoC "cache_cpu.vhdl" -pslfile "../jaspergold/set_associative_cache_properties.psl"
vcom -2008 -work PoC "cache_cpu_wrapper.vhdl"
vcom -work PoC "ocram.pkg.vhdl"
vcom -work PoC "arith_carrychain_inc.vhdl"
vcom -work PoC "ocram_sdp.vhdl"
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

#vcom -work PoC "mem_model.vhdl" --THIS CHANGED 
vcom -work PoC "mem_model2.vhdl"
vcom -work PoC "arith_prng.vhdl"

vcom -2008 -work PoC "cache_cpu_benchmarks_tb.vhdl"
# vcom -2008 -work PoC "cache_mem_tb.vhdl"
# vcom -2008 -work PoC "ocram_sp_tb.vhdl"


# Start the simulation
# vopt +acc cache_mem -o top_opt -debugdb
vsim -assertdebug -vopt -debugDB PoC.cache_cpu_tb PoC.cache_cpu_v_wrapper
#vsim -assertdebug PoC.cache_cpu_tb PoC.cache_cpu_v_wrapper
set StdArithNoWarnings 1
set NumericStdNoWarnings 1

add wave -position insertpoint sim/:cache_cpu_tb:UUT:SCAAT_tbl2:*
run -all

#add wave -position insertpoint sim/:cache_cpu_tb:UUT:SCAAT_tbl:*
#add wave -position insertpoint sim/:cache_cpu_tb:UUT:SCAAT_tbl:LFSR_SCAAT:*
#run
#vsim -assertdebug PoC.cache_cpu_tb PoC.cache_cpu_v_wrapper
# vsim -assertdebug -voptargs=+acc PoC.cache_cpu_tb
# PoC.cache_cpu_verification_module
# vsim -assertdebug PoC.cache_mem_tb

#vsim -set stdArithNoWarnings 1
#vsim -set NumericStdNoWarnings 1

# atv log -enable -asserts -recursive /*

# view assertions

# Draw waves
# do wave.do
# Run the simulation
#vcd file gcc_wrapper.vcd
#vcd add -r -optcells /*
#run
#vcd flush

# save the coverage reports
# coverage save coverage.ucdb

# vcover report -assert -detail -output assertion_det.txt coverage.ucdb

