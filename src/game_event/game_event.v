module game_event_with_piezo(
    input  wire clk,            // 1kHz 클럭 (실제론 고속 클럭 권장)
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
            if(key_star_rise)
                next_state = S_CONTINUE;
        end
        S_CONTINUE: begin
            if(collision_detected)
                next_state = S_OVER;
            else if(game_clear)
                next_state = S_CLEAR;
        end
        S_OVER: begin
            // 오버 시에 '*' 누르면 재시작(S_MAIN)
            if(key_star_rise)
                next_state = S_MAIN;
        end
        S_CLEAR: begin
            // 필요시 별 누르면 MAIN 복귀 등
            // if(key_star_rise) next_state = S_MAIN;
        end
    endcase
end

//---------------------------------------------------
// (3) LED 제어
//---------------------------------------------------
always @(*) begin
    led_red   = 1'b0;
    led_green = 1'b0;
    case(current_state)
        S_MAIN:     led_red   = 1'b1;  // 대기 - 빨강
        S_CONTINUE: led_green = 1'b1;  // 진행 - 초록
        S_OVER:     led_red   = 1'b1;  // 오버 - 빨강
        S_CLEAR:    led_green = 1'b1;  // 클리어 - 초록
    endcase
end

//---------------------------------------------------
// (4) Piezo 사운드: "음정 + 멜로디" 구현
//---------------------------------------------------

// (4-1) 노트(음정) 정의 (1kHz에서의 예시 분주값)
// 실제론 각 음정의 정확한 분주값을 계산해서 넣어야 합니다.
localparam DIV_SILENT = 10'd0;   // 무음
// 간단히 몇 개 음정만 예시:
localparam DIV_DO     = 10'd2;   // ~250Hz
localparam DIV_RE     = 10'd3;   // ~166Hz
localparam DIV_MI     = 10'd4;   // ~125Hz
localparam DIV_FA     = 10'd5;   // ~100Hz
localparam DIV_SOL    = 10'd6;   // ~83Hz
localparam DIV_LA     = 10'd7;   // ~71Hz
localparam DIV_SI     = 10'd8;   // ~62Hz

//---------------------------------------------------
// (4-2) 상태별 "멜로디" 테이블
//      - 각 멜로디는 일정 길이의 노트 시퀀스
//---------------------------------------------------

// [A] 진행 중 (S_CONTINUE) 멜로디 (계속 반복)
reg [9:0] melody_continue [0:3];  // 4노트
initial begin
    melody_continue[0] = DIV_DO;
    melody_continue[1] = DIV_RE;
    melody_continue[2] = DIV_MI;
    melody_continue[3] = DIV_RE;
end

// [B] 게임오버 (S_OVER) 멜로디 (예: 비프 3회)
reg [9:0] melody_over [0:5];      // 6단계
initial begin
    // 예: DO 0.3초, 쉼표 0.1초, DO 0.3초, 쉼표 0.1초, DO 0.3초, 끝
    melody_over[0] = DIV_DO;
    melody_over[1] = DIV_SILENT;
    melody_over[2] = DIV_DO;
    melody_over[3] = DIV_SILENT;
    melody_over[4] = DIV_DO;
    melody_over[5] = DIV_SILENT;
end

// [C] 클리어 (S_CLEAR) 멜로디 (간단 승리음)
reg [9:0] melody_clear [0:5];     // 6노트
initial begin
    melody_clear[0] = DIV_DO;
    melody_clear[1] = DIV_MI;
    melody_clear[2] = DIV_SOL;
    melody_clear[3] = DIV_MI;
    melody_clear[4] = DIV_DO;
    melody_clear[5] = DIV_SILENT;
end

//---------------------------------------------------
// (4-3) 노트 재생 위한 FSM
//---------------------------------------------------

// 노트 재생 길이(단위 시간) - 1kHz 기준 300ms 정도로 설정
localparam NOTE_DUR = 16'd300;  // 노트 1개당 300 사이클(=300ms) 재생

reg [15:0] note_timer;   // 현재 노트를 몇 ms째 재생 중인지
reg [2:0]  note_index;   // 현재 멜로디 배열의 인덱스
reg [9:0]  current_div;  // 현재 분주값(=음정)

// 재생할 멜로디의 최대 길이
localparam CONTINUE_LEN = 4; // melody_continue 길이
localparam OVER_LEN     = 6; // melody_over 길이
localparam CLEAR_LEN    = 6; // melody_clear 길이

always @(posedge clk or posedge rst) begin
    if(rst) begin
        note_timer  <= 0;
        note_index  <= 0;
        current_div <= DIV_SILENT;
    end else begin
        case(current_state)
            S_MAIN: begin
                // 무음, 인덱스 0
                note_timer  <= 0;
                note_index  <= 0;
                current_div <= DIV_SILENT;
            end

            S_CONTINUE: begin
                // 반복 재생
                // 1) 현재 노트 재생
                current_div <= melody_continue[note_index];

                // 2) NOTE_DUR만큼 지나면 다음 노트
                if(note_timer < NOTE_DUR - 1) begin
                    note_timer <= note_timer + 1;
                end else begin
                    note_timer <= 0;
                    // 다음 노트
                    if(note_index == (CONTINUE_LEN - 1))
                        note_index <= 0;  // 계속 반복
                    else
                        note_index <= note_index + 1;
                end
            end

            S_OVER: begin
                // 오버 멜로디 한번 재생 (끝나면 마지막 노트 유지 or 무음)
                current_div <= melody_over[note_index];
                if(note_timer < NOTE_DUR - 1) begin
                    note_timer <= note_timer + 1;
                end else begin
                    note_timer <= 0;
                    if(note_index < OVER_LEN - 1)
                        note_index <= note_index + 1;
                    else
                        note_index <= OVER_LEN - 1; // 마지막 노트 유지
                end
            end

            S_CLEAR: begin
                // 클리어 멜로디
                current_div <= melody_clear[note_index];
                if(note_timer < NOTE_DUR - 1) begin
                    note_timer <= note_timer + 1;
                end else begin
                    note_timer <= 0;
                    if(note_index < CLEAR_LEN - 1)
                        note_index <= note_index + 1;
                    else
                        note_index <= CLEAR_LEN - 1;
                end
            end

            default: begin
                // 안전망
                note_timer  <= 0;
                note_index  <= 0;
                current_div <= DIV_SILENT;
            end
        endcase
    end
end

//---------------------------------------------------
// (4-4) 실제 분주로 사각파 만들기
//---------------------------------------------------
reg [9:0] cnt;
reg piezo_reg;

always @(posedge clk or posedge rst) begin
    if(rst) begin
        cnt       <= 0;
        piezo_reg <= 1'b0;
    end else begin
        if(current_div == 0) begin
            // 무음
            cnt       <= 0;
            piezo_reg <= 1'b0;
        end else begin
            if(cnt >= (current_div - 1)) begin
                cnt       <= 0;
                piezo_reg <= ~piezo_reg;
            end else begin
                cnt <= cnt + 1;
            end
        end
    end
end

assign piezo_out = piezo_reg;

endmodule