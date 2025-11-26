library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity tb_processador is
end entity;
 
architecture behaviour of tb_processador is
    component processador is
        port(
            clock: in std_logic;
            reset: in std_logic;
            out0: out std_logic_vector(7 downto 0)
        );

    end component;
    
signal clock_sg:  std_logic := '0';
signal reset_sg:  std_logic := '1';

begin

    inst_processador : processador
        port map(
            clock => clock_sg,
            reset => reset_sg
        );

    clock_sg <= not clock_sg after 5 ns;

process
begin
    wait for 2 ns;

    reset_sg <= '0';

end process;

end behaviour;
