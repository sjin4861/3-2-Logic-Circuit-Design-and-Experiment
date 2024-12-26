module top(
    input  wire clk_1khz,    // 이미 보드에서 1kHz 클럭이 들어옴
    input  wire rst,
    input  wire key_star,
    input  wire collision_detected,
    input  wire game_clear,

    // --- 풀컬러 LED 4개 (각각 R/G만 사용) ---
    output wire F_LED1_RED,
    output wire F_LED1_GREEN,
    output wire F_LED2_RED,
    output wire F_LED2_GREEN,
    output wire F_LED3_RED,
    output wire F_LED3_GREEN,
    output wire F_LED4_RED,
    output wire F_LED4_GREEN,

    // --- LCD(8bit) ---
    output wire LCD_E,
    output wire LCD_RS,
    output wire LCD_RW,
    output wire [7:0] LCD_DATA,
    output wire piezo_out
);

//------------------------------------------------
// (1) 버튼(키) 동기화 & 에지 검출
//------------------------------------------------
reg [1:0] sync_star;
wire      key_star_rise;

// (1) 동기화 (1kHz 기준)
always @(posedge clk_1khz or posedge rst) begin
    if(rst) begin
        sync_star <= 2'b00;
    end else begin
        sync_star <= {sync_star[0], key_star};
    end
end

// (2) 상승 엣지 검출
assign key_star_rise = (sync_star == 2'b01);

//------------------------------------------------
// (2) 게임 FSM (game_event) - 1kHz 클럭
//------------------------------------------------
wire [1:0] current_state;

// LED 색 신호(단일비트) → 이를 풀컬러 4개 LED에 동일 적용
wire led_color_red;
wire led_color_green;

game_event_with_piezo u_game_event (
    .clk                (clk_1khz),
    .rst                (rst),
    .key_star_rise      (key_star_rise),
    .collision_detected (collision_detected),
    .game_clear         (game_clear),
    .led_red            (led_color_red),    // 리팩토링 후 이름 변경
    .led_green          (led_color_green),  // 리팩토링 후 이름 변경
    .current_state      (current_state),
    .piezo_out          (piezo_out)
);

//------------------------------------------------
// (3) 블록 개수 관리 로직
//------------------------------------------------
reg [3:0] block_remain;   // 최대 15 가능, 여기서는 10부터 시작
reg [9:0] sec_cnt;        // 1kHz라 1000까지 세면 1초

always @(posedge clk_1khz or posedge rst) begin
    if(rst) begin
        block_remain <= 4'd10;
        sec_cnt      <= 0;
    end else begin
        if(current_state == 2'b01) begin
            // S_CONTINUE 일 때만 1초마다 감소
            if(sec_cnt == 999) begin
                sec_cnt <= 0;
                if(block_remain > 0)
                    block_remain <= block_remain - 1;
            end else begin
                sec_cnt <= sec_cnt + 1;
            end
        end else begin
            // 다른 상태면 다시 10으로 초기화
            block_remain <= 4'd10;
            sec_cnt      <= 0;
        end
    end
end

//------------------------------------------------
// (4) LCD 제어 (lcd_control) - 1kHz 클럭
//------------------------------------------------
lcd_control u_lcd_control (
    .clk         (clk_1khz),
    .rst         (rst),
    .game_state  (current_state),
    .block_remain(block_remain),
    .LCD_E       (LCD_E),
    .LCD_RS      (LCD_RS),
    .LCD_RW      (LCD_RW),
    .LCD_DATA    (LCD_DATA)
);

//------------------------------------------------
// (5) 풀컬러 LED 4개 매핑
//------------------------------------------------
// 모든 LED가 동일 색을 켬 (led_color_red/led_color_green)
assign F_LED1_RED   = led_color_red;
assign F_LED2_RED   = led_color_red;
assign F_LED3_RED   = led_color_red;
assign F_LED4_RED   = led_color_red;

assign F_LED1_GREEN = led_color_green;
assign F_LED2_GREEN = led_color_green;
assign F_LED3_GREEN = led_color_green;
assign F_LED4_GREEN = led_color_green;

endmodule