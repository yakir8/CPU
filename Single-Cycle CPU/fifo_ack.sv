module fifo_ack #(
        parameter   WIDTH       = 2,
        parameter   DEPTH       = 2, //must be a power of 2
        parameter   ADDR_W      = $clog2(DEPTH),
        parameter   ACK_FIFO    = 1
    )(
        input   logic               clk,
        input   logic               rstn,
        
        //write I/F
        input   logic   [WIDTH-1:0] data_in,
        input   logic               enq,
        output  logic               wrfull,
        
        //read I/F
        output  logic   [WIDTH-1:0] data_out,
        input   logic               deq,
        output  logic               rdempty
    );
    
    logic   [ADDR_W:0]      rdptr;
    logic   [ADDR_W:0]      wrptr;
    logic   [ADDR_W-1:0]    rdaddr;
    logic   [ADDR_W-1:0]    wraddr;
    logic                   rden;
    logic                   wren;
    logic                   ack;
    
    assign  rdaddr  = rdptr[ADDR_W-1:0];
    assign  wraddr  = wrptr[ADDR_W-1:0];
    assign  ack     = (deq & ~rdempty);
    assign  wren    = enq & ~wrfull;
    assign  rden    = ack || (ACK_FIFO && wren && rdempty);
    
	ram_dp #(
        .DATA_W     (WIDTH),
        .NUM_WORDS  (DEPTH),
        .ADDR_W     (ADDR_W),
        .READ_NEW   (ACK_FIFO)
    ) mem (
        .clk        (clk),
        .data_in    (data_in),
        .data_out   (data_out),
        .rdaddr     (rdaddr + ADDR_W'(ACK_FIFO ? ack : 0)),
        .wraddr     (wraddr),
        .wren       (wren),
        .rden       (rden)
    );
    
    //write
    always_ff @(posedge clk, negedge rstn) begin
        if (!rstn) begin
            wrptr   <= '0;
        end
        else if (wren) begin
            wrptr   <= wrptr + 1;
        end
    end
    
    //read
    always_ff @(posedge clk, negedge rstn) begin
        if (!rstn) begin
            rdptr   <= '0;
        end
        else if (ack) begin
            rdptr   <= rdptr + 1;
        end
    end
    
    assign  wrfull  = (rdaddr == wraddr) && (rdptr[ADDR_W] != wrptr[ADDR_W]);
    assign  rdempty = (rdaddr == wraddr) && (rdptr[ADDR_W] == wrptr[ADDR_W]);
endmodule
