
vlib PoC
vlib work
source "./PoC_lib_files/PoC_1.do"

vlog -sv -work PoC "bindings.sva"
vlog -sv -work PoC "direct_mapped_cache_properties_form2.sva"
vcom -2008 -work PoC "./PoC_lib_files/cache_cpu.vhdl"

set amshal_pkg_dir ./amshal_misc/

vcom -2008 -work PoC "SCAAT_pkg.vhdl"

vcom -2008 -work PoC "${amshal_pkg_dir}/SCAAT_pkg.vhdl"
vcom -2008 -work PoC "${amshal_pkg_dir}/amshal_misc_pkg.vhdl"

vcom -2008 -work PoC "${amshal_pkg_dir}/*.vhdl"




vlog -work PoC "cache_security.v"
vcom -2008 -work PoC "SCAAT_CAM.vhdl"
vcom -2008 -work PoC "SCAAT_CAM2.vhdl"
vcom -2008 -work PoC "SCAAT_mem3.vhdl"
vcom -2008 -work PoC "SCAAT_mem4.vhdl"
vcom -2008 -work PoC "SCAAT_mem5.vhdl"
vcom -2008 -work PoC "SCAAT_mem5_4MB.vhdl"

vcom -2008 -work PoC "Rand_Gen_LFSR.vhdl"
vcom -2008 -work PoC "SCAAT_unit2.vhdl"
vcom -2008 -work PoC "SCAAT_unit2_R.vhdl"
vcom -2008 -work PoC "SI_FSM.vhdl"

vcom -2008 -work PoC "cache_cpu_SCAAT.vhdl"

do "./PoC_lib_files/PoC_2.do"

vcom -2008 -work PoC "cache_cpu_wrapper.vhdl"


vcom -2008 -work PoC "cache_cpu_benchmarks_tb_clean.vhdl"

#vsim PoC.cache_cpu_tb -voptargs=+acc
#set StdArithNoWarnings 1
#set NumericStdNoWarnings 1

#add wave -position end sim:/cache_cpu_tb/SCAAT_addr
#add wave -position end sim:/cache_cpu_tb/CPU_RequestGen/output_name
#add wave -position end sim:/cache_cpu_tb/TOTALACCESScounter
#add wave -position end sim:/cache_cpu_tb/attk_active
#add wave -position end sim:/cache_cpu_tb/UUT/SCAAT_tbl2/found_in_SCAAT
#add wave -position end sim:/cache_cpu_tb/UUT/SCAAT_tbl2/found_in_SCAAT_rising_edge

#add wave -position end sim:/cache_cpu_tb/UUT/SCAAT_tbl2/f_rst_sig
#add wave -position end sim:/cache_cpu_tb/UUT/SCAAT_tbl2/countSCAAT


#run -all