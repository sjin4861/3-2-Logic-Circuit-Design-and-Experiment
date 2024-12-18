/*
 * game_2.v
 *
 * A Verilog module implementing a dino-obstacle game logic with collision detection
 * and game-cleared status. It drives a 7-segment 8-array display using multiplexing
 * and registers. The dino position and obstacle data are combined to form the
 * display output. 
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
 *  - Dino movement is handled by two inputs (key0, key8) with triggers.
 *  - Obstacles shift from COM8 to COM1. If the obstacle at COM1 matches the dino's position, 
 *    collision_detected goes high.
 *  - Once the obstacle sequence is fully displayed without collision, game_cleared goes high.
 *
 * Dependencies:
 *  - count_8.v         : 3-bit counter for multiplexing
 *  - four_bit_reg_ce.v : 4-bit register with clock enable
 *  - mx_4bit_2x1.v     : 4-bit 2x1 multiplexer
 *  - trigger.v         : Debounce/trigger for key inputs
 */

module game_2(
    input wire clk,
    input wire rst,
    input wire key0,       // Move dino down
    input wire key8,       // Move dino up
    input wire key_star,   // Restart key
    input wire run_game, // from game_event
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
    //    - Provides Q0, Q1, Q2 for a 3-bit scan index.
    //===========================================================
    wire Q0, Q1, Q2;

    // 8-counter for scanning 7-seg COM lines
    count_8 counter_inst(
        .clk   (clk),
        .rst_n (rst_n),
        .Q0    (Q0),
        .Q1    (Q1),
        .Q2    (Q2)
    );

    //===========================================================
    // 2) Dino Position Definitions
    //    - Using 2 bits for top, mid, bottom positions.
    //===========================================================
    localparam DINO_TOP = 2'b01;   // Top position (activates seg_a)
    localparam DINO_MID = 2'b10;   // Middle position (activates seg_g)
    localparam DINO_BOT = 2'b11;   // Bottom position (activates seg_d)

    // Dino position register
    reg [1:0] dino_position;

    //===========================================================
    // 3) Key Trigger Modules 
    //    - Used for debouncing/momentary detection
    //===========================================================
    wire trigger_key0;
    wire trigger_key8;
    wire trigger_key_star;

    // Trigger modules for key inputs
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
    //    - Dino only updates position if run_game = 1
    //===========================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dino_position <= DINO_MID; // Initialize to middle
        end
        else if (run_game) begin
            // Move dino up
            if (trigger_key8 && dino_position != DINO_TOP)
                dino_position <= dino_position - 1;
            // Move dino down
            else if (trigger_key0 && dino_position != DINO_BOT)
                dino_position <= dino_position + 1;
        end
    end
    //===========================================================
    // 5) Obstacle Movement Clock Enable
    //    - obstacle_enable pulses when obstacle_counter hits OBSTACLE_PERIOD
    //===========================================================
    reg [23:0] obstacle_counter;
    wire obstacle_enable;

    parameter OBSTACLE_PERIOD = 24'd500; // Adjust for obstacle speed

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
    // 6) Obstacle Sequence
    //    - We have a fixed array of 20 obstacles. 
    //    - 2'b00 indicates no obstacle, or a "gap".
    //===========================================================
    reg [1:0] obstacle_sequence [0:19];

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
    end

    reg [1:0] obstacle_data;
    reg [4:0] obstacle_index; // to iterate through 20 obstacles

    //===========================================================
    // 7) Game Status Registers 
    //    - collision_reg : latched when dino collides with obstacle
    //    - game_clear_reg: latched when obstacles run out successfully
    //===========================================================
    reg collision_reg;
    reg game_clear_reg;

    // Assign outputs
    assign collision_detected = collision_reg;
    assign game_cleared       = game_clear_reg;

    //===========================================================
    // 8) Obstacle Logic: Indexing and Sequence
    //    - Only update if run_game = 1 and obstacle_enable is triggered.
    //===========================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            obstacle_index <= 5'd0;
            obstacle_data  <= 2'b00;
            collision_reg  <= 1'b0;
            game_clear_reg <= 1'b0;
        end
        else if (trigger_key_star) begin
            // On restart key, reset obstacle sequence and flags
            obstacle_index <= 5'd0;
            obstacle_data  <= 2'b00;
            collision_reg  <= 1'b0;
            game_clear_reg <= 1'b0;
        end
        else if (run_game && obstacle_enable) begin
            obstacle_data <= obstacle_sequence[obstacle_index];
            obstacle_index <= obstacle_index + 1;

            // If we've displayed all obstacles, game is cleared
            if (obstacle_index == 5'd19) begin
                game_clear_reg <= 1'b1; // All obstacles avoided => game cleared
                obstacle_index <= 5'd0; // Reset index for repeating sequence or stopping
            end
        end
    end

    //===========================================================
    // 9) Obstacle Register Array
    //    - 8 registers representing obstacles from COM8 to COM1.
    //    - Shift them only if run_game=1 and obstacle_enable=1.
    //===========================================================
    reg [1:0] obstacle_regs [0:7];

    // Shift obstacles toward dino
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            integer i;
            for (i=0; i<8; i=i+1)
                obstacle_regs[i] <= 2'b00;
        end
        else if (trigger_key_star) begin
            // Clear everything on restart
            integer j;
            for (j=0; j<8; j=j+1)
                obstacle_regs[j] <= 2'b00;
        end
        else if (obstacle_enable) begin
            integer k;
            for (k=0; k<7; k=k+1)
                obstacle_regs[k] <= obstacle_regs[k+1];
            obstacle_regs[7] <= obstacle_data;
        end
    end

    //===========================================================
    // 10) Collision Detection
    //     - If obstacle_regs[0] == dino_position (non-zero), collision occurs.
    //===========================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            collision_reg <= 1'b0;
        else if (!collision_reg) begin
            // Only detect collision once; if we want it to stay latched
            if (obstacle_regs[0] != 2'b00 && obstacle_regs[0] == dino_position)
                collision_reg <= 1'b1;
        end
        else if (trigger_key_star) begin
            // Clear collision if restarted
            collision_reg <= 1'b0;
        end
    end

    //===========================================================
    // 11) Combine Dino and Obstacle Data for Display
    //     - COM1 always shows the dino (simple logic).
    //       If you wanted obstacle override on COM1, you could do:
    //         display_data[0] = (obstacle_regs[0] != 2'b00) ? obstacle_regs[0] : dino_position;
    //===========================================================    
    assign display_data[0] = dino_position; 
    wire [1:0] display_data [0:7];
    assign display_data[1] = obstacle_regs[1];
    assign display_data[2] = obstacle_regs[2];
    assign display_data[3] = obstacle_regs[3];
    assign display_data[4] = obstacle_regs[4];
    assign display_data[5] = obstacle_regs[5];
    assign display_data[6] = obstacle_regs[6];
    assign display_data[7] = obstacle_regs[7];

    //===========================================================
    // 12) Register Inputs for 7-Segment Display
    //     - Convert 2-bit data to 4-bit for the four_bit_reg_ce modules
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
    // 13) Instantiate 8 four_bit_reg_ce modules
    //     - These store the data for each COM line
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
    // 14) MUX Tree for 7-Segment Display Multiplexing
    //     - 3 layers of mx_4bit_2x1 modules controlled by Q0, Q1, Q2
    //===========================================================
    wire [3:0] mux_out0, mux_out1, mux_out2, mux_out3;
    wire [3:0] mux_out4, mux_out5, mux_out6;

    // First layer MUXes
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

    // Second layer MUXes
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

    // Third layer MUX (Final)
    mx_4bit_2x1 mux6(
        .ce(Q2),
        .s0(mux_out4),
        .s1(mux_out5),
        .m_out(mux_out6)
    );

    //===========================================================
    // 15) COM Signals (Active Low)
    //     - The 3-bit digit_select chooses which COM line is active
    //===========================================================
    wire [2:0] digit_select = {Q2, Q1, Q0};

    // Generate COM signals (active low)
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
    //     - final_mux_out's lower 2 bits select seg_a/g/d for top/mid/bot
    //===========================================================
    wire [1:0] final_mux_out = mux_out6[1:0];

    assign seg_a = (final_mux_out == DINO_TOP);
    assign seg_g = (final_mux_out == DINO_MID);
    assign seg_d = (final_mux_out == DINO_BOT);

endmodule