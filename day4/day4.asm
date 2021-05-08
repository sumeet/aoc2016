section .text
;; TODO: without libc
global main
extern printf

%define parse_cursor_reg r12
%define total_sum_reg r13
%define sector_id_reg r14

%macro clear_letter_count 0
  %assign i 0
  %rep 26
    mov byte [letter_count + i], 0
    %assign i i+1
  %endrep
%endmacro

%macro cmp_between 3
; %1: value
; %2: lower bound (inclusive)
; %3: upper bound (inclusive)
; sets flags (true or false)
  cmp %1, %2 ; val < lower bound
  jl %%false
  cmp %1, %3 ; val <= upper bound
  jle %%true
  jmp %%false
  %%true:
    mov rax, 0
    cmp rax, 0
    jmp %%end
  %%false:
    mov rax, 1
    cmp rax, 0
  %%end:
%endmacro

%define this_char byte [input + parse_cursor_reg]

get_and_clear_winner:
  %push
  %stacksize flat64
  %assign %$localsize 0 
  %local winner_char:byte, winner_count:byte
    enter %$localsize, 0
    mov byte [winner_char], 0
    mov byte [winner_count], 0
    %assign i 0
    %rep 26
      movzx rax, byte [letter_count + i]
      cmp al, byte [winner_count]
      jle done%+ i
      set_winner%+ i:
        mov byte [winner_char], 'a' + i
        mov byte [winner_count], al
      done%+ i:
      %assign i i+1
    %endrep
    ; clear the count of the highest char
    movzx rax, byte [winner_char]
    mov byte [letter_count + rax - 'a'], 0
    ; return the highest char
    movzx rax, byte [winner_char]
    leave
    ret
  %pop
main:
init:
  mov parse_cursor_reg, 0
  mov total_sum_reg, 0
line_loop:
  mov sector_id_reg, 0
  clear_letter_count
inner_line_parse_loop:
  ; end of line, if we made it this far, then we can add to total sum!
  cmp this_char, ']'
  jne not_end_of_line
  add total_sum_reg, sector_id_reg
  jmp continue_line_loop
not_end_of_line:
  ; hit null terminator, go print and end the program
  cmp this_char, 0
  je print

  cmp_between this_char, 'a', 'z'
  je handle_alpha
  cmp_between this_char, '0', '9'
  je handle_digit
  jmp continue_inner_line_parse_loop
  handle_alpha:
    ; if we've already seen the sector_id, then start verifying, because
    ; the number appears AFTER the encrypted name
    ;
    ; name            id  cksum
    ; ^               ^   ^
    ; aaaaa-bbb-z-y-x-123[abxyz]
    cmp sector_id_reg, 0
    jne verify_checksum_char
    count_letter:
      movzx rax, this_char
      inc byte [letter_count + rax - 'a']
      jmp continue_inner_line_parse_loop
    verify_checksum_char:
      call get_and_clear_winner
      ; get_and_clear_winner returns the first winningest char to rax
      cmp al, this_char
      je continue_inner_line_parse_loop
      jmp continue_line_loop
  handle_digit:
    mov rax, sector_id_reg
    mov rdx, 10
    mul rdx
    movzx rbx, this_char
    lea sector_id_reg, [rax + rbx - '0']
continue_inner_line_parse_loop:
  inc parse_cursor_reg
  jmp inner_line_parse_loop
continue_line_loop:
  inc parse_cursor_reg
  jmp line_loop
print:
  mov rsi, total_sum_reg
  mov rdi, printf_msg
  mov rax, 0
  call printf
  mov rax, 0
  ret

section .data
printf_msg: db "%d", 10, 0
input: incbin "./input"
; null terminate the read file
db 0
letter_count: times 26 db 0
