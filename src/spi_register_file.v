module spi_register_file(
input pclk,
input preset,
input psel,
input enable,
input pwrite,
input [7:0] paddr,
input [31:0] pwdata,
output reg [31:0] prdata,
output  pready,
output irq,

output [15:0] clk_div,
output start_transfer,
output [7:0] tx_data_in,
input  [7:0] rx_data_out,
output cpol,
output cpha,
input  done,
input busy

);

reg cpol_reg;
reg cpha_reg;
reg [15:0] clk_divider_reg;
reg [7:0] tx_data_reg;
reg start_transfer_reg;
wire write_enable= psel && enable && pwrite;
wire read_rxdata  = psel && enable && !pwrite && (paddr[4:2]==3'd4);
reg done_latched;
reg irq_en_reg;

assign start_transfer =start_transfer_reg;
assign cpol= cpol_reg;
assign cpha= cpha_reg;
assign tx_data_in=tx_data_reg;
assign clk_div =clk_divider_reg;
assign pready =1;
assign irq     = done_latched && irq_en_reg;
    
always @(posedge pclk or posedge preset)begin
if(preset)begin
cpol_reg<=0;
cpha_reg<=0;
clk_divider_reg<=0;
tx_data_reg<=0;
start_transfer_reg<=0;
done_latched<=0;
//prdata<=0;
end 
    
      else begin
        start_transfer_reg<=0;
        if (read_rxdata)
            done_latched <= 0;
        if (done)
            done_latched <= 1;

           if(write_enable) begin
              case (paddr[4:2])
               3'd0: begin  // ctrl 00
                    cpol_reg<= pwdata[1];
                    cpha_reg<=pwdata[2];
                    irq_en_reg<=pwdata[3];
                  end
               3'd2:begin    //clk div 08
                   clk_divider_reg<=pwdata[15:0];
                   end
                  
               3'd3:begin   //txdata 0c
                  tx_data_reg<=pwdata[7:0];   
                    if(!busy)begin   
                     start_transfer_reg<=1;
                    end
                  end
                  
               endcase
            end
       end
end

always @(*)begin
   prdata=32'b0;
      case (paddr[4:2])
           3'd0:begin    //ctrl 00
             prdata[1]=cpol_reg;
             prdata[2]=cpha_reg;
             prdata[3]=irq_en_reg;
             end
           3'd1:begin   //status 04
             prdata[0]=busy;
             prdata[1]=done_latched;
             end
           3'd2:begin  //clkdiv  08
             prdata[15:0]=clk_divider_reg;
             end
           3'd3:begin  //txdata  0c
             prdata [7:0]=tx_data_reg;
             end
           3'd4:begin  //rxdata  10
             prdata [7:0]=rx_data_out;
             end 
             default:prdata=0;       
      endcase       
   
   
end  
endmodule
