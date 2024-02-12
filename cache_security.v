module security
		#(
			parameter	MAIN_MEM_ADDR = 14,
			parameter	CACHE_ADDR = 7,
			parameter 	PREG_PROTECT_LOW = 0,
			parameter 	PREG_PROTECT_HIGH = 1879048192
		)
		(
			input clock,
			input reset,
						
			input [MAIN_MEM_ADDR-1:0]	mainmem_address,
			input [CACHE_ADDR-1:0]		cache_address,
			input 						MemoryAccess,
			input 						cache_hit,
			input 						cache_miss,
		
			//AHB SLAVE INTERFACE
			output	reg					IRQ,
			///AMSHAL
			output	reg					VVV_STATE
		);

localparam	IDLE = 3'b000,
			FIRST_V = 3'b001,
			FIRST_A = 3'b010,			
			SECOND_V_VH = 3'b011,
			SECOND_V_AM = 3'b100,			
			SECOND_A_VM = 3'b101,
			SECOND_A_AH = 3'b110,
			ATTACK = 3'b111;

//reg	[31:0]	REG_CONFIG;
//reg	[31:0]	REG_STATUS;
//reg	[31:0]	REG_PROTECT_LOW;
//reg	[31:0]	REG_PROTECT_HIGH;

reg	 [2:0]	REG_STATES	[0:(2**CACHE_ADDR)-1];

reg	 [2:0]	next_state;
reg		VVV_STATE_Reached;
wire [2:0]	state;

//reg						MemoryAccess_dly;
//reg						MemoryAccess_dly2;

//reg						cache_hit_dly;
//reg						cache_miss_dly;

//reg [CACHE_ADDR-1:0]	last_address;

wire		attack_space;

/*
always @(posedge clock, posedge reset)
begin
	if (reset)
	begin
		REG_CONFIG <= 0;
		REG_STATUS <= 0;
		REG_PROTECT_LOW <= 0;
		REG_PROTECT_HIGH <= 100;
	end
	else
	begin
		REG_CONFIG <= REG_CONFIG;
		REG_STATUS <= REG_STATUS;
		REG_PROTECT_LOW <= REG_PROTECT_LOW;
		REG_PROTECT_HIGH <= REG_PROTECT_HIGH;
	end
end
*/
integer i;

always @(posedge clock, posedge reset)
begin
	if (reset)
		for(i=0;i<(2**CACHE_ADDR);i=i+1)
			REG_STATES[i] <= 0;
	else
		if (MemoryAccess) 
			REG_STATES[cache_address] <= next_state;
end 

assign state = REG_STATES[cache_address];

always @(posedge clock, posedge reset)
begin
	if (reset) begin
//		MemoryAccess_dly	<= 0;
//		MemoryAccess_dly2	<= 0;
//		last_address		<= 0;
		IRQ 				<= 0;
		///AMSHAL
		VVV_STATE			<= 0;
	end
	else
	begin
//		MemoryAccess_dly	<= MemoryAccess;
//		MemoryAccess_dly2	<= MemoryAccess_dly;
//		cache_hit_dly		<= cache_hit;
//		cache_miss_dly		<= cache_miss;
//		last_address		<= cache_address;
		IRQ					<= (next_state == ATTACK);
		///AMSHAL
		VVV_STATE			<= VVV_STATE_Reached;
	end		
end 

assign attack_space = (mainmem_address < PREG_PROTECT_LOW) | (mainmem_address > PREG_PROTECT_HIGH);

always @*
begin
	VVV_STATE_Reached = 1'b0;
	case (state)
	IDLE: begin
			if (MemoryAccess) 
				if (attack_space)
					next_state = FIRST_A;
				else
					next_state = FIRST_V;
			else
				next_state = state;
	end
	FIRST_A: begin
				if (MemoryAccess) 
					if (attack_space)
						if (cache_hit)
							next_state = SECOND_A_AH;
						else
							next_state = IDLE;
					else
						if (cache_miss)
							next_state = SECOND_A_VM;
						else
							next_state = IDLE;
				else
					next_state = state;		
	end
	FIRST_V: begin
				if (MemoryAccess) 
					if (attack_space)
						if (cache_miss)
							next_state = SECOND_V_AM;
						else
							next_state = IDLE;
					else
						if (cache_hit)
							next_state = SECOND_V_VH;
						else
							next_state = IDLE;
				else
					next_state = state;			
	end
	SECOND_V_VH: begin
					if (MemoryAccess) 
						if (attack_space)
							if (cache_miss)
								next_state = ATTACK;
							else
								next_state = IDLE;
						else
							if (cache_hit) begin
								next_state = ATTACK;
								//VVV_STATE_Reached = 1'b1;
								end
							else
								next_state = IDLE;
					else
						next_state = state;		
	end
	SECOND_V_AM:begin
					if (MemoryAccess) 
						if (attack_space)
							next_state = IDLE;
						else
							if (cache_miss)
								next_state = ATTACK;
							else
								next_state = IDLE;
					else
						next_state = state;		
	end
	SECOND_A_VM:begin
					if (MemoryAccess) 
						if (attack_space)
							if (cache_miss)
								next_state = ATTACK;
							else
								next_state = IDLE;
						else
							next_state = ATTACK;						
				else
					next_state = state;		
	end
	SECOND_A_AH:begin
					if (MemoryAccess) 
						if (attack_space)						
							next_state = IDLE;
					else
						if (cache_miss)
							next_state = ATTACK;
						else
							next_state = IDLE;
				else
					next_state = state;		
	end
	ATTACK: next_state = IDLE;	
	default: next_state = IDLE;
	endcase
end

endmodule
