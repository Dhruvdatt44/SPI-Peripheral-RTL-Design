module spi_engine_top#(
    parameter WORD_LEN  = 8,
    parameter DIV_WIDTH = 16
)(
input Pclk,
input Rst,
input Start_transfer,
input [DIV_WIDTH-1:0] Clk_div_val,
input CPOL,
input CPHA,
input Miso_bit,
input [WORD_LEN-1:0] Tx_data_in,
output Busy,
output Done_pulse,
output CS_n,
output Sclk_out,
output Mosi_bit,
output [WORD_LEN-1:0] Rx_data_out
);
wire Load;
wire Enable;
wire Sclk_tick;
wire Shift_en;
wire Sample_en;
wire Last_bit;

SPI_FSM fsm(
.pclk(Pclk),
.rst(Rst),
.start_transfer(Start_transfer),
.last_bit(Last_bit),
.busy(Busy),
.done_pulse(Done_pulse),
.cs_n(CS_n),
.load(Load),
.engine_enable(Enable)
);

spi_clkdiv #(.DIV_WIDTH(DIV_WIDTH)) CLKDIV(
.pclk(Pclk),
.rst(Rst),
.enable(Enable),
.clkdiv_val(Clk_div_val),
.sclk_tick(Sclk_tick)
);

shiftregisters  #(.WORD_LEN(WORD_LEN)) SR(
.pclk(Pclk),
.rst(Rst),
.load(Load),
.shift_en(Shift_en),
.sample_en(Sample_en),
.tx_data_in(Tx_data_in),
.miso_bit(Miso_bit),
.mosi_bit(Mosi_bit),
.rx_data_out(Rx_data_out),
.last_bit(Last_bit)
);
SPI_edge_gen EdgeGen(
.pclk(Pclk),
.rst(Rst),
.enable(Enable),
.sclk_tick(Sclk_tick),
.cpol(CPOL),
.cpha(CPHA),
.sclk_out(Sclk_out),
.sample_en(Sample_en),
.shift_en(Shift_en)
);
endmodule