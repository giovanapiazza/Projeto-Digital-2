library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TB_Monociclo is
end entity;

architecture behaviour of TB_Monociclo is
    
    component Monociclo is
        port(
            clock: in std_logic;
            reset: in std_logic;
            debug_pc: out std_logic_vector(7 downto 0);
            debug_instrucao: out std_logic_vector(23 downto 0);
            debug_reg_dest: out std_logic_vector(15 downto 0);
            debug_source0: out std_logic_vector(15 downto 0);
            debug_source1: out std_logic_vector(15 downto 0)
        );
    end component;
    
    signal clock_sg : std_logic := '0';
    signal reset_sg : std_logic := '1';
    
    -- Sinais de Debug
    signal w_pc          : std_logic_vector(7 downto 0);
    signal w_instrucao   : std_logic_vector(23 downto 0);
    signal w_reg_dest    : std_logic_vector(15 downto 0);
    signal w_source0     : std_logic_vector(15 downto 0);
    signal w_source1     : std_logic_vector(15 downto 0);

    -- SINAL MÁGICO PARA VISUALIZAÇÃO (MNEMÔNICO)
    signal w_mnemonico   : string(1 to 4) := "....";

begin

    inst_Monociclo : Monociclo
        port map(
            clock => clock_sg,
            reset => reset_sg,
            debug_pc => w_pc,
            debug_instrucao => w_instrucao,
            debug_reg_dest => w_reg_dest,
            debug_source0 => w_source0,
            debug_source1 => w_source1
        );

    -- Clock: 100MHz (10ns período)
    clock_sg <= not clock_sg after 5 ns;

    -- Processo de Reset e Tempo
    process
    begin
        wait for 10 ns;
        reset_sg <= '0';
        wait for 2000 ns; -- Tempo suficiente para rodar o loop
        assert false report "Fim da Simulação" severity note;
        wait;
    end process;

    -- TRADUTOR DE INSTRUÇÕES (Opcode -> Texto)
    process(w_instrucao)
        variable opcode_temp : std_logic_vector(3 downto 0);
    begin
        opcode_temp := w_instrucao(23 downto 20);
        case opcode_temp is
            when "0000" => w_mnemonico <= "LDI "; -- Load Immediate
            when "0001" => w_mnemonico <= "ADD ";
            when "0010" => w_mnemonico <= "SUB ";
            when "0011" => w_mnemonico <= "MUL ";
            when "0100" => w_mnemonico <= "JMP ";
            when "0101" => w_mnemonico <= "BEQ ";
            when "0110" => w_mnemonico <= "BNE ";
            when "0111" => w_mnemonico <= "SW  "; -- Store Word
            when "1000" => w_mnemonico <= "ADDI";
            when "1001" => w_mnemonico <= "SUBI";
            when "1010" => w_mnemonico <= "MULI";
            when "1011" => w_mnemonico <= "LW  "; -- Load Word
            when others => w_mnemonico <= "NOP ";
        end case;
    end process;

end behaviour;
