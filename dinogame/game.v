module game(
    input wire clk,
    input wire rst,
    input wire key0,   // Move dino down
    input wire key8,   // Move dino up
    input wire key_star, // Restart key
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
    output wire com8
    // output wire collision_detected,
    // output wire game_clear
);

    wire rst_n = ~rst;

    // Counter outputs
    wire Q0, Q1, Q2;

    // 8-counter instance
    count_8 counter_inst(
        .clk(clk),
        .rst_n(rst_n),
        .Q0(Q0),
        .Q1(Q1),
        .Q2(Q2)
    );

    // Dino position state definitions
    localparam DINO_TOP = 2'b01;    // Top position (activates seg_a)
    localparam DINO_MID = 2'b10;    // Middle position (activates seg_g)
    localparam DINO_BOT = 2'b11;    // Bottom position (activates seg_d)

    // Dino position state variable
    reg [1:0] dino_position;

    // Triggered key signals
    wire trigger_key0;
    wire trigger_key8;
    wire trigger_key_star;

    // Trigger 모듈 인스턴스화
    trigger trigger_down (
        .CLK(clk),
        .Din(key0),
        .rst_n(rst_n),
        .Dout(trigger_key0)
    );

    trigger trigger_up (
        .CLK(clk),
        .Din(key8),
        .rst_n(rst_n),
        .Dout(trigger_key8)
    );

    trigger trigger_restart (
        .CLK(clk),
        .Din(key_star),
        .rst_n(rst_n),
        .Dout(trigger_key_star)
    );

    // Update dino position based on key inputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            dino_position <= DINO_MID; // Start at middle position
        else begin
            if (trigger_key8 && dino_position != DINO_TOP)
                dino_position <= dino_position - 1; // Move up
            else if (trigger_key0 && dino_position != DINO_BOT)
                dino_position <= dino_position + 1; // Move down
        end
    end

    reg [23:0] obstacle_counter;
    wire obstacle_clk;

    parameter OBSTACLE_PERIOD = 24'd500; // Adjust as needed

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            obstacle_counter <= 24'd0;
        else if (obstacle_counter >= OBSTACLE_PERIOD)
            obstacle_counter <= 24'd0;
        else
            obstacle_counter <= obstacle_counter + 1;
    end

    assign obstacle_enable = (obstacle_counter == OBSTACLE_PERIOD);


    // Define an array of obstacle positions
    reg [1:0] obstacle_sequence [0:19]; // 20 obstacles

    initial begin
        obstacle_sequence[0] = DINO_TOP;    // Obstacle at top
        obstacle_sequence[1] = 2'b00;       // No obstacle
        obstacle_sequence[2] = DINO_BOT;    // Obstacle at bottom
        obstacle_sequence[3] = 2'b00;       // No obstacle
        obstacle_sequence[4] = DINO_MID;    // Obstacle at middle
        obstacle_sequence[5] = 2'b00;       // No obstacle
        obstacle_sequence[6] = DINO_TOP;    // Obstacle at top
        obstacle_sequence[7] = 2'b00;       // No obstacle
        obstacle_sequence[8] = DINO_BOT;    // Obstacle at bottom
        obstacle_sequence[9] = 2'b00;       // No obstacle
        obstacle_sequence[10] = DINO_MID;   // Obstacle at middle
        obstacle_sequence[11] = 2'b00;      // No obstacle
        obstacle_sequence[12] = DINO_TOP;   // Obstacle at top
        obstacle_sequence[13] = 2'b00;      // No obstacle
        obstacle_sequence[14] = DINO_BOT;   // Obstacle at bottom
        obstacle_sequence[15] = 2'b00;      // No obstacle
        obstacle_sequence[16] = DINO_MID;   // Obstacle at middle
        obstacle_sequence[17] = 2'b00;      // No obstacle
        obstacle_sequence[18] = DINO_TOP;   // Obstacle at top
        obstacle_sequence[19] = 2'b00;      // No obstacle
    end

    // Obstacle data (obstacles appear at random positions)
    reg [1:0] obstacle_data;

    reg [4:0] obstacle_index;

    reg game_clear_reg; // Register to hold the game clear status
    reg game_over_reg; // Register to hold the game over status

    // assign game_clear = game_clear_reg; // Assign the register to the output

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            obstacle_index <= 5'd0;
            obstacle_data <= 2'b00; // No obstacle
            //game_clear_reg <= 1'b0; // Reset game clear status
            //game_over_reg <= 1'b0; // Reset game over status
        end else if (obstacle_enable) begin
            obstacle_data <= obstacle_sequence[obstacle_index];
            obstacle_index <= obstacle_index + 1;
            if (obstacle_index == 5'd19) begin
                //game_clear_reg <= 1'b1; // Set game clear status
                obstacle_index <= 5'd0; // Reset after 20 obstacles
            end
        end
    end

    // Outputs of registers for each COM line
    reg [1:0] obstacle_regs [0:7]; // Registers for obstacle positions

    // Shift obstacle data towards the dino
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
        end else if (obstacle_enable) begin
            // Shift obstacles towards dino
            // 총 20개의 장애물을 옮겨야함
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

    // Combine dino and obstacle data for display
    wire [1:0] display_data [0:7];

    // At position 0 (COM1), overlay dino's position and obstacle

    // note

    
    // assign collision_detected = (obstacle_regs[0] == dino_position);
    // always @(posedge clk or negedge rst_n) begin
    //     if (!rst_n)
    //         game_over_reg <= 1'b0;
    //     else if ((obstacle_regs[0] != 2'b00) && (obstacle_regs[0] == dino_position))
    //         game_over_reg <= 1'b1;
    // end

    assign display_data[0] = dino_position;
    assign display_data[1] = obstacle_regs[1];
    assign display_data[2] = obstacle_regs[2];
    assign display_data[3] = obstacle_regs[3];
    assign display_data[4] = obstacle_regs[4];
    assign display_data[5] = obstacle_regs[5];
    assign display_data[6] = obstacle_regs[6];
    assign display_data[7] = obstacle_regs[7];

    // Convert display data to 4-bit format for registers (upper 2 bits unused)
    wire [3:0] din_for_reg_ce [0:7];

    assign din_for_reg_ce[0] = {2'b00, display_data[0]};
    assign din_for_reg_ce[1] = {2'b00, display_data[1]};
    assign din_for_reg_ce[2] = {2'b00, display_data[2]};
    assign din_for_reg_ce[3] = {2'b00, display_data[3]};
    assign din_for_reg_ce[4] = {2'b00, display_data[4]};
    assign din_for_reg_ce[5] = {2'b00, display_data[5]};
    assign din_for_reg_ce[6] = {2'b00, display_data[6]};
    assign din_for_reg_ce[7] = {2'b00, display_data[7]};
    // Instantiate 8 four_bit_reg_ce modules
    wire [3:0] reg_out [0:7]; // Outputs of registers

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
    // First layer MUXes (4 MUXes)
    wire [3:0] mux_out0, mux_out1, mux_out2, mux_out3;

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

    // Second layer MUXes (2 MUXes)
    wire [3:0] mux_out4, mux_out5;

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

    // Third layer MUX (Final MUX)
    wire [3:0] mux_out6;

    mx_4bit_2x1 mux6(
        .ce(Q2),
        .s0(mux_out4),
        .s1(mux_out5),
        .m_out(mux_out6)
    );

    // Combine Q2, Q1, Q0 to form digit select
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

    // Map final mux output to segment outputs
    wire [1:0] final_mux_out = mux_out6[1:0];

    assign seg_a = (final_mux_out == DINO_TOP);
    assign seg_g = (final_mux_out == DINO_MID);
    assign seg_d = (final_mux_out == DINO_BOT);
endmodule
