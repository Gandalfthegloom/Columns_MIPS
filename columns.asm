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
bg_palette:
    .word 0x00000000
.include "sprites.asm"

##############################################################################
# Code
##############################################################################
.text
.globl main

main:
    # Initialize the game

    # Background loading
    lw   $t0, ADDR_DSPL
    jal draw_background

    # Block Generation (this function loads t0 and t1-t3 as position and colors)
    li $a0, 152 # top tile position
    jal block_generate 

    li $a0, 0
    jal move_block
    li $t9, 0 # timer

    j game_loop


draw_background:
    la   $t1, background_sprite     # $t1 = address of sprite data
    li   $t2, 512            # 16 * 16 pixels

    background_loop:
        beq  $t2, $zero, draw_done

        lw   $t3, 0($t1)         # load next pixel from sprite
        sw   $t3, 0($t0)         # store to display

        addiu $t1, $t1, 4        # advance sprite pointer
        addiu $t0, $t0, 4        # advance display pointer
        addiu $t2, $t2, -1       # decrement pixel counter]

        j    background_loop

    draw_done:
        jr   $ra                 # return to caller

block_generate: # Param: $a0 = top tile position
    addi $sp, $sp, -4              # make space on stack
    sw   $ra, 0($sp)               # save caller's return address
    
    move $t0, $a0
    jal gem_generate
    move $t1, $a2
    jal gem_generate
    move $t2, $a2
    jal gem_generate
    move $t3, $a2

    lw   $ra, 0($sp)               # restore return address for main
    addi $sp, $sp, 4               # pop stack

    jr $ra
    
    # Parameters: gem_generate($a2 = tile address to be generated)
    gem_generate:
    
        li $v0, 42
        li $a0, 0
        li $a1, 6
        syscall
        
        move $t5, $a0
        sll $t5, $t5, 2
        la $t4, gem_palette
        add $t4, $t4, $t5
        lw $a2, 0($t4) # color of top tile
    
        jr $ra
  
    
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
    beq $t5, 0x64, pressed_key_D # after this like, t5 is free
    j END_IF0
    
    # 2a. Check for collisions
    col_bottom: # Check Bottom
        move $t6, $a1
        addi $t6, $t6, 384 # check bottom of the bottom part of block
        lw $t5, ADDR_DSPL
        add $t5, $t5, $t6
        lw $t7, bg_palette
        lw $t6, 0($t5)
        bne $t7, $t6, END_IF0
        jr $ra
        
    col_left: # Check Left, a1 is address of top gem i.e. t0
        move $t6, $a1
        addi $t6, $t6, 252 # check left of the bottom part of block
        lw $t5, ADDR_DSPL
        add $t5, $t5, $t6
        lw $t7, bg_palette
        lw $t6, 0($t5)
        bne $t7, $t6, END_IF0
        jr $ra
        
    col_right: # Check Right
        move $t6, $a1
        addi $t6, $t6, 260 # check right of the bottom part of block
        lw $t5, ADDR_DSPL
        add $t5, $t5, $t6
        lw $t7, bg_palette
        lw $t6, 0($t5)
        bne $t7, $t6, END_IF0
        jr $ra
    
    # 3. Draw the screen
    pressed_key_W:
        addi $sp, $sp, -4              # make space on stack
        sw   $ra, 0($sp)               # save c
        
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
        
        lw   $ra, 0($sp)               # restore return address for main
        addi $sp, $sp, 4               # pop stack
        
    pressed_key_A:
        # move left
        andi $t5, $t0, 124
        beq $t5, 0, END_IF0

        move $a1, $t0
        jal col_left
        
        li $a0, -4
        jal move_block
        
        j END_IF0
        
    pressed_key_S:
        # move down
        bge $t0, 1536, END_IF0
        
        move $a1, $t0
        jal col_bottom
        
        li $a0, 128
        jal move_block
        
        j END_IF0
        
    pressed_key_D:
        # move right
        andi $t5, $t0, 124
        bge $t5, 124, END_IF0
        
        move $a1, $t0
        jal col_right
        
        li $a0, 4
        jal move_block
        
        j END_IF0
        
    END_IF0:
	# 4. Sleep
	lw $t8, DROP_TICK
	addi $t9, $t9, 1 # add tick
	bne $t9, $t8, game_loop # while not drop tick, loop
	li $t9, 0 # reset timer
	bge $t0, 1536, landed
	
	move $t6, $t0
    addi $t6, $t6, 384 # check left of the bottom part of block
    lw $t5, ADDR_DSPL
    add $t5, $t5, $t6
    lw $t7, bg_palette
    lw $t6, 0($t5)
    bne $t7, $t6, landed
	
    li $a0, 128
    jal move_block # automatically moves down the block
    j game_loop

    landed:
        # Block Generation (this function loads t0 and t1-t3 as position and colors)
        li $a0, 152 # top tile position
        jal block_generate 
    
        li $a0, 0
        jal move_block
        li $t9, 0 # timer
    
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