`timescale 1ns/1ps
module fifo_tb();
    localparam FIFO_WIDTH = 4;
    localparam FIFO_DEPTH = 4;
    
    logic                       clk;
    logic                       rstn;
    logic   [FIFO_WIDTH-1:0]    data_in;
    logic                       enq;
    logic                       wrfull;
    logic   [FIFO_WIDTH-1:0]    data_out;
    logic                       deq;
    logic                       rdempty;
    
    fifo_ack #(
        .WIDTH  (FIFO_WIDTH),
        .DEPTH  (FIFO_DEPTH)
    ) fifo_rdreq (
        .clk        (clk),
        .rstn       (rstn),
        .data_in    (data_in),
        .enq        (enq),
        .wrfull     (wrfull),
        .data_out   (data_out),
        .deq        (deq),
        .rdempty    (rdempty)
    );
    
    always #1 clk   = ~clk;
    
    initial begin
        clk  = 1'b1;
        rstn = 1'b1;
        data_in = '0;
        enq  = 1'b0;
        deq  = 1'b0;
        #1 rstn = 1'b0;
        @(posedge clk) rstn = 1'b1;
        data_in = 8;
        enq  = 1'b1;
        @(posedge clk) enq = 1'b0;
        @(posedge clk) deq = 1'b1;
        @(posedge clk) deq = 1'b0;
        @(posedge clk) enq = 1'b1;
        data_in = 6;
        @(posedge clk) data_in = 7;
        @(posedge clk) data_in = 3;
        @(posedge clk);
        @(posedge clk) enq = 1'b0;
        deq = 1'b1;
        @(posedge clk) deq = 1'b0;
        @(posedge clk) deq = 1'b1;
        repeat (3) begin
            @(posedge clk);
        end
        deq = 1'b0;
        @(posedge clk);
        @(posedge clk) $finish;
    end
endmodule
