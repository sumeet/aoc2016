section .data
INPUT_LENGTH equ 8
input: db "ugkcyxxp", 0

; sample
;INPUT_LENGTH equ 3
;input: db "abc", 0

printf_msg: db "%.8x", 10, 0
;printf_msg: db "%s", 10, 0
; TODO: figure out how to call the actual itoa from libc (not able to link)
itoa_msg: db "%d", 0
checksum_buffer: times 16 db 0
to_hash_buffer: times 1000 db 0
found_password_digits: db 0 ; bitmask 
NUM_PASSWORD_DIGITS equ 8
saved_password: dd 0 ; 8 * 0.5 (for 1 hex digit) => 4 bytes

%define loop_index_reg r12 ; non-volatile register
%define init_loop_index_reg() mov loop_index_reg, 0

%macro memcpy 3
; %1: dest addr
; %2: src addr
; %3: num_bytes
  cld
  mov rdi, %1
  mov rsi, %2
  mov rcx, %3
  rep movsb
%endmacro

section .text
;; TODO: without libc
global main
extern printf
extern sprintf
; TODO: it's slow to use this but probably doesn't matter
extern strlen

; from libcrypto
; unsigned char *MD5(const unsigned char *d, unsigned long n,
;                    unsigned char *md);
extern MD5

main:
  .init:
    init_loop_index_reg()

  .loop_body:
    cmp byte [found_password_digits], 0b11111111
    je print

    memcpy to_hash_buffer, input, INPUT_LENGTH
    mov rdi, to_hash_buffer + INPUT_LENGTH
    mov rsi, itoa_msg
    mov rdx, loop_index_reg
    mov rax, 0 ; not sure why rax needs to be set to 0 before calling
    call sprintf

    ; get the total length of the buffer we need to hash
    mov rdi, to_hash_buffer
    mov rax, 0
    call strlen

    ; md5sum it
    mov rdi, to_hash_buffer
    mov rsi, rax ; the size (return of strlen)
    mov rdx, checksum_buffer
    mov rax, 0
    call MD5

    ; check that first 5 hex digits, 20 bits, or first 2.5 bytes are 0

    ; word (2 bytes, i.e., 16 bits)
    cmp word [checksum_buffer], 0
    jne .continue_loop
    ; first 4 bits are 0
    ; TODO: not sure why we have to move this into the register first, but the following didn't work:
    ;   cmp byte [checksum_buffer + 2], 0x10 (who knows what the heck this did)
    movzx rax, byte [checksum_buffer + 2]
    cmp rax, 0x10
    jge .continue_loop

    ; grab the last 4 bits
    and rax, 0b00001111 ; or 0xf

    ; check if it will fit in the password
    cmp rax, NUM_PASSWORD_DIGITS
    jge .continue_loop

    ; check if we already saw that part of the password:
    ; "Use only the first result for each position"
    mov rcx, rax
    mov rdx, 1
    shl rdx, cl
    test byte [found_password_digits], dl
    jnz .continue_loop

    ; set the corresponding bit in found_password_digits
    or byte [found_password_digits], dl

    ; grab the next 4 bits
    movzx rbx, byte [checksum_buffer + 3]
    shr rbx, 4 ; shift right by 4 bits to grab the upper 4 bits
    ; throw it into the saved password
    mov rcx, NUM_PASSWORD_DIGITS
    sub rcx, rax
    sub rcx, 1
    lea rcx, [rcx * 4]
    shl rbx, cl

    add dword [saved_password], ebx
  .continue_loop:
    inc loop_index_reg
    jmp .loop_body

print:
  mov rdi, printf_msg
  mov rsi, 0 ; not sure if this is needed
  mov esi, dword [saved_password]
  mov rax, 0
  call printf
  mov rax, 0
  ret
