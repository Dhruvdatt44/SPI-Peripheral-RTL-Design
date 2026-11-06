module SPI_edge_gen(
input pclk,
input rst,
input enable,
input sclk_tick,
input cpol,
input cpha,
output reg sclk_out,
output reg sample_en,
output reg shift_en);

reg  edge_phase;

always @(posedge pclk or posedge rst)begin
      if (rst)begin
      edge_phase<=0;
      end
      else if (!enable)begin
      edge_phase<=0;
      end
      else if (enable && sclk_tick)begin
      edge_phase<=~edge_phase;
      
      end
      else begin
      edge_phase<=edge_phase;
      end
end

always @(posedge pclk or posedge rst) begin
       if(rst)begin
       sclk_out<=cpol;
       sample_en<=0;
       shift_en<=0;
       end
       else if(!enable)begin
       sclk_out<=cpol;
       sample_en<=0;
       shift_en<=0;
       end
       else if(enable && sclk_tick)begin
       sclk_out<=~sclk_out;
       sample_en<=(cpha==edge_phase);
       shift_en<=(cpha!=edge_phase);
       end
       else begin
       sclk_out<=sclk_out;
       sample_en<=0;
       shift_en<=0;
       end
end

endmodule
