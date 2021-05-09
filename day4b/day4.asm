%include "../lib/memmove.asm"

%macro zero_out_bytes 2
; %1: starting addr
; %2: num_bytes
  %assign i 0
  %rep %2
    mov byte [%1 + i], 0
    %assign i i+1
  %endrep
%endmacro

section .data
printf_msg: db "%s", 10, 0
input: incbin "./input"
; null terminate the read file
db 0
letter_count: times 26 db 0

THIS_ROOM_NAME_SIZE equ 400
this_room_name: times THIS_ROOM_NAME_SIZE db 0
this_room_name_length: dq 0

%macro reset_this_room_name 0
  zero_out_bytes this_room_name, THIS_ROOM_NAME_SIZE
  mov qword [this_room_name_length], 0
%endmacro

THIS_SECTOR_ID_STRING_SIZE equ 10
this_sector_id_string: times THIS_SECTOR_ID_STRING_SIZE db 0
this_sector_id_string_length: dq 0

%macro reset_this_sector_id_string 0
  zero_out_bytes this_sector_id_string, THIS_SECTOR_ID_STRING_SIZE
  mov qword [this_sector_id_string_length], 0
%endmacro

all_room_names: times 20000 db 0
all_room_names_length: dq 0

section .text
;; TODO: without libc
global main
extern printf

%define parse_cursor_reg r12
%define total_sum_reg r13
%define sector_id_reg r14

%macro clear_letter_count 0
  zero_out_bytes letter_count, 26
%endmacro

%macro copy_this_room_name_to_all_room_names 0
  
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

; rotates a null terminated lowercase alpha string by N rotations (wraps around at 'z')
rotate_string:
; args:
;   starting position: rdi
;   num_rotations: rsi
  .start_loop:
    cmp byte [rdi], 0
    je .done

    ; adapted python code:
    ; def add_to_char(c, num_rots):
    ;     offset = ord(c) - ord('a')
    ;     new_offset = (offset + num_rots) % 26
    ;     return chr((ord('a') + new_offset))
    movzx rax, byte [rdi]
    ; find the original offset
    sub rax, 'a'
    ; add the number of rotations
    add rax, rsi
    mov rdx, 0
    mov rbx, 26
    div rbx
    ; rdx now contains the new offset: (offset + num rotations) mod 26
    add rdx, 'a'
    mov byte [rdi], dl
  .continue_loop:
    inc rdi
    jmp .start_loop
  .done:
    ret

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
  reset_this_room_name
  reset_this_sector_id_string
inner_line_parse_loop:
  ; end of line, if we made it this far, then we can add to total sum!
  cmp this_char, ']'
  jne not_end_of_line
end_of_line:
  cmp sector_id_reg, 0
  je continue_line_loop

  valid_checksum:
    add total_sum_reg, sector_id_reg
    ; rotate string in here
    mov rdi, this_room_name ; starting position
    mov rsi, sector_id_reg ; num_rotations
    call rotate_string

    ; move rotated string to end list
    mov rdi, all_room_names ; destination
    ; add the length so we append to the end
    add rdi, [all_room_names_length]
    mov rsi, this_room_name ; source
    mov rdx, [this_room_name_length] ; num bytes to copy
    call memmove
    mov rax, [all_room_names_length]
    add rax, [this_room_name_length]
    mov [all_room_names_length], rax

    ; copy digits to end of string
    mov rdi, all_room_names ; destination
    ; add the length so we append to the end
    add rdi, [all_room_names_length]
    mov rsi, this_sector_id_string ; source
    mov rdx, [this_sector_id_string_length] ; num bytes to copy
    call memmove

    mov rax, [all_room_names_length]
    add rax, [this_sector_id_string_length]
    ; add another for the newline
    add rax, 1
    mov [all_room_names_length], rax
    add rax, all_room_names
    ; the newline is 1 earlier
    sub rax, 1
    ; add the newline
    mov byte [rax], 10
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
      .append_this_room_name:
        mov rax, this_room_name
        add rax, [this_room_name_length]
        movzx rbx, this_char
        mov byte [rax], bl
        inc qword [this_room_name_length]

      .add_letter_count:
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
    .append_to_this_sector_id_string:
      mov rax, this_sector_id_string
      add rax, [this_sector_id_string_length]
      movzx rbx, this_char
      mov byte [rax], bl
      inc qword [this_sector_id_string_length]

    .continue_parse_sector_id:
      mov rax, sector_id_reg
      mov rbx, 10
      mul rbx
      movzx rbx, this_char
      lea sector_id_reg, [rax + rbx - '0']
continue_inner_line_parse_loop:
  inc parse_cursor_reg
  jmp inner_line_parse_loop
continue_line_loop:
  inc parse_cursor_reg
  jmp line_loop
print:
  mov rsi, all_room_names
  mov rdi, printf_msg
  mov rax, 0
  call printf
  mov rax, 0
  ret

