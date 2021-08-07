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
    logic   [REGFILE_ADDR_WIDTH-1:0]    id_ex_regfile_wraddr;
    logic   [REGFILE_ADDR_WIDTH-1:0]    ex_wb_regfile_wraddr;
    logic   [CPU_DATA_WIDTH-1:0]        regfile_data_out1;
    logic   [CPU_DATA_WIDTH-1:0]        regfile_data_out2;
    logic   [CPU_DATA_WIDTH-1:0]        id_ex_regfile_data_out1;
    logic   [CPU_DATA_WIDTH-1:0]        id_ex_regfile_data_out2;
    logic   [CPU_DATA_WIDTH-1:0]        regfile_data_in;
    logic                               regfile_wren;
    logic                               id_ex_regfile_wren;
    logic                               ex_wb_regfile_wren;
	logic                           	id_req_fifo_deq;
	logic                           	id_ex_req_fifo_deq;
	logic                           	ex_wb_req_fifo_deq;
    RegfileDataInSel                    regfile_data_in_sel;
    RegfileDataInSel                    id_ex_regfile_data_in_sel;
    RegfileDataInSel                    ex_wb_regfile_data_in_sel;
    logic                               ram_wren;
    logic                               id_ex_ram_wren;
    logic   [CPU_DATA_WIDTH-1:0]        ram_data_out;
    logic   [PC_WIDTH-1:0]              pc; //program counter
    logic   [PC_WIDTH-1:0]              if_id_pc; //program counter
    logic   [PC_WIDTH-1:0]              id_ex_pc; //program counter
    logic   [PC_WIDTH-1:0]              ex_wb_pc; //program counter
    logic   [PC_WIDTH-1:0]              pc_offset;
    logic   [PC_WIDTH-1:0]              id_ex_pc_offset;
    logic   [PC_WIDTH-1:0]              next_pc;
    logic   [CPU_INST_WIDTH-1:0]        inst;
    //logic   [CPU_INST_WIDTH-1:0]        if_id_inst;
    Branch                              branch_type;
    Branch                              id_ex_branch_type;
    logic                               halt_;
    logic                               id_ex_halt;
    logic                               ex_wb_halt;
    logic   [CPU_DATA_WIDTH-1:0]        alu_result;
    logic   [CPU_DATA_WIDTH-1:0]        ex_wb_alu_result;
    logic   [CPU_DATA_WIDTH-1:0]        alu_data_in1;
    logic   [CPU_DATA_WIDTH-1:0]        alu_data_in2;
    ALUFunc                             alu_func;
    ALUFunc                             id_ex_alu_func;
    ALUDataIn2Sel                       alu_data_in2_sel;
    ALUDataIn2Sel                       id_ex_alu_data_in2_sel;
    logic   [CPU_DATA_WIDTH-1:0]        alu_const;
    logic   [CPU_DATA_WIDTH-1:0]        id_ex_alu_const;
    logic   [NUM_FLAGS-1:0]             flags;
    Inst                                if_id_inst;
    Inst                                id_ex_inst;
    Inst                                ex_wb_inst;
    logic                               flush;
    
    /***********************
    *     Control Unit     *
    ***********************/
    
    always_ff @(posedge clk, negedge rstn) begin
        if (!rstn) begin
            pc  <= '0;
        end
        else if (!halt) begin
            if (flush) begin
                pc  <= next_pc;
            end
            else begin
                pc  <= pc + 1;
            end
        end
    end
    
    /*ram_sp*/ rom #(
        .DATA_W     (CPU_INST_WIDTH),
        .NUM_WORDS  (INST_MEM_SIZE),
        .ADDR_W     (PC_WIDTH)
    ) inst_mem (
        //.clk        (clk),
        //.wren       (1'b0),
        //.data_in    ('0),
        //.rden       (1'b1),
        .addr       (pc),
        .data_out   (inst)
    );
    
    //   IF/ID
    always_ff @(posedge clk, negedge rstn) begin
        if (!rstn) begin
            if_id_pc    <= '1;
            if_id_inst  <= Inst'{opcode: OP_NOP, default: 0}; //'0;
        end
        else if (!halt) begin
            if_id_pc    <= pc;
            if_id_inst  <= inst;
            if (flush) begin
                if_id_pc    <= '1;
                if_id_inst  <= Inst'{opcode: OP_NOP, default: 0};
            end
        end
    end
    
    inst_decoder inst_decoder (
        .inst_in                (if_id_inst),
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
		.req_fifo_empty			(req_fifo_rdempty),
		.req_fifo_deq			(id_req_fifo_deq),
		.read_fifo_enq			(read_fifo_enq),
		.read_fifo_wrfull		(read_fifo_wrfull),
        .branch_type            (branch_type),
        .halt                   (halt_)
    );
    
    /***********************
    *      Data Path       *
    ***********************/
        
	 always_comb begin
		case(ex_wb_regfile_data_in_sel)
			REGFILE_DIN_ALU: begin
					regfile_data_in   = ex_wb_alu_result;
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
        .wraddr     (ex_wb_regfile_wraddr),
        .wren       (ex_wb_regfile_wren)
    );
	
	assign	read_fifo_data_in = regfile_data_out1;
    
    //   ID/EX
    always_ff @(posedge clk, negedge rstn) begin
        if (!rstn) begin
            id_ex_pc                    <= '1;
            id_ex_inst                  <= Inst'{opcode: OP_NOP, default: 0};
            id_ex_alu_func              <= ALU_PASS;
            id_ex_ram_wren              <= 1'b0;
            id_ex_alu_data_in2_sel      <= ALU_DIN2_CONST;
            id_ex_alu_const             <= '0;
            id_ex_regfile_data_out1     <= '0;
            id_ex_regfile_data_out2     <= '0;
            id_ex_regfile_data_in_sel   <= REGFILE_DIN_RAM;
            id_ex_branch_type           <= BR_NONE;
            id_ex_pc_offset             <= '0;
            id_ex_halt                  <= 1'b0;
            id_ex_regfile_wraddr        <= '0;
            id_ex_regfile_wren          <= 1'b0;
			id_ex_req_fifo_deq			<= 1'b0;
        end
        else if (!halt) begin
            id_ex_pc                    <= if_id_pc;
            id_ex_inst                  <= if_id_inst;
            id_ex_alu_func              <= alu_func;
            id_ex_ram_wren              <= ram_wren;
            id_ex_alu_data_in2_sel      <= alu_data_in2_sel;
            id_ex_alu_const             <= alu_const;
            id_ex_regfile_data_out1     <= regfile_data_out1;
            id_ex_regfile_data_out2     <= regfile_data_out2;
            id_ex_regfile_data_in_sel   <= regfile_data_in_sel;
            id_ex_branch_type           <= branch_type;
            id_ex_pc_offset             <= pc_offset;
            id_ex_halt                  <= halt_;
            id_ex_regfile_wraddr        <= regfile_wraddr;
            id_ex_regfile_wren          <= regfile_wren;
			id_ex_req_fifo_deq			<= id_req_fifo_deq;
            if (flush) begin
                id_ex_pc                    <= '1;
                id_ex_inst                  <= Inst'{opcode: OP_NOP, default: 0};
                id_ex_ram_wren              <= 1'b0;
                id_ex_branch_type           <= BR_NONE;
                id_ex_halt                  <= 1'b0;
                id_ex_regfile_wren          <= 1'b0;
				id_ex_req_fifo_deq			<= 1'b0;
            end
        end
    end
    
    ram_sp #(
        .DATA_W             (CPU_DATA_WIDTH),
        .NUM_WORDS          (DATA_MEM_SIZE),
        .ADDR_W             (DATA_MEM_ADDR_W),
        .REGISTERED_OUTPUT  (1)
    ) data_mem (
        .clk        (clk),
        .data_in    (id_ex_regfile_data_out2),
        .data_out   (ram_data_out),
        .addr       (id_ex_regfile_data_out1),
        .wren       (id_ex_ram_wren),
        .rden       (1'b1)
    );
    
    assign  alu_data_in1    = id_ex_regfile_data_out1;
    assign  alu_data_in2    = (id_ex_alu_data_in2_sel == ALU_DIN2_CONST) ? id_ex_alu_const : id_ex_regfile_data_out2;
    
    alu #(
        .WIDTH          (CPU_DATA_WIDTH)
    ) alu_inst (
        .num1           (alu_data_in1),
        .num2           (alu_data_in2),
        .func           (id_ex_alu_func),
        .result         (alu_result),
        .carry_flag     (flags[FLAG_C]),
        .negative_flag  (flags[FLAG_N]),
        .zero_flag      (flags[FLAG_Z]),
        .overflow_flag  (flags[FLAG_O])
    );
    
    branch_control branch_control_inst (
        .next_pc        (next_pc),
        .pc             (id_ex_pc),
        .pc_offset      (id_ex_pc_offset),
        .cf             (flags[FLAG_C]),
        .zf             (flags[FLAG_Z]),
        .nf             (flags[FLAG_N]),
        .of             (flags[FLAG_O]),
        .branch_type    (id_ex_branch_type)
    );
    
    assign  flush   = (PC_WIDTH'(id_ex_pc + 1) != next_pc);
    assign 	req_fifo_deq = ex_wb_req_fifo_deq;
	
    always_ff @(posedge clk, negedge rstn) begin
        if (!rstn) begin
            ex_wb_pc                    <= '1;
            ex_wb_inst                  <= Inst'{opcode: OP_NOP, default: 0};
            ex_wb_alu_result            <= '0;
            ex_wb_regfile_data_in_sel   <= REGFILE_DIN_RAM;
            ex_wb_halt                  <= 1'b0;
            ex_wb_regfile_wraddr        <= '0;
            ex_wb_regfile_wren          <= 1'b0;
			ex_wb_req_fifo_deq			<= 1'b0;
        end
        else if (!halt) begin
            ex_wb_pc                    <= id_ex_pc;
            ex_wb_inst                  <= id_ex_inst;
            ex_wb_alu_result            <= alu_result;
            ex_wb_regfile_data_in_sel   <= id_ex_regfile_data_in_sel;
            ex_wb_halt                  <= id_ex_halt;
            ex_wb_regfile_wraddr        <= id_ex_regfile_wraddr;
            ex_wb_regfile_wren          <= id_ex_regfile_wren;
			ex_wb_req_fifo_deq			<= id_ex_req_fifo_deq;
        end
    end
    
    assign  halt    = ex_wb_halt;
endmodule
