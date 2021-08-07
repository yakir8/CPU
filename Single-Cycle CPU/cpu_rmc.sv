module cpu_rmc
    import cpuPkg::*;
    (
        input   logic                           clk,
        input   logic                           rstn,
        output  logic                           halt,
        
        //requests fifo
        input   logic   [CPU_DATA_WIDTH-1:0]    req_fifo_data,
        output  logic                           req_fifo_deq,
        input   logic                           req_fifo_rdempty,
		
	//read fifo
        output  logic   [CPU_DATA_WIDTH-1:0]    read_fifo_data_in,
        output  logic                           read_fifo_enq,
        input   logic                           read_fifo_wrfull
    );
    
    logic   [REGFILE_ADDR_WIDTH-1:0]    regfile_rdaddr1;
    logic   [REGFILE_ADDR_WIDTH-1:0]    regfile_rdaddr2;
    logic   [REGFILE_ADDR_WIDTH-1:0]    regfile_wraddr;
    logic   [CPU_DATA_WIDTH-1:0]        regfile_data_out1;
    logic   [CPU_DATA_WIDTH-1:0]        regfile_data_out2;
    logic   [CPU_DATA_WIDTH-1:0]        regfile_data_in;
    logic                               regfile_wren;
    RegfileDataInSel                    regfile_data_in_sel;
    logic                               ram_wren;
    logic   [CPU_DATA_WIDTH-1:0]        ram_data_out;
	logic   [CPU_DATA_WIDTH-1:0]        ram_data_in;
    logic   [PC_WIDTH-1:0]              pc; //program counter
    logic   [PC_WIDTH-1:0]              pc_offset;
    logic   [PC_WIDTH-1:0]              next_pc;
    logic   [CPU_INST_WIDTH-1:0]        inst;
    Branch                              branch_type;
    logic                               halt_;
    logic   [CPU_DATA_WIDTH-1:0]        alu_result;
    logic   [CPU_DATA_WIDTH-1:0]        alu_data_in1;
    logic   [CPU_DATA_WIDTH-1:0]        alu_data_in2;
    ALUFunc                             alu_func;
    ALUDataIn2Sel                       alu_data_in2_sel;
    logic   [CPU_DATA_WIDTH-1:0]        alu_const;
    logic   [NUM_FLAGS-1:0]             flags;
    
    
    /***********************
    *     Control Unit     *
    ***********************/
    
    always_ff @(posedge clk, negedge rstn) begin
        if (!rstn) begin
            pc  <= '0;
        end
        else if (!halt_) begin
            pc  <= next_pc;
        end
    end
    
    /*ram_sp*/ rom #(
        .DATA_W    	 (CPU_INST_WIDTH),
        .NUM_WORDS 	 (INST_MEM_SIZE),
        .ADDR_W    	 (PC_WIDTH)
    ) inst_mem (
        //.clk        (clk),
        //.wren       (1'b0),
        //.data_in    ('0),
        //.rden       (1'b1),
        .addr       	(pc),
        .data_out   	(inst)
    );
    
    inst_decoder inst_decoder (
        .inst_in                (inst),
        .regfile_rdaddr1        (regfile_rdaddr1),
        .regfile_rdaddr2        (regfile_rdaddr2),
        .regfile_wraddr         (regfile_wraddr),
        .regfile_wren           (regfile_wren),
        .alu_func               (alu_func),
        .ram_wren               (ram_wren),
        .regfile_data_in_sel    (regfile_data_in_sel),
        .alu_data_in2_sel       (alu_data_in2_sel),
        .alu_const              (alu_const),
        .pc_offset              (pc_offset),
        .branch_type            (branch_type),
		.req_fifo_empty			(req_fifo_rdempty),
		.read_fifo_enq			(read_fifo_enq),
		.read_fifo_wrfull		(read_fifo_wrfull),
		.req_fifo_deq			(req_fifo_deq),
        .halt                   (halt_)
    );
    	
    branch_control branch_control_inst (
        .next_pc        (next_pc),
        .pc             (pc),
        .pc_offset      (pc_offset),
        .cf             (flags[FLAG_C]),
        .zf             (flags[FLAG_Z]),
        .nf             (flags[FLAG_N]),
        .of             (flags[FLAG_O]),
        .branch_type    (branch_type)
    );
    
    always_ff @(posedge clk, negedge rstn) begin
        if (!rstn) begin
            halt    <= 1'b0;
        end
        else if (halt_) begin
            halt    <= 1'b1;
        end
    end    
    
    /***********************
    *      Data Path       *
    ***********************/
        
    always_comb begin
		case(regfile_data_in_sel)
			REGFILE_DIN_ALU: begin
					regfile_data_in   = alu_result;
			end
			REGFILE_DIN_RAM: begin
					regfile_data_in   = ram_data_out;
			end
			REGFILE_DIN_FIFO: begin
					regfile_data_in   = req_fifo_data;
			end
		endcase
	end

    regfile #(
        .DATA_W     (CPU_DATA_WIDTH),
        .NUM_REGS   (REGFILE_NUM_REGS),
        .READ_PORTS (REGFILE_RD_PORTS)
    ) register_file (
        .clk        (clk),
        .rstn       (rstn),
        //read I/F - asynchronous
        .rdaddr     ({regfile_rdaddr2, regfile_rdaddr1}),
        .data_out   ({regfile_data_out2, regfile_data_out1}),
        //write I/F - synchronous
        .data_in    (regfile_data_in),
        .wraddr     (regfile_wraddr),
        .wren       (regfile_wren)
    );

	assign	read_fifo_data_in = regfile_data_out1;
    		
	ram_sp #(
        .DATA_W             (CPU_DATA_WIDTH),
        .NUM_WORDS          (DATA_MEM_SIZE),
        .ADDR_W             (DATA_MEM_ADDR_W),
        .REGISTERED_OUTPUT  (0)
    ) data_mem (
        .clk        		(clk),
        .data_in    		(regfile_data_out2),
        .data_out   		(ram_data_out),
        .addr       		(regfile_data_out1),
        .wren       		(ram_wren),
        .rden       		(1'b1)
    );
    
    assign  alu_data_in1    = regfile_data_out1;
    assign  alu_data_in2    = (alu_data_in2_sel == ALU_DIN2_CONST) ? alu_const : regfile_data_out2;
    
    alu #(
        .WIDTH          (CPU_DATA_WIDTH)
    ) alu_inst (
        .num1           (alu_data_in1),
        .num2           (alu_data_in2),
        .func           (alu_func),
        .result         (alu_result),
        .carry_flag     (flags[FLAG_C]),
        .negative_flag  (flags[FLAG_N]),
        .zero_flag      (flags[FLAG_Z]),
        .overflow_flag  (flags[FLAG_O])
    );
	
endmodule
