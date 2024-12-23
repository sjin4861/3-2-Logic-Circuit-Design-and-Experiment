module lcd_control(
    input wire clk,    // 1kHz
    input wire rst,
    input wire [1:0] game_state,
    input wire [3:0] block_remain,  
    output wire LCD_E,
    output wire LCD_RS,
    output wire LCD_RW,
    output wire [7:0] LCD_DATA
);

//----------------------------------------------------------
// (A) 상태 정의
//----------------------------------------------------------
localparam ST_INIT1 = 3'b000; // FUNCTION_SET
localparam ST_INIT2 = 3'b001; // DISP_ONOFF
localparam ST_INIT3 = 3'b010; // ENTRY_MODE
localparam ST_LINE1 = 3'b100; // 라인1 출력
localparam ST_LINE2 = 3'b101; // 라인2 출력
localparam ST_IDLE  = 3'b110; // 유지

//----------------------------------------------------------
// (B) 내부 레지스터
//----------------------------------------------------------
reg [2:0] state;
reg [15:0] cnt;
reg lcd_rs_reg, lcd_rw_reg;
reg [7:0] lcd_data_reg;

// "직전 game_state" 저장
reg [1:0] prev_game_state;

//----------------------------------------------------------
// (C) prev_game_state 갱신
//----------------------------------------------------------
always @(posedge clk or posedge rst) begin
    if(rst)
        prev_game_state <= 2'b00;  // S_MAIN
    else if(state==ST_IDLE)
        prev_game_state <= game_state;
end

//----------------------------------------------------------
// (D) 메인 FSM: 1kHz로 동작
//----------------------------------------------------------
always @(posedge clk or posedge rst) begin
    if(rst) begin
        state <= ST_INIT1;
        cnt   <= 16'd0;
    end else begin
        case(state)
            //-----------------------------------------
            // 초기화 순서
            //-----------------------------------------
            ST_INIT1: begin
                if(cnt==10) begin
                    state <= ST_INIT2;
                    cnt <= 0;
                end else begin
                    cnt <= cnt + 1;
                end
            end

            ST_INIT2: begin
                if(cnt==10) begin
                    state <= ST_INIT3;
                    cnt <= 0;
                end else begin
                    cnt <= cnt + 1;
                end
            end

            ST_INIT3: begin
                if(cnt==10) begin
                    state <= ST_LINE1;
                    cnt <= 0;
                end else begin
                    cnt <= cnt + 1;
                end
            end

            //-----------------------------------------
            // 라인1 → 라인2 순차 출력
            //-----------------------------------------
            ST_LINE1: begin
                if(cnt >= 16) begin
                    // 라인1 출력 끝나면 라인2로
                    state <= ST_LINE2;
                    cnt <= 0;
                end else begin
                    cnt <= cnt + 1;
                end
            end

            ST_LINE2: begin
                if(cnt >= 16) begin
                    // 라인2 출력 끝나면 IDLE로
                    state <= ST_IDLE;
                    cnt <= 0;
                end else begin
                    cnt <= cnt + 1;
                end
            end

            //-----------------------------------------
            // ST_IDLE
            //-----------------------------------------
            ST_IDLE: begin
                // 1) 만약 state가 바뀌었으면 즉시 재출력
                if(prev_game_state != game_state) begin
                    state <= ST_LINE1;
                    cnt <= 0;
                end
                // 2) OR S_CONTINUE인 동안 1초마다 갱신
                else if(game_state == 2'b01) begin
                    if(cnt == 999) begin  
                        // 1초마다 다시 라인 출력
                        state <= ST_LINE1;
                        cnt <= 0;
                    end else begin
                        cnt <= cnt + 1;
                    end
                end
                // 3) 그 외에는 계속 대기
                else begin
                    state <= ST_IDLE;
                end
            end

            default: begin
                state <= ST_IDLE;
                cnt <= 0;
            end
        endcase
    end
end

//----------------------------------------------------------
// (E) LCD 명령/데이터 출력
//----------------------------------------------------------
always @(posedge clk or posedge rst) begin
    if(rst) begin
        lcd_rs_reg   <= 1'b1;
        lcd_rw_reg   <= 1'b1;
        lcd_data_reg <= 8'b0;
    end else begin
        // 기본값
        lcd_rs_reg   <= 1'b1;
        lcd_rw_reg   <= 1'b1;
        lcd_data_reg <= 8'b00000000;

        case(state)
            // 초기화 커맨드들
            ST_INIT1: begin
                lcd_rs_reg <= 0;
                lcd_rw_reg <= 0;
                lcd_data_reg <= 8'b00111100; // FUNCTION_SET
            end
            ST_INIT2: begin
                lcd_rs_reg <= 0;
                lcd_rw_reg <= 0;
                lcd_data_reg <= 8'b00001100; // DISP_ONOFF
            end
            ST_INIT3: begin
                lcd_rs_reg <= 0;
                lcd_rw_reg <= 0;
                lcd_data_reg <= 8'b00000110; // ENTRY_MODE
            end

            // 라인1 출력
            ST_LINE1: begin
                lcd_rw_reg <= 0;
                if(cnt == 0) begin
                    // 커서(Line1)
                    lcd_rs_reg <= 0;
                    lcd_data_reg <= 8'b10000000; 
                end else begin
                    // 실제 문자들
                    lcd_rs_reg <= 1;
                    case(game_state)
                        2'b00: begin // S_MAIN => "AVOID IT!"
                            case(cnt)
                                1:  lcd_data_reg<="A";
                                2:  lcd_data_reg<="V";
                                3:  lcd_data_reg<="O";
                                4:  lcd_data_reg<="I";
                                5:  lcd_data_reg<="D";
                                6:  lcd_data_reg<=" ";
                                7:  lcd_data_reg<="I";
                                8:  lcd_data_reg<="T";
                                9:  lcd_data_reg<="!";
                                default: lcd_data_reg<=" ";
                            endcase
                        end
                        2'b01: begin // S_CONTINUE => "Playing..."
                            case(cnt)
                                1:  lcd_data_reg<="P";
                                2:  lcd_data_reg<="l";
                                3:  lcd_data_reg<="a";
                                4:  lcd_data_reg<="y";
                                5:  lcd_data_reg<="i";
                                6:  lcd_data_reg<="n";
                                7:  lcd_data_reg<="g";
                                8:  lcd_data_reg<=".";
                                9:  lcd_data_reg<=".";
                                10: lcd_data_reg<=".";
                                default: lcd_data_reg<=" ";
                            endcase
                        end
                        2'b10: begin // S_OVER => "GAME OVER"
                            case(cnt)
                                1:  lcd_data_reg<="G";
                                2:  lcd_data_reg<="A";
                                3:  lcd_data_reg<="M";
                                4:  lcd_data_reg<="E";
                                5:  lcd_data_reg<=" ";
                                6:  lcd_data_reg<="O";
                                7:  lcd_data_reg<="V";
                                8:  lcd_data_reg<="E";
                                9:  lcd_data_reg<="R";
                                default: lcd_data_reg<=" ";
                            endcase
                        end
                        2'b11: begin // S_CLEAR => "GAME CLEAR!"
                            case(cnt)
                                1:  lcd_data_reg<="G";
                                2:  lcd_data_reg<="A";
                                3:  lcd_data_reg<="M";
                                4:  lcd_data_reg<="E";
                                5:  lcd_data_reg<=" ";
                                6:  lcd_data_reg<="C";
                                7:  lcd_data_reg<="L";
                                8:  lcd_data_reg<="E";
                                9:  lcd_data_reg<="A";
                                10: lcd_data_reg<="R";
                                11: lcd_data_reg<="!";
                                default: lcd_data_reg<=" ";
                            endcase
                        end
                        default: lcd_data_reg<=" ";
                    endcase
                end
            end

            // 라인2 출력
            ST_LINE2: begin
                lcd_rw_reg <= 0;
                if(cnt == 0) begin
                    // 커서(Line2)
                    lcd_rs_reg <= 0;
                    lcd_data_reg<=8'b11000000; // 0xC0
                end else begin
                    // 실제 문자들
                    lcd_rs_reg <= 1;
                    case(game_state)
                        2'b00: begin // MAIN => "* start"
                            case(cnt)
                                1:  lcd_data_reg<="*";
                                2:  lcd_data_reg<=" ";
                                3:  lcd_data_reg<="s";
                                4:  lcd_data_reg<="t";
                                5:  lcd_data_reg<="a";
                                6:  lcd_data_reg<="r";
                                7:  lcd_data_reg<="t";
                                default: lcd_data_reg<=" ";
                            endcase
                        end
                        2'b01: begin // S_CONTINUE => "Block Remain : XX"
                            case(cnt)
                                1:  lcd_data_reg<="B";
                                2:  lcd_data_reg<="l";
                                3:  lcd_data_reg<="o";
                                4:  lcd_data_reg<="c";
                                5:  lcd_data_reg<="k";
                                6:  lcd_data_reg<=" ";
                                7:  lcd_data_reg<="R";
                                8:  lcd_data_reg<="e";
                                9:  lcd_data_reg<="m";
                                10: lcd_data_reg<="a";
                                11: lcd_data_reg<="i";
                                12: lcd_data_reg<="n";
                                13: lcd_data_reg<=":";
                                14: lcd_data_reg<=" ";
                                // block_remain 두 자리 출력
                                15: lcd_data_reg <= ((block_remain / 10) + 8'd48);
                                16: lcd_data_reg <= ((block_remain % 10) + 8'd48);
                                default: lcd_data_reg<=" ";
                            endcase
                        end
                        2'b10: begin // OVER => "Try again?"
                            case(cnt)
                                1:  lcd_data_reg<="T";
                                2:  lcd_data_reg<="r";
                                3:  lcd_data_reg<="y";
                                4:  lcd_data_reg<=" ";
                                5:  lcd_data_reg<="a";
                                6:  lcd_data_reg<="g";
                                7:  lcd_data_reg<="a";
                                8:  lcd_data_reg<="i";
                                9:  lcd_data_reg<="n";
                                10: lcd_data_reg<="?";
                                default: lcd_data_reg<=" ";
                            endcase
                        end
                        2'b11: begin // CLEAR => "Congratz!"
                            case(cnt)
                                1:  lcd_data_reg<="C";
                                2:  lcd_data_reg<="o";
                                3:  lcd_data_reg<="n";
                                4:  lcd_data_reg<="g";
                                5:  lcd_data_reg<="r";
                                6:  lcd_data_reg<="a";
                                7:  lcd_data_reg<="t";
                                8:  lcd_data_reg<="z";
                                9:  lcd_data_reg<="!";
                                default: lcd_data_reg<=" ";
                            endcase
                        end
                        default: lcd_data_reg<=" ";
                    endcase
                end
            end

            default: /* ST_IDLE etc. */ begin
                // 아무 것도 하지 않음
            end
        endcase
    end
end

//----------------------------------------------------------
// (F) LCD 핀 연결
//----------------------------------------------------------
assign LCD_E    = clk;   // 1kHz를 Enable로 사용
assign LCD_RS   = lcd_rs_reg;
assign LCD_RW   = lcd_rw_reg;
assign LCD_DATA = lcd_data_reg;

endmodule