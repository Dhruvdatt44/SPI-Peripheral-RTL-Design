module shiftregisters #(parameter WORD_LEN=8 )(
input pclk,
input rst,
input cpha,
input load,
input shift_en,
input sample_en,
input  [WORD_LEN-1:0] tx_data_in,
input miso_bit,
output reg mosi_bit,
output reg [WORD_LEN-1:0] rx_data_out,
output reg last_bit 
    );
    reg [$clog2(WORD_LEN)-1:0] bit_count;
    reg [WORD_LEN-1:0] tx_shift;

always @(posedge pclk or posedge rst) begin
       if (rst)begin
       tx_shift<=0;
       mosi_bit<=0;
       end
       else if(load && cpha==0)begin
       mosi_bit <=tx_data_in[WORD_LEN-1];
       tx_shift <={tx_data_in[WORD_LEN-2:0],1'b0};
       end
       else if(load)begin
       tx_shift<=tx_data_in;
       end
       else if(shift_en)begin
       mosi_bit <=tx_shift[WORD_LEN-1];
       tx_shift <={tx_shift[WORD_LEN-2:0],1'b0};
       end
       else begin
       tx_shift <= tx_shift;
       mosi_bit <= mosi_bit;
       end
       

end
always @(posedge pclk or posedge rst) begin
      if(rst)begin
      rx_data_out<=0;
      bit_count <=0;
      last_bit<=0;
      end
      else if (load)begin
      rx_data_out<=0;
      bit_count <=0;
      last_bit<=0;
      end
      else if (sample_en)begin
      rx_data_out<= {rx_data_out[WORD_LEN-2:0],miso_bit};
      bit_count<= bit_count+1;
      last_bit    <= (bit_count == WORD_LEN-1);
      end
      else begin
      rx_data_out<=rx_data_out;
      bit_count<=bit_count;
      last_bit<=last_bit;
      end
      
      

end

endmodule
