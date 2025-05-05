----------------------------------------------------------------------------------
-- Company:		RuleCity LLC
-- Engineer: 	Matt Ownby
-- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- NOTE : subcarrier output is included here because it is synced up with hsync2 on the chip we are trying to replace
-- Current field is an output because we are the authority on whether hsync/vsync are aligned (top field) or not (bottom field)
entity outputGen is
    Port ( clock14_3 : in  std_logic;
           reset_prime : in  std_logic;	-- resets counters to 0 (top field start)
	        is_top_field : out  boolean;	-- false = bottom, true = top
           subcarrier_out : out  STD_LOGIC;
           sgblk_prime : out  std_logic;
			  csync_prime : out  std_logic;
           hsync2_prime : out  std_logic;
           vsync2_prime : out  std_logic);
end outputGen;

architecture Behavioral of outputGen is

	-- these numbers come from observing the behavior of the Sony CX773A chip that we are trying to replace
	constant cyclesPerVsync : natural := 238875;
	constant cyclesPerHalfLine : natural := 455;
	constant cyclesPerLine : natural := cyclesPerHalfLine*2;
	constant cyclesPerCsyncPulse : natural := 68;
	constant t1 : natural := 22;
	constant t2 : natural := 32;
	constant t4 : natural := (cyclesPerHalfLine - cyclesPerCsyncPulse);

	-- initial values set so that on first clock, they go to 0 (to make simulation easier)
	signal iVsync2Count : natural range 0 to (cyclesPerVsync-1) := (cyclesPerVsync-1);
	signal iHsync2Count : natural range 0 to (cyclesPerLine-1) := (cyclesPerLine-1);
	
	signal sgblk_vsync2 : std_logic;
	signal sgblk_hsync2 : std_logic;

	signal csyncPrimeInt : std_logic;
	signal vsync2PrimeInt : std_logic;
	signal sgblkPrimeInt : std_logic;
	signal hsync2PrimeInt : std_logic;

	-- bit 1 of this counter will be the generated subcarrier.  needed because the reference clock is 4x the sub carrier.
	-- Initialized with '01' so on next clock it goes to '10' to be in sync with start of hsync2
	signal subcarrier_generated_counter : std_logic_vector(1 downto 0) := "01";

begin

-- sub carrier
subcarrier_out <= subcarrier_generated_counter(1);

vsync2PrimeInt <= '0' when (iVsync2Count < 8190) else '1';
hsync2PrimeInt <= '0' when (iHsync2Count < 96) else '1';

-- sgblk
sgblk_vsync2 <= '0' when (iVsync2Count < 18354) else '1';
sgblk_hsync2 <= '0' when (iHsync2Count < 154) else '1';
sgblkPrimeInt <= sgblk_hsync2 and sgblk_vsync2;

-- csync
csyncPrimeInt <= '0' when (
		((vsync2PrimeInt = '1') and ((iHsync2Count >= t1) and (iHsync2Count < (t1+cyclesPerCsyncPulse))))
		or
		((vsync2PrimeInt = '0') and
			(
					-- first 6 short pulses (lines 1-3,262.5-264.5)
					((iVsync2Count >= (cyclesPerHalfLine*0)+t1) and (iVsync2Count < (cyclesPerHalfLine*0)+t1+t2))
					or
					((iVsync2Count >= (cyclesPerHalfLine*1)+t1) and (iVsync2Count < (cyclesPerHalfLine*1)+t1+t2))
					or
					((iVsync2Count >= (cyclesPerHalfLine*2)+t1) and (iVsync2Count < (cyclesPerHalfLine*2)+t1+t2))
					or
					((iVsync2Count >= (cyclesPerHalfLine*3)+t1) and (iVsync2Count < (cyclesPerHalfLine*3)+t1+t2))
					or
					((iVsync2Count >= (cyclesPerHalfLine*4)+t1) and (iVsync2Count < (cyclesPerHalfLine*4)+t1+t2))
					or
					((iVsync2Count >= (cyclesPerHalfLine*5)+t1) and (iVsync2Count < (cyclesPerHalfLine*5)+t1+t2))						
						
					-- next 6 longer pulses aka vsync pulse (lines 4-6,265.5-267.5)
					or
					((iVsync2Count >= (cyclesPerHalfLine*6)+t1) and (iVsync2Count < (cyclesPerHalfLine*6)+t1+t4))						
					or
					((iVsync2Count >= (cyclesPerHalfLine*7)+t1) and (iVsync2Count < (cyclesPerHalfLine*7)+t1+t4))						
					or
					((iVsync2Count >= (cyclesPerHalfLine*8)+t1) and (iVsync2Count < (cyclesPerHalfLine*8)+t1+t4))						
					or
					((iVsync2Count >= (cyclesPerHalfLine*9)+t1) and (iVsync2Count < (cyclesPerHalfLine*9)+t1+t4))						
					or
					((iVsync2Count >= (cyclesPerHalfLine*10)+t1) and (iVsync2Count < (cyclesPerHalfLine*10)+t1+t4))						
					or
					((iVsync2Count >= (cyclesPerHalfLine*11)+t1) and (iVsync2Count < (cyclesPerHalfLine*11)+t1+t4))						
						
					-- last 6 short pulses (lines 7-9,268.5-270.5)
					or
					((iVsync2Count >= (cyclesPerHalfLine*12)+t1) and (iVsync2Count < (cyclesPerHalfLine*12)+t1+t2))
					or
					((iVsync2Count >= (cyclesPerHalfLine*13)+t1) and (iVsync2Count < (cyclesPerHalfLine*13)+t1+t2))
					or
					((iVsync2Count >= (cyclesPerHalfLine*14)+t1) and (iVsync2Count < (cyclesPerHalfLine*14)+t1+t2))
					or
					((iVsync2Count >= (cyclesPerHalfLine*15)+t1) and (iVsync2Count < (cyclesPerHalfLine*15)+t1+t2))
					or
					((iVsync2Count >= (cyclesPerHalfLine*16)+t1) and (iVsync2Count < (cyclesPerHalfLine*16)+t1+t2))
					or
					((iVsync2Count >= (cyclesPerHalfLine*17)+t1) and (iVsync2Count < (cyclesPerHalfLine*17)+t1+t2))
			)
		)
	)
	else '1';
	
onClk14: process (clock14_3)
begin
	if (rising_edge(clock14_3)) then

		-- if reset is active
		if (reset_prime = '0') then
			iVsync2Count <= 0;
			iHsync2Count <= 0;
			subcarrier_generated_counter <= "10";	-- vsync for top field has subcarrier high when vsync goes low
						
		-- else reset is not active
		else

			if (iVsync2Count = (cyclesPerVsync-1)) then
				iVsync2Count <= 0;
			else
				iVsync2Count <= iVsync2Count + 1;
			end if;
			
			if (iHsync2Count = (cyclesPerLine-1)) then
				iHsync2Count <= 0;
			else
				iHsync2Count <= iHsync2Count + 1;
			end if;

			subcarrier_generated_counter <= std_logic_vector(unsigned(subcarrier_generated_counter) + 1);

		-- end if reset is not active
		end if;
		
	end if;
end process onClk14;

-- this process is necessary to remove noise/bounce from the outgoing signals (especially csync)
latcher: process(clock14_3)
begin
	if (rising_edge(clock14_3)) then
		csync_prime <= csyncPrimeInt;
		vsync2_prime <= vsync2PrimeInt;
		hsync2_prime <= hsync2PrimeInt;
		sgblk_prime <= sgblkPrimeInt;
	end if;
end process latcher;

handleField: process (vsync2PrimeInt)
begin
	if (falling_edge(vsync2PrimeInt)) then
		
		is_top_field <= (iHsync2Count = 0);
			
	end if;
end process handleField;

end Behavioral;
