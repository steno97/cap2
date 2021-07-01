library IEEE;
use IEEE.std_logic_1164.all;
--use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_signed.all;
use IEEE.std_logic_arith.all;
use IEEE.numeric_std.all;
--use IEEE.std.standard.BOOLEAN;
use WORK.myTypes.all;
--use WORK.alu_type.all;

entity ALU is
  generic (N : integer := numBit);
  port 	 ( FUNC: IN aluOp;
           DATA1, DATA2: IN std_logic_vector(N-1 downto 0);
           OUTALU: OUT std_logic_vector(N-1 downto 0));
end ALU;



architecture Architectural of ALU is

component SHIFTER_GENERIC
	generic(N: integer :=numBit);
	port(	A: in std_logic_vector(N-1 downto 0);
		B: in std_logic_vector(4 downto 0);
		LOGIC_ARITH: in std_logic;	-- 1 = logic, 0 = arith
		LEFT_RIGHT: in std_logic;	-- 1 = left, 0 = right
		SHIFT_ROTATE: in std_logic;	-- 1 = shift, 0 = rotate
		OUTPUT: out std_logic_vector(N-1 downto 0)
	);
end component;

component P4_ADDER
generic (
		NBIT :		integer := numBit);
	port (
		A :	in	std_logic_vector(N-1 downto 0);
		B :	in	std_logic_vector(N-1 downto 0);
		Cin :	in	std_logic;
		S :	out	std_logic_vector(N-1 downto 0);
		Cout :	out	std_logic);
end component;


--component BOOTHMUL
--GENERIC ( NBIT_A : integer := NumBit_A;
				-- NBIT_B : integer := NumBit_B;
				-- NBIT_P : integer := NumBit_P
				--);
	
--	PORT ( A 	: IN  std_logic_vector ( NBIT_A-1 downto 0);
	--       B		: IN  std_logic_vector ( NBIT_B-1 downto 0);
		--	 P    : OUT std_logic_vector ( NBIT_P-1 downto 0)
		  -- )
--end component;

signal Cin_i : std_logic;
signal LOGIC_ARITH_i : std_logic;
signal LEFT_RIGHT_i : std_logic;
signal SHIFT_ROTATE_i : std_logic;
signal OUTPUT1: std_logic_vector(N-1 downto 0);
signal OUTPUT2: std_logic_vector(N-1 downto 0);
signal data2i: std_logic_vector(N-1 downto 0);
begin

  shifter:  SHIFTER_GENERIC
	port map(
		A 			=> 			DATA1,
		B 			=> 			DATA2(4 downto 0),
		LOGIC_ARITH =>			LOGIC_ARITH_i, --da inserire il segnale -- 1 = logic, 0 = arith
		LEFT_RIGHT 	=> 			LEFT_RIGHT_i , --da inserire il segnale	-- 1 = left, 0 = right
		SHIFT_ROTATE => 		SHIFT_ROTATE_i ,	--da inserire il segnale -- 1 = shift, 0 = rotate
		OUTPUT 		 => 		OUTPUT1);
     
  adder: p4_adder 
	port map (
		A 		=> DATA1,
		B 		=> DATA2i,
		Cin 	=> Cin_i   , -- da inserire 0
		S 		=> OUTPUT2   ,  --da inserire 0
		Cout =>	open); --we mantain the Cout signal for future implementation of the DLX with status flags

----da fare tutto il process
P_ALU: process (FUNC, DATA1, DATA2)
--variable tmp_arithmetic: unsigned (N downto 0); --temporary signal for arithmetic computation

  begin
	
    case func is
	
	when NOP => null;
		
	--sono da fare le istruzioni di branch-------------------------------------------------------------	
	
	when BEQZ => if (data1 /= data2) then
					OUTALU<="00000000000000000000000000000000";----snei
				end if;
				 if (data1 = data2) then
					OUTALU<="00000000000000000000000000000001";----snei
				end if;
	when BNEZ => if (data1 = data2) then
					OUTALU<="00000000000000000000000000000000";----snei
				end if;
				 if (data1 /= data2) then
					OUTALU<="00000000000000000000000000000001";----snei
				end if;	
	--sono da fare le istruzioni di branch-------------------------------------------------------------		
		
		
		
		
	when ADDS | ADDUI 	=>  Cin_i<='0';
					OUTALU<= output2;	
	
			
    --ricordarsi di gestire l"unsigned          
    when SUBI | SUBUI	=> 	Cin_i<='0';
					OUTALU<= output2;
					data2i<=not(data2)+"00000000000000000000000000000001";

	    --ricordarsi di gestire l"unsigned
    when ADD | ADDU	=> 	Cin_i<='0';
					OUTALU<= output2;
    when SUB | SUBU	=> 	Cin_i<='0';
					OUTALU<= output2;
					data2i<= not(data2)+"00000000000000000000000000000001";
	    --ricordarsi di gestire l"unsigned
      
      
      
      
	when SLLI => 	LOGIC_ARITH_i <='1'; --da inserire il segnale -- 1 = logic, '0' = arith
		 			LEFT_RIGHT_i  <='1'; --da inserire il segnale	-- 1 = left, '0' = right
					SHIFT_ROTATE_i <='1';
					OUTALU<= output1;
				 
	when SRLI => LOGIC_ARITH_i <='0'; --da inserire il segnale -- 1 = logic, '0' = arith
		 			LEFT_RIGHT_i  <='0'; --da inserire il segnale	-- 1 = left, '0' = right
					SHIFT_ROTATE_i <='1';
					OUTALU<= output1;
					
	when LLS => LOGIC_ARITH_i <='1'; --da inserire il segnale -- '1' = logic, '0' = arith
		 			LEFT_RIGHT_i  <='1'; --da inserire il segnale	-- '1' = left, '0' = right
					SHIFT_ROTATE_i <='1';
					OUTALU<= output1;
    
	when LRS => LOGIC_ARITH_i <='0'; --da inserire il segnale -- '1' = logic, '0' = arith
		 			LEFT_RIGHT_i  <='0'; --da inserire il segnale	-- '1' = left, '0' = right
					SHIFT_ROTATE_i <='1';
					OUTALU<= output1;
     
                                                                                 
	when ANDR => gen_and: for i in 0 to N-1 loop
								OUTALU(i) <= DATA1(i) and DATA2(i); 	-- and op
						 end loop;  
	when ORR  => gen_or: for i in 0 to N-1 loop
								OUTALU(i) <= DATA1(i) or DATA2(i);    	-- or op
						 end loop; 
	when XORR => gen_xor: for i in 0 to N-1 loop
								OUTALU(i) <= DATA1(i) xor DATA2(i);	--xor op
						 end loop; 
	when ANDI => gen_and1: for i in 0 to N-1 loop
								OUTALU(i) <= DATA1(i) and DATA2(i); 	-- and op
						 end loop;  
	when ORI  => gen_or1: for i in 0 to N-1 loop
								OUTALU(i) <= DATA1(i) or DATA2(i);    	-- or op
						 end loop; 
	when XORI => gen_xor1: for i in 0 to N-1 loop
								OUTALU(i) <= DATA1(i) xor DATA2(i);	--xor op
						 end loop; 
						 
	
	when SGE| SGEI =>    if (signed(data1) < signed(data2)) then
					OUTALU<="00000000000000000000000000000000";----slei
				end if;
				 if (signed(data1) >= signed(data2)) then
					OUTALU<="00000000000000000000000000000001";----slei
				end if;
	when  SGEUI |SGEU =>    if (unsigned(data1) < unsigned(data2)) then
					OUTALU<="00000000000000000000000000000000";----slei
				end if;
				 if (unsigned(data1) >= unsigned(data2)) then
					OUTALU<="00000000000000000000000000000001";----slei
				end if;
	when SNE | SNEI => if (signed(data1) /= signed(data2)) then
					OUTALU<="00000000000000000000000000000001";----snei
				end if;
				 if (signed(data1) = signed(data2)) then
					OUTALU<="00000000000000000000000000000000";----snei
				end if;
				
	when SLE | SLEI =>      if (signed(data1) > signed(data2)) then
					OUTALU<="00000000000000000000000000000000";----slei
				end if;
				 if (signed(data1) <= signed(data2)) then
					OUTALU<="00000000000000000000000000000001";----slei
				end if;
	
	
	---------------------------- load and store 
	
	when LW	=> 	Cin_i<='0';
				OUTALU<= output2;
	when SW =>	Cin_i<='0';
				OUTALU<= output2;
	
	when LB	=> 	Cin_i<='0';
				OUTALU<= output2;
	when SB =>	Cin_i<='0';
				OUTALU<= output2;
	when LBU => 	Cin_i<='0';
				OUTALU<= output2;
	
	------------------------------  load and store
	
	
	when SEQ | SEQI =>  if (signed(data1) == signed(data2)) then
					OUTALU<="00000000000000000000000000000001";----snei
				end if;
				 if (signed(data1) /= signed(data2)) then
					OUTALU<="00000000000000000000000000000000";----snei
				end if;
	
	when SLT | SLTI  =>      if (signed(data1) >= signed(data2)) then
					OUTALU<="00000000000000000000000000000000";----slei
				end if;
				 if (signed(data1) < signed(data2)) then
					OUTALU<="00000000000000000000000000000001";----slei
				end if;
	when | SLTU |SLTUI =>      if (unsigned(data1) >= unsigned(data2)) then
					OUTALU<="00000000000000000000000000000000";----slei
				end if;
				 if (unsigned(data1) < unsigned(data2)) then
					OUTALU<="00000000000000000000000000000001";----slei
				end if;
	when SGT | SGTI  =>    if (signed(data1) < signed(data2)) then
					OUTALU<="00000000000000000000000000000000";----slei
				end if;
				 if (signed(data1) > signed(data2)) then
					OUTALU<="00000000000000000000000000000001";----slei
				end if;
	 when SGTUI |SGTU  =>    if (unsigned(data1) < signed(data2)) then
					OUTALU<="00000000000000000000000000000000";----slei
				end if;
				 if (unsigned(data1) > unsigned(data2)) then
					OUTALU<="00000000000000000000000000000001";----slei
				end if;
				
	when others => null;
    end case; 
  end process P_ALU;

end Architectural;
  

  


configuration CFG_ALU_Architectural of ALU is
  for Architectural
  end for;
end CFG_ALU_Architectural;

	

