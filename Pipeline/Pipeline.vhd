library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Pipeline is
    port(
        clock          : in std_logic;
        reset          : in std_logic;
        -- Debug Outputs for Waveform Validation
        debug_pc       : out std_logic_vector(7 downto 0);
        debug_instrucao: out std_logic_vector(23 downto 0); -- Instruction at ID stage
        debug_wb_dado  : out std_logic_vector(15 downto 0)  -- Data written at WB stage
    );
end entity;

architecture pipeline_arch of Pipeline is

    -- Memory and Register Types
    type t_mem_p is array (0 to 255) of std_logic_vector(23 downto 0);
    type t_mem_d is array (0 to 255) of std_logic_vector(15 downto 0); -- 16-bit Data Memory
    type t_reg_bank is array (0 to 15) of std_logic_vector(15 downto 0); -- 16 registers x 16 bits

    signal mem_p : t_mem_p;
    signal mem_d : t_mem_d := (others => (others => '0'));
    signal regs  : t_reg_bank := (others => (others => '0'));

    -- ================= PIPELINE SIGNALS ================= --
    
    -- STAGE 1: IF (Instruction Fetch)
    signal pc_current      : unsigned(7 downto 0) := (others => '0');
    signal pc_next         : unsigned(7 downto 0);
    signal if_instr        : std_logic_vector(23 downto 0);
    signal stall_pc        : std_logic := '0';

    -- REGISTER IF/ID
    signal id_pc           : unsigned(7 downto 0);
    signal id_instr        : std_logic_vector(23 downto 0);
    signal flush_if_id     : std_logic := '0';
    signal stall_if_id     : std_logic := '0';

    -- STAGE 2: ID (Instruction Decode)
    signal id_opcode       : std_logic_vector(3 downto 0);
    signal id_rs, id_rt, id_rd : std_logic_vector(3 downto 0);
    signal id_imm          : std_logic_vector(15 downto 0);
    signal id_data1, id_data2 : std_logic_vector(15 downto 0);
    
    -- ID Control Signals
    signal ctrl_wb_regwrite: std_logic;
    signal ctrl_mem_write  : std_logic;
    signal ctrl_mem_read   : std_logic;
    signal ctrl_branch     : std_logic;
    signal ctrl_alu_op     : std_logic_vector(3 downto 0);
    signal ctrl_alu_src    : std_logic; -- 0:Reg, 1:Imm

    -- REGISTER ID/EX
    signal ex_pc           : unsigned(7 downto 0);
    signal ex_data1, ex_data2 : std_logic_vector(15 downto 0);
    signal ex_imm          : std_logic_vector(15 downto 0);
    signal ex_rs, ex_rt, ex_rd : std_logic_vector(3 downto 0);
    -- ID/EX Controls
    signal ex_ctrl_regwrite: std_logic;
    signal ex_ctrl_memwrite: std_logic;
    signal ex_ctrl_memread : std_logic;
    signal ex_ctrl_branch  : std_logic;
    signal ex_ctrl_alu_op  : std_logic_vector(3 downto 0);
    signal ex_ctrl_alusrc  : std_logic;
    signal flush_id_ex     : std_logic := '0';

    -- STAGE 3: EX (Execute)
    signal alu_in_a, alu_in_b : std_logic_vector(15 downto 0);
    signal alu_in_b_mux    : std_logic_vector(15 downto 0);
    signal ex_alu_result   : std_logic_vector(15 downto 0);
    signal forward_a, forward_b : std_logic_vector(1 downto 0); -- Forwarding Signals
    signal branch_target   : unsigned(7 downto 0);
    signal branch_taken    : std_logic;

    -- REGISTER EX/MEM
    signal mem_alu_result  : std_logic_vector(15 downto 0);
    signal mem_write_data  : std_logic_vector(15 downto 0);
    signal mem_rd          : std_logic_vector(3 downto 0);
    -- EX/MEM Controls
    signal mem_ctrl_regwrite: std_logic;
    signal mem_ctrl_memwrite: std_logic;
    signal mem_ctrl_memread : std_logic;

    -- STAGE 4: MEM (Memory Access)
    signal mem_read_data   : std_logic_vector(15 downto 0);

    -- REGISTER MEM/WB
    signal wb_read_data    : std_logic_vector(15 downto 0);
    signal wb_alu_result   : std_logic_vector(15 downto 0);
    signal wb_rd           : std_logic_vector(3 downto 0);
    -- MEM/WB Controls
    signal wb_ctrl_regwrite: std_logic;
    signal wb_ctrl_memread : std_logic; -- To know if it is Load

    -- STAGE 5: WB (Write Back)
    signal wb_final_data   : std_logic_vector(15 downto 0);

begin

    -- ==========================================================
    -- 0. LOAD PROGRAM (TESTE DE FORWARDING)
    -- ==========================================================
    process(reset)
    begin
        if reset = '1' then
             -- 0: LDI R1, 15  (Carrega 15 no R1)
             mem_p(0) <= "0000" & "0001" & "0000" & "0000" & "00001111";
             
             -- 1: LDI R2, 10  (Carrega 10 no R2)
             mem_p(1) <= "0000" & "0010" & "0000" & "0000" & "00001010";
             
             -- 2: SUB R3, R1, R2  (R3 = 15 - 10 = 5)
             -- O resultado (5) é gerado no estágio EX desta instrução.
             mem_p(2) <= "0010" & "0011" & "0001" & "0010" & "00000000";
             
             -- 3: ADD R4, R3, R1  (R4 = 5 + 15 = 20)
             -- *** TESTE DE FORWARDING ***
             -- Esta instrução pede o R3 enquanto a SUB ainda não gravou no WB.
             -- O hardware deve fazer Forwarding do EX da anterior para o EX desta.
             mem_p(3) <= "0001" & "0100" & "0011" & "0001" & "00000000";
             
             -- 4: JMP 4 (Loop Infinito para encerrar)
             mem_p(4) <= "0100" & "0000" & "0000" & "0000" & "00000100";
             
             -- Limpa o resto da memória
             for i in 5 to 255 loop mem_p(i) <= (others => '0'); end loop;
        end if;
    end process;

    -- ==========================================================
    -- STAGE 1: IF (FETCH)
    -- ==========================================================
    if_instr <= mem_p(to_integer(pc_current));

    -- PC Mux (Branch Target vs PC+1)
    pc_next <= branch_target when branch_taken = '1' else pc_current + 1;

    process(clock, reset)
    begin
        if reset = '1' then
            pc_current <= (others => '0');
        elsif rising_edge(clock) then
            if stall_pc = '0' then -- Freeze PC on Stall
                pc_current <= pc_next;
            end if;
        end if;
    end process;

    -- IF/ID REGISTER
    process(clock, reset)
    begin
        if reset = '1' then
            id_pc <= (others => '0');
            id_instr <= (others => '0');
        elsif rising_edge(clock) then
            if flush_if_id = '1' then
                id_instr <= (others => '0'); -- Insert NOP on Flush
            elsif stall_if_id = '0' then
                id_pc <= pc_current;
                id_instr <= if_instr;
            end if;
        end if;
    end process;

    -- ==========================================================
    -- STAGE 2: ID (DECODE)
    -- ==========================================================
    id_opcode <= id_instr(23 downto 20);
    id_rd     <= id_instr(19 downto 16); -- Destination
    id_rs     <= id_instr(15 downto 12); -- Source 1
    id_rt     <= id_instr(11 downto 8);  -- Source 2
    id_imm    <= std_logic_vector(resize(signed(id_instr(7 downto 0)), 16)); -- Sign Extend

    id_data1 <= regs(to_integer(unsigned(id_rs)));
    id_data2 <= regs(to_integer(unsigned(id_rt)));

    -- Simple Control Unit
    process(id_opcode)
    begin
        ctrl_wb_regwrite <= '0'; ctrl_mem_write <= '0'; 
        ctrl_mem_read <= '0'; ctrl_branch <= '0'; ctrl_alu_src <= '0';
        
        case id_opcode is
            when "0000" => ctrl_wb_regwrite <= '1'; ctrl_alu_src <= '1'; -- LDI
            when "0001" | "0010" | "0011" => ctrl_wb_regwrite <= '1'; -- ADD, SUB, MUL
            when "0100" | "0101" | "0110" => ctrl_branch <= '1';      -- JMP, BEQ, BNE
            when "0111" => ctrl_mem_write <= '1'; ctrl_alu_src <= '1'; -- SW
            when "1000" | "1001" | "1010" => ctrl_wb_regwrite <= '1'; ctrl_alu_src <= '1'; -- ADDI, SUBI, MULI
            when "1011" => ctrl_wb_regwrite <= '1'; ctrl_mem_read <= '1'; ctrl_alu_src <= '1'; -- LW
            when others => null;
        end case;
    end process;
    ctrl_alu_op <= id_opcode;

    -- HAZARD DETECTION UNIT (Load-Use Hazard)
    -- Detects if the instruction in ID needs a value being loaded by the instruction in EX
    process(id_rs, id_rt, ex_ctrl_memread, ex_rd)
    begin
        stall_pc <= '0'; stall_if_id <= '0'; flush_id_ex <= '0';
        
        if (ex_ctrl_memread = '1') and ((ex_rd = id_rs) or (ex_rd = id_rt)) and (ex_rd /= "0000") then
            stall_pc <= '1';        -- Freeze PC
            stall_if_id <= '1';     -- Freeze IF/ID
            flush_id_ex <= '1';     -- Flush ID/EX (Insert Bubble)
        end if;
    end process;

    -- ID/EX REGISTER
    process(clock, reset)
    begin
        if reset = '1' then
            ex_ctrl_regwrite <= '0'; ex_ctrl_memwrite <= '0'; ex_ctrl_branch <= '0';
        elsif rising_edge(clock) then
            if flush_id_ex = '1' then
                ex_ctrl_regwrite <= '0'; ex_ctrl_memwrite <= '0'; ex_ctrl_branch <= '0'; ex_ctrl_memread <= '0';
            else
                ex_pc <= id_pc;
                ex_data1 <= id_data1; ex_data2 <= id_data2; ex_imm <= id_imm;
                ex_rs <= id_rs; ex_rt <= id_rt; ex_rd <= id_rd;
                -- Pass Controls
                ex_ctrl_regwrite <= ctrl_wb_regwrite; ex_ctrl_memwrite <= ctrl_mem_write;
                ex_ctrl_memread <= ctrl_mem_read; ex_ctrl_branch <= ctrl_branch;
                ex_ctrl_alu_op <= ctrl_alu_op; ex_ctrl_alusrc <= ctrl_alu_src;
            end if;
        end if;
    end process;

    -- ==========================================================
    -- STAGE 3: EX (EXECUTE)
    -- ==========================================================
    
    -- FORWARDING UNIT
    -- Solves Data Hazards by fetching data from MEM or WB stages
    process(ex_rs, ex_rt, mem_rd, mem_ctrl_regwrite, wb_rd, wb_ctrl_regwrite)
    begin
        forward_a <= "00"; forward_b <= "00";
        -- Forwarding from MEM stage
        if (mem_ctrl_regwrite='1') and (mem_rd/="0000") and (mem_rd=ex_rs) then forward_a <= "10"; end if;
        if (mem_ctrl_regwrite='1') and (mem_rd/="0000") and (mem_rd=ex_rt) then forward_b <= "10"; end if;
        -- Forwarding from WB stage
        if (wb_ctrl_regwrite='1') and (wb_rd/="0000") and (wb_rd=ex_rs) then forward_a <= "01"; end if;
        if (wb_ctrl_regwrite='1') and (wb_rd/="0000") and (wb_rd=ex_rt) then forward_b <= "01"; end if;
    end process;

    -- ALU Input Muxes (Forwarding Logic)
    alu_in_a <= ex_data1 when forward_a="00" else mem_alu_result when forward_a="10" else wb_final_data;
    alu_in_b_mux <= ex_data2 when forward_b="00" else mem_alu_result when forward_b="10" else wb_final_data;
    
    -- ALU Source B Mux (Immediate vs Register)
    alu_in_b <= alu_in_b_mux when ex_ctrl_alusrc='0' else ex_imm;

    -- ALU Logic
    process(ex_ctrl_alu_op, alu_in_a, alu_in_b)
    begin
        case ex_ctrl_alu_op is
            when "0000" => ex_alu_result <= alu_in_b; -- LDI
            when "0001" | "0111" | "1000" | "1011" => -- ADD, SW, ADDI, LW
                           ex_alu_result <= std_logic_vector(signed(alu_in_a) + signed(alu_in_b));
            when "0010" | "1001" => -- SUB, SUBI
                           ex_alu_result <= std_logic_vector(signed(alu_in_a) - signed(alu_in_b));
            when "0011" | "1010" => -- MUL, MULI
                           ex_alu_result <= std_logic_vector(resize(signed(alu_in_a) * signed(alu_in_b), 16));
            when others => ex_alu_result <= (others => '0');
        end case;
    end process;

    -- Branch Resolution (Calculated at EX stage)
    process(ex_ctrl_alu_op, alu_in_a, alu_in_b_mux, ex_imm, ex_pc)
    begin
        branch_taken <= '0';
        branch_target <= (others => '0');
        if ex_ctrl_branch = '1' then
            -- Default target is PC + 1 + Offset
            branch_target <= ex_pc + 1 + unsigned(resize(signed(ex_imm(7 downto 0)), 8));
            
            if ex_ctrl_alu_op = "0100" then -- JMP (Absolute)
                branch_taken <= '1'; 
                branch_target <= unsigned(ex_imm(7 downto 0));
            elsif ex_ctrl_alu_op = "0101" and alu_in_a = alu_in_b_mux then -- BEQ
                branch_taken <= '1'; 
            elsif ex_ctrl_alu_op = "0110" and alu_in_a /= alu_in_b_mux then -- BNE
                branch_taken <= '1'; 
            end if;
        end if;
    end process;

    -- Flush pipeline if branch taken
    flush_if_id <= branch_taken;

    -- EX/MEM REGISTER
    process(clock, reset)
    begin
        if reset = '1' then mem_ctrl_regwrite <= '0'; mem_ctrl_memwrite <= '0';
        elsif rising_edge(clock) then
            if branch_taken = '1' then -- Flush EX/MEM on Branch
                mem_ctrl_regwrite <= '0'; mem_ctrl_memwrite <= '0';
            else
                mem_alu_result <= ex_alu_result;
                mem_write_data <= alu_in_b_mux; -- Store Data
                mem_rd <= ex_rd;
                mem_ctrl_regwrite <= ex_ctrl_regwrite;
                mem_ctrl_memwrite <= ex_ctrl_memwrite;
                mem_ctrl_memread <= ex_ctrl_memread;
            end if;
        end if;
    end process;

    -- ==========================================================
    -- STAGE 4: MEM (MEMORY)
    -- ==========================================================
    process(clock)
    begin
        if rising_edge(clock) then
            if mem_ctrl_memwrite = '1' then
                mem_d(to_integer(unsigned(mem_alu_result(7 downto 0)))) <= mem_write_data;
            end if;
        end if;
    end process;
    -- Asynchronous Read
    mem_read_data <= mem_d(to_integer(unsigned(mem_alu_result(7 downto 0))));

    -- MEM/WB REGISTER
    process(clock, reset)
    begin
        if reset = '1' then wb_ctrl_regwrite <= '0';
        elsif rising_edge(clock) then
            wb_read_data <= mem_read_data;
            wb_alu_result <= mem_alu_result;
            wb_rd <= mem_rd;
            wb_ctrl_regwrite <= mem_ctrl_regwrite;
            wb_ctrl_memread <= mem_ctrl_memread;
        end if;
    end process;

    -- ==========================================================
    -- STAGE 5: WB (WRITE BACK)
    -- ==========================================================
    wb_final_data <= wb_read_data when wb_ctrl_memread = '1' else wb_alu_result;

    process(clock)
    begin
        if rising_edge(clock) then
            if wb_ctrl_regwrite = '1' and unsigned(wb_rd) /= 0 then
                regs(to_integer(unsigned(wb_rd))) <= wb_final_data;
            end if;
        end if;
    end process;

    -- Connect Debug Signals
    debug_pc <= std_logic_vector(pc_current);
    debug_instrucao <= id_instr;
    debug_wb_dado <= wb_final_data;

end pipeline_arch;
