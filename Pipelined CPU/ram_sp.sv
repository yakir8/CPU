module ram_sp #(
        parameter   DATA_W              = 1,
        parameter   NUM_WORDS           = 2,
        parameter   ADDR_W              = $clog2(NUM_WORDS),
        parameter   REGISTERED_OUTPUT   = 1
    )(
        input   logic                   clk,
        input   logic   [DATA_W-1:0]    data_in,
        output  logic   [DATA_W-1:0]    data_out,
        input   logic   [ADDR_W-1:0]    addr,
        input   logic                   wren,
        input   logic                   rden
    );
    
    logic   [DATA_W-1:0]    mem [0:NUM_WORDS-1];
    logic   [DATA_W-1:0]    data_out_s;
    
    always_ff @(posedge clk) begin
        if (rden) begin
            data_out_s  <= mem[addr];
        end
    end
    
    assign  data_out    = REGISTERED_OUTPUT ? data_out_s : mem[addr];
    
    always_ff @(posedge clk) begin
        if (wren) begin
            mem[addr]   <= data_in;
        end
    end
endmodule
