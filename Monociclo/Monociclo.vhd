library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Monociclo is
    port(
        clock          : in std_logic;
        reset          : in std_logic;
        -- Saídas de Debug (para visualizar no Waveform)
        debug_pc       : out std_logic_vector(7 downto 0);
        debug_instrucao: out std_logic_vector(23 downto 0);
        debug_reg_dest : out std_logic_vector(15 downto 0); -- Valor escrito no Reg Destino
        debug_source0  : out std_logic_vector(15 downto 0); -- Valor lido do Reg 1
        debug_source1  : out std_logic_vector(15 downto 0)  -- Valor lido do Reg 2
    );
end entity;

architecture behaviour of Monociclo is

    -- Definições de Memórias e Registradores
    -- Memória de Instruções: 256 posições x 24 bits
    type t_mem_p is array (0 to 255) of std_logic_vector(23 downto 0);
    
    -- Memória de Dados: 256 posições x 16 bits (Requisito: Dados de 16 bits)
    type t_mem_d is array (0 to 255) of std_logic_vector(15 downto 0);
    
    -- Banco de Registradores: 16 regs x 16 bits
    type t_reg_bank is array (0 to 15) of std_logic_vector(15 downto 0);

    signal mem_p : t_mem_p;
    signal mem_d : t_mem_d := (others => (others => '0'));
    signal regs  : t_reg_bank := (others => (others => '0'));

    -- Sinais Internos
    signal pc          : unsigned(7 downto 0) := (others => '0');
    signal instrucao   : std_logic_vector(23 downto 0);
    
    -- Decodificação
    signal op_code     : std_logic_vector(3 downto 0);
    signal reg_dest_idx: std_logic_vector(3 downto 0);
    signal reg_op0_idx : std_logic_vector(3 downto 0);
    signal reg_op1_idx : std_logic_vector(3 downto 0);
    signal imediato    : std_logic_vector(7 downto 0);
    
    -- Extensão de Sinal
    signal imm_extended    : std_logic_vector(15 downto 0);

    -- Dados Operandos e ULA
    signal source0     : std_logic_vector(15 downto 0);
    signal source1     : std_logic_vector(15 downto 0);
    signal ula_out     : std_logic_vector(15 downto 0);
    signal mem_read_data: std_logic_vector(15 downto 0);
    
    -- Sinais de Controle
    signal is_branch_taken : std_logic;
    signal write_enable    : std_logic;
    signal mem_write       : std_logic;

begin

    -- 1. Inicialização da Memória de Programa (Hardcoded para Validação)
    -- Roteiro: Loop, Aritmética (ADD, MUL), Memória (SW, LW)
    process(reset)
    begin
        if reset = '1' then
            -- FORMATO: OP(4) | DEST(4) | SRC1(4) | SRC2(4) | IMM(8)
            
            -- 0: LDI R1, 0      (Acumulador = 0)
            mem_p(0) <= "0000" & "0001" & "0000" & "0000" & "00000000";
            
            -- 1: LDI R2, 1      (Incremento = 1)
            mem_p(1) <= "0000" & "0010" & "0000" & "0000" & "00000001";
            
            -- 2: LDI R3, 5      (Limite do Loop = 5)
            mem_p(2) <= "0000" & "0011" & "0000" & "0000" & "00000101";
            
            -- 3: ADDI R4, R0, 100 (Endereço Base da Memória = 100)
            mem_p(3) <= "1000" & "0100" & "0000" & "0000" & "01100100";

            -- === INICIO DO LOOP (PC=4) ===
            
            -- 4: ADD R1, R1, R2 (R1 = R1 + 1)
            mem_p(4) <= "0001" & "0001" & "0001" & "0010" & "00000000";
            
            -- 5: MUL R5, R1, R2 (Teste de MUL)
            mem_p(5) <= "0011" & "0101" & "0001" & "0010" & "00000000";
            
            -- 6: SW R1, 100 (Salva R1 na memória posição 100)
            -- Nota: Usa o imediato '100' como endereço direto neste exemplo simples
            mem_p(6) <= "0111" & "0000" & "0001" & "0000" & "01100100";
            
            -- 7: LW R6, 100 (Carrega da memória 100 para R6)
            mem_p(7) <= "1011" & "0110" & "0000" & "0000" & "01100100";
            
            -- 8: BNE R1, R3, -4 (Se R1 != 5, salta para PC 4)
            -- Offset -5 (FB em hex) pois PC+1 = 9, 9-5 = 4.
            mem_p(8) <= "0110" & "0000" & "0001" & "0011" & "11111011";
            
            -- 9: JMP 9 (Loop infinito ao terminar)
            mem_p(9) <= "0100" & "0000" & "0000" & "0000" & "00001001";
            
            -- Preenche o resto com 0
            for i in 10 to 255 loop
                mem_p(i) <= (others => '0');
            end loop;
        end if;
    end process;

    -- 2. Fetch (Busca)
    instrucao <= mem_p(to_integer(pc));

    -- 3. Decode (Decodificação)
    op_code      <= instrucao(23 downto 20);
    reg_dest_idx <= instrucao(19 downto 16);
    reg_op0_idx  <= instrucao(15 downto 12);
    reg_op1_idx  <= instrucao(11 downto 8);
    imediato     <= instrucao(7 downto 0);
    
    -- Extensão de sinal (8 bits -> 16 bits)
    imm_extended <= std_logic_vector(resize(signed(imediato), 16));

    -- Leitura do Banco de Registradores
    source0 <= regs(to_integer(unsigned(reg_op0_idx)));
    source1 <= regs(to_integer(unsigned(reg_op1_idx)));

    -- Leitura da Memória de Dados (Para instrução LW)
    mem_read_data <= mem_d(to_integer(unsigned(imediato)));

    -- 4. Execute (ULA e Controle)
    process(op_code, source0, source1, imm_extended, mem_read_data, imediato)
    begin
        -- Valores padrão
        ula_out <= (others => '0');
        mem_write <= '0';
        write_enable <= '1'; -- Habilita escrita no Reg por padrão

        case op_code is
            when "0000" => -- LDI (Load Immediate)
                ula_out <= imm_extended;
            
            when "0001" => -- ADD
                ula_out <= std_logic_vector(signed(source0) + signed(source1));
                
            when "0010" => -- SUB
                ula_out <= std_logic_vector(signed(source0) - signed(source1));
                
            when "0011" => -- MUL (Resultado truncado em 16 bits)
                ula_out <= std_logic_vector(resize(signed(source0) * signed(source1), 16));
                
            when "0100" => -- JMP
                write_enable <= '0'; -- Não escreve em reg
                
            when "0101" => -- BEQ
                write_enable <= '0';
                
            when "0110" => -- BNE
                write_enable <= '0';
                
            when "0111" => -- SW (Store Word)
                mem_write <= '1';
                write_enable <= '0';
                
            when "1000" => -- ADDI
                ula_out <= std_logic_vector(signed(source0) + signed(imm_extended));
                
            when "1001" => -- SUBI
                ula_out <= std_logic_vector(signed(source0) - signed(imm_extended));
                
            when "1010" => -- MULI
                ula_out <= std_logic_vector(resize(signed(source0) * signed(imm_extended), 16));
                
            when "1011" => -- LW (Load Word)
                ula_out <= mem_read_data; 
                
            when others =>
                write_enable <= '0';
        end case;
    end process;

    -- Lógica de Decisão de Branch
    process(op_code, source0, source1)
    begin
        is_branch_taken <= '0';
        if op_code = "0101" and (source0 = source1) then -- BEQ
            is_branch_taken <= '1';
        elsif op_code = "0110" and (source0 /= source1) then -- BNE
            is_branch_taken <= '1';
        end if;
    end process;

    -- 5. Processo Sincrono (Atualização de PC, Registradores e Memória)
    process(clock, reset)
    begin
        if reset = '1' then
            pc <= (others => '0');
            regs <= (others => (others => '0'));
            -- Memória de dados pode ser resetada ou não, aqui mantemos
        elsif rising_edge(clock) then
            
            -- Atualização do PC
            if op_code = "0100" then -- JMP (Absoluto)
                pc <= unsigned(imediato);
            elsif is_branch_taken = '1' then -- Branch (Relativo ao PC)
                -- PC = PC + 1 + Offset (Imediato com sinal)
                pc <= pc + 1 + unsigned(resize(signed(imediato), 8));
            else
                pc <= pc + 1;
            end if;

            -- Escrita na Memória de Dados (SW)
            if mem_write = '1' then
                mem_d(to_integer(unsigned(imediato))) <= source0; 
            end if;

            -- Escrita no Banco de Registradores
            -- Reg 0 travado em Zero (Reg0 não pode ser escrito)
            if write_enable = '1' and unsigned(reg_dest_idx) /= 0 then
                regs(to_integer(unsigned(reg_dest_idx))) <= ula_out;
            end if;
            
        end if;
    end process;

    -- Atribuição das saídas de debug
    debug_pc        <= std_logic_vector(pc);
    debug_instrucao <= instrucao;
    debug_reg_dest  <= regs(to_integer(unsigned(reg_dest_idx)));
    debug_source0   <= source0;
    debug_source1   <= source1;

end behaviour;


