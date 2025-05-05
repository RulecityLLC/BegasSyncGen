----------------------------------------------------------------------------------
-- Company: RuleCity LLC
-- Engineer: Matt Ownby

----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

entity main is
    Port ( clk14_3native : in  STD_LOGIC;
           lm1881field_isTop : in  STD_LOGIC;
           lm1881csync_prime : in  STD_LOGIC;
           subcarrier_out : out  STD_LOGIC;
           csync_prime_out : out  STD_LOGIC;
           vsync2_prime_out : out  STD_LOGIC;
           hsync2_prime_out : out  STD_LOGIC;
           sgblk_prime_out : out  STD_LOGIC;
           led_sync_is_from_ntsc : out  STD_LOGIC;
           led_sync_is_generated : out  STD_LOGIC);
end main;

architecture Behavioral of main is

	COMPONENT outputGen is
    Port ( clock14_3 : in  std_logic;
           reset_prime : in  std_logic;
	        is_top_field : out  boolean;
			  subcarrier_out : out  STD_LOGIC;
           sgblk_prime : out  std_logic;
			  csync_prime : out  std_logic;
           hsync2_prime : out  std_logic;
           vsync2_prime : out  std_logic);
	end COMPONENT;

	COMPONENT subcarrierMux is
    Port ( clk14_native : in  STD_LOGIC;
			  lm1881Csync : in  STD_LOGIC;
           csync_is_active : out STD_LOGIC);
	end COMPONENT;

	COMPONENT outputGenFromLm1881
	PORT(
		clock14_3 : IN std_logic;
		lm1881Csync : IN std_logic;
		lm1881Field : IN std_logic;          
		hsync2_prime : OUT std_logic;
		vsync2_prime : OUT std_logic;
		sgblk_prime : OUT std_logic
		);
	END COMPONENT;

	COMPONENT vsyncCounter
	PORT(
		vsyncPrime : IN std_logic;          
		blinkerOut : OUT std_logic
		);
	END COMPONENT;

	signal main_csync_is_active : std_logic := '0';
	signal main_csync_is_not_active : std_logic := '1';	-- to reset generated signals

	signal hsync2_prime_out_generated : std_logic;
	signal hsync2_prime_out_lm1881 : std_logic;

	signal vsync2_prime_out_generated : std_logic;
	signal vsync2_prime_out_lm1881 : std_logic;

	signal sgblk_prime_out_generated : std_logic;
	signal sgblk_prime_out_lm1881 : std_logic;
	
	signal csync_prime_out_generated : std_logic;
	
	signal subcarrier_out_generated : std_logic;

	signal vsync2_prime_out_int : std_logic;	-- needed to hook up blinker
	signal blinker : std_logic;

begin

main_csync_is_not_active <= not main_csync_is_active;	-- to reset generated signals

-- we AND with blinker so that the user can quickly tell whether the device is working (the active LED will be blinking)
led_sync_is_from_ntsc <= main_csync_is_active AND blinker;
led_sync_is_generated <= main_csync_is_not_active AND blinker;

hsync2_prime_out <= hsync2_prime_out_lm1881 when main_csync_is_active = '1' else hsync2_prime_out_generated;
vsync2_prime_out_int <= vsync2_prime_out_lm1881 when main_csync_is_active = '1' else vsync2_prime_out_generated;
vsync2_prime_out <= vsync2_prime_out_int;
sgblk_prime_out <= sgblk_prime_out_lm1881 when main_csync_is_active = '1' else sgblk_prime_out_generated;
csync_prime_out <= lm1881csync_prime when main_csync_is_active = '1' else csync_prime_out_generated;

-- if we have an active video signal, we shouldn't need to output a subcarrier because it means we aren't using ldp-1000a
subcarrier_out <= '0' when main_csync_is_active = '1' else subcarrier_out_generated;

	Inst_outputGen : outputGen PORT MAP(
		clock14_3 => clk14_3native,
		reset_prime => main_csync_is_not_active,	-- if csync is active, we hold generator in a state of reset so that it operates properly if csync is removed
		is_top_field => open,	-- for troubleshooting only
		subcarrier_out => subcarrier_out_generated,
		sgblk_prime => sgblk_prime_out_generated,
		csync_prime => csync_prime_out_generated,
		hsync2_prime => hsync2_prime_out_generated,
		vsync2_prime => vsync2_prime_out_generated
	);
	
	Inst_subcarrierMux : subcarrierMux PORT MAP(
		clk14_native => clk14_3native,
		lm1881Csync => lm1881csync_prime,
		csync_is_active => main_csync_is_active
	);
		
	Inst_outputGenFromLm1881: outputGenFromLm1881 PORT MAP(
		clock14_3 => clk14_3native,
		lm1881Csync => lm1881csync_prime,
		lm1881Field => lm1881field_isTop,
		hsync2_prime => hsync2_prime_out_lm1881,
		vsync2_prime => vsync2_prime_out_lm1881,
		sgblk_prime => sgblk_prime_out_lm1881
	);

	Inst_vsyncCounter: vsyncCounter PORT MAP(
		vsyncPrime => vsync2_prime_out_int,
		blinkerOut => blinker
	);

end Behavioral;
