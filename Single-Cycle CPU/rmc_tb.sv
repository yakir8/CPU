`timescale 1ns/1ps
module rmc_tb();
    import cpuPkg::*;
    
    localparam  REQ_FIFO_DEPTH  = 2 ** 2; //must be a power of 2
    localparam  READ_FIFO_DEPTH = 2 ** 2; //must be a power of 2
    localparam  NUM_REQUESTS    = 5;
    localparam  MAX_WORDS       = 8;
    string      INST_ROM        = "C:/modelsim/project/Single-Cycle CPU/inst_rom.mem";
    string      DATA_RAM        = "C:/modelsim/project/Single-Cycle CPU/data_ram.mem";
    
    typedef enum logic {
        REQ_READ,
        REQ_WRITE
    } ReqType;
    
    typedef struct packed {
        logic   [CPU_DATA_WIDTH-$bits(ReqType)-1:0] num_words;
        ReqType                                     req_type;
        logic   [CPU_DATA_WIDTH-1:0]                address;
    } ReqHeader;
    
    logic                           clk;
    logic                           rstn;
    logic                           halt;
    logic   [CPU_DATA_WIDTH-1:0]    req_fifo_data_in;
    logic                           req_fifo_enq;
    logic                           req_fifo_wrfull;
    logic   [CPU_DATA_WIDTH-1:0]    req_fifo_data_out;
    logic                           req_fifo_deq;
    logic                           req_fifo_rdempty;
    
    logic                           read_fifo_deq;
    bit                             read_fifo_rdempty;
    logic   [CPU_DATA_WIDTH-1:0]    read_fifo_data_out;
    logic   [CPU_DATA_WIDTH-1:0]    read_fifo_data_in;
    logic                           read_fifo_enq;
    logic                           read_fifo_wrfull;
	
	
    int                             seed;
    ReqHeader                       req_header;
    logic   [CPU_DATA_WIDTH-1:0]    data_word;
    int                             read_stream_actual_idx;
    int                             read_stream_correct_idx;
    
    bit     [CPU_DATA_WIDTH-1:0]    data_ram    [DATA_MEM_SIZE];
    bit     [CPU_DATA_WIDTH-1:0]    read_stream_correct [NUM_REQUESTS * MAX_WORDS];
    bit     [CPU_DATA_WIDTH-1:0]    read_stream_actual  [NUM_REQUESTS * MAX_WORDS];
    
    bit                             error_flag;
    bit                             test_read_requests;
    bit                             test_write_requests;
    
    always #1 clk = ~clk;
    
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
    
	
	fifo_ack #(
        .WIDTH  (CPU_DATA_WIDTH),
        .DEPTH  (REQ_FIFO_DEPTH) //must be a power of 2
    ) read_fifo (
        .clk        (clk),
        .rstn       (rstn),
        
        //write I/F
        .data_in    (read_fifo_data_in),
        .enq        (read_fifo_enq),
        .wrfull     (read_fifo_wrfull),
        
        //read I/F
        .data_out   (read_fifo_data_out),
        .deq        (read_fifo_deq),
        .rdempty    (read_fifo_rdempty)
    );
	
	
    cpu_rmc cpu (
        .clk                (clk),
        .rstn               (rstn),
        .halt               (halt),
        
        //requests fifo
        .req_fifo_data      (req_fifo_data_out),
        .req_fifo_deq       (req_fifo_deq),
        .req_fifo_rdempty   (req_fifo_rdempty),
		
		// read fifo
		.read_fifo_data_in  (read_fifo_data_in),
        .read_fifo_enq      (read_fifo_enq),
        .read_fifo_wrfull   (read_fifo_wrfull)
    );
	
    //fifo_enq
	initial begin
        clk                     = 1'b1;
        rstn                    = 1'b1;
        seed                    = 4455;
        req_fifo_data_in        = '0;
        req_fifo_enq            = 1'b0;
        read_stream_correct_idx = 0;
        error_flag              = 0;
        test_read_requests      = 0;
        test_write_requests     = 0;
        #1 rstn                 = 1'b0;
        $readmemh(INST_ROM, cpu.inst_mem.mem);
        $readmemh(DATA_RAM, cpu.data_mem.mem);
        $readmemh(DATA_RAM, data_ram);
        @(posedge clk) rstn = 1'b1;
        repeat (NUM_REQUESTS) begin //generate requests
            req_header   = $random(seed); //generate header: num_words, req_type, address
        /*↓↓↓↓↓ delete this ↓ line to allow read requests ↓↓↓↓↓*/
           // req_header.req_type     = REQ_WRITE; //force req_type to be WRITE request
        /*↑↑↑↑↑ delete this ↑ line to allow read requests ↑↑↑↑↑*/
            req_header.num_words    = (req_header.num_words % MAX_WORDS) + 1; //limit num_words to MAX_WORDS
            
            fifo_enq({req_header.num_words, req_header.req_type}); //enq 1st header word
            fifo_enq(req_header.address); //enq 2nd header word
            while (req_header.num_words) begin //execute request
                if (req_header.req_type == REQ_WRITE) begin //WRITE request
                    test_write_requests = 1;
                    data_word = $random(seed); //generate data word
                    fifo_enq(data_word); //enq data word
                    data_ram[req_header.address] = data_word; //write data word to TB memory
                end
                else begin //READ request
                    test_read_requests  = 1;
                    read_stream_correct[read_stream_correct_idx]    = data_ram[req_header.address]; //record data read from TB memory
                    read_stream_correct_idx++; //advance pointer
                end
                req_header.address++; //advance address
                req_header.num_words--; //update words counter
            end
        end
        
        #100;
        
        if (test_read_requests) begin
            if (read_stream_actual_idx !== read_stream_correct_idx) begin //check that total number of words read by read requests is correct
                error_flag = 1;
                $display("Something is wrong! Indices should be equal");
                $display("read_stream_correct_idx = %d", read_stream_correct_idx);
                $display("read_stream_actual_idx  = %d", read_stream_actual_idx);
            end
            
            for (int idx = 0; idx < read_stream_correct_idx; idx++) begin //check that correct data was read by read requests
                if (read_stream_actual[idx] !== read_stream_correct[idx]) begin
                    error_flag = 1;
                    $display("read_stream_correct[%d] = %d", idx, read_stream_correct[idx]);
                    $display("read_stream_actual [%d] = %d", idx, read_stream_actual[idx]);
                end
            end
        end
        else begin
            $display("READ requests weren't tested");
        end
        
        if (test_write_requests) begin
            for (int idx = 0; idx < DATA_MEM_SIZE; idx++) begin //check that correct data was written to memory
                if (data_ram[idx] !== cpu.data_mem.mem[idx]) begin
                    error_flag = 1;
                    $display("data_ram        [%d] = %d", idx, data_ram[idx]);
                    $display("cpu.data_mem.mem[%d] = %d", idx, cpu.data_mem.mem[idx]);
                end
            end
        end
        else begin
            $display("WRITE requests weren't tested");
        end
        
        if (error_flag) begin
            $display("Simulation ended with errors!!!");
        end
        else begin
            $display("Simulation success!!!");
        end
        $stop;
    end
    
    //fifo_deq
    initial begin
        read_fifo_deq   = 1'b0;
        forever begin
            fifo_deq();
        end
    end
    
    always_ff @(posedge clk, negedge rstn) begin
        if (!rstn) begin
            read_stream_actual_idx  <= 0;
        end
        else if (read_fifo_deq && !read_fifo_rdempty) begin
            read_stream_actual[read_stream_actual_idx]  <= read_fifo_data_out;
            read_stream_actual_idx  <= read_stream_actual_idx + 1;
        end
    end
    
    task fifo_enq (
            input   bit [CPU_DATA_WIDTH-1:0] data_in
        );
        
        #0.1 wait (req_fifo_wrfull == 1'b0);
        while ($random(seed) & 'h3) begin //chance of 25% per clock cycle to perform enq
            @(posedge clk) #0.1;
        end
        req_fifo_data_in    = data_in;
        req_fifo_enq        = 1'b1;
        @(posedge clk) req_fifo_enq = 1'b0;
    endtask
    
    task fifo_deq ();
        #0.1 wait (read_fifo_rdempty == 1'b0);
        read_fifo_deq   = $random(seed);  //chance of 50% per clock cycle to perform deq
        @(posedge clk) read_fifo_deq = 1'b0;
    endtask
endmodule
