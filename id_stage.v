`include "defines.v"

 module id_stage(
    input  wire                    cpu_rst_n,
    input  wire [`EXC_CODE_BUS ]   id_exccode_i,
    
    // ��ȡָ�׶λ�õ�����
    input  wire [`INST_ADDR_BUS]   id_pc_i,
    input  wire [`INST_ADDR_BUS]   pc_plus_4,
    input  wire [`INST_BUS     ]   id_inst_i,
    
    // ��ͨ�üĴ����Ѷ��������� 
    input  wire [`REG_BUS      ]   rd1,
    input  wire [`REG_BUS      ]   rd2,
    
    // ͨ�üĴ����Ѷ���ǰ��
    input  wire                    exe2id_wreg,
    input  wire [`REG_ADDR_BUS ]   exe2id_wa,
    input  wire [`INST_BUS     ]   exe2id_wd,
    input  wire                    mem2id_wreg,
    input  wire [`REG_ADDR_BUS ]   mem2id_wa,
    input  wire [`INST_BUS     ]   mem2id_wd,
    
    // ��תָ������ź�
    output wire [1:0]              jump_select,
    output wire [`INST_ADDR_BUS]   jump_addr_1,
    output wire [`INST_ADDR_BUS]   jump_addr_2,
    output wire [`INST_ADDR_BUS]   jump_addr_3,
    output wire [`INST_ADDR_BUS]   ret_addr,
    
    // ����ִ�н׶ε�������Ϣ
    output wire [`ALUTYPE_BUS  ]   id_alutype_o,
    output wire [`ALUOP_BUS    ]   id_aluop_o,
    output wire                    id_whilo_o,
    output wire                    id_mreg_o,
    output wire [`REG_ADDR_BUS ]   id_wa_o,
    output wire                    id_wreg_o,
    output wire [`REG_BUS      ]   id_din_o,
    
    // ����ִ�н׶ε�Դ������1��Դ������2
    output wire [`REG_BUS      ]   id_src1_o,
    output wire [`REG_BUS      ]   id_src2_o,
    
    // ������ͨ�üĴ����Ѷ˿ڵĶ�ʹ�ܺ͵�ַ
    output wire [`REG_ADDR_BUS ]   ra1,
    output wire [`REG_ADDR_BUS ]   ra2,
    
    // ��ˮ����ͣ
    input  wire                    exe2id_mreg,    // �жϼ������
    input  wire                    mem2id_mreg,
    output wire                    stallreq_id,    // ����׶���ͣ�����ź�
    
    // ����cp0
    output wire [`REG_ADDR_BUS ]   cp0_addr,       // CP0�мĴ����ĵ�ַ
    
    // �쳣����
    input  wire                    flush_im,       // ȡ����ָ��洢��IM������ָ��
    input  wire                    id_in_delay_i,  // ��������׶ε�ָ�����ӳٲ�ָ��
    output wire [`INST_ADDR_BUS]   id_pc_o,        // ��������׶ε�ָ���PCֵ
    output wire                    id_in_delay_o,  // ��������׶ε�ָ�����ӳٲ�ָ��
    output wire                    next_delay_o,   // ��һ����������׶ε�ָ�����ӳٲ�ָ��
    output wire [`EXC_CODE_BUS ]   id_exccode_o    // ��������׶ε�ָ����쳣���ͱ���
);
    
    // �������ź�flush_imΪ��1��,��ȡ����ָ��Ϊ��ָ��
    wire [`INST_BUS] id_inst = (flush_im == `FLUSH) ? `ZERO_WORD : id_inst_i;
    
    // ��ȡָ�����и����ֶε���Ϣ
    wire [5 :0] op   = id_inst[31:26];
    wire [5 :0] func = id_inst[5 : 0];
    wire [4 :0] rd   = id_inst[15:11];
    wire [4 :0] rs   = id_inst[25:21];
    wire [4 :0] rt   = id_inst[20:16];
    wire [4 :0] sa   = id_inst[10: 6];
    wire [15:0] imm  = id_inst[15: 0]; 
    
    /*-------------------- ��һ�������߼���ȷ����ǰ��Ҫ�����ָ�� --------------------*/
    wire inst_reg   = ~|op;   // R��ָ��
    // ��������
    wire inst_add   = inst_reg&func[5]&~func[4]&~func[3]&~func[2]&~func[1]&~func[0];
    wire inst_addi  = ~op[5]&~op[4]&op[3]&~op[2]&~op[1]&~op[0];
    wire inst_addu  = inst_reg&func[5]&~func[4]&~func[3]&~func[2]&~func[1]&func[0];
    wire inst_addiu = ~op[5]&~op[4]&op[3]&~op[2]&~op[1]&op[0];
    wire inst_sub   = inst_reg&func[5]&~func[4]&~func[3]&~func[2]&func[1]&~func[0];
    wire inst_subu  = inst_reg&func[5]&~func[4]&~func[3]&~func[2]&func[1]&func[0];
    wire inst_slt   = inst_reg&func[5]&~func[4]&func[3]&~func[2]&func[1]&~func[0];
    wire inst_slti  = ~op[5]&~op[4]&op[3]&~op[2]&op[1]&~op[0];
    wire inst_sltu  = inst_reg&func[5]&~func[4]&func[3]&~func[2]&func[1]&func[0];
    wire inst_sltiu = ~op[5]&~op[4]&op[3]&~op[2]&op[1]&op[0];
    wire inst_div   = inst_reg&~func[5]&func[4]&func[3]&~func[2]&func[1]&~func[0];
    wire inst_divu  = inst_reg&~func[5]&func[4]&func[3]&~func[2]&func[1]&func[0];
    wire inst_mult  = inst_reg&~func[5]&func[4]&func[3]&~func[2]&~func[1]&~func[0];
    wire inst_multu = inst_reg&~func[5]&func[4]&func[3]&~func[2]&~func[1]&func[0];
    // �߼�����
    wire inst_and   = inst_reg&func[5]&~func[4]&~func[3]& func[2]&~func[1]&~func[0];
    wire inst_andi  = ~op[5]&~op[4]&op[3]&op[2]&~op[1]&~op[0];
    wire inst_lui   = ~op[5]&~op[4]&op[3]&op[2]&op[1]&op[0];
    wire inst_nor   = inst_reg&func[5]&~func[4]&~func[3]&func[2]&func[1]&func[0];
    wire inst_or    = inst_reg&func[5]&~func[4]&~func[3]&func[2]&~func[1]&func[0];
    wire inst_ori   = ~op[5]&~op[4]&op[3]&op[2]&~op[1]&op[0];
    wire inst_xor   = inst_reg&func[5]&~func[4]&~func[3]&func[2]&func[1]&~func[0];
    wire inst_xori  = ~op[5]&~op[4]&op[3]&op[2]&op[1]&~op[0];
    // ��λָ��
    wire inst_sllv  = inst_reg&~func[5]&~func[4]&~func[3]&func[2]&~func[1]&~func[0];
    wire inst_sll   = inst_reg&~func[5]&~func[4]&~func[3]&~func[2]&~func[1]&~func[0];
    wire inst_srav  = inst_reg&~func[5]&~func[4]&~func[3]&func[2]&func[1]&func[0];
    wire inst_sra   = inst_reg&~func[5]&~func[4]&~func[3]&~func[2]&func[1]&func[0];
    wire inst_srlv  = inst_reg&~func[5]&~func[4]&~func[3]&func[2]&func[1]&~func[0];
    wire inst_srl   = inst_reg&~func[5]&~func[4]&~func[3]&~func[2]&func[1]&~func[0];
    // ��֧��ת
    wire inst_beq   = ~op[5]&~op[4]&~op[3]&op[2]&~op[1]&~op[0];
    wire inst_bne   = ~op[5]&~op[4]&~op[3]&op[2]&~op[1]&op[0];
    wire inst_bgez  = ~op[5]&~op[4]&~op[3]&~op[2]&~op[1]&op[0]&~rt[4]&rt[0];
    wire inst_bltz  = ~op[5]&~op[4]&~op[3]&~op[2]&~op[1]&op[0]&~rt[4]&~rt[0];
    wire inst_bgezal= ~op[5]&~op[4]&~op[3]&~op[2]&~op[1]&op[0]&rt[4]&rt[0];
    wire inst_bltzal= ~op[5]&~op[4]&~op[3]&~op[2]&~op[1]&op[0]&rt[4]&~rt[0];
    wire inst_bgtz  = ~op[5]&~op[4]&~op[3]&op[2]&op[1]&op[0];
    wire inst_blez  = ~op[5]&~op[4]&~op[3]&op[2]&op[1]&~op[0];
    wire inst_j     = ~op[5]&~op[4]&~op[3]&~op[2]&op[1]&~op[0];
    wire inst_jal   = ~op[5]&~op[4]&~op[3]&~op[2]&op[1]&op[0];
    wire inst_jr    = inst_reg&~func[5]&~func[4]&func[3]&~func[2]&~func[1]&~func[0];
    wire inst_jalr  = inst_reg&~func[5]&~func[4]&func[3]&~func[2]&~func[1]&func[0];
    //�����ƶ�
    wire inst_mfhi  = inst_reg&~func[5]&func[4]&~func[3]&~func[2]&~func[1]&~func[0];
    wire inst_mflo  = inst_reg&~func[5]&func[4]&~func[3]&~func[2]&func[1]&~func[0];
    wire inst_mthi  = inst_reg&~func[5]&func[4]&~func[3]&~func[2]&~func[1]&func[0];
    wire inst_mtlo  = inst_reg&~func[5]&func[4]&~func[3]&~func[2]&func[1]&func[0];
    //����ָ��
    wire inst_break   = inst_reg&~func[5]&~func[4]&func[3]&func[2]&~func[1]&func[0];
    wire inst_syscall = inst_reg&~func[5]&~func[4]&func[3]&func[2]&~func[1]&~func[0];
    //�ô�ָ��
    wire inst_lb    = op[5]&~op[4]&~op[3]&~op[2]&~op[1]&~op[0];
    wire inst_lbu   = op[5]&~op[4]&~op[3]&op[2]&~op[1]&~op[0];
    wire inst_lh    = op[5]&~op[4]&~op[3]&~op[2]&~op[1]&op[0];
    wire inst_lhu   = op[5]&~op[4]&~op[3]&op[2]&~op[1]&op[0];
    wire inst_lw    = op[5]&~op[4]&~op[3]&~op[2]&op[1]&op[0];
    wire inst_sb    = op[5]&~op[4]&op[3]&~op[2]&~op[1]&~op[0];
    wire inst_sh    = op[5]&~op[4]&op[3]&~op[2]&~op[1]&op[0];
    wire inst_sw    = op[5]&~op[4]&op[3]&~op[2]&op[1]&op[0];
    //��Ȩָ��
    wire inst_eret  = ~op[5]&op[4]&~op[3]&~op[2]&~op[1]&~op[0]&~func[5]&func[4]&func[3]&~func[2]&~func[1]&~func[0];
    wire inst_mfc0  = ~op[5]&op[4]&~op[3]&~op[2]&~op[1]&~op[0]&~id_inst[23];
    wire inst_mtc0  = ~op[5]&op[4]&~op[3]&~op[2]&~op[1]&~op[0]& id_inst[23];
    /*--------------------------------------------------------------------------------*/
    
    
    /*------------------------ �ڶ��������߼������ɾ�������ź� ----------------------*/
    // ��������alutype
    wire inst_lsmem = inst_lb | inst_lbu | inst_lh | inst_lhu | inst_lw | inst_sb | inst_sh | inst_sw;
    assign id_alutype_o[2] = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : 
                             (inst_sllv|inst_sll|inst_srav|inst_sra|inst_srlv|inst_srl|
                             inst_beq|inst_bne|inst_bgez|inst_bltz|inst_bgezal|inst_bltzal|inst_bgtz|inst_blez|inst_j|inst_jal|inst_jr|inst_jalr|
                             inst_break | inst_syscall | inst_eret | inst_mtc0);
    assign id_alutype_o[1] = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : 
                             (inst_and|inst_andi|inst_lui|inst_nor|inst_or|inst_ori|inst_xor|inst_xori|
                             inst_mfhi|inst_mflo|
                             inst_break | inst_syscall | inst_eret | inst_mfc0 | inst_mtc0);
    assign id_alutype_o[0] = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : 
                             (inst_add|inst_addi|inst_addu|inst_addiu|inst_sub|inst_subu|inst_slt|inst_slti|inst_sltu|inst_sltiu|inst_div|inst_divu|inst_mult|inst_multu|
                             inst_mfhi|inst_mflo|
                             inst_beq|inst_bne|inst_bgez|inst_bltz|inst_bgezal|inst_bltzal|inst_bgtz|inst_blez|inst_j|inst_jal|inst_jr|inst_jalr|
                             inst_mfc0 | inst_lsmem);

    // �ڲ�������aluop
    assign id_aluop_o[7]   = 1'b0;
    assign id_aluop_o[6]   = 1'b0;
    assign id_aluop_o[5]   = (cpu_rst_n == `RST_ENABLE) ? 1'b0 :
                             (inst_mfhi|inst_mflo|inst_mthi|inst_mtlo|
                              inst_lb|inst_lbu|inst_lh|inst_lhu|inst_lw|inst_sb|inst_sh|inst_sw|
                              inst_break|inst_syscall|inst_eret|inst_mfc0|inst_mtc0);
    assign id_aluop_o[4]   = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : 
                             (inst_lui|inst_andi|inst_nor|inst_or|inst_ori|inst_xor|inst_xori|
                              inst_sllv|inst_sll|inst_srav|inst_sra|inst_srlv|inst_srl|
                              inst_lbu|inst_lh|inst_lhu|inst_lw|inst_sb|inst_sh|inst_sw|
                              inst_eret|inst_mfc0|inst_mtc0);
    assign id_aluop_o[3]   = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : 
                             (inst_and|inst_sll|inst_srav|inst_sra|inst_srlv|inst_srl|
                             inst_slti|inst_sltu|inst_sltiu|inst_div|inst_divu|inst_mult|inst_multu|
                             inst_mfhi|inst_mflo|inst_mthi|inst_mtlo|
                             inst_lb|
                             inst_break|inst_syscall|inst_mfc0|inst_mtc0);
    assign id_aluop_o[2]   = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : 
                             (inst_and|inst_ori|inst_xor|inst_xori|inst_sllv|inst_srl|
                             inst_addiu|inst_sub|inst_subu|inst_slt|inst_divu|inst_mult|inst_multu|
                             inst_mtlo|
                             inst_lb|inst_sb|inst_sh|inst_sw|
                             inst_break|inst_syscall|inst_eret);
    assign id_aluop_o[1]   = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : 
                             (inst_and|inst_nor|inst_or|inst_xori|inst_sllv|inst_sra|inst_srlv|
                             inst_addi|inst_addu|inst_subu|inst_slt|inst_sltiu|inst_div|inst_multu|
                             inst_mflo|inst_mthi|
                             inst_lb|inst_lhu|inst_lw|inst_sw|
                             inst_syscall|inst_eret);
    assign id_aluop_o[0]   = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : 
                             (inst_and|inst_lui|inst_or|inst_xor|inst_sllv|inst_srav|inst_srlv|
                             inst_add|inst_addu|inst_sub|inst_slt|inst_sltu|inst_div|inst_mult|
                             inst_mfhi|inst_mthi|
                             inst_lb|inst_lh|inst_lw|inst_sh|
                             inst_break|inst_eret|inst_mtc0);
    
    // дͨ�üĴ���ʹ���ź�
    assign id_wreg_o = (inst_and|inst_andi|inst_lui|inst_nor|inst_or|inst_ori|inst_xor|inst_xori|
                        inst_sllv|inst_sll|inst_srav|inst_sra|inst_srlv|inst_srl|
                        inst_add|inst_addi|inst_addu|inst_addiu|inst_sub|inst_subu|inst_slt|inst_slti|inst_sltu|inst_sltiu|
                        inst_mfhi|inst_mflo|
                        inst_lb|inst_lbu|inst_lh|inst_lhu|inst_lw|
                        inst_bgezal|inst_bltzal|inst_jal|inst_jalr|
                        inst_mfc0);
    
    // д��Ŀ�ļĴ����ĵ�ַ
    wire rtsel     = inst_lui|inst_andi|inst_ori|inst_xori|inst_addi|inst_addiu|inst_slti|inst_sltiu|inst_div|inst_divu|inst_mult|inst_multu|
                     inst_lb|inst_lbu|inst_lh|inst_lhu|inst_lw|inst_mfc0;
    assign id_wa_o = (inst_bgezal|inst_bltzal|inst_jal) ? 5'b11111 :
                     rtsel ? rt : rd;
    
    // дHILO�Ĵ���ʹ���ź�
    assign id_whilo_o = (inst_div|inst_divu|inst_mult|inst_multu|inst_mthi|inst_mtlo);
    
    // д�ؽ׶�����Դ 1:data_ram 0:exe_stage
    assign id_mreg_o  = (inst_lb|inst_lbu|inst_lh|inst_lhu|inst_lw);
    /*------------------------------------------------------------------------------*/
    
    // ��ͨ�üĴ����Ѷ˿�1�ĵ�ַΪrs�ֶΣ����˿�2�ĵ�ַΪrt�ֶ�
    assign ra1 = rs;
    assign ra2 = rt;
    // ����ǰ��
    wire[1:0] fwrd1 =   (cpu_rst_n == `RST_ENABLE) ? 2'b00 :
                        (exe2id_wreg == `WRITE_ENABLE && exe2id_wa == ra1) ? 2'b01 :
                        (mem2id_wreg == `WRITE_ENABLE && mem2id_wa == ra1) ? 2'b10 :2'b11;
    wire[1:0] fwrd2 =   (cpu_rst_n == `RST_ENABLE) ? 2'b00 :
                        (exe2id_wreg == `WRITE_ENABLE && exe2id_wa == ra2) ? 2'b01 :
                        (mem2id_wreg == `WRITE_ENABLE && mem2id_wa == ra2) ? 2'b10 :2'b11;
    // ��÷ô�׶�Ҫ�������ݴ�����������
    // ��������ִ�н׶�ǰ�Ƶ����ݣ��ô�׶�ǰ�Ƶ����ݣ�ͨ�üĴ����ѵĶ��˿�2
    assign id_din_o =   (fwrd2 == 2'b01) ? exe2id_wd :
                        (fwrd2 == 2'b10) ? mem2id_wd :
                        (fwrd2 == 2'b11) ? rd2 : `ZERO_WORD;
    
    // ��λʹ���ź�   (src1ѡ��) 0 rd1   1 sa
    wire shift  = inst_sll|inst_sra|inst_srl;
    // ������ʹ���ź� (src2ѡ��) 0 rd2   1 imm_32
    wire immsel = inst_andi|inst_lui|inst_ori|inst_xori|inst_addi|inst_addiu|inst_slti|inst_sltiu|
                  inst_lb|inst_lbu|inst_lh|inst_lhu|inst_lw|inst_sb|inst_sh|inst_sw;
    // ���������
    wire sext = (inst_addi|inst_addiu|inst_slti|inst_sltiu|inst_lb|inst_lbu|inst_lh|inst_lhu|inst_lw|inst_sb|inst_sh|inst_sw) ? imm[15] : 0;
    wire [31:0] imm_ext = inst_lui ? {imm,16'b0} : {{16{sext}},imm};
    // ���Դ������1.Դ������1��������λλ��������ִ�н׶�ǰ�Ƶ����ݡ����Էô�׶�ǰ�Ƶ����ݡ�����ͨ�üĴ����ѵĶ��˿�1
    assign id_src1_o = (shift == `SHIFT_ENABLE) ? {27'b0, sa} :
                        (fwrd1 == 2'b01) ? exe2id_wd :
                        (fwrd1 == 2'b10) ? mem2id_wd :
                        (fwrd1 == 2'b11) ? rd1 : `ZERO_WORD;
    // ���Դ������2.Դ������2������������������ִ�н׶�ǰ�Ƶ����ݡ����Էô�׶�ǰ�Ƶ����ݡ�����ͨ�üĴ����ѵĶ��˿�2
    assign id_src2_o = (immsel == `IMM_ENABLE) ? imm_ext :
                        (fwrd2 == 2'b01) ? exe2id_wd :
                        (fwrd2 == 2'b10) ? mem2id_wd :
                        (fwrd2 == 2'b11) ? rd2 : `ZERO_WORD;
    
    // ת��ָ��ר��
    wire lesseq =  id_src1_o[31]|(~|id_src1_o);
    wire great  =  ~lesseq;
    assign jump_select[1] = (inst_beq&id_src1_o==id_src2_o)|(inst_bne&id_src1_o!=id_src2_o)|
                            (inst_bgez&~id_src1_o[31])|(inst_bltz&id_src1_o[31])|
                            (inst_bgezal&~id_src1_o[31])|(inst_bltzal&id_src1_o[31])|
                            (inst_blez&lesseq)|(inst_bgtz&great)|inst_jr|inst_jalr;
    assign jump_select[0] = (inst_beq&id_src1_o==id_src2_o)|(inst_bne&id_src1_o!=id_src2_o)|
                            (inst_bgez&~id_src1_o[31])|(inst_bltz&id_src1_o[31])|
                            (inst_bgezal&~id_src1_o[31])|(inst_bltzal&id_src1_o[31])|
                            (inst_blez&lesseq)|(inst_bgtz&great)|inst_j|inst_jal;
    assign jump_addr_1 = {pc_plus_4[31:28],id_inst[25:0],2'b00};
    assign jump_addr_2 = pc_plus_4 + {{14{imm[15]}},imm,2'b00};
    assign jump_addr_3 = id_src1_o;
    assign ret_addr    = pc_plus_4 + 4;
/************************��ˮ����ͣ begin*********************************/
    // ����׶���ͣ�źţ�����������
    // �����ǰ����ִ�н׶ε�ָ���Ǽ���ָ������봦������׶�ָ�����������أ�����������������ڼ������
    // �����ǰ���ڷô�׶ε�ָ���Ǽ���ָ������봦������׶�ָ�����������أ��������������Ҳ���ڼ������
    assign stallreq_id = (cpu_rst_n == `RST_ENABLE) ? `NOSTOP :
                         ((fwrd1 == 2'b01 || fwrd2 == 2'b01) && (exe2id_mreg == `TRUE_V)) ? `STOP :
                         ((fwrd1 == 2'b10 || fwrd2 == 2'b10) && (mem2id_mreg == `TRUE_V)) ? `STOP : `NOSTOP;
/************************��ˮ����ͣ end***********************************/
/************************�쳣���� begin*******************************/
    // �ж���һ��ָ���Ƿ�Ϊ�ӳٲ�ָ��
    assign next_delay_o = (inst_beq | inst_bne | inst_bgez | inst_bgtz | inst_blez | inst_bltz | inst_bgezal | inst_bltzal | inst_j | inst_jal | inst_jr | inst_jalr);
    // �жϵ�ǰ��������׶�ָ���Ƿ�����쳣����������Ӧ���쳣���ͱ���
    assign id_exccode_o = (cpu_rst_n == `RST_ENABLE) ? `EXC_NONE : 
                        (id_exccode_i == `EXC_ADEL) ? id_exccode_i :
                        (!(inst_add | inst_addi | inst_addu | inst_addiu | inst_sub | inst_subu | inst_slt| inst_slti | inst_sltu | inst_sltiu | inst_div | inst_divu | inst_mult | inst_multu |
                        inst_and | inst_andi | inst_lui | inst_nor | inst_or | inst_ori | inst_xor | inst_xori | 
                        inst_sllv | inst_sll | inst_srav | inst_sra | inst_srlv | inst_srl | 
                        inst_beq | inst_bne | inst_bgez | inst_bgtz | inst_blez | inst_bltz | inst_bgezal | inst_bltzal | inst_j | inst_jal | inst_jr | inst_jalr |
                        inst_mfhi | inst_mflo | inst_mthi | inst_mtlo |
                        inst_break | inst_syscall | 
                        inst_lb | inst_lbu | inst_lh | inst_lhu | inst_lw | inst_sb | inst_sh | inst_sw |
                        inst_eret | inst_mfc0 | inst_mtc0)) ? `EXC_RI :
                       (inst_syscall == `TRUE_V ) ? `EXC_SYS : 
                       (inst_eret == `TRUE_V    ) ? `EXC_ERET : 
                       (inst_break == `TRUE_V) ? `EXC_BP : 
                        id_exccode_i;
/************************�쳣���� end*********************************/
/************************MFC0,MTC0 begin*******************************/
    assign cp0_addr = (cpu_rst_n == `RST_ENABLE) ? `REG_NOP : rd;       // ���CP0�Ĵ����ķ��ʵ�ַ
/************************MFC0,MTC0 end*********************************/
    // ֱ��������һ�׶ε��ź�
    assign id_pc_o = id_pc_i;
    assign id_in_delay_o = id_in_delay_i;

endmodule
