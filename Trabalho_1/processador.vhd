library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity processador is
    port(
        clock: in std_logic;
        reset: in std_logic;
        out0: out std_logic_vector(7 downto 0)
    );
end entity;

architecture behaviour of processador is


    -- FORMATO DA  INSTRUÇAO --
    -- 4 BITS - OPCODE
    -- 4 BITS - REG 1
    -- 4 BITS - REG 2
    -- 4 BITS - REG DEST
    -- 8 BITS - ENDEREÇO / IMEDIATO


    type t_mem_p is array (integer range 0 to 255) of std_logic_vector(23 downto 0);
    type t_mem_d is array (integer range 0 to 255) of std_logic_vector(7 downto 0);
    
    signal mem_p: t_mem_p;
    signal mem_d: t_mem_d;

    signal instrucao: std_logic_vector(23 downto 0);

    signal op_code: std_logic_vector(3 downto 0);
    signal reg_op0: std_logic_vector(3 downto 0);
    signal reg_op1: std_logic_vector(3 downto 0);
    signal reg_dest: std_logic_vector(3 downto 0);
    signal imediato: std_logic_vector(7 downto 0);

    signal pc: std_logic_vector(7 downto 0);

    signal F_jump: std_logic;
    signal F_equal: std_logic;
    signal F_regwrite: std_logic;
    signal F_memwrite: std_logic;

    signal source0: std_logic_vector(7 downto 0);
    signal source1: std_logic_vector(7 downto 0);

    signal temp_mult: std_logic_vector(15 downto 0);

    signal ula: std_logic_vector(7 downto 0);

    signal en_0: std_logic;
    signal en_1: std_logic;
    signal en_2: std_logic;
    signal en_3: std_logic;
    signal en_4: std_logic;
    signal en_5: std_logic;
    signal en_6: std_logic;
    signal en_7: std_logic;
    signal en_8: std_logic;
    signal en_9: std_logic;
    signal en_10: std_logic;
    signal en_11: std_logic;
    signal en_12: std_logic;
    signal en_13: std_logic;
    signal en_14: std_logic;
    signal en_15: std_logic;

    signal reg_0: std_logic_vector(7 downto 0);
    signal reg_1: std_logic_vector(7 downto 0);
    signal reg_2: std_logic_vector(7 downto 0);
    signal reg_3: std_logic_vector(7 downto 0);
    signal reg_4: std_logic_vector(7 downto 0);
    signal reg_5: std_logic_vector(7 downto 0);
    signal reg_6: std_logic_vector(7 downto 0);
    signal reg_7: std_logic_vector(7 downto 0);
    signal reg_8: std_logic_vector(7 downto 0);
    signal reg_9: std_logic_vector(7 downto 0);
    signal reg_10: std_logic_vector(7 downto 0);
    signal reg_11: std_logic_vector(7 downto 0);
    signal reg_12: std_logic_vector(7 downto 0);
    signal reg_13: std_logic_vector(7 downto 0);
    signal reg_14: std_logic_vector(7 downto 0);
    signal reg_15: std_logic_vector(7 downto 0);




begin

    mem_p(0) <= "000000000000000000001111";
    mem_p(1) <= "000000010000000000001001";
    mem_p(2) <= "000100100000000100000000";
    mem_p(3) <= "001000110010000000000000";
    mem_p(4) <= "010000000000000000000110";
    mem_p(5) <= "000000000000000000000000";
    mem_p(6) <= "001101110000000100000000";
    mem_p(7) <= "100001010000000000001111";
    mem_p(8) <= "011100000001000000000000";
    mem_p(9) <= "011000000000000100001011";
    mem_p(10) <= "011100000001000000000001";
    mem_p(11) <= "000000010000000000001111";
    mem_p(12) <= "010100000000000100010011";
    mem_p(13) <= "011100000001000000000000";
    mem_p(14) <= "011100000001000000000000";
    mem_p(15) <= "011100000001000000000000";
    mem_p(16) <= "011100000001000000000000";
    mem_p(17) <= "011100000001000000000000";
    mem_p(18) <= "011100000001000000000000";
    mem_p(19) <= "000011110000000011111111";

    -------- BUSCA/DECOD DA INSTRUÇÃO ---------------------------

    instrucao <= mem_p(to_integer(signed(pc)));

    op_code <= instrucao(23 downto 20);
    reg_dest <= instrucao(19 downto 16);
    reg_op0 <= instrucao(15 downto 12);
    reg_op1 <= instrucao(11 downto 8);
    imediato <= instrucao(7 downto 0);

    ------------------------------  FLAGS  ----------------------

    F_jump <= '1' when (op_code = "0100") or (op_code = "0101" and F_equal = '1') or (op_code = "0110" and F_equal = '0') else
        
        '0';

    F_equal <= '1' when (source0 = source1) else
        
        '0';
        
    F_memwrite <= '1' when (op_code = "0111") else
        
        '0';

    F_regwrite <= '0' when (F_jump = '1') or (F_memwrite = '1') else
        
        '1';

 
    ------------- LEITURA DOS REGS PARA OP ----------------------

    source0 <= reg_0 when reg_op0 = "0000" else
        reg_1 when reg_op0 = "0001" else
        reg_2 when reg_op0 = "0010" else
        reg_3 when reg_op0 = "0011" else
        reg_4 when reg_op0 = "0100" else
        reg_5 when reg_op0 = "0101" else
        reg_6 when reg_op0 = "0110" else
        reg_7 when reg_op0 = "0111" else
        reg_8 when reg_op0 = "1000" else
        reg_9 when reg_op0 = "1001" else
        reg_10 when reg_op0 = "1010" else
        reg_11 when reg_op0 = "1011" else
        reg_12 when reg_op0 = "1100" else
        reg_13 when reg_op0 = "1101" else
        reg_14 when reg_op0 = "1110" else
        reg_15 when reg_op0 = "1111";

    source1 <= reg_0 when reg_op1 = "0000" else
        reg_1 when reg_op1 = "0001" else
        reg_2 when reg_op1 = "0010" else
        reg_3 when reg_op1 = "0011" else
        reg_4 when reg_op1 = "0100" else
        reg_5 when reg_op1 = "0101" else
        reg_6 when reg_op1 = "0110" else
        reg_7 when reg_op1 = "0111" else
        reg_8 when reg_op1 = "1000" else
        reg_9 when reg_op1 = "1001" else
        reg_10 when reg_op1 = "1010" else
        reg_11 when reg_op1 = "1011" else
        reg_12 when reg_op1 = "1100" else
        reg_13 when reg_op1 = "1101" else
        reg_14 when reg_op1 = "1110" else
        reg_15 when reg_op1 = "1111";


    ------------ SAÍDA DA ULA -------------------------------------

    temp_mult <= source0 * source1;

    ula <= imediato when op_code = "0000" else              --LDA
        source0 + source1 when op_code = "0001" else        --ADD
        source0 - source1 when op_code = "0010" else        --SUB
        temp_mult(7 downto 0) when op_code = "0011" else    --MUL
        imediato when op_code = "0100" else                 --J
        imediato when op_code = "0101" else                 --BEQ
        imediato when op_code = "0110" else                 --BNE
        imediato when op_code = "0111" else                 --STA
        source0 + imediato when op_code = "1000" else       --ADDI
        source0 - imediato when op_code = "1001";           --SUBI


    ---------- ENABLE PARA ESCREVER NOS REGS ------------------------

    en_0 <= '1' when reg_dest = "0000" and F_regwrite = '1' else
        '0';

    en_1 <= '1' when reg_dest = "0001" and F_regwrite = '1' else
        '0';

    en_2 <= '1' when reg_dest = "0010" and F_regwrite = '1' else
        '0';

    en_3 <= '1' when reg_dest = "0011" and F_regwrite = '1' else
        '0';

    en_4 <= '1' when reg_dest = "0100" and F_regwrite = '1' else
        '0';

    en_5 <= '1' when reg_dest = "0101" and F_regwrite = '1' else
        '0';

    en_6 <= '1' when reg_dest = "0110" and F_regwrite = '1' else
        '0';

    en_7 <= '1' when reg_dest = "0111" and F_regwrite = '1' else
        '0';

    en_8 <= '1' when reg_dest = "1000" and F_regwrite = '1' else
        '0';

    en_9 <= '1' when reg_dest = "1001" and F_regwrite = '1' else
        '0';

    en_10 <= '1' when reg_dest = "1010" and F_regwrite = '1' else
        '0';

    en_11 <= '1' when reg_dest = "1011" and F_regwrite = '1' else
        '0';

    en_12 <= '1' when reg_dest = "1100" and F_regwrite = '1' else
        '0';

    en_13 <= '1' when reg_dest = "1101" and F_regwrite = '1' else
        '0';

    en_14 <= '1' when reg_dest = "1110" and F_regwrite = '1' else
        '0';

    en_15 <= '1' when reg_dest = "1111" and F_regwrite = '1' else
        '0';


process (clock, reset)
begin
    
    if (reset = '1') then

        reg_0 <= (others => '0');
        reg_1 <= (others => '0');
        reg_2 <= (others => '0');
        reg_3 <= (others => '0');
        reg_4 <= (others => '0');
        reg_5 <= (others => '0');
        reg_6 <= (others => '0');
        reg_7 <= (others => '0');
        reg_8 <= (others => '0');
        reg_9 <= (others => '0');
        reg_10 <= (others => '0'); 
        reg_11 <= (others => '0'); 
        reg_12 <= (others => '0'); 
        reg_13 <= (others => '0'); 
        reg_14 <= (others => '0'); 
        reg_15 <= (others => '0'); 
        pc <= (others => '0'); 


    elsif (clock = '1' and clock'event) then

        --pc <= pc + "00000001";

        if(F_jump = '1') then
            
            pc <= imediato;

        elsif (F_jump = '0') then

            pc <= pc + "00000001";

        end if;

        if(F_memwrite = '1') then

            mem_d(to_integer(signed(imediato))) <=  source0;

        end if;

        if(en_0 = '1') then

            reg_0 <= ula;

        end if;
            
        if(en_1 = '1') then

            reg_1<= ula;
 
        end if;
            
        if(en_2 = '1') then

            reg_2 <= ula;

        end if;
            
        if(en_3 = '1') then

            reg_3 <= ula;

        end if;
            
        if(en_4 = '1') then

            reg_4 <= ula;

        end if;
            
        if(en_5 = '1') then

            reg_5 <= ula;

        end if;
            
        if(en_6 = '1') then

            reg_6 <= ula;

        end if;
            
        if(en_7 = '1') then

            reg_7 <= ula;

        end if;
            
        if(en_8 = '1') then

            reg_8 <= ula;

        end if;
            
        if(en_9 = '1') then

            reg_9 <= ula;

        end if;
            
        if(en_10 ='1') then

            reg_10 <= ula;
        end if;
            
            
        if(en_11 ='1') then

            reg_11 <= ula;
        end if;
            
            
        if(en_12 ='1') then

            reg_12 <= ula;
        end if;
            
            
        if(en_13 ='1') then

            reg_13 <= ula;
        end if;
            
            
        if(en_14 ='1') then

            reg_14 <= ula;
        end if;
            
            
        if(en_15 ='1') then

            reg_15 <= ula;
        end if;
            
            
    end if;

end process;

end behaviour;
