----------------------------------------------------------------------------------
-- Company: 	RuleCity LLC
-- Engineer: 	Matt Ownby
--
-- NOTE: This file no longer has anything to do with muxing the subcarrier; I just kept the name for convenience.
-- The file actually deals with determining whether the LM1881 is producing an active csync pulse.
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

entity subcarrierMux is
    Port ( clk14_native : in  STD_LOGIC;
			  lm1881Csync : in STD_LOGIC;
			  
           -- need this exported so that other components know whether clock is derived or generated
           csync_is_active : out STD_LOGIC);
end subcarrierMux;

architecture Behavioral of subcarrierMux is

-- Number of bits is chosen to accomodate 910 * 1.5 (1365) 14.3 MHz cycles, where 910 cycles is 1 horizontal line.
-- This should be enough time to assume that no active video signal is available.
signal clk14_idle_counter : std_logic_vector(11 downto 0) := (others => '0');

signal derived_is_active : boolean := false;
signal clk14_idle_clear_prime : std_logic := '1';

begin

-- for convenience
derived_is_active <= (clk14_idle_counter(11) = '0');

csync_is_active <= '1' when derived_is_active else '0';

clk14IdleThink: process (clk14_native,clk14_idle_clear_prime)
begin

	-- async clear takes precedence
	if (clk14_idle_clear_prime = '0') then
	
		clk14_idle_counter <= (others => '0');

	elsif (rising_edge(clk14_native)) then
		-- we don't want to overflow because then we wouldn't know whether the derived clock is idle
		if (clk14_idle_counter(11) = '0') then
			clk14_idle_counter <= std_logic_vector(unsigned(clk14_idle_counter) + 1);			
		end if;
	end if;

end process clk14IdleThink;

lm1881CsyncThink: process(lm1881Csync,clk14_idle_counter)
begin

	-- if the clock idle counter has just reset (due to us lowering the clear flag), then raise the clear flag so that it can start counting again
	if (clk14_idle_counter = "000000000000") then
	
		clk14_idle_clear_prime <= '1';
	
	-- if lm1881 csync is active, then we want to keep resetting the idle counter so it doesn't get too high
	elsif (falling_edge(lm1881Csync)) then
	
		clk14_idle_clear_prime <= '0';

	end if;

end process lm1881CsyncThink;

end Behavioral;
