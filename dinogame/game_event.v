module game_event(
    input  wire clk,
    input  wire rst,
    input  wire key_star,          // From keypad (*)
    input  wire collision_detected, // From game_2.v
    input  wire game_cleared,       // From game_2.v
    output reg  run_game,           // Tells game_2 whether to run or pause
    output reg  LED_RED,
    output reg  LED_GREEN
);

    // State definitions
    localparam STATE_IDLE       = 2'b00; // Waiting for start
    localparam STATE_RUNNING    = 2'b01; // Game in progress
    localparam STATE_COLLISION  = 2'b10; // Dino collided with obstacle
    localparam STATE_CLEARED    = 2'b11; // All obstacles avoided

    reg [1:0] curr_state, next_state;

    // Trigger module for key_star (if needed)
    wire trigger_star;
    trigger trigger_star_inst (
        .CLK(clk),
        .Din(key_star),
        .rst_n(~rst),
        .Dout(trigger_star)
    );

    // State register
    always @(posedge clk or negedge rst) begin
        if (!rst) 
            curr_state <= STATE_IDLE;
        else
            curr_state <= next_state;
    end

    // Next state logic
    always @(*) begin
        next_state = curr_state;  // Default to stay in same state
        case (curr_state)
            STATE_IDLE: begin
                if (trigger_star)
                    next_state = STATE_RUNNING;
            end

            STATE_RUNNING: begin
                if (collision_detected)
                    next_state = STATE_COLLISION;
                else if (game_cleared)
                    next_state = STATE_CLEARED;
            end

            STATE_COLLISION: begin
                // Wait for user to press * to restart
                if (trigger_star)
                    next_state = STATE_IDLE;
            end

            STATE_CLEARED: begin
                // Wait for user to press * to restart
                if (trigger_star)
                    next_state = STATE_IDLE;
            end

            default: next_state = STATE_IDLE;
        endcase
    end

    // Output logic
    // run_game goes HIGH only in STATE_RUNNING
    // LED_GREEN is on in RUNNING or IDLE (no collision), LED_RED is on in COLLISION
    // (You can adjust LED behavior as you wish, e.g. turn GREEN off in IDLE.)
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            run_game   <= 1'b0;
            LED_RED    <= 1'b0;
            LED_GREEN  <= 1'b0;
        end else begin
            case (next_state)
                STATE_IDLE: begin
                    run_game   <= 1'b0;
                    LED_RED    <= 1'b0;
                    LED_GREEN  <= 1'b1;  // e.g., idle -> green on
                end

                STATE_RUNNING: begin
                    run_game   <= 1'b1;  // Let game_2 run
                    LED_RED    <= 1'b0;
                    LED_GREEN  <= 1'b1;  // Green LED on during normal play
                end

                STATE_COLLISION: begin
                    run_game   <= 1'b0;  // Pause the game
                    LED_RED    <= 1'b1;  // Collision -> red LED
                    LED_GREEN  <= 1'b0;
                end

                STATE_CLEARED: begin
                    run_game   <= 1'b0;  
                    LED_RED    <= 1'b0;  
                    LED_GREEN  <= 1'b1;  // Cleared -> green LED
                end

                default: begin
                    run_game   <= 1'b0;
                    LED_RED    <= 1'b0;
                    LED_GREEN  <= 1'b0;
                end
            endcase
        end
    end

endmodule