//Subject:     CO project 2 - PC
//--------------------------------------------------------------------------------
//Version:     1
//--------------------------------------------------------------------------------
//Writer:      Luke
//----------------------------------------------
//Date:        2010/8/16
//----------------------------------------------
//Description: 
//--------------------------------------------------------------------------------

module ProgramCounter(
    clk_i,
	rst_i,
	pcwrite_i,
	pc_in_i,
	pc_out_o
	);
     
//I/O ports
input           clk_i;
input	        rst_i;
input			pcwrite_i;
input  [32-1:0] pc_in_i;
output [32-1:0] pc_out_o;
 
//Internal Signals
reg    [32-1:0] pc_out_o;
 
//Parameter

    
//Main function
always @(posedge clk_i) begin
    if(~rst_i)
	    pc_out_o <= 0;
	else begin
		if(pcwrite_i==1)
			pc_out_o <= pc_in_i;
		else
			pc_out_o <= pc_out_o;
	end
end

endmodule



                    
                    