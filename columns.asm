################# CSC258 Assembly Final Project ###################
# This file contains our implementation of Columns.
#
# Student 1: Farrell Arifandi Purba Sidadolog, Student Number
# Student 2: I Nyoman Narayan Kitas Utama, Student Number (if applicable)
#
# We assert that the code submitted here is entirely our own 
# creation, and will indicate otherwise when it is not.
#
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       8
# - Unit height in pixels:      8
# - Display width in pixels:    256
# - Display height in pixels:   120
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################

.data
##############################################################################
# Immutable Data
##############################################################################
ADDR_DSPL:
    .word 0x10008000
ADDR_KBRD:
    .word 0xffff0000
DROP_TICK:
    .word 0x400000
gem_palette:    
    .word 0xA31621, 0xED7D3A, 0xDCED31, 0x0CCE6B, 0x4E8098, 0x503047
gem_pal_len:    
    .word 6

##############################################################################
# Code
##############################################################################
.text
.globl main

main:
    # Initialize the game
    li $t0, 0 # top tile position
    
    li $v0, 42
    li $a0, 0
    li $a1, 6
    syscall
    move $t5, $a0
    sll $t5, $t5, 2
    la $t4, gem_palette
    add $t4, $t4, $t5
    lw $t1, 0($t4) # color of top tile
    
    li $v0, 42
    li $a0, 0
    li $a1, 6
    syscall
    move $t5, $a0
    sll $t5, $t5, 2
    la $t4, gem_palette
    add $t4, $t4, $t5
    lw $t2, 0($t4) # color of middle tile
    
    li $v0, 42
    li $a0, 0
    li $a1, 6
    syscall
    move $t5, $a0
    sll $t5, $t5, 2
    la $t4, gem_palette
    add $t4, $t4, $t5
    lw $t3, 0($t4) # color of bottom tile
    
    li $a0, 0
    jal move_block
    li $t9, 0 # timer
    
game_loop:
    # 1a. Check if key has been pressed
    lw $t4, ADDR_KBRD
    lw $t5, 0($t4)
    bne $t5, 1, END_IF0
    
    # 1b. Check which key has been pressed
    lw $t5, 4($t4)
    beq $t5, 0x71, exit
    beq $t5, 0x77, pressed_key_W
    beq $t5, 0x61, pressed_key_A
    beq $t5, 0x73, pressed_key_S
    beq $t5, 0x64, pressed_key_D
    j END_IF0
    # 2a. Check for collisions
    
    # 2b. Update locations (capsules)
    # 3. Draw the screen
    pressed_key_W:
        # scroll colors
        addi $sp, $sp, -4
        sw $t3, 0($sp)
        move $t3, $t2
        move $t2, $t1
        lw $t1, 0($sp)
        addi $sp, $sp, 4
        
        li $a0, 0
        jal move_block
        j END_IF0
        
    pressed_key_A:
        # move left
        andi $t5, $t0, 124
        beq $t5, 0, END_IF0
        
        li $a0, -4
        jal move_block
        
        j END_IF0
        
    pressed_key_S:
        # move down
        bge $t0, 1536, END_IF0
        
        li $a0, 128
        jal move_block
        
        j END_IF0
        
    pressed_key_D:
        # move right
        andi $t5, $t0, 124
        bge $t5, 124, END_IF0
        
        li $a0, 4
        jal move_block
        
        j END_IF0
        
    END_IF0:
	# 4. Sleep
	lw $t8, DROP_TICK
	addi $t9, $t9, 1
	bne $t9, $t8, game_loop
	li $t9, 0
	bge $t0, 1536, game_loop
    li $a0, 128
    jal move_block

    # 5. Go back to Step 1
    j game_loop
    
move_block:
    lw $t4, ADDR_DSPL
    add $t4, $t4, $t0
    sw $zero, 0($t4)
    addi $t4, $t4, 128
    sw $zero, 0($t4)
    addi $t4, $t4, 128
    sw $zero, 0($t4)
    add $t0, $t0, $a0
        
    lw $t4, ADDR_DSPL
    add $t4, $t4, $t0
    sw $t1, 0($t4)
    addi $t4, $t4, 128
    sw $t2, 0($t4)
    addi $t4, $t4, 128
    sw $t3, 0($t4)
    
    jr $ra
    
exit:
    li $v0, 10
    syscall