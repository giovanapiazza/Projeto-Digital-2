# 1. Limpa ondas antigas
delete wave *

# 2. Configurações Globais (TB)
add wave -noupdate -divider "TESTBENCH GLOBAL"
add wave -noupdate -label "Clock" /tb_pipeline/clock_sg
add wave -noupdate -label "Reset" /tb_pipeline/reset_sg
# Essa string é mágica para o debug!
add wave -noupdate -label "Instrução Atual" -color "yellow" /tb_pipeline/w_mnemonico 

# =========================================================
# ESTÁGIO 1: FETCH (IF)
# =========================================================
add wave -noupdate -divider "STAGE 1: FETCH (IF)"
add wave -noupdate -group "IF Stage" -radix unsigned -label "PC Atual" /tb_pipeline/inst_Pipeline/pc_current
add wave -noupdate -group "IF Stage" -radix unsigned -label "PC Next" /tb_pipeline/inst_Pipeline/pc_next
add wave -noupdate -group "IF Stage" -radix hex -label "Instruction (Hex)" /tb_pipeline/inst_Pipeline/if_instr
add wave -noupdate -group "IF Stage" -color "red" -label "Stall PC" /tb_pipeline/inst_Pipeline/stall_pc

# =========================================================
# ESTÁGIO 2: DECODE (ID)
# =========================================================
add wave -noupdate -divider "STAGE 2: DECODE (ID)"
add wave -noupdate -group "ID Stage" -radix hex -label "Instr (ID)" /tb_pipeline/inst_Pipeline/id_instr
add wave -noupdate -group "ID Stage" -radix unsigned -label "RS (Fonte 1)" /tb_pipeline/inst_Pipeline/id_rs
add wave -noupdate -group "ID Stage" -radix unsigned -label "RT (Fonte 2)" /tb_pipeline/inst_Pipeline/id_rt
add wave -noupdate -group "ID Stage" -radix unsigned -label "RD (Destino)" /tb_pipeline/inst_Pipeline/id_rd
add wave -noupdate -group "ID Stage" -radix decimal -label "Imediato" /tb_pipeline/inst_Pipeline/id_imm
add wave -noupdate -group "ID Stage" -radix decimal -label "Leitura Reg 1" /tb_pipeline/inst_Pipeline/id_data1
add wave -noupdate -group "ID Stage" -radix decimal -label "Leitura Reg 2" /tb_pipeline/inst_Pipeline/id_data2
add wave -noupdate -group "ID Stage" -color "magenta" -label "Stall IF/ID" /tb_pipeline/inst_Pipeline/stall_if_id
add wave -noupdate -group "ID Stage" -color "magenta" -label "Flush ID/EX" /tb_pipeline/inst_Pipeline/flush_id_ex

# =========================================================
# ESTÁGIO 3: EXECUTE (EX)
# =========================================================
add wave -noupdate -divider "STAGE 3: EXECUTE (EX)"
add wave -noupdate -group "EX Stage" -radix unsigned -label "EX PC" /tb_pipeline/inst_Pipeline/ex_pc
add wave -noupdate -group "EX Stage" -color "orange" -label "ALU Op" /tb_pipeline/inst_Pipeline/ex_ctrl_alu_op
add wave -noupdate -group "EX Stage" -label "Forward A" /tb_pipeline/inst_Pipeline/forward_a
add wave -noupdate -group "EX Stage" -label "Forward B" /tb_pipeline/inst_Pipeline/forward_b
add wave -noupdate -group "EX Stage" -radix decimal -label "ALU Input A" /tb_pipeline/inst_Pipeline/alu_in_a
add wave -noupdate -group "EX Stage" -radix decimal -label "ALU Input B" /tb_pipeline/inst_Pipeline/alu_in_b
add wave -noupdate -group "EX Stage" -radix decimal -label "Resultado ALU" /tb_pipeline/inst_Pipeline/ex_alu_result
add wave -noupdate -group "EX Stage" -color "cyan" -label "Branch Taken?" /tb_pipeline/inst_Pipeline/branch_taken

# =========================================================
# ESTÁGIO 4: MEMORY (MEM)
# =========================================================
add wave -noupdate -divider "STAGE 4: MEMORY (MEM)"
add wave -noupdate -group "MEM Stage" -label "Mem Write En" /tb_pipeline/inst_Pipeline/mem_ctrl_memwrite
add wave -noupdate -group "MEM Stage" -label "Mem Read En" /tb_pipeline/inst_Pipeline/mem_ctrl_memread
add wave -noupdate -group "MEM Stage" -radix unsigned -label "Address (ALU Res)" /tb_pipeline/inst_Pipeline/mem_alu_result
add wave -noupdate -group "MEM Stage" -radix decimal -label "Write Data" /tb_pipeline/inst_Pipeline/mem_write_data
add wave -noupdate -group "MEM Stage" -radix decimal -label "Read Data" /tb_pipeline/inst_Pipeline/mem_read_data

# =========================================================
# ESTÁGIO 5: WRITE BACK (WB)
# =========================================================
add wave -noupdate -divider "STAGE 5: WRITE BACK (WB)"
add wave -noupdate -group "WB Stage" -label "Reg Write En" /tb_pipeline/inst_Pipeline/wb_ctrl_regwrite
add wave -noupdate -group "WB Stage" -radix unsigned -label "Reg Destino" /tb_pipeline/inst_Pipeline/wb_rd
add wave -noupdate -group "WB Stage" -radix decimal -label "DADO FINAL ESCRITO" /tb_pipeline/inst_Pipeline/wb_final_data

# =========================================================
# BANCO DE REGISTRADORES (DEBUG)
# =========================================================
add wave -noupdate -divider "REGISTERS (R0-R15)"
# Mostra o array de registradores inteiro para ver os valores mudando
add wave -noupdate -radix decimal /tb_pipeline/inst_Pipeline/regs

# Configura a view para caber tudo
configure wave -namecolwidth 200
configure wave -valuecolwidth 100
wave zoom full
