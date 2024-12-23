module game_event(
    input wire clk,    // 1kHz
    input wire rst,
    input wire key_star_rise,     // '*' 키 상승엣지
    input wire collision_detected, 
    input wire game_clear,
    output reg led_red,
    output reg led_green,
    output reg [1:0] current_state
);

// 상태 정의
localparam S_MAIN     = 2'b00;
localparam S_CONTINUE = 2'b01;
localparam S_OVER     = 2'b10;
localparam S_CLEAR    = 2'b11;

reg [1:0] next_state;

// (1) 상태 레지스터
always @(posedge clk or posedge rst) begin
    if(rst)
        current_state <= S_MAIN;
    else
        current_state <= next_state;
end

// (2) 다음 상태 결정
always @(*) begin
    next_state = current_state;
    case(current_state)
        S_MAIN: begin
            if(key_star_rise)        // '*' 키
                next_state = S_CONTINUE;
        end
        S_CONTINUE: begin
            if(collision_detected)
                next_state = S_OVER;
            else if(game_clear)
                next_state = S_CLEAR;
        end
        S_OVER: begin
            // (추가) 게임오버 시에 '*' 누르면 재시작(S_MAIN)
            if(key_star_rise)
                next_state = S_MAIN;
        end
        S_CLEAR: begin
            // 필요 시 MAIN 복귀, 또는 그대로 유지
        end
    endcase
end

// (3) LED 제어 → 여기서는 단일 비트 2개만 출력
//     (top에서 풀컬러 4개로 매핑)
always @(*) begin
    led_red   = 1'b0;
    led_green = 1'b0;
    case(current_state)
        S_MAIN:     led_red   = 1'b1;  // 대기 상태 - 빨강
        S_CONTINUE: led_green = 1'b1;  // 진행 중 - 초록
        S_OVER:     led_red   = 1'b1;  // 게임오버 - 빨강
        S_CLEAR:    led_green = 1'b1;  // 클리어  - 초록
    endcase
end

endmodule
