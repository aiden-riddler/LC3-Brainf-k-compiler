.orig x3000 

START   
    ; Display prompt to add brainfry code
    LEA R0, PROMPT
    PUTS

    ; Get program code from user
    LD R1, PROGRAM_CODE_PTR
READ_LOOP
    GETC
    OUT
    ADD R2, R0, #-10;
    BRz END_INPUT
    ADD R3, R1, R4
    STR R0, R3, #0
    ADD R4, R4, #1
    BR READ_LOOP
    
END_INPUT
    ADD R3, R1, R4  ; Calculate the address for the null terminator
    AND R0, R0, #0  ; Clear R0 to zero
    STR R0, R3, #0  ; Store the null terminator
    ; print program loaded statement
    LEA R0, PROGRAM_LOADED_STR
    PUTS
    AND R4, R4, #0

PRINT_LOOP
    ADD R3, R1, R4     ; Calculate the address of the current character
    LDR R0, R3, #0     ; Load the character into R0
    BRz CONTINUE      ; If the character is null (0), end the loop
    TRAP x21           ; Output the character in R0
    ADD R4, R4, #1     ; Increment the index/offset
    BR PRINT_LOOP      ; Repeat the loop
    
CONTINUE
    LEA R0, NEW_LINE
    PUTS
    LEA R3, TAPE        ; pointer
    LD R4, PROGRAM_CODE_PTR     ; PROGRAM_CODE[0]
    
PROCESS_CODE
    LDR R0, R4, #0  ; PROGRAM_CODE[i]
    ADD R4, R4, #1  ; Move to the next character
    
    LD R5, NEG126
    ADD R2, R0, R5
    BRz EXIT ; check if end of program ~
    
    ; process commands (>)
    LD R5, NEG62
    ADD R2, R0, R5
    BRz INCREMENT_POINTER
    
    ; process commands (<)
    LD R5, NEG60
    ADD R2, R0, R5
    BRz DECREMENT_POINTER
    
    ; process commands (+)
    LD R5, NEG43
    ADD R2, R0, R5
    BRz INCREMENT_CELL
    
    ; process commands (-)
    LD R5, NEG45
    ADD R2, R0, R5
    BRz DECREMENT_CELL
    
    ; process commands (.)
    LD R5, NEG46
    ADD R2, R0, R5
    BRz OUTPUT_CELL
    
    ; process commands (,)
    LD R5, NEG44
    ADD R2, R0, R5
    BRz INPUT_CELL
    
    ; process commands ([)
    LD R5, NEG91
    ADD R2, R0, R5
    BRz HANDLE_OPEN_BRACKET
    
    ; process commands (])
    LD R5, NEG93
    ADD R2, R0, R5
    BRz HANDLE_CLOSE_BRACKET
    
    BR PROCESS_CODE
    
INCREMENT_POINTER
    ADD R3, R3, #1
    BR PROCESS_CODE
    
DECREMENT_POINTER
    ADD R3, R3, #-1
    BR PROCESS_CODE
    
INCREMENT_CELL
    LDR R1, R3, #0
    ADD R1, R1, #1
    STR R1, R3, #0
    BR PROCESS_CODE
    
DECREMENT_CELL
    LDR R1, R3, #0
    ADD R1, R1, #-1
    STR R1, R3, #0
    BR PROCESS_CODE
    
OUTPUT_CELL
    LDR R0, R3, #0
    OUT
    BR PROCESS_CODE
    
INPUT_CELL
    TRAP x20
    STR R0, R3, #0
    BR PROCESS_CODE
    
HANDLE_CLOSE_BRACKET
    LEA R5, STACK_PTR      ; Load the address of the stack pointer
    LDR R2, R5, #0         ; Load the current top of the stack into R2
    ADD R2, R2, #-1         ; Decrement the stack pointer
    STR R2, R5, #0         ; Update the stack pointer
    LDR R1, R3, #0
    BRnp POP_AND_JUMP
    BR PROCESS_CODE
    
POP_AND_JUMP
    LDR R4, R2, #0         ; load the popped address of '[' onto the stack
    BR PROCESS_CODE
    
HANDLE_OPEN_BRACKET
    LDR R1, R3, #0
    BRz PUSH_AND_JUMP
    
    ; Push logic
    LEA R5, STACK_PTR      ; Load the address of the stack pointer
    LDR R2, R5, #0         ; Load the current top of the stack into R2
    ADD R4, R4, #-1
    STR R4, R2, #0         ; Store the position of '[' onto the stack
    ADD R2, R2, #1         ; Increment the stack pointer
    STR R2, R5, #0         ; Update the stack pointer
    ADD R4, R4, #1
    BR PROCESS_CODE
    
PUSH_AND_JUMP
    AND R7, R7, #0       ; Clear R2
    ADD R7, R7, #1 
    ADD R4, R4, #-1
    
FIND_MATCHING_BRACKET
    ADD R4, R4, #1  ; Move to the next character
    LDR R0, R4, #0  ; PROGRAM_CODE[i]
    
    ; Check if R0 is '[' or ']'
    LD R5, NEG91
    ADD R2, R0, R5     ; Compare with '['
    BRz INCREMENT_NEST   ; If '[' increment nest level
    LD R5, NEG93
    ADD R2, R0, R5     ; Compare with ']'
    BRz DECREMENT_NEST   ; If ']' decrement nest level
    
    BR FIND_MATCHING_BRACKET
    
INCREMENT_NEST
    ADD R7, R7, #1       ; Increment nest counter
    BR FIND_MATCHING_BRACKET

DECREMENT_NEST
    ADD R7, R7, #-1      ; Decrement nest counter
    BRz FOUND_BRACKET    ; If nest counter is zero, matching ']' found
    BR FIND_MATCHING_BRACKET
    
FOUND_BRACKET
    ADD R4, R4, #1 
    BR PROCESS_CODE

EXIT
    LEA R0, PROGRAM_HALTED
    PUTS
    HALT

; Data segment
PROMPT  .STRINGZ "Please enter the brainfry program code and press enter to submit: "
PROGRAM_LOADED_STR .STRINGZ	"\nLoaded program in memory\n"
NEW_LINE .STRINGZ "\n"
NEG126 .FILL #-126 
NEG62 .FILL #-62
NEG60 .FILL #-60
NEG43 .FILL #-43
NEG45 .FILL #-45
NEG46 .FILL #-46
NEG44 .FILL #-44
NEG91 .FILL #-91
NEG93 .FILL #-93
STACK_PTR .FILL STACK
PROGRAM_HALTED .STRINGZ "\n===\nHALT detected"
PROGRAM_CODE_PTR .FILL PROGRAM_CODE
TAPE  .BLKW #2500   ; 5k tape
PROGRAM_CODE  .BLKW 1000
STACK    .BLKW 15

.end
    