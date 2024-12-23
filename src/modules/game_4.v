/*
 * game_2_modified.v
 *
 * - 최초에 key_star 트리거가 발생해야만 게임 진행을 시작(game_active=1)하도록 수정.
 * - 충돌(collision_detected) 또는 게임 클리어(game_cleared) 발생 시 game_active=0으로 전환 후
 *   다시 key_star가 들어오기 전까지 동작 중지.
 *
 * run_game 신호는 사용하지 않으며, 필요하다면 상위 모듈에서 제거하거나 무시하면 됩니다.
 */

module game_4(
    input wire clk,
    input wire rst,
    input wire key0,       // Move dino down
    input wire key8,       // Move dino up
    input wire key_star,   // Restart key (게임 시작/재시작)
    output wire seg_a,
    output wire seg_g,
    output wire seg_d,
    output wire com1,
    output wire com2,
    output wire com3,
    output wire com4,
    output wire com5,
    output wire com6,
    output wire com7,
    output wire com8,
    output wire collision_detected, // Goes high if collision occurs
    output wire game_cleared        // Goes high if all obstacles are avoided
);

    wire rst_n = ~rst;

    //===========================================================
    // 1) Display Multiplexing Counter
    //===========================================================
    wire Q0, Q1, Q2;

    count_8 counter_inst(
        .clk   (clk),
        .rst_n (rst_n),
        .Q0    (Q0),
        .Q1    (Q1),
        .Q2    (Q2)
    );

    //===========================================================
    // 2) Dino Position Definitions
    //===========================================================
    localparam DINO_TOP = 2'b01;   
    localparam DINO_MID = 2'b10;   
    localparam DINO_BOT = 2'b11;   

    // Dino position register
    reg [1:0] dino_position;

    //===========================================================
    // 3) Key Trigger Modules
    //===========================================================
    wire trigger_key0;
    wire trigger_key8;
    wire trigger_key_star;

    trigger trigger_down (
        .CLK   (clk),
        .Din   (key0),
        .rst_n (rst_n),
        .Dout  (trigger_key0)
    );

    trigger trigger_up (
        .CLK   (clk),
        .Din   (key8),
        .rst_n (rst_n),
        .Dout  (trigger_key8)
    );

    trigger trigger_restart (
        .CLK   (clk),
        .Din   (key_star),
        .rst_n (rst_n),
        .Dout  (trigger_key_star)
    );

    //===========================================================
    // 4) 게임 활성 상태 레지스터
    //    - game_active = 1: Dino/Obstacle 동작
    //    - game_active = 0: 대기상태(정지)
    //===========================================================
    reg game_active;

    //===========================================================
    // 5) Dino Movement Logic
    //    - game_active = 1일 때만 dino_position 갱신
    //===========================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dino_position <= DINO_MID; // 초기에는 중간
        end
        else begin
            // (1) key_star(재시작) 눌렸으면 초기화
            if (trigger_key_star) begin
                dino_position <= DINO_MID;
            end
            // (2) game_active일 때만 이동 로직
            else if (game_active) begin
                if (trigger_key8 && dino_position != DINO_TOP)
                    dino_position <= dino_position - 1;
                else if (trigger_key0 && dino_position != DINO_BOT)
                    dino_position <= dino_position + 1;
            end
            // else : 유지
        end
    end

    //===========================================================
    // 6) Obstacle Movement Clock Enable
    //===========================================================
    reg [23:0] obstacle_counter;
    wire obstacle_enable;

    parameter OBSTACLE_PERIOD = 24'd500;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n || trigger_key_star) begin
            obstacle_counter <= 24'd0;
        end
        //else if (!game_active) begin
        //    // 게임이 멈춰 있으면 카운터도 멈춘 상태로 둠
        //    obstacle_counter <= obstacle_counter;
        //end
        else if (obstacle_counter >= OBSTACLE_PERIOD) begin
            obstacle_counter <= 24'd0;
        end
        else begin
            obstacle_counter <= obstacle_counter + 1;
        end
    end

    assign obstacle_enable = (obstacle_counter == OBSTACLE_PERIOD);

    //===========================================================
    // 7) Obstacle Sequence
    //===========================================================
    reg [1:0] obstacle_sequence [0:25];

    initial begin
        obstacle_sequence[0]  = DINO_TOP;
        obstacle_sequence[1]  = 2'b00;    
        obstacle_sequence[2]  = DINO_BOT;
        obstacle_sequence[3]  = 2'b00;
        obstacle_sequence[4]  = DINO_MID;
        obstacle_sequence[5]  = 2'b00;
        obstacle_sequence[6]  = DINO_TOP;
        obstacle_sequence[7]  = 2'b00;
        obstacle_sequence[8]  = DINO_BOT;
        obstacle_sequence[9]  = 2'b00;
        obstacle_sequence[10] = DINO_MID;
        obstacle_sequence[11] = 2'b00;
        obstacle_sequence[12] = DINO_TOP;
        obstacle_sequence[13] = 2'b00;
        obstacle_sequence[14] = DINO_BOT;
        obstacle_sequence[15] = 2'b00;
        obstacle_sequence[16] = DINO_MID;
        obstacle_sequence[17] = 2'b00;
        obstacle_sequence[18] = DINO_TOP;
        obstacle_sequence[19] = 2'b00;
        obstacle_sequence[20] = 2'b00;
        obstacle_sequence[21] = 2'b00;
        obstacle_sequence[22] = 2'b00;
        obstacle_sequence[23] = 2'b00;
        obstacle_sequence[24] = 2'b00;
        obstacle_sequence[25] = 2'b00;
    end

    reg [1:0] obstacle_data;
    reg [4:0] obstacle_index;

    //===========================================================
    // 8) Game Status Registers
    //===========================================================
    reg collision_reg;
    reg game_clear_reg;

    assign collision_detected = collision_reg;
    assign game_cleared       = game_clear_reg;

    //===========================================================
    // 9) game_active, collision_reg, game_clear_reg 제어 로직
    //    - key_star 트리거가 들어오면 게임 재시작(Reset)
    //    - 충돌 또는 클리어 시에는 game_active=0으로 전환
    //===========================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            game_active   <= 1'b0;
        end
        else if (trigger_key_star) begin
            // 게임을 새로 시작해야 하므로, 내부 레지스터 리셋
            game_active   <= 1'b1;
        end
        else begin
            // 이미 충돌 or 클리어가 발생했다면, 대기 상태 유지
            if (collision_reg || game_clear_reg) begin
                game_active <= 1'b0;
            end
        end
    end

    //===========================================================
    // 10) Obstacle Logic: Indexing and Sequence
    //    - game_active=1, obstacle_enable=1일 때만 진행
    //===========================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n || trigger_key_star) begin
            obstacle_index <= 5'd0;
            obstacle_data  <= 2'b00;
            game_clear_reg <= 1'b0;
        end
        else if (game_active && obstacle_enable) begin
            obstacle_data <= obstacle_sequence[obstacle_index];
            obstacle_index <= obstacle_index + 1;
            // 모든 장애물을 출력했다면 게임 클리어
            if (obstacle_index == 5'd26) begin
                game_clear_reg <= 1'b1;
                // index를 0으로 돌려도 되지만, 이후 게임 정지 상태
                obstacle_index <= 5'd0;
            end
        end
    end

    //===========================================================
    // 11) Obstacle Register Array (Shift)
    //===========================================================
    reg [1:0] obstacle_regs [0:7];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            obstacle_regs[0] <= 2'b00;
            obstacle_regs[1] <= 2'b00;
            obstacle_regs[2] <= 2'b00;
            obstacle_regs[3] <= 2'b00;
            obstacle_regs[4] <= 2'b00;
            obstacle_regs[5] <= 2'b00;
            obstacle_regs[6] <= 2'b00;
            obstacle_regs[7] <= 2'b00;
        end
        else if (trigger_key_star) begin
            // ★ star_signal이 오면 화면(장애물) 전체를 클리어
            obstacle_regs[0] <= 2'b00;
            obstacle_regs[1] <= 2'b00;
            obstacle_regs[2] <= 2'b00;
            obstacle_regs[3] <= 2'b00;
            obstacle_regs[4] <= 2'b00;
            obstacle_regs[5] <= 2'b00;
            obstacle_regs[6] <= 2'b00;
            obstacle_regs[7] <= 2'b00;
        end
        else if (game_active && obstacle_enable) begin
            obstacle_regs[0] <= obstacle_regs[1];
            obstacle_regs[1] <= obstacle_regs[2];
            obstacle_regs[2] <= obstacle_regs[3];
            obstacle_regs[3] <= obstacle_regs[4];
            obstacle_regs[4] <= obstacle_regs[5];
            obstacle_regs[5] <= obstacle_regs[6];
            obstacle_regs[6] <= obstacle_regs[7];
            obstacle_regs[7] <= obstacle_data;
        end
    end

    //===========================================================
    // 12) Collision Detection
    //===========================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            collision_reg <= 1'b0;
        end
        else begin
            if (trigger_key_star) begin
                // 재시작 시 reset
                collision_reg <= 1'b0;
            end
            else if (!collision_reg && game_active) begin
                // 장애물이 있을 때(obstacle_regs[0] != 2'b00) 
                // dino_position과 같으면 충돌
                if (obstacle_regs[0] != 2'b00 && obstacle_regs[0] == dino_position) begin
                    collision_reg <= 1'b1;
                end
            end
        end
    end

    //===========================================================
    // 13) Dino + Obstacle Data for Display
    //===========================================================
    wire [1:0] display_data [0:7];

    assign display_data[0] = dino_position; 
    assign display_data[1] = obstacle_regs[1];
    assign display_data[2] = obstacle_regs[2];
    assign display_data[3] = obstacle_regs[3];
    assign display_data[4] = obstacle_regs[4];
    assign display_data[5] = obstacle_regs[5];
    assign display_data[6] = obstacle_regs[6];
    assign display_data[7] = obstacle_regs[7];

    //===========================================================
    // 14) 7-Segment Display를 위한 4비트 변환
    //===========================================================
    wire [3:0] din_for_reg_ce [0:7];
    assign din_for_reg_ce[0] = {2'b00, display_data[0]};
    assign din_for_reg_ce[1] = {2'b00, display_data[1]};
    assign din_for_reg_ce[2] = {2'b00, display_data[2]};
    assign din_for_reg_ce[3] = {2'b00, display_data[3]};
    assign din_for_reg_ce[4] = {2'b00, display_data[4]};
    assign din_for_reg_ce[5] = {2'b00, display_data[5]};
    assign din_for_reg_ce[6] = {2'b00, display_data[6]};
    assign din_for_reg_ce[7] = {2'b00, display_data[7]};

    //===========================================================
    // 15) Instantiate 8 four_bit_reg_ce modules
    //===========================================================
    wire [3:0] reg_out [0:7];

    four_bit_reg_ce reg_inst0(
        .clk(clk),
        .rst_n(rst_n),
        .ce(1'b1), // Always enabled to prevent blinking
        .din(din_for_reg_ce[0]),
        .out(reg_out[0])
    );

    four_bit_reg_ce reg_inst1(
        .clk(clk),
        .rst_n(rst_n),
        .ce(1'b1), // Always enabled to prevent blinking
        .din(din_for_reg_ce[1]),
        .out(reg_out[1])
    );

    four_bit_reg_ce reg_inst2(
        .clk(clk),
        .rst_n(rst_n),
        .ce(1'b1), // Always enabled to prevent blinking
        .din(din_for_reg_ce[2]),
        .out(reg_out[2])
    );

    four_bit_reg_ce reg_inst3(
        .clk(clk),
        .rst_n(rst_n),
        .ce(1'b1), // Always enabled to prevent blinking
        .din(din_for_reg_ce[3]),
        .out(reg_out[3])
    );

    four_bit_reg_ce reg_inst4(
        .clk(clk),
        .rst_n(rst_n),
        .ce(1'b1), // Always enabled to prevent blinking
        .din(din_for_reg_ce[4]),
        .out(reg_out[4])
    );

    four_bit_reg_ce reg_inst5(
        .clk(clk),
        .rst_n(rst_n),
        .ce(1'b1), // Always enabled to prevent blinking
        .din(din_for_reg_ce[5]),
        .out(reg_out[5])
    );

    four_bit_reg_ce reg_inst6(
        .clk(clk),
        .rst_n(rst_n),
        .ce(1'b1), // Always enabled to prevent blinking
        .din(din_for_reg_ce[6]),
        .out(reg_out[6])
    );

    four_bit_reg_ce reg_inst7(
        .clk(clk),
        .rst_n(rst_n),
        .ce(1'b1), // Always enabled to prevent blinking
        .din(din_for_reg_ce[7]),
        .out(reg_out[7])
    );

    //===========================================================
    // 16) MUX Tree for 7-Segment Display Multiplexing
    //===========================================================
    wire [3:0] mux_out0, mux_out1, mux_out2, mux_out3;
    wire [3:0] mux_out4, mux_out5, mux_out6;

    mx_4bit_2x1 mux0(
        .ce(Q0),
        .s0(reg_out[0]),
        .s1(reg_out[1]),
        .m_out(mux_out0)
    );

    mx_4bit_2x1 mux1(
        .ce(Q0),
        .s0(reg_out[2]),
        .s1(reg_out[3]),
        .m_out(mux_out1)
    );

    mx_4bit_2x1 mux2(
        .ce(Q0),
        .s0(reg_out[4]),
        .s1(reg_out[5]),
        .m_out(mux_out2)
    );

    mx_4bit_2x1 mux3(
        .ce(Q0),
        .s0(reg_out[6]),
        .s1(reg_out[7]),
        .m_out(mux_out3)
    );

    // Second layer
    mx_4bit_2x1 mux4(
        .ce(Q1),
        .s0(mux_out0),
        .s1(mux_out1),
        .m_out(mux_out4)
    );

    mx_4bit_2x1 mux5(
        .ce(Q1),
        .s0(mux_out2),
        .s1(mux_out3),
        .m_out(mux_out5)
    );

    // Third layer
    mx_4bit_2x1 mux6(
        .ce(Q2),
        .s0(mux_out4),
        .s1(mux_out5),
        .m_out(mux_out6)
    );

    //===========================================================
    // 17) COM Signals (Active Low)
    //===========================================================
    wire [2:0] digit_select = {Q2, Q1, Q0};

    assign com1 = ~(digit_select == 3'b000);
    assign com2 = ~(digit_select == 3'b001);
    assign com3 = ~(digit_select == 3'b010);
    assign com4 = ~(digit_select == 3'b011);
    assign com5 = ~(digit_select == 3'b100);
    assign com6 = ~(digit_select == 3'b101);
    assign com7 = ~(digit_select == 3'b110);
    assign com8 = ~(digit_select == 3'b111);

    //===========================================================
    // 18) 최종 세그먼트 출력
    //===========================================================
    wire [1:0] final_mux_out = mux_out6[1:0];

    assign seg_a = (final_mux_out == DINO_TOP);
    assign seg_g = (final_mux_out == DINO_MID);
    assign seg_d = (final_mux_out == DINO_BOT);

endmodule
