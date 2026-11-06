
module spi_pin_interface (
    input  wire pclk,
    input  wire rst,         

    
    input  wire Sclk_out,    
    input  wire Mosi_bit,    
    input  wire CS_n,         
    output wire Miso_bit,    

   
    output wire Sclk_pad,
    output wire Mosi_pad,
    output wire CS_n_pad,
    input  wire Miso_pad
);

    
    assign Sclk_pad = Sclk_out;
    assign Mosi_pad = Mosi_bit;
    assign CS_n_pad = CS_n;

    reg miso_sync_stage1;
    reg miso_sync_stage2;

    always @(posedge pclk or posedge rst) begin
        if (rst) begin
            miso_sync_stage1 <= 1'b0;
            miso_sync_stage2 <= 1'b0;
        end
        else begin
            miso_sync_stage1 <= Miso_pad;
            miso_sync_stage2 <= miso_sync_stage1;
        end
    end

    assign Miso_bit = miso_sync_stage2;

endmodule