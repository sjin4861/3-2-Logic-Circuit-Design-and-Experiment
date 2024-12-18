module avoid_it_top(
    input  wire clk,
    input  wire rst,
    input  wire key0,
    input  wire key8,
    input  wire key_star,
    // 7-segment
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
    // LEDs
    output wire LED_RED,
    output wire LED_GREEN
);

    wire collision_detected_sig;
    wire game_cleared_sig;
    wire run_game_sig;

    // Instantiate game_event
    game_event event_inst (
        .clk               (clk),
        .rst               (rst),
        .key_star          (key_star),
        .collision_detected(collision_detected_sig),
        .game_cleared      (game_cleared_sig),
        .run_game          (run_game_sig),
        .LED_RED           (LED_RED),
        .LED_GREEN         (LED_GREEN)
    );

    // Instantiate game_2 (modified to accept run_game input)
    game_2 game_inst (
        .clk               (clk),
        .rst               (rst),
        .key0              (key0),
        .key8              (key8),
        .key_star          (key_star),
        .collision_detected(collision_detected_sig),
        .game_cleared      (game_cleared_sig),
        .run_game          (run_game_sig), 
        .seg_a(seg_a),
        .seg_g(seg_g),
        .seg_d(seg_d),
        .com1(com1),
        .com2(com2),
        .com3(com3),
        .com4(com4),
        .com5(com5),
        .com6(com6),
        .com7(com7),
        .com8(com8)
    );

endmodule