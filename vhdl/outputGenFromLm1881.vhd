----------------------------------------------------------------------------------
-- Company: RuleCity LLC
-- Engineer: Matt Ownby
-- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

entity outputGenFromLm1881 is
    Port ( clock14_3 : in  STD_LOGIC;
           lm1881Csync : in  STD_LOGIC;
			  lm1881Field : in  STD_LOGIC;
           hsync2_prime : out  STD_LOGIC;
			  vsync2_prime : out  STD_LOGIC;
			  sgblk_prime : out  STD_LOGIC);
end outputGenFromLm1881;

architecture Behavioral of outputGenFromLm1881 is

	-- these numbers come from observing the behavior of the Sony CX773A chip that we are trying to replace
	constant cyclesPerVsync : natural := 238875;
	constant cyclesPerHalfLine : natural := 455;
	constant cyclesPerLine : natural := cyclesPerHalfLine*2;
	constant cyclesPerCsyncPulse : natural := 68;
	
	-- We start at the same time as csync.  we want to go 6 cycles beyond the end of csync, to match ending of original behavior
	constant cyclesPerHsync2Pulse : natural := cyclesPerCsyncPulse + 6;
	
	-- vsync2 is supposed to last for 9 lines (lines 1-9 for example)
	-- However, the lm1881 starts vsync on line 4.5 so we actually need to hold vsync for 5.5 lines insteead of 9
	constant cyclesPerVsync2Pulse : natural := ((cyclesPerLine * 11)/2);

	-- initialization values chosen to make simulation convenient
	signal iVsync2Count : natural range 0 to (cyclesPerVsync + cyclesPerLine) := cyclesPerVsync;	-- adding extra cycles to compensate for variation between 4*Fsc clock and our native clock
	signal iHsync2Count : natural range 0 to (cyclesPerLine*2) := cyclesPerLine;
		
	signal sgblk_vsync2 : std_logic;
	signal sgblk_hsync2 : std_logic;
	
	signal lm1881FieldSynced : std_logic := '0';
	signal fieldOld : std_logic := '0';
		
	signal hsync2_count_clear_prime : std_logic := '1';
	signal hsync2_armed_prime : std_logic := '1';

begin

hsync2_prime <= '0' when (iHsync2Count < cyclesPerHsync2Pulse) else '1';
vsync2_prime <= '0' when (iVsync2Count < cyclesPerVsync2Pulse) else '1';

-- sgblk
sgblk_vsync2 <= '0' when (iVsync2Count < (10164 + cyclesPerVsync2Pulse)) else '1';	-- sgblk vsync is 10164 cycles longer than vsync2
sgblk_hsync2 <= '0' when (iHsync2Count < (58 + cyclesPerHsync2Pulse)) else '1';	-- sgblk hsync is 58 cycles longer than hsync2
sgblk_prime <= sgblk_hsync2 and sgblk_vsync2;

-- required to make async LM1881 signals synchronous with the clock
lm1881Synchronizer : process(clock14_3)
begin
	if (rising_edge(clock14_3)) then

		lm1881FieldSynced <= lm1881Field;

	end if;
end process lm1881Synchronizer;

lm1881Hsync2CountThink: process(clock14_3,hsync2_count_clear_prime)
begin

	-- async clear takes precedence
	if (hsync2_count_clear_prime = '0') then
	
		iHsync2Count <= 0;
		hsync2_armed_prime <= '1';
		
	elsif (rising_edge(clock14_3)) then

		-- csync will trigger twice as often during vsync pulse.  We need to filter this out.
		-- On a noisy signal, csync can also falsely trigger at other points.  We set the threshold for valid csync high enough to filter these out, but low enough to allow for variations in actual sync frequency.
		if (iHsync2Count > 872) then
			hsync2_armed_prime <= '0';
		end if;

		iHsync2Count <= iHsync2Count + 1;

	end if;

end process lm1881Hsync2CountThink;

lm1881CsyncThink: process(lm1881Csync,iHsync2Count)
begin

	-- if the counter has just reset (due to us lowering the clear flag), then raise the clear flag so that it can start counting again
	if (iHsync2Count = 0) then
	
		hsync2_count_clear_prime <= '1';
	
	-- if lm1881 csync has gone low
	elsif (falling_edge(lm1881Csync)) then
	
		-- if we're at a point where it's valid for hsync2 to go low
		if (hsync2_armed_prime = '0') then
			hsync2_count_clear_prime <= '0';
		-- else it's part of the vsync pulse (or just noise), so we ignore it			
		end if;

	end if;

end process lm1881CsyncThink;

lm1881FieldThink: process(clock14_3)
begin

	if (rising_edge(clock14_3)) then

		-- if field has changed then vsync has become active
		if (lm1881FieldSynced /= fieldOld) then
			
			iVsync2Count <= 0;
			fieldOld <= lm1881FieldSynced;

		else
			iVsync2Count <= iVsync2Count + 1;
		end if;

	end if;

end process lm1881FieldThink;

end Behavioral;