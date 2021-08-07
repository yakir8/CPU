module alu
    import cpuPkg::*;
    #(
        parameter WIDTH     = 4
    )(
        input   logic   [WIDTH-1:0]     num1,
        input   logic   [WIDTH-1:0]     num2,
        input   ALUFunc                 func,
        output  logic   [WIDTH-1:0]     result,
        output  logic                   carry_flag,
        output  logic                   negative_flag,
        output  logic                   zero_flag,
        output  logic                   overflow_flag
    );
    
    always_comb begin
        result          = '1;
        carry_flag      = 1'b0;
        overflow_flag   = 1'b0;
        case (func)
            ALU_INC: begin
                {carry_flag, result}    = num1 + 1;
            end
            ALU_ADD: begin
                {carry_flag, result}    = num1 + num2;
            end
            ALU_ADD_INC: begin
                {carry_flag, result}    = num1 + num2 + 1;
            end
            ALU_SUB_1C: begin
                {carry_flag, result}    = num1 + ~num2;
                result += carry_flag;
            end
            ALU_SUB: begin
                {carry_flag, result}    = num1 - num2;
            end
            ALU_DEC: begin
                {carry_flag, result}    = num1 - 1;
            end
            ALU_PASS: begin
                result = num1;
            end
            ALU_NOT: begin
                result  = ~num1;
            end
            ALU_AND: begin
                result  = num1 & num2;
            end
            ALU_OR: begin
                result  = num1 | num2;
            end
            ALU_XOR: begin
                result  = num1 ^ num2;
            end
            ALU_PASS2: begin
                result  = num2;
            end
            ALU_SHR: begin
                {result, carry_flag}    = {1'b0, num2};
            end
            ALU_SHL: begin
                {result, carry_flag}    = {num2[WIDTH-2:0], 1'b0, num2[WIDTH-1]};
            end
            default: begin
                result  = '1;
            end
        endcase
    end
    
    assign  negative_flag   = result[WIDTH-1];
    assign  zero_flag       = (result == '0);
endmodule
