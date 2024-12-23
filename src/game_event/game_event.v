module game_event_with_piezo(
    input  wire clk,            // 1kHz
    input  wire rst,
    input  wire key_star_rise,  // '*' 키 상승엣지
    input  wire collision_detected, 
    input  wire game_clear,

    output reg  led_red,
    output reg  led_green,
    output reg  [1:0] current_state,

    // ★ 추가: 피에조(부저) 출력
    output wire piezo_out
);

//---------------------------------------------------
// (0) 상태 정의
//---------------------------------------------------
localparam S_MAIN     = 2'b00;
localparam S_CONTINUE = 2'b01;
localparam S_OVER     = 2'b10;
localparam S_CLEAR    = 2'b11;

reg [1:0] next_state;

//---------------------------------------------------
// (1) 상태 레지스터
//---------------------------------------------------
always @(posedge clk or posedge rst) begin
    if(rst)
        current_state <= S_MAIN;
    else
        current_state <= next_state;
end

//---------------------------------------------------
// (2) 다음 상태 결정
//---------------------------------------------------
always @(*) begin
    next_state = current_state;
    case(current_state)
        S_MAIN: begin
            if(key_star_rise)         // '*' 키
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
            // 여기서는 특별한 조건이 없으니 유지
        end
    endcase
end

//---------------------------------------------------
// (3) LED 제어 (단일 비트 2개)
//---------------------------------------------------
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

//---------------------------------------------------
// (4) Piezo 제어 로직
//---------------------------------------------------

// (4-1) 상태별 분주값(주파수 결정)
//       1kHz 클록 기준, 대략 원하는 음정으로 예시
wire [9:0] divide_val;  // 최대 1023까지
assign divide_val = (current_state == S_CONTINUE) ? 10'd2  :  // 1kHz / (2*2)   = 250Hz
                   (current_state == S_OVER)     ? 10'd4  :  // 1kHz / (2*4)   = 125Hz
                   (current_state == S_CLEAR)    ? 10'd8  :  // 1kHz / (2*8)   = 62.5Hz
                                                  10'd0;   // S_MAIN 또는 그외: 소리X

// (4-2) 분주 카운터
reg [9:0] cnt;
always @(posedge clk or posedge rst) begin
    if(rst) begin
        cnt <= 0;
    end else begin
        // divide_val == 0 이면 소리를 내지 않는다 (piezo_out=0)
        if(divide_val == 0) begin
            cnt <= 0; // 카운터 동작X
        end else begin
            // 1kHz마다 카운트
            if(cnt >= (divide_val - 1))
                cnt <= 0;
            else
                cnt <= cnt + 1;
        end
    end
end

// (4-3) 사각파 발생
// divide_val != 0일 때만 토글, ==0이면 0
reg piezo_reg;
always @(posedge clk or posedge rst) begin
    if(rst) begin
        piezo_reg <= 1'b0;
    end else begin
        if(divide_val == 0) begin
            piezo_reg <= 1'b0;
        end else if(cnt == (divide_val - 1)) begin
            // 카운트 끝날 때마다 토글
            piezo_reg <= ~piezo_reg;
        end
    end
end

assign piezo_out = piezo_reg;

endmodule
