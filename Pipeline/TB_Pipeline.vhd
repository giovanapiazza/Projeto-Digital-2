library ieee;
use ieee.std_logic_1164.all;

entity TB_Pipeline is
end entity;

architecture behaviour of TB_Pipeline is
    
    component Pipeline is
        port(
            clock: in std_logic;
            reset: in std_logic;
            debug_pc: out std_logic_vector(7 downto 0);
            debug_instrucao: out std_logic_vector(23 downto 0);
            debug_wb_dado: out std_logic_vector(15 downto 0)
        );
    end component;
    
    signal clock_sg : std_logic := '0';
    signal reset_sg : std_logic := '1';
    
    signal w_pc        : std_logic_vector(7 downto 0);
    signal w_instrucao : std_logic_vector(23 downto 0);
    signal w_wb_dado   : std_logic_vector(15 downto 0);
    
    -- Visual Helper: Mnemonic String
    signal w_mnemonico : string(1 to 4) := "....";

begin

    inst_Pipeline : Pipeline
        port map(
            clock => clock_sg,
            reset => reset_sg,
            debug_pc => w_pc,
            debug_instrucao => w_instrucao,
            debug_wb_dado => w_wb_dado
        );

    -- Clock Generation: 100MHz (10ns period)
    clock_sg <= not clock_sg after 5 ns;

    process
    begin
        wait for 15 ns;
        reset_sg <= '0';
        
        -- Run long enough for pipeline fill and loop execution
        wait for 2500 ns; 
        
        assert false report "Simulation Finished" severity note;
        wait;
    end process;

    -- INSTRUCTION TRANSLATOR (Opcode -> Text)
    -- This process runs only in simulation to help visualization
    process(w_instrucao)
        variable opcode_temp : std_logic_vector(3 downto 0);
    begin
        opcode_temp := w_instrucao(23 downto 20);
        case opcode_temp is
            when "0000" => w_mnemonico <= "LDI ";
            when "0001" => w_mnemonico <= "ADD ";
            when "0010" => w_mnemonico <= "SUB ";
            when "0011" => w_mnemonico <= "MUL ";
            when "0100" => w_mnemonico <= "JMP ";
            when "0101" => w_mnemonico <= "BEQ ";
            when "0110" => w_mnemonico <= "BNE ";
            when "0111" => w_mnemonico <= "SW  ";
            when "1000" => w_mnemonico <= "ADDI";
            when "1001" => w_mnemonico <= "SUBI";
            when "1010" => w_mnemonico <= "MULI";
            when "1011" => w_mnemonico <= "LW  ";
            when others => w_mnemonico <= "NOP ";
        end case;
    end process;

end behaviour;


