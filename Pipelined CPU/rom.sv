module rom #(
        parameter   DATA_W      = 1,
        parameter   NUM_WORDS   = 2,
        parameter   ADDR_W      = $clog2(NUM_WORDS)
    )(
        output  logic   [DATA_W-1:0]    data_out,
        input   logic   [ADDR_W-1:0]    addr
    );
    
    logic   [DATA_W-1:0]    mem [0:NUM_WORDS-1];
    
    assign  data_out    = mem[addr];
endmodule
