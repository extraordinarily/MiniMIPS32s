`include "defines.v"

module scu(
    input  wire              cpu_rst_n,

    input  wire              botb_stall_request,
    input  wire              stallreq_id,//��ͣ����
    input  wire              stallreq_exe,//��ͣ����

    output wire [`STALL_BUS] stall//��ͣ�ź�
    );

    assign stall = (cpu_rst_n == `RST_ENABLE) ? 5'b00000 :
                   (botb_stall_request == `STOP) ? 5'b11111 :
                   (stallreq_exe == `STOP   ) ? 5'b01111 :
                   (stallreq_id  == `STOP   ) ? 5'b00111 : 5'b00000;

endmodule
