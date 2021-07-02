library IEEE;
use IEEE.std_logic_1164.all; 
use IEEE.std_logic_arith.all;

entity IR_DECODE is
Generic (NBIT: integer:= numBit; opBIT: integer:= OP_CODE_SIZE; regBIT: integer:= REG_SIZE ); 
	Port (	
		IR_26:	in	std_logic_vector(NBIT-opBIT-1 downto 0); 
		OPCODE:	in	std_logic_vector(opBIT-1 downto 0); --OpCODE <= IR(6 bit)
		is_signed:	in	std_logic;
		RS1: out	std_logic_vector(regBIT-1 downto 0); --RS1 <= (5 bit)
		RS2: out	std_logic_vector(regBIT-1 downto 0); --RS2 <= (5 bit)
		RD: out	std_logic_vector(regBIT-1 downto 0); --RD <= (5 bit)
		IMMEDIATE: out	std_logic_vector(NBIT-1 downto 0)
		);
--IMMEDIATE <= imm16, imm26 or func(11)
--imm16 when i-type, imm26 (signed imm) when j-type, func when R type

end IR_DECODE;


architecture BEHAV of IR_DECODE is
--constants
 constant rTYPE: std_logic_vector(opBIT-1 downto 0) :="000000";
 constant jTYPE: std_logic_vector(opBIT-1 downto 0) := "00001X";
 --j=0x02='000010', jal=0x03='000011' 
 
--components
	component sign_eval is
		generic (N_in: integer := numBit;
				  N_out: integer := numBit);
		port (
			IR_out: in std_logic_vector(N_in-1 downto 0);
			signed_val: in std_logic; 
			Immediate: out std_logic_vector (N_out-1 downto 0));
	end component;
--process
begin
		
	dec_IR : process(IR_26,is_signed)
	begin
	case OPCODE is
		when rTYPE =>   
			RS1  <= IR_26(25 downto 21);
			RS2  <= IR_26(20 downto 16);
			RD   <= IR_26(15 downto 11);
			IMMEDIATE <= (others => '0'); --func
			--nop??
			

		when jTYPE => 
			RS1  <= (others => '0');
			RS2  <= (others => '0');
			RD   <= (others => '0');

			SIGN_EXTENSION_imm26: sign_eval
			generic map (26, NBIT)
			port map (IR_26, 1, IMMEDIATE);
			--j,jal (signed imm)
			--JR, JALR SONO DI CHE TIPO?

		when others =>
		--I-TYPE
			RS1  <= IR_26(25 downto 21);
			RD  <= IR_26(20 downto 16);
			RS2  <= (others => '0');
			
			SIGN_EXTENSION_imm16: sign_eval
			generic map (16, NBIT)
			port map (IR_26(15 downto 0), is_signed, IMMEDIATE);
			
			--beqz, bnez signed in teoria
			
		end case;
	end process;
end architecture;

		