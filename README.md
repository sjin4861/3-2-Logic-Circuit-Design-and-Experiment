# PNU 논리회로설계및실험 5조 - Avoid_It (7-segment 8-array를 이용한 장애물 피하기 게임)


## 프로젝트 개요
Chrome의 공룡 게임을 모티브로 하여 FPGA 보드에서 새로운 방식으로 게임을 구현하는 것을 목표로 합니다.
Text LCD, 키패드, 8 Array 7-Segment, PIEZO, Full Color LED 등 다양한 하드웨어 장치와 연동함으로써 몰입감 있는 사용자 경험을 제공합니다.

- Text LCD : 상태(대기, 진행, 게임 오버, 게임 클리어)와 블록 잔여량 표시
- KeyPad : 게임 시작, 재시작 및 게임 도중 사용자의 동작 입력
- PIEZO : 상황별 사운드 출력
- Full Color LED : 상태별 색 변화 (초록 = 진행/클리어, 빨강 = 게임 오버)
- 7-Segment : 블럭들을 표현하여 실제 게임 진행 상황 출력

이 프로젝트의 시연 영상을 보려면 아래 링크를 클릭하세요:
[시연 영상]()

---

## 게임 진행 및 시나리오

1. **대기 화면 및 시작**  
- 초기 상태에서 Text LCD에 대기 화면 표시
- 키패드의 '*' 키를 눌러 게임 시작
- PIEZO로 간단한 스타트 사운드 재생 가능 

2. **게임 진행 및 블록 피하기**  
- Text LCD 하단에 'Block Remain' 표시 (1초마다 10→9→8… 감소)
- 사용자 키 입력으로 공룡을 이동하여 블록 충돌 회피
- Full Color LED는 초록색 → '진행 중'
- PIEZO로 긴장감·경쾌함 등의 효과음 구현
3. **게임 오버**  
- 블록과 충돌 시 Text LCD 'GAME OVER' + LED(빨강) 점등
- PIEZO로 게임 오버 사운드
- '*' 키로 재시작 가능
4. **게임 클리어**  
- 모든 블록을 피하면 LCD에 "Clear! Congratz!"
- LED(초록), PIEZO(클리어 사운드)

---

## 주요 과제 수행
1) 게임 로직(Game Logic)
   - 상태머신(FSM) 기반으로 Init→Idle→Play→End(Over/Clear) 설계
   - 8-Counter, Shift Register, Trigger, Mux 등 사용

2) 충돌(Collision) 로직
   - 공룡 위치와 장애물 배열을 하드웨어적으로 비교
   - 충돌 시 '게임 오버' 상태 진입

3) PIEZO 활용
   - 분주기(Divider)로 주파수 생성
   - 상황별 배경음·알림음 구현

4) Text LCD
   - 초기화 FSM(Function Set, Display On/Off 등)
   - ASCII 코드 전송으로 문자열 표시
   - Block Remain 등 동적 데이터 갱신

5) Full Color LED
   - R/G 채널만 사용 (빨강=대기/오버, 초록=진행/클리어)
   - .xdc 핀 매핑, LED 상태 FSM과 연동