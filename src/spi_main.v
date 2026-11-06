
module spi_top(
input Pclk,
input Preset,
input Psel,
input Penable,
input Pwrite,
input [7:0] Paddr,
input [31:0] Pwdata,
output[31:0] Prdata,
output Pready,
output Irq, 

input MISO,
output CS,
output SCLK,
output MOSI
);
wire [15:0] clk_divider;
wire start_Transfer;
wire [7:0] tx_data;
wire [7:0] rx_data;
wire Cpol;
wire Cpha;
wire Done;
wire Busy;

wire miso;
wire sclk;
wire cs;
wire mosi;

spi_register_file registers(
.pclk(Pclk),
.preset(Preset),
.psel(Psel),
.enable(Penable),
.pwrite(Pwrite),
.paddr(Paddr),
.pwdata(Pwdata),
.prdata(Prdata),
.pready(Pready),
.irq(Irq),
.clk_div(clk_divider),
.start_transfer(start_Transfer),
.tx_data_in(tx_data),
.rx_data_out(rx_data),
.cpol(Cpol),
.cpha(Cpha),
.done(Done),
.busy(Busy)
);

spi_pin_interface  inter(
.pclk(Pclk),
.rst(Preset),
.Sclk_out(sclk),
.Mosi_bit(mosi),
.Miso_bit(miso),
.CS_n(cs),
.Sclk_pad(SCLK),
.Mosi_pad(MOSI),
.CS_n_pad(CS),
.Miso_pad(MISO)
);

spi_engine_top top(
.Pclk(Pclk),
.Rst(Preset),
.Start_transfer(start_Transfer),
.Clk_div_val(clk_divider),
.CPOL(Cpol),
.CPHA(Cpha),
.Miso_bit(miso),
.Tx_data_in(tx_data),
.Busy(Busy),
.Done_pulse(Done),
.CS_n(cs),
.Sclk_out(sclk),
.Mosi_bit(mosi),
.Rx_data_out(rx_data)
);

endmodule
