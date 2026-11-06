module SPI_FSM(
input pclk,
input rst,
input start_transfer,
input last_bit,
output reg busy,
output reg done_pulse,
output reg cs_n,
output reg load,
output reg engine_enable);

localparam IDLE      = 3'b00;
localparam CS_SETUP  = 3'b001;
localparam SHIFT     = 3'b010;
localparam CS_HOLD   = 3'b011;
localparam DONE      = 3'b100; 

reg [2:0] state;
localparam hold_cycle=2;
localparam setup_cycles =2;
reg [3:0] hold_counter;
reg [3:0] setup_counter;


always @(posedge pclk or posedge rst)begin
    if (rst)begin
    state<=IDLE;
    busy<=0;
    done_pulse<=0;
    cs_n<=1;
    load<=0;
    engine_enable<=0;
    setup_counter<=0;
    hold_counter<=0;
    end
    else begin
         case (state)
           IDLE:begin 
                cs_n<=1;
                busy<=0;
                done_pulse<=0;
                load<=0;
                engine_enable<=0;
                 if (start_transfer)begin
                    state<=CS_SETUP;
                    setup_counter<=0;
                    hold_counter<=0;
                 end   
                 else begin
                  state<=IDLE;
                  
                  end  
            end
            CS_SETUP:begin
                 load<= (setup_counter==0);
                 if (setup_counter==setup_cycles-1) begin
                    state<=SHIFT;
                    setup_counter<=setup_counter;
                 end   
                 else begin
                 state<=CS_SETUP;
                 setup_counter<=setup_counter+1;
                 end  
                 engine_enable<=0;
                 cs_n<=0;
                 busy<=1;
                 done_pulse<=0; 
            end              
            SHIFT:begin
               load<=0;
               cs_n<=0;
               engine_enable<=1;
               busy<=1;
               done_pulse<=0;
               if(last_bit)begin
                 state<=CS_HOLD;
                 end
               else begin
                 state<=SHIFT;
                 end
             end
             CS_HOLD:begin
               cs_n<=0;
               load<=0;
               busy<=1;
               engine_enable<=0;
               done_pulse<=0;
               if(hold_counter==hold_cycle-1)begin
                 state<=DONE;
                 hold_counter<=hold_counter;
                 end
               else begin
                state<=CS_HOLD;
                hold_counter<=hold_counter+1;
                end
             end
             DONE:begin
                load<=0;
                cs_n<=1;
                engine_enable<=0;
                busy<=0;
                done_pulse<=1;
                state<=IDLE;
                
             end
         endcase
    end
end  
endmodule