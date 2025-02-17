//Subject:     CO project 2 - Simple Single CPU
//--------------------------------------------------------------------------------
//Version:     1
//--------------------------------------------------------------------------------
//Writer:      
//----------------------------------------------
//Date:        
//----------------------------------------------
//Description: 
//--------------------------------------------------------------------------------
module Simple_Single_CPU(
                clk_i,
		rst_i
		);
		
//I/O port
input         clk_i;
input         rst_i;

//Internal Signles


wire [32-1:0]pc_;
wire [32-1:0]instrucitonMemory_;
wire decoder_regwrite_registerFile_;
wire [2-1:0]decoder_RegDst_MuxWriteReg_;
wire decoder_branch_;
wire decoder_MuxALUSrc_;
wire [3-1:0]decoder_ALUOp_ALUctrl_;
wire [32-1:0]registerFile_RSdata_;
wire [32-1:0]registerFile_RTdata_;
wire [32-1:0]ALUResult_;
wire ALUZero_;
wire [32-1:0]Adder1_;
wire [32-1:0]Adder2_MuxPCSource_;
wire [32-1:0]MuxPCSource_;
wire [32-1:0]signExtend_;
wire [32-1:0]shiftLeft2_Adder2_;
wire [4-1:0]ALUCtrl_ALU_;
wire [5-1:0]MuxWriteReg_;
wire [32-1:0]MuxALUSrc_;
wire [2-1:0]branchType_;
wire        MuxForBranch_;
wire [32-1:0]Mux_Jump_;
//Greate componentes
ProgramCounter PC(
        .clk_i(clk_i),      
	    .rst_i (rst_i),     
	    .pc_in_i(Mux_Jr_) ,   
	    .pc_out_o(pc_) 
	    );
	
Adder Adder1(
        .src1_i(32'd4),     
	    .src2_i(pc_),     
	    .sum_o(Adder1_)    
	    );
	
Instr_Memory IM(
        .addr_i(pc_),  
	    .instr_o(instrucitonMemory_)    
	    );


wire jr_;
//jr op code and jr func
assign jr_ = ({instrucitonMemory_[31:26], instrucitonMemory_[5:0]} == {6'b000000, 6'b001000})? 1: 0;
wire [32-1:0] Mux_Jr_;
MUX_2to1 #(.size(32)) Mux_Jr(
        .data0_i(Mux_Jump_),
        .data1_i(registerFile_RSdata_),//jr address
        .select_i(jr_o_ | jr_),
        .data_o(Mux_Jr_)
        );  

wire [32-1:0] Mux_Jal_;
MUX_2to1 #(.size(32)) Mux_Jal(
        .data0_i(muxWriteData_),
        .data1_i(Adder1_),//+32'd4),//for jal
        .select_i(jal_o_),
        .data_o(Mux_Jal_)
        );  

MUX_3to1 #(.size(5)) Mux_Write_Reg(
        .data0_i(instrucitonMemory_[20:16]), //rt
        .data1_i(instrucitonMemory_[15:11]),
        .data2_i(5'd31),//use for jal(jump and link) save PC + 4
        .select_i(decoder_RegDst_MuxWriteReg_),
        .data_o(MuxWriteReg_)
        );	
		
Reg_File RF(
        .clk_i(clk_i),      
	    .rst_i(rst_i) ,     
        .RSaddr_i(instrucitonMemory_[25:21]) ,  
        .RTaddr_i(instrucitonMemory_[20:16]) ,  
        .RDaddr_i(MuxWriteReg_) ,  
        .RDdata_i(Mux_Jal_)  , 
        .RegWrite_i (decoder_regwrite_registerFile_& ~jr_),
        .RSdata_o(registerFile_RSdata_) ,  
        .RTdata_o(registerFile_RTdata_)   
        );

wire Jump_;
wire MemRead_;
wire MemWrite_;
wire MemToReg_;
wire jr_o_;
wire jal_o_;
Decoder Decoder(
        .instr_op_i(instrucitonMemory_[31:26]), 
	    .RegWrite_o(decoder_regwrite_registerFile_), 
	    .ALU_op_o(decoder_ALUOp_ALUctrl_),   
	    .ALUSrc_o(decoder_MuxALUSrc_),   
	    .RegDst_o(decoder_RegDst_MuxWriteReg_),   
		.Branch_o(decoder_branch_),
        .BranchType_o(branchType_),
        .Jump_o(Jump_),//p3
        .MemRead_o(MemRead_),//p3
        .MemWrite_o(MemWrite_),//p3
        .MemtoReg_o(MemToReg_),//p3
        .jr_o(jr_o_),
        .jal_o(jal_o_)
	    );



ALU_Ctrl AC(
        .funct_i(instrucitonMemory_[5:0]),   
        .ALUOp_i(decoder_ALUOp_ALUctrl_),   
        .ALUCtrl_o(ALUCtrl_ALU_) 
        );
	
Sign_Extend SE(
        .data_i(instrucitonMemory_[15:0]),
        .data_o(signExtend_)
        );

MUX_2to1 #(.size(32)) Mux_ALUSrc(
        .data0_i(registerFile_RTdata_),
        .data1_i(signExtend_),
        .select_i(decoder_MuxALUSrc_),
        .data_o(MuxALUSrc_)
        );	
		
ALU ALU(
        .src1_i(registerFile_RSdata_),
        .src2_i(MuxALUSrc_),
        .ctrl_i(ALUCtrl_ALU_),
        .shamt_i(instrucitonMemory_[10:6]),
        .result_o(ALUResult_),
        .zero_o(ALUZero_)
        );
		
Adder Adder2(
            // .src1_i(shiftLeft2_Adder2_),
            .src1_i(signExtend_<<2),          
	    .src2_i(Adder1_+4),     
	    .sum_o(Adder2_MuxPCSource_)      
	    );
		
// Shift_Left_Two_32 Shifter(
//         .data_i(signExtend_),
//         .data_o(shiftLeft2_Adder2_)
//         ); 		


wire [31:0] dataMemory_;
Data_Memory Data_Memory(
        .clk_i(clk_i),
        .addr_i(ALUResult_),
        .data_i(registerFile_RTdata_),
        .MemRead_i(MemRead_),
        .MemWrite_i(MemWrite_),
        .data_o(dataMemory_)
    );

wire [31:0] muxWriteData_;

MUX_2to1 #(.size(32)) MuxWriteData(
        .data0_i(ALUResult_),
        .data1_i(dataMemory_),//lw
        .select_i(MemToReg_),
        .data_o(muxWriteData_)
    );


wire [28-1:0]shiftLeft2_28_;

Shift_Left_Two_26 Shifter2(
        .data_i(instrucitonMemory_[26-1:0]),
        .data_o(shiftLeft2_28_)
        );


MUX_4to1 #(.size(1)) MuxForBranch(
        .data0_i(ALUZero_),//BEQ
        .data1_i(ALUResult_[31]!=1),//BGEZ 
        .data2_i(ALUResult_[31]==1),//BLT  use SUB check sign bit
        .data3_i(~ALUZero_),//BNE
        .select_i(branchType_),
        .data_o(MuxForBranch_)
    );

MUX_2to1 #(.size(32)) Mux_PC_Source(
        .data0_i(Adder1_),
        .data1_i(Adder2_MuxPCSource_),
        .select_i(decoder_branch_ & MuxForBranch_),
        .data_o(MuxPCSource_)
        );  

wire [32-1:0]jump_address_;
// assign jump_address_ = {Adder1_[31:28],shiftLeft2_28_};
assign jump_address_ = {Adder1_[31:28],instrucitonMemory_[26-1:0],2'b00};


MUX_2to1 #(.size(32)) Mux_Jump(
        .data0_i(MuxPCSource_),
        .data1_i(jump_address_),
        .select_i(Jump_),
        .data_o(Mux_Jump_)
        );

endmodule
		  


