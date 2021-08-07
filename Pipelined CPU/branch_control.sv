module branch_control 
    import cpuPkg::*;
    (
        output  logic   [PC_WIDTH-1:0]      next_pc,
        input   logic   [PC_WIDTH-1:0]      pc,
        input   logic   [PC_WIDTH-1:0]      pc_offset,
        input   logic                       cf,
        input   logic                       zf,
        input   logic                       nf,
        input   logic                       of,
        input   Branch                      branch_type
    );
    
    logic is_branch;
    
    always_comb begin
        case (branch_type)
            BR_C: begin
                is_branch   = cf;
            end
            BR_NC: begin
                is_branch   = ~cf;
            end
            BR_Z: begin
                is_branch   = zf;
            end
            BR_NZ: begin
                is_branch   = ~zf;
            end
            BR_N: begin
                is_branch   = nf;
            end
            BR_P: begin
                is_branch   = ~nf;
            end
            BR_O: begin
                is_branch   = of;
            end
            BR_NO: begin
                is_branch   = ~of;
            end
            BR_JUMP: begin
                is_branch   = 1'b1;
            end
			BR_FIFO: begin
                is_branch   = 1'b1;
            end
            default: begin
                is_branch   = 1'b0;
            end
        endcase
    end
    
    always_comb begin
        next_pc = pc + 1;
        if (is_branch) begin
			if (branch_type == BR_FIFO) begin
				next_pc -= 1;
			end
			else begin
				next_pc += pc_offset;
			end
        end
    end
endmodule
