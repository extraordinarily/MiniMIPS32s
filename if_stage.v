`include "defines.v"

module if_stage(
    input  wire                    cpu_clk_50M,
    input  wire                    cpu_rst_n,
    
    // ת��ָ��
    input  wire [`INST_ADDR_BUS]   jump_addr_1,
    input  wire [`INST_ADDR_BUS]   jump_addr_2,
    input  wire [`INST_ADDR_BUS]   jump_addr_3,
    input  wire [1:0]              jump_select,
    
    // ��ˮ����ͣ
    input  wire [`STALL_BUS    ]   stall,
    
    // �쳣����
    input  wire                    flush, //�����ˮ���ź�
    input  wire [`INST_ADDR_BUS]   cp0_excaddr, 
    
    // ���򴫲�
    output reg  [`INST_ADDR_BUS]   pc,
    output wire [`INST_ADDR_BUS]   pc_plus_4,
    output wire [`EXC_CODE_BUS ]   if_exccode_o,
    
    // ����ָ��洢��
    output wire                    ice,
    output wire [`INST_ADDR_BUS]   iaddr
    );
    
    assign pc_plus_4 = pc+4;
    
    reg [`INST_ADDR_BUS] pc_next;
    always @(*) begin
        case(jump_select)
        2'b00: pc_next <= pc_plus_4  ;
        2'b01: pc_next <= jump_addr_1;
        2'b10: pc_next <= jump_addr_3;
        2'b11: pc_next <= jump_addr_2;
        endcase
    end
    
    always @(posedge cpu_clk_50M) begin
        if (cpu_rst_n == `CHIP_DISABLE)
            pc <= `PC_INIT;
        else if (flush == `TRUE_V)
            pc <= cp0_excaddr;
        else if (stall[0] == `NOSTOP)
            pc <= pc_next;
    end
    
    assign iaddr = pc;
    assign ice = (stall[1] == `TRUE_V || flush) ? 0 : cpu_rst_n;
    assign if_exccode_o = (pc[1:0]==2'b00) ? `EXC_NONE : `EXC_ADEL;
    
endmodule