--DATAPATH DLX GROUP_42
--stage 1: FETCH F
--stage 2: DECODE D
--stage 3: EXECUTE E
--stage 4: MEMORY M
--stage 5: WRITE BACK WB
library IEEE;
use IEEE.std_logic_1164.all; 
use work.myTypes.all;
use IEEE.numeric_std.all;

entity DATAPTH is
Generic (NBIT: integer:= numBit; REG_BIT: integer:= REG_SIZE);
	Port (	
		CLK:	in	std_logic;
		RST:	in	std_logic;
		PC: in	std_logic_vector(NBIT-1 downto 0);
		IR: in	std_logic_vector(NBIT-1 downto 0);
		PC_OUT: out	std_logic_vector(NBIT-1 downto 0); --pc_out
		--DTPTH_OUT: out std_logic_vector(NBIT-1 downto 0);
		
		--cu signals
		EN0: in	std_logic;
		signed_op: in	std_logic;
		RF1: in	std_logic;
		RF2: in	std_logic;
		WF1: in	std_logic; --sel WB
		EN1: in	std_logic;
		S1: in	std_logic; --sel A
		S2: in	std_logic; --sel B
		EN2: in	std_logic;
		lhi_sel: in	std_logic;
		jump_en:in	std_logic;
		branch_cond: in	std_logic;
		sb_op: in	std_logic;
		RM: in	std_logic;
		WM: in	std_logic;
		EN3: in	std_logic;
		S3: in	std_logic;
		--alu signals
		instruction_alu:  in aluOp;
		
		--data memory signals
		DATA_MEM_ADDR: out	std_logic_vector(NBIT-1 downto 0);
		DATA_MEM_IN: out	std_logic_vector(NBIT-1 downto 0);
		DATA_MEM_OUT: in	std_logic_vector(NBIT-1 downto 0);
		DATA_MEM_ENABLE: out	std_logic;
		DATA_MEM_RM: out	std_logic;
		DATA_MEM_WM: out	std_logic);
end DATAPTH;


architecture STRUCTURAL of DATAPTH is 
--components: 

--MUX: IF SEL=1 ->Y=A, ELSE Y=B
component MUX21_GENERIC is
	generic (NBIT: integer:=numBit);
	Port (	
		A:	In	std_logic_vector(NBIT-1 DOWNTO 0);
		B:	In	std_logic_vector(NBIT-1 DOWNTO 0);
		SEL:	In	std_logic;
		Y:	Out	std_logic_vector(NBIT-1 DOWNTO 0));
end component;

component FF is
	port (
		CLK, RESET, EN, D : in std_logic;
		Q : out std_logic
	);
end component;


component regFFD is
Generic (NBIT: integer:= numBit);
	Port (	
		CK:	In	std_logic;
		RESET:	In	std_logic;
		ENABLE: In 	std_logic;
		D:	In	std_logic_vector(NBIT-1 downto 0);
		Q:	Out	std_logic_vector(NBIT-1 downto 0));
end component;

component IR_DECODE is 
Generic (NBIT: integer:= numBit;opBIT: integer:= OP_CODE_SIZE; regBIT: integer:= REG_SIZE ); 
	Port (	
		IR_26:	in	std_logic_vector(NBIT-opBIT-1 downto 0); 
		OPCODE:	in	std_logic_vector(opBIT-1 downto 0); 
		is_signed:	in	std_logic;
		RS1: out	std_logic_vector(regBIT-1 downto 0); 
		RS2: out	std_logic_vector(regBIT-1 downto 0); 
		RD: out	std_logic_vector(regBIT-1 downto 0); 
		IMMEDIATE: out	std_logic_vector(NBIT-1 downto 0)
		);
end component;

component register_file is
 port ( 
	 CLK: 		IN std_logic;
	 RESET: 		IN std_logic;
	 ENABLE: 	IN std_logic;
	 RD1: 		IN std_logic;
	 RD2: 		IN std_logic;
	 WR: 			IN std_logic;
	 ADD_WR: 	IN std_logic_vector(REG_SIZE-1 downto 0);
	 ADD_RD1: 	IN std_logic_vector(REG_SIZE-1 downto 0);
	 ADD_RD2: 	IN std_logic_vector(REG_SIZE-1 downto 0);
	 DATAIN: 	IN std_logic_vector(NBIT-1 downto 0);
    OUT1: 		OUT std_logic_vector(NBIT-1 downto 0);
	 OUT2: 		OUT std_logic_vector(NBIT-1 downto 0));
end component;

component windRF is
 generic(
		M:	integer:=num_global_regs;
		N:	integer:=num_local_inout_regs;
		F:	integer:=num_windows;
		NBIT:	integer:=Numbit);
 port ( CLK: 		IN std_logic; 
        RESET:	 	IN std_logic; --synchronous
		ENABLE: 	IN std_logic; --active high
		CALL: 		IN std_logic; --control signal(==cs) to subroutine calls (active high)
		RETRN: 		IN std_logic; --cs to subroutine callbacks (active high)
		FILL:	 	OUT std_logic; -- cs to retrieve data from memory (active high)
		SPILL: 		OUT std_logic; --cs to put data in the mem (active high)
		BUSin: 		IN std_logic_vector(NBIT-1 downto 0); --for fill data from mem
		BUSout: 	OUT std_logic_vector(NBIT-1 downto 0); -- for spill data to mem
		RD1: 		IN std_logic; --cs for read port (active high)
		RD2: 		IN std_logic;
		WR: 		IN std_logic; --cs for write port (active high)
		ADD_WR: 	IN std_logic_vector(virt_addr-1 downto 0); --address of write port
		ADD_RD1: 	IN std_logic_vector(virt_addr-1 downto 0); ---address of read port
		ADD_RD2: 	IN std_logic_vector(virt_addr-1 downto 0);
		DATAIN: 	IN std_logic_vector(NBIT-1 downto 0); --write port
		OUT1: 		OUT std_logic_vector(NBIT-1 downto 0); --read port
		OUT2: 		OUT std_logic_vector(NBIT-1 downto 0)
);
end component;

component ALU is
  generic (N : integer := NBIT);
  port 	 ( CLK:	in	std_logic;
			FUNC: IN AluOp;
           DATA1, DATA2: IN std_logic_vector(N-1 downto 0);
           OUT_ALU: OUT std_logic_vector(N-1 downto 0));
end component;

component zero_eval is
  generic (NBIT:integer:= NBIT);
  port (
    input: in  std_logic_vector(NBIT-1 downto 0);
    res: out std_logic );
end component;

component COND_BT is
Generic (NBIT: integer:= numBit); 
	Port (	
		ZERO_BIT:	in	std_logic;
		OPCODE_0:	in	std_logic; --OpCODE(0) <= IR(26)
		branch_op:	in	std_logic;
		con_sign: out	std_logic);
end component;

component load_data is
	port (
	  data_in: in std_logic_vector(31 downto 0);
      signed_val: in std_logic; 
	load_op: in std_logic;
      load_type: in std_logic_vector(1 downto 0); --load byte, halfword, word (3 valori=2 bit)
      data_out: out std_logic_vector (31 downto 0));	
end component;


--signals
	--stage 1
	signal NPC: std_logic_vector(NBIT-1 downto 0);
	--pipe
	signal NPC_Dec: std_logic_vector(NBIT-1 downto 0);
	signal PC_Dec: std_logic_vector(NBIT-1 downto 0);
	signal IR_Dec: std_logic_vector(NBIT-1 downto 0);
	--stage 2
	signal RS1: std_logic_vector(REG_BIT-1 downto 0);
	signal RS2: std_logic_vector(REG_BIT-1 downto 0);
	signal RD: std_logic_vector(REG_BIT-1 downto 0);
	signal Imm: std_logic_vector(NBIT-1 downto 0);
	signal regA: std_logic_vector(NBIT-1 downto 0);
	signal regB: std_logic_vector(NBIT-1 downto 0);
	signal LHI_id: std_logic_vector(NBIT-1 downto 0);
	--pipe
	signal NPC_ex: std_logic_vector(NBIT-1 downto 0);
	signal regA_ex: std_logic_vector(NBIT-1 downto 0);
	signal regB_ex: std_logic_vector(NBIT-1 downto 0);
	signal Imm_ex: std_logic_vector(NBIT-1 downto 0);
	signal RD_ex: std_logic_vector(REG_BIT-1 downto 0);
	signal IR_26_ex: std_logic_vector(1 downto 0);
	signal LHI_ex:std_logic_vector(NBIT-1 downto 0);
	signal signed_op_ex: std_logic;
	--stage 3 
	signal input1_ALU: std_logic_vector(NBIT-1 downto 0);
	signal input2_ALU: std_logic_vector(NBIT-1 downto 0);
	signal ALU_out:  std_logic_vector(NBIT-1 downto 0);
	signal is_zero: std_logic;
	signal cond: std_logic; 
	signal ALU_ex: std_logic_vector(NBIT-1 downto 0);
	--pipe
	signal NPC_mem: std_logic_vector(NBIT-1 downto 0);
	signal cond_mem: std_logic;
	signal ALU_mem: std_logic_vector(NBIT-1 downto 0);
	signal regB_mem: std_logic_vector(NBIT-1 downto 0);
	signal RD_mem: std_logic_vector(REG_BIT-1 downto 0);
	signal signed_op_mem: std_logic;
	signal IR_26_mem: std_logic_vector(1 downto 0);
	--stage 4:
	signal sel_saved_reg: std_logic;
	signal sel_npc: std_logic;
	signal PC_fetch: std_logic_vector(NBIT-1 downto 0);
	--pipe
	signal ALU_wb: std_logic_vector(NBIT-1 downto 0);
	signal sel_saved_reg_wb: std_logic;
	signal NPC_wb: std_logic_vector(NBIT-1 downto 0);
	signal LMD_wb: std_logic_vector(NBIT-1 downto 0);
	signal RD_wb: std_logic_vector(REG_BIT-1 downto 0);
	signal WM_wb: std_logic;
	--stage 5
	signal regB_in: std_logic_vector(NBIT-1 downto 0);
	signal LMD_out: std_logic_vector(NBIT-1 downto 0);
	signal OUT_data: std_logic_vector(NBIT-1 downto 0);
	signal OUT_wb: std_logic_vector(NBIT-1 downto 0);
	
begin
--stage 1-> inputs: PC; outputs: NPC, IR
	
	-- PC->PC+4->NPC
       NPC <= std_logic_vector(unsigned(PC) + to_unsigned(1,NBIT));
      
	  --PC_fetch from stage 4 (modify if more than 1 instruction must be executed)
	-- PC->INSTR. MEM(IRAM)-> IR 

	--sel_pc: process (sel_npc,Clk)
	sel_pc: process (sel_npc,Clk)
	begin
		if (sel_npc='1') then
		PC_OUT<=PC_fetch;
		else PC_OUT<=NPC;
		end if;
	end process;

	--pipeline signals (F->D)
	pipeline_newpc1: regFFD Generic map (NBIT) Port map(CK=>CLK, RESET=>RST,ENABLE=>EN0, D=>NPC, Q=>NPC_Dec);
	pipeline_pc1:regFFD Generic map (NBIT) Port map(CK=>CLK, RESET=>RST,ENABLE=>EN0, D=>PC, Q=>PC_Dec);
	pipeline_IR1:regFFD Generic map (NBIT) Port map(CK=>CLK, RESET=>RST,ENABLE=>EN0, D=>IR, Q=>IR_Dec);
	
--stage 2-> in: NPC, IR, PC; out: NPC, A, B, Imm

	-- IR assignement
	IR_OP:IR_DECODE
	Port map(IR_26=>IR_Dec(NBIT-OP_CODE_SIZE-1 downto 0), OPCODE=>IR_Dec(NBIT-1 downto NBIT-OP_CODE_SIZE),is_signed=>signed_op, RS1=>RS1, RS2=>RS2, RD=>RD, IMMEDIATE=>Imm);

	--RF mapping
	RF: windRF
 	generic map (M=>5,N=>5, F=>3, NBIT=>32)
 	port map( CLK=>CLK, RESET=>RST, ENABLE=> EN1, CALL=>'0', RETRN=>'0', FILL=>open, SPILL=>open, BUSin=>(others=>'0'), BUSout=>open, RD1=> RF1, RD2=> RF2, WR=>WF1, ADD_WR=>RD_wb, ADD_RD1=>RS1, ADD_RD2=>RS2, DATAIN=>OUT_wb, OUT1=>regA, OUT2=>regB);
	-- RF: register_file
	-- port map (CLK, RST, EN1, RF1, RF2, WF1, RD_wb, RS1, RS2, OUT_wb, regA, regB);
	--CALL=>open, RETRN=>open, FILL=>open, SPILL=>open, BUSin=>open, BUSout=>open, open ports (not handled subroutines: trap and ret instructions)

	LHI_id(31 downto 16)<=Imm(15 downto 0);
	LHI_id(15 downto 0)<=(others=>'0');
	
	--pipeline signals (D->E)
	pipeline_sign2: FF Port map(CLK=>CLK, RESET=>RST,EN=>EN1, D=>signed_op, Q=>signed_op_ex);
	pipeline_newpc2: regFFD Generic map (NBIT) Port map(CK=>CLK, RESET=>RST,ENABLE=>EN1, D=>NPC_Dec, Q=>NPC_ex);
	pipeline_A2: regFFD Generic map (NBIT) Port map(CK=>CLK, RESET=>RST,ENABLE=>EN1, D=>regA, Q=>regA_ex);
	pipeline_B2: regFFD Generic map (NBIT) Port map(CK=>CLK, RESET=>RST,ENABLE=>EN1, D=>regB, Q=>regB_ex);
	pipeline_IMM2: regFFD Generic map (NBIT) Port map(CK=>CLK, RESET=>RST,ENABLE=>EN1, D=>Imm, Q=>Imm_ex);
	pipeline_RD2: regFFD Generic map (REG_BIT) Port map(CK=>CLK, RESET=>RST,ENABLE=>EN1, D=>RD, Q=>RD_ex);
	pipeline_IR2: regFFD Generic map (2) Port map(CK=>CLK, RESET=>RST,ENABLE=>EN1, D=>IR_Dec(27 downto 26), Q=>IR_26_ex);
	pipeline_LHI2: regFFD Generic map (NBIT) Port map(CK=>CLK, RESET=>RST,ENABLE=>EN1, D=>LHI_id, Q=>LHI_ex);
	
--stage 3-> in: NPC, A, B, Imm, PC; out: NPC, cond, alu_out, B

	MUX_ALU_A: MUX21_GENERIC 
	Port Map (NPC_ex, regA_ex, S1, input1_ALU);
	--Port Map (regA_ex,NPC_ex,  S1, input1_ALU);
	MUX_ALU_B: MUX21_GENERIC 
	Port Map (Imm_ex, regB_ex,S2, input2_ALU);
	
	ALU_OP: ALU
	generic map(NBIT)
	port map(clk=> clk,FUNC=>instruction_alu, DATA1=>input1_ALU, DATA2=>input2_ALU,OUT_ALU=>ALU_out);
	
	ZERO_OP: zero_eval
	  generic map (NBIT)
	  port map (regA_ex, is_zero); --reg1=0--> is_zero=1
	  
	COND_OP: COND_BT
	generic map (NBIT)
	  port map (is_zero, IR_26_ex(0),branch_cond, cond); 
	--branch taken--> cond_sign=1; bnot taken or not branch opcode-->cond_sign=0;
	--- IF JUMP OR BRANCH TAKEN=> NPC=ALUOUT fai nop delle istruzioni 

	MUX_alu_out: MUX21_GENERIC 
	Port Map (LHI_ex, ALU_out, lhi_sel, ALU_ex); 
 
--pipeline signals (E->M)
	pipeline_sign3: FF Port map(CLK=>CLK, RESET=>RST,EN=>EN2, D=>signed_op_ex, Q=>signed_op_mem);
	pipeline_newpc3: regFFD Generic map (NBIT) Port map(CK=>CLK, RESET=>RST,ENABLE=>EN2, D=>NPC_ex, Q=>NPC_mem);
	pipeline_cond3: FF Port map(CLK=>CLK, RESET=>RST,EN=>EN2, D=>cond, Q=>cond_mem);
	pipeline_alu3:regFFD Generic map (NBIT) Port map(CK=>CLK, RESET=>RST,ENABLE=> EN2, D=>ALU_ex, Q=>ALU_mem);
	pipeline_B3: regFFD Generic map (NBIT) Port map(CK=>CLK, RESET=>RST,ENABLE=>EN2, D=>regB_ex, Q=>regB_mem);
   	pipeline_RD3: regFFD Generic map (REG_BIT) Port map(CK=>CLK, RESET=>RST,ENABLE=>EN2, D=>RD_ex, Q=>RD_mem);
	pipeline_IR3: regFFD Generic map (2) Port map(CK=>CLK, RESET=>RST,ENABLE=>EN2, D=>IR_26_ex, Q=>IR_26_mem);
--	stage 4-> in: NPC, cond, alu_out, B; out: PC, ALU_out, LMD_out
	jal_op: process (IR_26_mem(0), jump_en )
	begin
	sel_saved_reg <= (IR_26_mem(0) and jump_en);
	end process;
	--if jal o jalr: save npc in r31

	sel_npc_op: process (cond_mem, jump_en )
	begin
	sel_npc <= (cond_mem or jump_en);
	end process;

	MUX_PC: MUX21_GENERIC 
	Port Map (ALU_mem, NPC_mem, sel_npc, PC_fetch); 
	--if branch taken or jump instruction-> pc =alu_out
	
	MUX_data_in: process (sb_op)
	begin
		if sb_op='1' then
		regB_in (31 downto 8)<=(others=>'0');
		regB_in (7 downto 0)<= regB_mem(31 downto 24);
		else regB_in <= regB_mem;
		end if;
	end process;
	
	--data_memory -- guarda dov'è data memory
	DATA_MEM_ADDR<= ALU_mem;
	DATA_MEM_IN<= regB_in;
	DATA_MEM_RM<=RM; --read=load op
	DATA_MEM_WM<=WM; --write= store op
	DATA_MEM_ENABLE<=EN3;
	
	--lmd
	LOAD_DATA_OUT: load_data
	port map(data_in=>DATA_MEM_OUT, signed_val=>signed_op_mem, load_op=>RM, load_type=>IR_26_mem, data_out=>LMD_out);

	--pipeline signals (M->W)
	pipeline_newpc4: regFFD Generic map (NBIT) Port map(CK=>CLK, RESET=>RST,ENABLE=>EN3, D=>NPC_mem, Q=>NPC_wb);
	pipeline_alu4:regFFD Generic map (NBIT) Port map(CK=>CLK, RESET=>RST,ENABLE=>EN3, D=>ALU_mem, Q=>ALU_wb);
	pipeline_LMD4: regFFD Generic map (NBIT) Port map(CK=>CLK, RESET=>RST,ENABLE=>EN3, D=>LMD_out, Q=>LMD_wb);
	pipeline_RD4: regFFD Generic map (REG_BIT) Port map(CK=>CLK, RESET=>RST,ENABLE=>EN3, D=>RD_mem, Q=>RD_wb);
	pipeline_WM: FF Port map(CLK=>CLK, RESET=>RST,EN=>EN3, D=>WM, Q=>WM_wb);
	pipeline_JAL: FF Port map(CLK=>CLK, RESET=>RST,EN=>EN3, D=>sel_saved_reg, Q=>sel_saved_reg_wb);
--	stage 5-> in: ALU_out, LMD_out, out: OUT_WB

	MUX_WB: MUX21_GENERIC 
	Port Map (ALU_wb, LMD_wb, S3, OUT_data);-- sel_WB==S3
	
	MUX_jal: MUX21_GENERIC 
	Port Map (NPC_wb, OUT_WB, sel_saved_reg_wb, OUT_wb);-- saved_reg='1'-->npc else out wb
   --DTPTH_OUT<=OUT_wb;
   -- WF1 disponibile
end architecture;
