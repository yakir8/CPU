module ram_dp #(
        parameter   DATA_W      = 1,
        parameter   NUM_WORDS   = 2,
        parameter   ADDR_W      = $clog2(NUM_WORDS),
        parameter   READ_NEW    = 0
    )(
        input   logic                   clk,
        input   logic   [DATA_W-1:0]    data_in,
        output  logic   [DATA_W-1:0]    data_out,
        input   logic   [ADDR_W-1:0]    rdaddr,
        input   logic   [ADDR_W-1:0]    wraddr,
        input   logic                   wren,
        input   logic                   rden
    );
    
    logic   [DATA_W-1:0]    mem [0:NUM_WORDS-1];
    
    always_ff @(posedge clk) begin
        if (rden) begin
            if (READ_NEW && wren && (rdaddr == wraddr)) begin
                data_out    <= data_in;
            end
            else begin
                data_out    <= mem[rdaddr];
            end
        end
    end
    
    always_ff @(posedge clk) begin
        if (wren) begin
            mem[wraddr] <= data_in;
        end
    end
endmodule
