`timescale 1ns/1ps
module cpu_req_tb();

    import cpuPkg::*;
    localparam  REQ_FIFO_DEPTH  = 2 ** 2; //must be a power of 2
    localparam  READ_FIFO_DEPTH = 2 ** 2; //must be a power of 2
    localparam  NUM_REQUESTS    = 5;
    localparam  MAX_WORDS       = 8;
	
	// CPU signal
	logic   clk;
    logic   rstn;
    logic   halt;
	
	// fifo Signal
	logic   [CPU_DATA_WIDTH-1:0]    req_fifo_data_in;
    logic                           req_fifo_enq;
    logic                           req_fifo_wrfull;
    logic   [CPU_DATA_WIDTH-1:0]    req_fifo_data_out;
    logic                           req_fifo_deq;
    logic                           req_fifo_rdempty;       
		
	
    fifo_ack #(
        .WIDTH  (CPU_DATA_WIDTH),
        .DEPTH  (REQ_FIFO_DEPTH) //must be a power of 2
    ) req_fifo (
        .clk        (clk),
        .rstn       (rstn),
        
        //write I/F
        .data_in    (req_fifo_data_in),
        .enq        (req_fifo_enq),
        .wrfull     (req_fifo_wrfull),
        
        //read I/F
        .data_out   (req_fifo_data_out),
        .deq        (req_fifo_deq),
        .rdempty    (req_fifo_rdempty)
    );
	
	cpu_rmc cpu_inst (
        .clk    (clk),
        .rstn   (rstn),
        .halt   (halt),
		
		//requests fifo
        .req_fifo_data      (req_fifo_data_out),
        .req_fifo_deq       (req_fifo_deq),
        .req_fifo_rdempty   (req_fifo_rdempty)
    );
	
	
    always #10 clk = ~clk;

	
	initial begin
        clk     = 1'b1;
        rstn    = 1'b1;
        #1 rstn = 1'b0;
        $readmemh("C:/modelsim/Single-Cycle CPU/inst_rom.mem", cpu_inst.inst_mem.mem);
        $readmemh("C:/modelsim/Single-Cycle CPU/data_ram.mem", cpu_inst.data_mem.mem);
        @(posedge clk) rstn = 1'b1;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk) req_fifo_enq = 1;
		req_fifo_data_in = 16'hAAAA;
		@(posedge clk) req_fifo_enq = 0;
        @(halt) #100 $finish;
    end
endmodule

