----------------------------------------------------------------------------------
-- Company: 	RuleCity LLC
-- Engineer: 	Matt Ownby
-- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

entity vsyncCounter is
    Port ( vsyncPrime : in  STD_LOGIC;
           blinkerOut : out  STD_LOGIC);
end vsyncCounter;

architecture Behavioral of vsyncCounter is

	signal vsyncCount : std_logic_vector(2 downto 0) := "000";

begin

-- blink toggle every 8 vsyncs
blinkerOut <= vsyncCount(2);

onVsync: process (vsyncPrime)
begin

	if (falling_edge(vsyncPrime)) then
			
		vsyncCount <= std_logic_vector(unsigned(vsyncCount) + 1);
			
	end if;

end process onVsync;

end Behavioral;

