
vlib PoC

# Include files and compile them
do "./PoC_lib_files/PoC_1.do"


vlib work

vcom -2008 -work PoC "mem_model_fsm.vhdl"
#######AMSHAL

do "./PoC_lib_files/PoC_2.do"

vcom -2008 -work PoC "cache_cpu_memModel_tb.vhdl"

vsim -assertdebug -vopt -debugDB PoC.cache_cpu_memModel_tb
#vsim PoC.cache_cpu_tb -voptargs=+acc=bcglnprst+security
#vsim -assertdebug PoC.cache_cpu_tb PoC.cache_cpu_v_wrapper
set StdArithNoWarnings 1
set NumericStdNoWarnings 1
add wave -position insertpoint sim/:cache_cpu_memmodel_tb:UUT_with:*
