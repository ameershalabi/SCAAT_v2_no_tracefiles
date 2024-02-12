vlib work

set amshal_pkg_dir /home/amshal/pc/Projects/amshal_misc/


# main packages
vcom -2008 -work amshal_misc ${amshal_pkg_dir}/SCAAT_pkg.vhdl 
vcom -2008 -work amshal_misc ${amshal_pkg_dir}/amshal_misc_pkg.vhdl 

#encoders
vcom -2008 -work amshal_misc ${amshal_pkg_dir}/*.vhdl 
# vcom -2008 -work amshal_misc ${amshal_pkg_dir}/OR_ARRAY_32x5_Enc.vhdl 
# vcom -2008 -work amshal_misc ${amshal_pkg_dir}/OR_ARRAY_4x2_Enc.vhdl 
# vcom -2008 -work amshal_misc ${amshal_pkg_dir}/OR_ARRAY_8x3_Enc.vhdl 

# # combinational
# vcom -2008 -work amshal_misc ${amshal_pkg_dir}/DEC_generic.vhdl 
# vcom -2008 -work amshal_misc ${amshal_pkg_dir}/FIFO_generic.vhdl 
# vcom -2008 -work amshal_misc ${amshal_pkg_dir}/MUX_generic.vhdl 
# vcom -2008 -work amshal_misc ${amshal_pkg_dir}/incr_generic.vhdl 
# vcom -2008 -work amshal_misc ${amshal_pkg_dir}/decr_generic.vhdl 

# # register types
# vcom -2008 -work amshal_misc ${amshal_pkg_dir}/RAND_LFSR_generic.vhdl 
# vcom -2008 -work amshal_misc ${amshal_pkg_dir}/RAM_dual_read.vhdl 
# vcom -2008 -work amshal_misc ${amshal_pkg_dir}/REG_generic.vhdl 
# vcom -2008 -work amshal_misc ${amshal_pkg_dir}/SI_SPO_rl_shift_reg_generic.vhdl 
# vcom -2008 -work amshal_misc ${amshal_pkg_dir}/SIPO_rl_shift_reg_generic.vhdl 
# vcom -2008 -work amshal_misc ${amshal_pkg_dir}/SISO_rl_shift_reg_generic.vhdl 
# vcom -2008 -work amshal_misc ${amshal_pkg_dir}/REG_generic_f_rst.vhdl 

# # lateches
# vcom -2008 -work amshal_misc ${amshal_pkg_dir}/SRAM_latch.vhdl 
# vcom -2008 -work amshal_misc ${amshal_pkg_dir}/SRAM_latch_row.vhdl 
# vcom -2008 -work amshal_misc ${amshal_pkg_dir}/SRAM_latch_array.vhdl 

