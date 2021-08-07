module regfile #(
        parameter   DATA_W      = 1,
        parameter   NUM_REGS    = 2,
        parameter   ADDR_W      = $clog2(NUM_REGS),
        parameter   READ_PORTS  = 1
    )(
        input   logic                                   clk,
        input   logic                                   rstn,
        //read I/F - asynchronous
        input   logic   [READ_PORTS-1:0][ADDR_W-1:0]    rdaddr,
        output  logic   [READ_PORTS-1:0][DATA_W-1:0]    data_out,
        //write I/F - synchronous
        input   logic                   [DATA_W-1:0]    data_in,
        input   logic                   [ADDR_W-1:0]    wraddr,
        input   logic                                   wren
    );
    
    logic   [DATA_W-1:0]    registers   [0:NUM_REGS-1];
    
    //read - asynchronous
    always_comb begin
        for (int rd_port = 0; rd_port < READ_PORTS; rd_port++) begin
            data_out[rd_port]   = registers[rdaddr[rd_port]];
        end
    end
    
    //write - synchronous
    always_ff @(posedge clk, negedge rstn) begin
        if (!rstn) begin
            for (int reg_idx = 0; reg_idx < NUM_REGS; reg_idx++) begin
                registers[reg_idx]  <= '0;
            end
        end
        else if (wren) begin
            registers[wraddr]   <= data_in;
        end
    end
endmodule
