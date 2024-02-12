if [file exists work] {
    vdel -lib ./work -all
}

do "./compile_amshal_misc_pkg.do" 

vsim amshal_misc.amshal_misc_tb
#vsim -coverage -assertdebug amshal_misc.amshal_misc_tb

#add wave -position end sim/:amshal_misc_tb:*
add wave -position end sim/:amshal_misc_tb:cell_A_4_test:*
#add wave -position end sim/:amshal_misc_tb:cell:*
#add wave -position end sim/:amshal_misc_tb:cell2:*

run 150ns
#run -all
