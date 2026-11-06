
`timescale 1ns/1ps

module tb_spi_top_all_modes;

    reg         Pclk = 0;
    reg         Preset = 1;
    reg         Psel = 0, Penable = 0, Pwrite = 0;
    reg  [7:0]  Paddr = 0;
    reg  [31:0] Pwdata = 0;
    wire [31:0] Prdata;
    wire        Pready, Irq;
    wire        CS, SCLK, MOSI;

    wire        MISO = MOSI;            // loopback

    integer errors = 0;
    integer sclk_toggles;
    reg [31:0] rd;

    spi_top dut (
        .Pclk(Pclk), .Preset(Preset), .Psel(Psel), .Penable(Penable), .Pwrite(Pwrite),
        .Paddr(Paddr), .Pwdata(Pwdata), .Prdata(Prdata), .Pready(Pready), .Irq(Irq),
        .MISO(MISO), .CS(CS), .SCLK(SCLK), .MOSI(MOSI));

    always #5 Pclk = ~Pclk;

    // count SCLK edges only while CS is low (i.e. during a transfer)
    always @(SCLK) if (CS === 1'b0) sclk_toggles = sclk_toggles + 1;

    // ---------------- APB tasks (2-phase: SETUP then ACCESS) ----------------
    task apb_write(input [7:0] addr, input [31:0] data);
        begin
            @(posedge Pclk); #1;
            Paddr = addr; Pwdata = data; Pwrite = 1; Psel = 1; Penable = 0;
            @(posedge Pclk); #1;
            Penable = 1;
            @(posedge Pclk); #1;
            Psel = 0; Penable = 0; Pwrite = 0;
        end
    endtask

    task apb_read(input [7:0] addr);
        begin
            @(posedge Pclk); #1;
            Paddr = addr; Pwrite = 0; Psel = 1; Penable = 0;
            @(posedge Pclk); #1;
            Penable = 1;
            @(posedge Pclk); #1;
            rd = Prdata;
            Psel = 0; Penable = 0;
        end
    endtask

    // ---------------- one transfer ----------------
    task run_transfer(input c_pol, input [7:0] data_to_send);
        integer timeout;
        begin
            sclk_toggles = 0;

            // SCLK must be sitting at its idle level (CPOL) before we start
            if (SCLK !== c_pol || CS !== 1'b1) begin
                errors = errors + 1;
                $display("  ERROR: idle state CS=%b SCLK=%b, expected CS=1 SCLK=%b", CS, SCLK, c_pol);
            end

            apb_write(8'h0C, {24'b0, data_to_send});   // TXDATA write -> starts transfer

            timeout = 0;
            while (Irq !== 1'b1 && timeout < 3000) begin
                @(posedge Pclk);
                timeout = timeout + 1;
            end

            if (timeout >= 3000) begin
                errors = errors + 1;
                $display("  ERROR: timed out waiting for Irq (data %h)", data_to_send);
            end
            else begin
                apb_read(8'h10);                         // RXDATA (also clears done/Irq)
                if (rd[7:0] === data_to_send)
                    $display("  PASS: sent %h, received %h", data_to_send, rd[7:0]);
                else begin
                    errors = errors + 1;
                    $display("  FAIL: sent %h, received %h", data_to_send, rd[7:0]);
                end

                if (sclk_toggles !== 16) begin
                    errors = errors + 1;
                    $display("  ERROR: SCLK toggled %0d times, expected 16", sclk_toggles);
                end
            end

            repeat (3) @(posedge Pclk); #1;
            if (Irq !== 1'b0) begin
                errors = errors + 1;
                $display("  ERROR: Irq did not clear after RXDATA read");
            end

            apb_read(8'h04);                             // STATUS
            if (rd[0] !== 1'b0 || CS !== 1'b1) begin
                errors = errors + 1;
                $display("  ERROR: not idle after transfer (busy=%b CS=%b)", rd[0], CS);
            end

            repeat (20) @(posedge Pclk);                 // visible gap between transfers
        end
    endtask

    // ---------------- one mode, three words ----------------
    task run_mode(input c_pol, input c_pha,
                  input [7:0] word_a, input [7:0] word_b, input [7:0] word_c);
        begin
            $display("--- MODE %0d (CPOL=%b CPHA=%b) ---", {c_pol, c_pha}, c_pol, c_pha);
            apb_write(8'h00, {28'b0, 1'b1, c_pha, c_pol, 1'b0});  // CTRL: irq_en, cpha, cpol
            apb_write(8'h08, 32'd3);                               // CLKDIV
            repeat (5) @(posedge Pclk);                            // let SCLK settle at new idle level
            run_transfer(c_pol, word_a);
            run_transfer(c_pol, word_b);
            run_transfer(c_pol, word_c);
        end
    endtask

    initial begin
        sclk_toggles = 0;
        $display("==== spi_top: all 4 modes, 3 words each ====");

        repeat (4) @(posedge Pclk);
        Preset = 0;
        repeat (2) @(posedge Pclk);

        run_mode(1'b0, 1'b0, 8'hA5, 8'h3C, 8'hFF);   // Mode 0
        run_mode(1'b0, 1'b1, 8'h96, 8'hC3, 8'h01);   // Mode 1
        run_mode(1'b1, 1'b0, 8'h5A, 8'hF0, 8'h80);   // Mode 2
        run_mode(1'b1, 1'b1, 8'h0F, 8'hB4, 8'h7E);   // Mode 3

        if (errors == 0) $display("==== ALL 4 MODES PASSED ====");
        else             $display("==== %0d CHECK(S) FAILED ====", errors);

        $finish;
    end

    initial begin
        #20_000_000;
        $display("==== GLOBAL TIMEOUT ====");
        $finish;
    end
endmodule
