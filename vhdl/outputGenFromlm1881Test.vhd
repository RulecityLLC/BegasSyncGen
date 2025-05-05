--------------------------------------------------------------------------------
-- Company: 
-- Engineer:	Matt Ownby
--
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY outputGenFromlm1881Test IS
END outputGenFromlm1881Test;
 
ARCHITECTURE behavior OF outputGenFromlm1881Test IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT outputGenFromLm1881
    PORT(
         clock14_3 : IN  std_logic;
         lm1881Csync : IN  std_logic;
			lm1881Field : in  STD_LOGIC;
         hsync2_prime : OUT  std_logic;
			vsync2_prime : out  STD_LOGIC;
			sgblk_prime : out  STD_LOGIC
        );
    END COMPONENT;
    

   --Inputs
   signal clock14_3 : std_logic := '0';
   signal lm1881Csync : std_logic := '0';
	signal lm1881Field : std_logic := '0';

 	--Outputs
   signal hsync2_prime : std_logic;
	signal vsync2_prime : std_logic;
	signal sgblk_prime : std_logic;

   -- Clock period definitions
   constant clock14_3_period : time := 1 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: outputGenFromLm1881 PORT MAP (
          clock14_3 => clock14_3,
          lm1881Csync => lm1881Csync,
			 lm1881Field => lm1881Field,
          hsync2_prime => hsync2_prime,
			 vsync2_prime => vsync2_prime,
			 sgblk_prime => sgblk_prime
        );

   -- Clock process definitions
   clock14_3_process :process
   begin
		-- going from 1 to 0 to make simulation easier.
		clock14_3 <= '1';
		wait for clock14_3_period/2;
		clock14_3 <= '0';
		wait for clock14_3_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		

		-- initial state
		lm1881Csync <= '1';

		wait for clock14_3_period;

		assert (hsync2_prime = '1') report "Unexpected value for hsync2_prime" severity failure;

		-- this should lower hsync2
		lm1881Csync <= '0';
		
		wait for clock14_3_period;
		
		assert (hsync2_prime = '0') report "Unexpected value for hsync2_prime, should go low when csync goes low" severity failure;
		
		-- wait a reasonable amount of time to raise csync
		wait for clock14_3_period * 68;
		lm1881Csync <= '1';
		
		wait for clock14_3_period * (73-68);
		
		-- make sure hsync2 is still low
		assert (hsync2_prime = '0') report "Unexpected value for hsync2_prime, should still be low" severity failure;
		
		wait for clock14_3_period;
		
		-- hsync2 should now have gone high
		assert (hsync2_prime = '1') report "Unexpected value for hsync2_prime, should have gone high" severity failure;
		
		-- wait for half a line to complete
		wait for clock14_3_period * (455-74);
		
		-- this should be ignored by hsync2 handler since it is too frequent
		lm1881Csync <= '0';
		
		-- wait a reasonable amount of time to raise csync
		wait for clock14_3_period * 68;
		lm1881Csync <= '1';
		
		-- hsync2 should not have gone low
		assert (hsync2_prime = '1') report "Unexpected value for hsync2_prime, should have stayed high" severity failure;
		
		-- wait for the other half of the line to complete
		wait for clock14_3_period * (455-68);
		
		lm1881Csync <= '0';
		
		-- wait a reasonable amount of time to raise csync
		wait for clock14_3_period * 68;
		lm1881Csync <= '1';
		
		-- hsync2 should have gone low
		assert (hsync2_prime = '0') report "Unexpected value for hsync2_prime, should have gone low" severity failure;
		
      wait;
   end process;

END;
