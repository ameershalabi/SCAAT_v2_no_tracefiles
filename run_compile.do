
vlib PoC
vlib work
# Include files and compile them
do "./PoC_lib_files/PoC_1.do"

vlog -sv -work PoC "bindings.sva"
# vlog -sv -work PoC "../jaspergold/direct_mapped_cache_properties.sva"
vlog -sv -work PoC "direct_mapped_cache_properties_form2.sva"
# vlog -sv -work PoC "../jaspergold/set_associative_cache_properties.sva"
vcom -2008 -work PoC "./PoC_lib_files/cache_cpu.vhdl"

#######AMSHAL
#
set amshal_pkg_dir /home/amshal/pc/Projects/amshal_misc/
set CLD_IRQ_comp /home/amshal/pc/Projects/CLD/

#do "/home/amshal/pc/Projects/amshal_misc/compile_amshal_misc_pkg.do" 
#vcom -2008 -work amshal_pkg_dir ${amshal_pkg_dir}/*.vhdl 

vcom -2008 -work PoC "SCAAT_pkg.vhdl"

vcom -2008 -work PoC "${amshal_pkg_dir}/SCAAT_pkg.vhdl"
vcom -2008 -work PoC "${amshal_pkg_dir}/amshal_misc_pkg.vhdl"

vcom -2008 -work PoC "${amshal_pkg_dir}/*.vhdl"




#vcom -2008 -work PoC "OR_ARRAY_32x5_Enc_no_opt.vhdl"
vlog -work PoC "cache_security.v"
vcom -2008 -work PoC "SCAAT_CAM.vhdl"
vcom -2008 -work PoC "SCAAT_CAM2.vhdl"
vcom -2008 -work PoC "SCAAT_CAM3.vhdl"
vcom -2008 -work PoC "SCAAT_mem3.vhdl"
vcom -2008 -work PoC "SCAAT_mem4.vhdl"
vcom -2008 -work PoC "SCAAT_mem5.vhdl"

vcom -2008 -work PoC "Rand_Gen_LFSR.vhdl"
vcom -2008 -work PoC "SCAAT_unit2.vhdl"
vcom -2008 -work PoC "SCAAT_unit2_R.vhdl"
vcom -2008 -work PoC "SI_FSM.vhdl"

vcom -2008 -work PoC "cache_cpu_SCAAT.vhdl"
#######AMSHAL
do "./PoC_lib_files/PoC_2.do"

#vsim PoC.cache_cpu_tb PoC.cache_cpu_v_wrapper
#vsim PoC.cache_cpu_tb -voptargs=+acc=bcglnprst+security
#vsim -assertdebug PoC.cache_cpu_tb PoC.cache_cpu_v_wrapper
set StdArithNoWarnings 1
set NumericStdNoWarnings 1
# coverage save coverage.ucdb
