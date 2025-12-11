# ============================================================================
# SCRIPT DE WAVEFORM PARA O PROCESSADOR PIPELINE (SD_PDII)
# ============================================================================

onerror {resume}
quietly WaveActivateNextPane {} 0

# ----------------------------------------------------------------------------
# 1. CONTROLE GERAL E DEBUG
# ----------------------------------------------------------------------------
add wave -noupdate -divider "TOP LEVEL & CONTROLE"
add wave -noupdate -label "Clock" -radix binary /tb_pipeline/clock_sg
add wave -noupdate -label "Reset" -radix binary /tb_pipeline/reset_sg
add wave -noupdate -label "Instrução (Texto)" -radix ascii /tb_pipeline/w_mnemonico
add wave -noupdate -label "PC (Decimal)" -radix unsigned /tb_pipeline/w_pc
add wave -noupdate -label "WB Dado (Debug)" -radix decimal /tb_pipeline/w_wb_dado

# ----------------------------------------------------------------------------
# 2. ESTÁGIO IF (INSTRUCTION FETCH)
# ----------------------------------------------------------------------------
add wave -noupdate -divider "ESTÁGIO 1: IF (Fetch)"
add wave -noupdate -label "PC Atual" -radix unsigned /tb_pipeline/inst_Pipeline/pc_current
add wave -noupdate -label "Prox PC" -radix unsigned /tb_pipeline/inst_Pipeline/pc_next
add wave -noupdate -label "Instrução IF" -radix hexadecimal /tb_pipeline/inst_Pipeline/if_instr
add wave -noupdate -color {Orange} -label "Stall PC?" /tb_pipeline/inst_Pipeline/stall_pc

# ----------------------------------------------------------------------------
# 3. REGISTRADOR IF/ID
# ----------------------------------------------------------------------------
add wave -noupdate -divider "PIPE REG: IF/ID"
add wave -noupdate -label "ID PC" -radix unsigned /tb_pipeline/inst_Pipeline/id_pc
add wave -noupdate -label "ID Instr" -radix hexadecimal /tb_pipeline/inst_Pipeline/id_instr
add wave -noupdate -color {Red} -label "Flush IF/ID?" /tb_pipeline/inst_Pipeline/flush_if_id
add wave -noupdate -color {Orange} -label "Stall IF/ID?" /tb_pipeline/inst_Pipeline/stall_if_id

# ----------------------------------------------------------------------------
# 4. ESTÁGIO ID (DECODE)
# ----------------------------------------------------------------------------
add wave -noupdate -divider "ESTÁGIO 2: ID (Decode)"
add wave -noupdate -label "Opcode" -radix binary /tb_pipeline/inst_Pipeline/id_opcode
add wave -noupdate -label "Reg RS (Fonte 1)" -radix unsigned /tb_pipeline/inst_Pipeline/id_rs
add wave -noupdate -label "Reg RT (Fonte 2)" -radix unsigned /tb_pipeline/inst_Pipeline/id_rt
add wave -noupdate -label "Reg RD (Destino)" -radix unsigned /tb_pipeline/inst_Pipeline/id_rd
add wave -noupdate -label "Imediato Ext" -radix decimal /tb_pipeline/inst_Pipeline/id_imm
add wave -noupdate -label "Dado Lido 1" -radix decimal /tb_pipeline/inst_Pipeline/id_data1
add wave -noupdate -label "Dado Lido 2" -radix decimal /tb_pipeline/inst_Pipeline/id_data2
add wave -noupdate -color {Red} -label "Flush ID/EX?" /tb_pipeline/inst_Pipeline/flush_id_ex

# ----------------------------------------------------------------------------
# 5. ESTÁGIO EX (EXECUTE) & FORWARDING (BÔNUS!)
# ----------------------------------------------------------------------------
add wave -noupdate -divider "ESTÁGIO 3: EX + FORWARDING"
add wave -noupdate -label "EX PC" -radix unsigned /tb_pipeline/inst_Pipeline/ex_pc
add wave -noupdate -label "ALU Op" -radix binary /tb_pipeline/inst_Pipeline/ex_ctrl_alu_op

# Sinais Críticos de Forwarding
add wave -noupdate -color {Cornflower Blue} -label "Forward A (00=Reg, 10=Mem, 01=WB)" -radix binary /tb_pipeline/inst_Pipeline/forward_a
add wave -noupdate -color {Cornflower Blue} -label "Forward B (00=Reg, 10=Mem, 01=WB)" -radix binary /tb_pipeline/inst_Pipeline/forward_b

add wave -noupdate -label "ALU In A (Final)" -radix decimal /tb_pipeline/inst_Pipeline/alu_in_a
add wave -noupdate -label "ALU In B (Final)" -radix decimal /tb_pipeline/inst_Pipeline/alu_in_b

add wave -noupdate -label "Resultado ALU" -radix decimal /tb_pipeline/inst_Pipeline/ex_alu_result

add wave -noupdate -color {Yellow} -label "Branch Taken?" /tb_pipeline/inst_Pipeline/branch_taken

# ----------------------------------------------------------------------------
# 6. ESTÁGIO MEM (MEMORY)
# ----------------------------------------------------------------------------
add wave -noupdate -divider "ESTÁGIO 4: MEM"
add wave -noupdate -label "MEM Write?" /tb_pipeline/inst_Pipeline/mem_ctrl_memwrite
add wave -noupdate -label "Endereço Mem" -radix unsigned /tb_pipeline/inst_Pipeline/mem_alu_result
add wave -noupdate -label "Dado Escrito" -radix decimal /tb_pipeline/inst_Pipeline/mem_write_data
add wave -noupdate -label "Dado Lido" -radix decimal /tb_pipeline/inst_Pipeline/mem_read_data

# ----------------------------------------------------------------------------
# 7. ESTÁGIO WB (WRITE BACK) & BANCO DE REGISTRADORES
# ----------------------------------------------------------------------------
add wave -noupdate -divider "ESTÁGIO 5: WB & REG BANK"
add wave -noupdate -label "WB Write?" /tb_pipeline/inst_Pipeline/wb_ctrl_regwrite
add wave -noupdate -label "WB Destino (RD)" -radix unsigned /tb_pipeline/inst_Pipeline/wb_rd
add wave -noupdate -label "WB Dado Final" -radix decimal /tb_pipeline/inst_Pipeline/wb_final_data

# Adiciona o Banco de Registradores Completo para visualização
add wave -noupdate -divider "BANCO DE REGISTRADORES"
add wave -noupdate -label "Registradores" -radix decimal /tb_pipeline/inst_Pipeline/regs

# ----------------------------------------------------------------------------
# CONFIGURAÇÃO FINAL
# ----------------------------------------------------------------------------
configure wave -namecolwidth 220
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update

# Roda a simulação por tempo suficiente
run 2500 ns
wave zoom full
