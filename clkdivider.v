module spi_clkdiv #(parameter DIV_WIDTH=16)(

input pclk,
input rst,
input enable,
input [DIV_WIDTH-1:0] clkdiv_val,
output reg sclk_tick);
reg [DIV_WIDTH-1:0] count;

always @(posedge pclk or posedge rst) begin
       if (rst)begin
       count<= 0;
       sclk_tick<=0;
       end
       else if(!enable)begin
       count<=0;
       sclk_tick<=0;
       end
       else if (count == clkdiv_val) begin
       count<=0;
       sclk_tick<=1;
       end
       else begin
       sclk_tick<=0;
       count <= count +1;
       end
end



endmodule