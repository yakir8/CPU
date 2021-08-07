module inst_decoder 
    import cpuPkg::*;
    (
        output  logic   [REGFILE_ADDR_WIDTH-1:0]    regfile_rdaddr1,
        output  logic   [REGFILE_ADDR_WIDTH-1:0]    regfile_rdaddr2,
        output  logic   [REGFILE_ADDR_WIDTH-1:0]    regfile_wraddr,
        output  logic                               regfile_wren,
        output  ALUFunc                             alu_func,
        output  logic                               ram_wren,
        output  RegfileDataInSel                    regfile_data_in_sel,
        output  ALUDataIn2Sel                       alu_data_in2_sel,
		input   logic                       		req_fifo_empty,
		output	logic								req_fifo_deq,
		output	logic								read_fifo_enq,
		input	logic								read_fifo_wrfull,
        output  logic   [CPU_DATA_WIDTH-1:0]        alu_const,
        input   logic   [CPU_INST_WIDTH-1:0]        inst_in,
        output  logic   [PC_WIDTH-1:0]              pc_offset,
        output  Branch                              branch_type,
        output  logic                               halt
    );
    
    localparam  ADDR_OFFSET_W   = 2*REGFILE_ADDR_WIDTH;
    
    Inst                        inst;
    logic   [ADDR_OFFSET_W-1:0] addr_offset;
    
    assign  inst    = Inst'(inst_in);
    
    assign  regfile_wraddr  = inst.fmt.reg_reg.regfile_wraddr;
    assign  regfile_rdaddr1 = inst.fmt.reg_reg.regfile_rdaddr1;
    assign  regfile_rdaddr2 = inst.fmt.reg_reg.regfile_rdaddr2;
    assign  alu_const       = signed'(inst.fmt.reg_imm.imm);
    assign  addr_offset     = {inst.fmt.branch.addr_offset_msb, inst.fmt.branch.addr_offset_lsb};
    
    always_comb begin
        case (inst.opcode)
            OP_ADD, OP_ADD_IM, OP_ADD_INC, OP_AND, OP_AND_IM, OP_DEC, OP_INC, OP_LOAD,
            OP_MOV, OP_MOV_IM, OP_NOT, OP_OR, OP_OR_IM, OP_SHIFT_LEFT, OP_SHIFT_RIGHT,
            OP_XOR, OP_XOR_IM, OP_SUB_1C, OP_SUB_1C_IM, OP_SUB, OP_SUB_IM: begin
                regfile_wren    = 1'b1;
            end
			OP_LOAD_FIFO: begin
				regfile_wren    = req_fifo_empty ? 1'b0 : 1'b1;
			end
            default: begin
                regfile_wren    = 1'b0;
            end
        endcase
    end
	
	always_comb begin
        case (inst.opcode)
			OP_LOAD_FIFO: begin
				req_fifo_deq    = req_fifo_empty ? 1'b0 : 1'b1;
			end
            default: begin
                req_fifo_deq    = 1'b0;
            end
        endcase
    end
	
	always_comb begin
        case (inst.opcode)
			OP_STORE_FIFO: begin
				read_fifo_enq 	= read_fifo_wrfull ? 1'b0 : 1'b1;
			end
            default: begin
                read_fifo_enq    = 1'b0;
            end
        endcase
    end
    
    always_comb begin
        case (inst.opcode)
            OP_INC: begin
                alu_func    = ALU_INC;
            end
            OP_ADD, OP_ADD_IM: begin
                alu_func    = ALU_ADD;
            end
            OP_ADD_INC: begin
                alu_func    = ALU_ADD_INC;
            end
            OP_SUB_1C, OP_SUB_1C_IM: begin
                alu_func    = ALU_SUB_1C;
            end
            OP_SUB, OP_SUB_IM: begin
                alu_func    = ALU_SUB;
            end
            OP_DEC: begin
                alu_func    = ALU_DEC;
            end
            OP_MOV: begin
                alu_func    = ALU_PASS;
            end
            OP_MOV_IM: begin
                alu_func    = ALU_PASS2;
            end
            OP_AND, OP_AND_IM: begin
                alu_func    = ALU_AND;
            end
            OP_OR, OP_OR_IM: begin
                alu_func    = ALU_OR;
            end
            OP_XOR, OP_XOR_IM: begin
                alu_func    = ALU_XOR;
            end
            OP_NOT: begin
                alu_func    = ALU_NOT;
            end
            OP_SHIFT_RIGHT: begin
                alu_func    = ALU_SHR;
            end
            OP_SHIFT_LEFT: begin
                alu_func    = ALU_SHL;
            end
            default: begin
                alu_func    = ALU_PASS;
            end
        endcase
    end
    
    assign  ram_wren            = (inst.opcode == OP_STORE);
    
	// Selected Data In To Register File 
	always_comb begin
		case (inst.opcode)
			OP_LOAD: begin
				regfile_data_in_sel    = REGFILE_DIN_RAM;
			end
			OP_LOAD_FIFO: begin
				regfile_data_in_sel    = REGFILE_DIN_FIFO;
			end
            default: begin
                regfile_data_in_sel    = REGFILE_DIN_ALU;
            end
        endcase
	end
    
    always_comb begin
        case (inst.opcode)
            OP_ADD_IM, OP_AND_IM, OP_MOV_IM, OP_OR_IM, OP_SUB_1C_IM, OP_SUB_IM, OP_XOR_IM: begin
                alu_data_in2_sel    = ALU_DIN2_CONST;
            end
            default: begin
                alu_data_in2_sel    = ALU_DIN2_REGFILE;
            end
        endcase
    end
    
    assign  pc_offset   = signed'(addr_offset);
    
    always_comb begin
        case (inst.opcode)
            OP_JUMP: begin
                branch_type = BR_JUMP;
            end
            OP_BRANCH_C: begin
                branch_type = BR_C;
            end
            OP_BRANCH_NC: begin
                branch_type = BR_NC;
            end
            OP_BRANCH_N: begin
                branch_type = BR_N;
            end
            OP_BRANCH_P: begin
                branch_type = BR_P;
            end
            OP_BRANCH_Z: begin
                branch_type = BR_Z;
            end
            OP_BRANCH_NZ: begin
                branch_type = BR_NZ;
            end
            OP_BRANCH_O: begin
                branch_type = BR_O;
            end
			OP_LOAD_FIFO: begin
                branch_type = req_fifo_empty ? BR_FIFO : BR_NONE;
            end
            OP_BRANCH_NO: begin
                branch_type = BR_NO;
            end
			OP_STORE_FIFO: begin
                branch_type = read_fifo_wrfull ? BR_FIFO : BR_NONE;
            end
            default: begin
                branch_type = BR_NONE;
            end
        endcase
    end
    
    assign  halt    = (inst.opcode == OP_HALT);
endmodule
