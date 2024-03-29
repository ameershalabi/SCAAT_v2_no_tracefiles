#########################################
# Copyright (C) 2016 Project Bonfire    #
#                                       #
# This file is automatically generated! #
#             DO NOT EDIT!              #
#########################################

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

vlog -work PoC "cache_security.v"
vcom -2008 -work PoC "cache_cpu.vhdl"
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

vcom -work PoC "mem_model.vhdl"
vcom -work PoC "arith_prng.vhdl"

vcom -2008 -work PoC "cache_cpu_et_attack_tb.vhdl"
# vcom -2008 -work PoC "cache_cpu_tb.vhdl"
# vcom -2008 -work PoC "cache_mem_tb.vhdl"
# vcom -2008 -work PoC "ocram_sp_tb.vhdl"


# Start the simulation
# vopt +acc cache_mem -o top_opt -debugdb
vsim PoC.cache_cpu_tb -voptargs=+acc=bcglnprst+security
#vsim -assertdebug PoC.cache_cpu_tb PoC.cache_cpu_v_wrapper
# vsim -assertdebug -voptargs=+acc PoC.cache_cpu_tb
# PoC.cache_cpu_verification_module
# vsim -assertdebug PoC.cache_mem_tb

# atv log -enable -asserts -recursive /*

# view assertions

# Draw waves
# do wave.do
# Run the simulation
# vcd file wave.vcd
# vcd add -r -optcells cache_cpu_tb:UUT:*
do secwave.do
run -all
# vcd flush

# save the coverage reports
# coverage save coverage.ucdb

# vcover report -assert -detail -output assertion_det.txt coverage.ucdb

