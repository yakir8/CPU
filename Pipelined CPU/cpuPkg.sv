package cpuPkg;
    parameter   CPU_DATA_WIDTH      = 16;
    parameter   REGFILE_NUM_REGS    = 8;
    parameter   REGFILE_ADDR_WIDTH  = $clog2(REGFILE_NUM_REGS);
    parameter   REGFILE_RD_PORTS    = 2;
    parameter   INST_MEM_SIZE       = 1024;
    parameter   PC_WIDTH            = $clog2(INST_MEM_SIZE);
    parameter   DATA_MEM_SIZE       = 1 << CPU_DATA_WIDTH; //2 ** DATA_WIDTH
    parameter   DATA_MEM_ADDR_W     = $clog2(DATA_MEM_SIZE);
    
    parameter   ALU_FUNC_WIDTH  = 4;
    typedef enum logic [ALU_FUNC_WIDTH-1:0] {
        //Arithmetic Functions
        ALU_PASS,
        ALU_ADD,
        ALU_SUB,
        ALU_INC,
        ALU_DEC,
        ALU_ADD_INC,
        ALU_SUB_1C,
        //Logic Functions
        ALU_NOT,
        ALU_AND,
        ALU_OR,
        ALU_XOR,
        ALU_PASS2,
        ALU_SHR,
        ALU_SHL,
        NUM_ALU_FUNC
    } ALUFunc;
    parameter   NUM_AU_FUNC = ALU_SUB_1C + 1;
    parameter   NUM_LU_FUNC = NUM_ALU_FUNC - NUM_AU_FUNC;
    
    parameter   REGFILE_DATA_IN_SEL_WIDTH   = 2;
    typedef enum logic [REGFILE_DATA_IN_SEL_WIDTH-1:0] {
        REGFILE_DIN_ALU,
        REGFILE_DIN_RAM,
		REGFILE_DIN_FIFO
    } RegfileDataInSel;
    
    parameter   ALU_DATA_IN2_SEL_WIDTH      = 1;
    typedef enum logic [ALU_DATA_IN2_SEL_WIDTH-1:0] {
        ALU_DIN2_REGFILE,
        ALU_DIN2_CONST
    } ALUDataIn2Sel;
    
    parameter   NUM_FLAGS       = 4;
    parameter   FLAG_TYPE_WIDTH = $clog2(NUM_FLAGS);
    typedef enum logic [FLAG_TYPE_WIDTH-1:0] {
        FLAG_C, //carry
        FLAG_O, //overflow
        FLAG_Z, //zero
        FLAG_N  //negative
    } Flag;
    
    parameter   NUM_BRANCH_TYPES    = 10;
    parameter   BRANCH_TYPE_WIDTH   = $clog2(NUM_BRANCH_TYPES);
    typedef enum logic [BRANCH_TYPE_WIDTH-1:0] {
        BR_NONE,
        BR_JUMP,
        BR_C,
        BR_NC,
        BR_O,
        BR_NO,
        BR_Z,
        BR_NZ,
        BR_N,
        BR_P,
		BR_FIFO
    } Branch;
    
    parameter   CPU_INST_WIDTH  = CPU_DATA_WIDTH;
    
    //ISA params
    parameter   OPCODE_WIDTH    = CPU_INST_WIDTH - (3 * REGFILE_ADDR_WIDTH);
    //opcodes
    parameter   IM_OFFSET       = 64;
    typedef enum logic [OPCODE_WIDTH-1:0] {
       OP_NOP          = 0,
        OP_INC          = 1,
        OP_ADD          = 2,
        OP_ADD_INC      = 3,
        OP_SUB_1C       = 4,
        OP_SUB          = 5,
        OP_DEC          = 6,
        OP_MOV          = 7,
        OP_AND          = 8,
        OP_OR           = 9,
        OP_XOR          = 10,
        OP_NOT          = 11,
        OP_SHIFT_RIGHT  = 20,
        OP_SHIFT_LEFT   = 24,
        OP_LOAD_FIFO	= 30,
		OP_STORE_FIFO	= 31,
		OP_STORE        = 32,
        OP_LOAD         = 48,
        OP_ADD_IM       = 66,
        OP_SUB_1C_IM    = 68,
        OP_SUB_IM       = 69,
        OP_MOV_IM       = 71,
        OP_AND_IM       = 72,
        OP_OR_IM        = 73,
        OP_XOR_IM       = 74,
        OP_BRANCH_C     = 96,
        OP_BRANCH_NC    = 97,
        OP_BRANCH_Z     = 98,
        OP_BRANCH_NZ    = 99,
        OP_BRANCH_O     = 100,
        OP_BRANCH_NO    = 101,
        OP_BRANCH_N     = 102,
        OP_BRANCH_P     = 103,
        OP_JUMP         = 112,
        OP_HALT         = 127
    } Opcode;
    
    typedef struct packed {
        logic   [REGFILE_ADDR_WIDTH-1:0]    regfile_wraddr;
        logic   [REGFILE_ADDR_WIDTH-1:0]    regfile_rdaddr1;
        logic   [REGFILE_ADDR_WIDTH-1:0]    regfile_rdaddr2;
    } FmtReg;
    
    typedef struct packed {
        logic   [REGFILE_ADDR_WIDTH-1:0]    regfile_wraddr;
        logic   [REGFILE_ADDR_WIDTH-1:0]    regfile_rdaddr1;
        logic   [REGFILE_ADDR_WIDTH-1:0]    imm; //immediate value
    } FmtImm;
    
    typedef struct packed {
        logic   [REGFILE_ADDR_WIDTH-1:0]    addr_offset_msb;
        logic   [REGFILE_ADDR_WIDTH-1:0]    regfile_rdaddr1;
        logic   [REGFILE_ADDR_WIDTH-1:0]    addr_offset_lsb;
    } FmtBranch;
    
    typedef union packed {
        FmtReg      reg_reg;
        FmtImm      reg_imm;
        FmtBranch   branch;
    } InstFmt;
    
    typedef struct packed {
        Opcode  opcode;
        InstFmt fmt; //instruction format
    } Inst;
    
endpackage
