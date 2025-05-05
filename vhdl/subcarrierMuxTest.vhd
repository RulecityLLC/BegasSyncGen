--------------------------------------------------------------------------------
-- Company: 	RuleCity LLC
-- Engineer:	Matt Ownby

-- NOTE: run simulator to at least 3 uS to cover all test cases.

--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
USE ieee.numeric_std.ALL;

ENTITY subcarrierMuxTest IS
END subcarrierMuxTest;
 
ARCHITECTURE behavior OF subcarrierMuxTest IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT subcarrierMux
    PORT(
         clk14_native : IN  std_logic;
			lm1881Csync : in STD_LOGIC;
         csync_is_active : out STD_LOGIC
        );
    END COMPONENT;
    

   --Inputs
   signal clk14_native : std_logic := '0';
	signal lm1881Csync : std_logic := '1';

 	--Outputs
   signal csync_is_active : std_logic;

   -- Clock period definitions
   constant clk14_native_period : time := 1 ns;
   constant clk14_derived_period : time := 1 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: subcarrierMux PORT MAP (
          clk14_native => clk14_native,
			 lm1881Csync => lm1881Csync,
          csync_is_active => csync_is_active
        );

   -- Clock process definitions
   clk14_native_process :process
   begin
		clk14_native <= '0';
		wait for clk14_native_period/2;
		clk14_native <= '1';
		wait for clk14_native_period/2;
   end process;
  
   -- Stimulus process
   stim_proc: process
   begin

		wait for clk14_native_period;	
	
      -- wait for right before idle flag kicks in
      wait for clk14_native_period * 2046;	

		assert (csync_is_active = '1') report "Unexpected value for csync_is_active (right before idle)" severity error;

      wait for clk14_native_period;

		assert (csync_is_active = '0') report "Unexpected value for csync_is_active (right after idle)" severity error;

      wait for clk14_native_period;
      wait for clk14_native_period;
      wait for clk14_native_period;

		-- wake up lm1881 field clock to take over

		lm1881Csync <= '0';

      wait for clk14_native_period;

		assert (csync_is_active = '1') report "Unexpected value for csync_is_active (derived should take over again)" severity error;

      wait;
   end process;

END;
