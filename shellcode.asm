BITS 64
DEFAULT REL

begin:
    and rsp, 0xFFFFFFFFFFFFFFF0 ; Căn chỉnh stack 16-byte
    
    ; --- Tìm ntdll.dll ---
    mov rax, [gs:0x60]
    mov rbx, [rax + 0x18]
    mov rcx, [rbx + 0x10]
    mov rdx, [rcx]
    mov r12, [rdx + 0x30]       ; r12 = DllBase ntdll

    ; --- Duyệt Export Table ---
    mov eax, dword [r12 + 0x3C]
    lea rbx, [r12 + rax]
    mov eax, dword [rbx + 0x88]
    add rax, r12                ; rax = Export Directory VA

    mov r13d, dword [rax + 0x1C]
    add r13, r12                ; r13 = AddressOfFunctions
    mov r14d, dword [rax + 0x20]
    add r14, r12                ; r14 = AddressOfNames
    mov r15d, dword [rax + 0x24]
    add r15, r12                ; r15 = AddressOfNameOrdinals

    xor rdx, rdx
    lea rax, [Function_Name]

while_loop:                     ; Sửa nhãn đồng nhất
    mov rdi, rax
    mov esi, dword [r14 + rdx * 4]
    add rsi, r12
    mov rcx, 17
    repe cmpsb
    je Found
    inc rdx
    jmp while_loop

Found:
    movzx ecx, word [r15 + rdx * 2]
    mov eax, dword [r13 + rcx * 4]
    add rax, r12                ; rax = VA NtRaiseHardError

    ; --- Setup Stack an toàn (0x70 byte để không bị ghi đè) ---
    sub rsp, 0x70               

    ; 1. Dựng UNICODE_STRING "Notice!" tại [rsp+0x40]
    mov word [rsp+0x40], 14
    mov word [rsp+0x42], 16
    mov dword [rsp+0x44], 0
    lea rsi, [Title]
    mov [rsp+0x48], rsi

    ; 2. Dựng UNICODE_STRING "halo" tại [rsp+0x50]
    mov word [rsp+0x50], 8
    mov word [rsp+0x52], 10
    mov dword [rsp+0x54], 0
    lea rsi, [Message]
    mov [rsp+0x58], rsi

    ; 3. Dựng Mảng địa chỉ tại [rsp+0x60] cho R9
    lea rdi, [rsp+0x40]
    mov [rsp+0x60], rdi
    lea rdi, [rsp+0x50]
    mov [rsp+0x68], rdi

    ; 4. Setup tham số cho Call
    mov rcx, 0x40000015        ; ErrorStatus
    mov rdx, 2                  ; Number of params
    mov r8, 3                   ; Mask
    lea r9, [rsp+0x60]          ; R9 = Mảng tham số

    mov qword [rsp+0x20], 1     ; Tham số 5: ValidResponse (OK)
    lea rsi, [rsp+0x38]         ; Dùng ô trống 0x38 làm biến nhận kết quả (c)
    mov [rsp+0x28], rsi         ; Tham số 6: Response pointer

    call rax                    ; Thực thi
    add rsp, 0x70               ; Dọn dẹp stack
    xor eax, eax 
    ret

align 8
Function_Name: db "NtRaiseHardError", 0
Title:         dw 'N','o','t','i','c','e','!',0
Message:       dw 'h','a','l','o',0