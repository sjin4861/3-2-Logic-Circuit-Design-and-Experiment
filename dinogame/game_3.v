/*
 * game_3.v
 *
 * A Verilog module implementing a dino-obstacle game logic with collision detection
 * and game-cleared status, similar to game_2.v but with more obstacles and no 'for' loops
 * for shifting logic. The obstacle sequence is denser and longer (30 obstacles).
 *
 * Inputs:
 *  - clk, rst        : System clock and active-high reset
 *  - key0, key8      : Keys to move the dino down or up
 *  - key_star        : Key to restart the game
 *  - run_game        : Control signal from a higher-level module (game_event),
 *                      indicating whether to run or pause the game logic.
 *
 * Outputs:
 *  - seg_a, seg_g, seg_d     : Segment lines for 7-segment display
 *  - com1..com8              : COM signals for 8-digit multiplexing
 *  - collision_detected      : Signal that goes high if a collision occurs
 *  - game_cleared            : Signal that goes high if all obstacles are successfully avoided
 *
 * Internally:
 *  - The logic is the same as game_2.v, but we have a larger obstacle sequence (30 obstacles)
 *    and shift/reset the obstacle registers manually without using for-loops.
 */

module game_3(
    input wire clk,
    input wire rst,
    input wire key0,       // Move dino down
    input wire key8,       // Move dino up
    input wire key_star,   // Restart key
    input wire run_game,   // from game_event
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
    // 1) Display Multiplexing Counter (count_8)
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
    localparam DINO_TOP = 2'b01;  // Activates seg_a
    localparam DINO_MID = 2'b10;  // Activates seg_g
    localparam DINO_BOT = 2'b11;  // Activates seg_d

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
    // 4) Dino Movement Logic
    //    - Updates only when run_game=1
    //===========================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dino_position <= DINO_MID;
        end
        else if (run_game) begin
            if (trigger_key8 && dino_position != DINO_TOP)
                dino_position <= dino_position - 1;
            else if (trigger_key0 && dino_position != DINO_BOT)
                dino_position <= dino_position + 1;
        end
    end

    //===========================================================
    // 5) Obstacle Movement Clock Enable
    //===========================================================
    reg [23:0] obstacle_counter;
    wire obstacle_enable;

    parameter OBSTACLE_PERIOD = 24'd500; // Adjust speed as needed

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            obstacle_counter <= 24'd0;
        else if (obstacle_counter >= OBSTACLE_PERIOD)
            obstacle_counter <= 24'd0;
        else
            obstacle_counter <= obstacle_counter + 1;
    end

    assign obstacle_enable = (obstacle_counter == OBSTACLE_PERIOD);

    //===========================================================
    // 6) Obstacle Sequence (30 obstacles, more dense)
    //    2'b00 -> gap, else DINO_TOP/MID/BOT
    //===========================================================
    reg [1:0] obstacle_sequence [0:29]; // 30 obstacles
    initial begin
        // A more dense pattern (feel free to customize)
        obstacle_sequence[0]  = DINO_TOP;
        obstacle_sequence[1]  = DINO_BOT;
        obstacle_sequence[2]  = DINO_MID;
        obstacle_sequence[3]  = DINO_TOP;
        obstacle_sequence[4]  = 2'b00;
        obstacle_sequence[5]  = DINO_BOT;
        obstacle_sequence[6]  = DINO_TOP;
        obstacle_sequence[7]  = DINO_BOT;
        obstacle_sequence[8]  = DINO_MID;
        obstacle_sequence[9]  = 2'b00;
        obstacle_sequence[10] = DINO_TOP;
        obstacle_sequence[11] = DINO_MID;
        obstacle_sequence[12] = DINO_BOT;
        obstacle_sequence[13] = DINO_TOP;
        obstacle_sequence[14] = DINO_BOT;
        obstacle_sequence[15] = DINO_TOP;
        obstacle_sequence[16] = DINO_MID;
        obstacle_sequence[17] = 2'b00;
        obstacle_sequence[18] = DINO_BOT;
        obstacle_sequence[19] = DINO_TOP;
        obstacle_sequence[20] = DINO_MID;
        obstacle_sequence[21] = DINO_BOT;
        obstacle_sequence[22] = 2'b00;
        obstacle_sequence[23] = DINO_TOP;
        obstacle_sequence[24] = DINO_BOT;
        obstacle_sequence[25] = DINO_MID;
        obstacle_sequence[26] = DINO_TOP;
        obstacle_sequence[27] = DINO_BOT;
        obstacle_sequence[28] = DINO_MID;
        obstacle_sequence[29] = 2'b00;
    end

    reg [1:0] obstacle_data;
    reg [5:0] obstacle_index; // Enough bits for 0..29

    //===========================================================
    // 7) Game Status Registers
    //===========================================================
    reg collision_reg;
    reg game_clear_reg;

    assign collision_detected = collision_reg;
    assign game_cleared       = game_clear_reg;

    //===========================================================
    // 8) Obstacle Logic: Larger Sequence
    //===========================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            obstacle_index <= 6'd0;
            obstacle_data  <= 2'b00;
            collision_reg  <= 1'b0;
            game_clear_reg <= 1'b0;
        end
        else if (trigger_key_star) begin
            obstacle_index <= 6'd0;
            obstacle_data  <= 2'b00;
            collision_reg  <= 1'b0;
            game_clear_reg <= 1'b0;
        end
        else if (run_game && obstacle_enable) begin
            obstacle_data <= obstacle_sequence[obstacle_index];
            obstacle_index <= obstacle_index + 1;

            // If we've displayed all 30 obstacles without collision
            if (obstacle_index == 6'd29) begin
                game_clear_reg <= 1'b1;
                obstacle_index <= 6'd0; // Optionally cycle again
            end
        end
    end

    //===========================================================
    // 9) Obstacle Register Array (no for-loops, manual shifting)
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
            obstacle_regs[0] <= 2'b00;
            obstacle_regs[1] <= 2'b00;
            obstacle_regs[2] <= 2'b00;
            obstacle_regs[3] <= 2'b00;
            obstacle_regs[4] <= 2'b00;
            obstacle_regs[5] <= 2'b00;
            obstacle_regs[6] <= 2'b00;
            obstacle_regs[7] <= 2'b00;
        end
        else if (run_game && obstacle_enable) begin
            // Manual shifting without for-loop
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
    // 10) Collision Detection (no for-loop)
    //===========================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            collision_reg <= 1'b0;
        end
        else if (!collision_reg) begin
            if (obstacle_regs[0] != 2'b00 && obstacle_regs[0] == dino_position)
                collision_reg <= 1'b1;
        end
        else if (trigger_key_star) begin
            collision_reg <= 1'b0;
        end
    end

    //===========================================================
    // 11) Combine Dino & Obstacle Data for Display (COM1 = Dino)
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
    // 12) Register Inputs for 7-Segment Display (no for-loop)
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
    // 13) Instantiate 8 four_bit_reg_ce modules (no for-loop)
    //===========================================================
    wire [3:0] reg_out [0:7];

    four_bit_reg_ce reg_inst0(
        .clk(clk),
        .rst_n(rst_n),
        .ce(1'b1),
        .din(din_for_reg_ce[0]),
        .out(reg_out[0])
    );

    four_bit_reg_ce reg_inst1(
        .clk(clk),
        .rst_n(rst_n),
        .ce(1'b1),
        .din(din_for_reg_ce[1]),
        .out(reg_out[1])
    );

    four_bit_reg_ce reg_inst2(
        .clk(clk),
        .rst_n(rst_n),
        .ce(1'b1),
        .din(din_for_reg_ce[2]),
        .out(reg_out[2])
    );

    four_bit_reg_ce reg_inst3(
        .clk(clk),
        .rst_n(rst_n),
        .ce(1'b1),
        .din(din_for_reg_ce[3]),
        .out(reg_out[3])
    );

    four_bit_reg_ce reg_inst4(
        .clk(clk),
        .rst_n(rst_n),
        .ce(1'b1),
        .din(din_for_reg_ce[4]),
        .out(reg_out[4])
    );

    four_bit_reg_ce reg_inst5(
        .clk(clk),
        .rst_n(rst_n),
        .ce(1'b1),
        .din(din_for_reg_ce[5]),
        .out(reg_out[5])
    );

    four_bit_reg_ce reg_inst6(
        .clk(clk),
        .rst_n(rst_n),
        .ce(1'b1),
        .din(din_for_reg_ce[6]),
        .out(reg_out[6])
    );

    four_bit_reg_ce reg_inst7(
        .clk(clk),
        .rst_n(rst_n),
        .ce(1'b1),
        .din(din_for_reg_ce[7]),
        .out(reg_out[7])
    );

    //===========================================================
    // 14) MUX Tree for 7-Segment Multiplexing
    //===========================================================
    wire [3:0] mux_out0, mux_out1, mux_out2, mux_out3;
    wire [3:0] mux_out4, mux_out5, mux_out6;

    // First layer
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

    // Third layer (final mux)
    mx_4bit_2x1 mux6(
        .ce(Q2),
        .s0(mux_out4),
        .s1(mux_out5),
        .m_out(mux_out6)
    );

    //===========================================================
    // 15) COM Signals (Active Low)
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
    // 16) Final Segment Output
    //===========================================================
    wire [1:0] final_mux_out = mux_out6[1:0];

    assign seg_a = (final_mux_out == DINO_TOP);
    assign seg_g = (final_mux_out == DINO_MID);
    assign seg_d = (final_mux_out == DINO_BOT);

endmodule