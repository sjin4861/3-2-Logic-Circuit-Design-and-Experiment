module game_event(
    input  wire clk,
    input  wire rst,
    input  wire key_star,          // From keypad (*)
    input  wire collision_detected, // From game_2/game_3
    input  wire game_cleared,       // From game_2/game_3

    // Outputs to game_2/game_3
    output reg  run_game,           // Tells game whether to run or pause

    // Outputs for status indicators
    output reg  LED_RED,
    output reg  LED_GREEN,

    // LCD outputs (multiplexed)
    output wire LCD_E,
    output wire LCD_RS,
    output wire LCD_RW,
    output wire [7:0] LCD_DATA
);

    //===========================================================
    // 1) State Definitions
    //===========================================================
    localparam STATE_IDLE       = 2'b00; // Waiting for start
    localparam STATE_RUNNING    = 2'b01; // Game in progress
    localparam STATE_COLLISION  = 2'b10; // Dino collided with obstacle
    localparam STATE_CLEARED    = 2'b11; // All obstacles avoided

    reg [1:0] curr_state, next_state;

    //===========================================================
    // 2) Key Trigger for key_star
    //===========================================================
    wire trigger_star;
    trigger trigger_star_inst (
        .CLK(clk),
        .Din(key_star),
        .rst_n(~rst),
        .Dout(trigger_star)
    );

    //===========================================================
    // 3) State Register
    //===========================================================
    always @(posedge clk or negedge rst) begin
        if (!rst)
            curr_state <= STATE_IDLE;
        else
            curr_state <= next_state;
    end

    //===========================================================
    // 4) Next State Logic
    //===========================================================
    always @(*) begin
        next_state = curr_state;  // Default to stay in same state
        case (curr_state)
            // Wait for user to press * to start
            STATE_IDLE: begin
                if (trigger_star)
                    next_state = STATE_RUNNING;
            end

            // Running until collision or cleared
            STATE_RUNNING: begin
                if (collision_detected)
                    next_state = STATE_COLLISION;
                else if (game_cleared)
                    next_state = STATE_CLEARED;
            end

            // Collision => wait for * to restart
            STATE_COLLISION: begin
                if (trigger_star)
                    next_state = STATE_IDLE;
            end

            // Cleared => wait for * to restart
            STATE_CLEARED: begin
                if (trigger_star)
                    next_state = STATE_IDLE;
            end

            default: next_state = STATE_IDLE;
        endcase
    end

    //===========================================================
    // 5) Output Logic (run_game, LEDs)
    //===========================================================
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            run_game   <= 1'b0;
            LED_RED    <= 1'b0;
            LED_GREEN  <= 1'b0;
        end else begin
            case (next_state)
                STATE_IDLE: begin
                    // Idle => game paused, LED RED off, LED GREEN on
                    run_game   <= 1'b0;
                    LED_RED    <= 1'b0;
                    LED_GREEN  <= 1'b1;
                end

                STATE_RUNNING: begin
                    // Running => game active, LED RED off, LED GREEN on
                    run_game   <= 1'b1;
                    LED_RED    <= 1'b0;
                    LED_GREEN  <= 1'b1;
                end

                STATE_COLLISION: begin
                    // Collision => pause game, LED RED on, LED GREEN off
                    run_game   <= 1'b0;
                    LED_RED    <= 1'b1;
                    LED_GREEN  <= 1'b0;
                end

                STATE_CLEARED: begin
                    // Cleared => pause game, LED RED off, LED GREEN on
                    run_game   <= 1'b0;
                    LED_RED    <= 1'b0;
                    LED_GREEN  <= 1'b1;
                end

                default: begin
                    run_game   <= 1'b0;
                    LED_RED    <= 1'b0;
                    LED_GREEN  <= 1'b0;
                end
            endcase
        end
    end

    //===========================================================
    // 6) Multiplex LCD Modules
    //    - We'll instantiate the 4 text LCD modules:
    //      textlcd_game_start, textlcd_stage_level,
    //      textlcd_game_over, textlcd_game_clear
    //      Then choose which one's outputs go to LCD_E, LCD_RS, LCD_RW, LCD_DATA
    //===========================================================
    // Wires from each LCD module
    wire lcd_e_start, lcd_rs_start, lcd_rw_start;
    wire [7:0] lcd_data_start;

    textlcd_game_start u_game_start (
        .rst(rst),
        .clk(clk),
        .lcd_e(lcd_e_start),
        .lcd_rs(lcd_rs_start),
        .lcd_rw(lcd_rw_start),
        .lcd_data(lcd_data_start)
    );

    wire lcd_e_level, lcd_rs_level, lcd_rw_level;
    wire [7:0] lcd_data_level;
    textlcd_stage_level u_stage_level (
        .rst(rst),
        .clk(clk),
        .lcd_e(lcd_e_level),
        .lcd_rs(lcd_rs_level),
        .lcd_rw(lcd_rw_level),
        .lcd_data(lcd_data_level)
    );

    wire lcd_e_over, lcd_rs_over, lcd_rw_over;
    wire [7:0] lcd_data_over;
    textlcd_game_over u_game_over (
        .rst(rst),
        .clk(clk),
        .lcd_e(lcd_e_over),
        .lcd_rs(lcd_rs_over),
        .lcd_rw(lcd_rw_over),
        .lcd_data(lcd_data_over)
    );

    wire lcd_e_clear, lcd_rs_clear, lcd_rw_clear;
    wire [7:0] lcd_data_clear;
    textlcd_game_clear u_game_clear (
        .rst(rst),
        .clk(clk),
        .lcd_e(lcd_e_clear),
        .lcd_rs(lcd_rs_clear),
        .lcd_rw(lcd_rw_clear),
        .lcd_data(lcd_data_clear)
    );

    // Final registers to drive LCD outputs
    reg lcd_e_reg, lcd_rs_reg, lcd_rw_reg;
    reg [7:0] lcd_data_reg;

    // Choose which LCD module drives the outputs based on curr_state
    always @(*) begin
        // Default to "game_start" signals
        lcd_e_reg    = lcd_e_start;
        lcd_rs_reg   = lcd_rs_start;
        lcd_rw_reg   = lcd_rw_start;
        lcd_data_reg = lcd_data_start;

        case (curr_state)
            // IDLE => show "game_start" screen
            STATE_IDLE: begin
                lcd_e_reg    = lcd_e_start;
                lcd_rs_reg   = lcd_rs_start;
                lcd_rw_reg   = lcd_rw_start;
                lcd_data_reg = lcd_data_start;
            end

            // RUNNING => show "stage_level" screen
            STATE_RUNNING: begin
                lcd_e_reg    = lcd_e_level;
                lcd_rs_reg   = lcd_rs_level;
                lcd_rw_reg   = lcd_rw_level;
                lcd_data_reg = lcd_data_level;
            end

            // COLLISION => show "game_over" screen
            STATE_COLLISION: begin
                lcd_e_reg    = lcd_e_over;
                lcd_rs_reg   = lcd_rs_over;
                lcd_rw_reg   = lcd_rw_over;
                lcd_data_reg = lcd_data_over;
            end

            // CLEARED => show "game_clear" screen
            STATE_CLEARED: begin
                lcd_e_reg    = lcd_e_clear;
                lcd_rs_reg   = lcd_rs_clear;
                lcd_rw_reg   = lcd_rw_clear;
                lcd_data_reg = lcd_data_clear;
            end
        endcase
    end

    // Assign final outputs
    assign LCD_E    = lcd_e_reg;
    assign LCD_RS   = lcd_rs_reg;
    assign LCD_RW   = lcd_rw_reg;
    assign LCD_DATA = lcd_data_reg;

endmodule