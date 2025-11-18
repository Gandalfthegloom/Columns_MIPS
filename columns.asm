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
TOP_LEFT:
    .word 140
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
    landed:
    # t0-t8 is free to use
        addi $sp, $sp, -4
        sw $ra, 0($sp)
        
        # Loop: mark matches → remove → gravity → check if more matches
        match_gravity_loop:
            jal mark_match      # Mark all horizontal matches
            jal remove_match    # Remove marked tiles, $v0 = 1 if any removed
            beq $v0, $zero, done_matching  # If nothing removed, we're done
            jal gravity         # Apply gravity
            j match_gravity_loop  # Check for new matches
        
        done_matching:
        lw $ra, 0($sp)
        addi $sp, $sp, 4
            
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
    
mark_match:
    # Marks tiles that are part of horizontal matches of 3+
    # No parameters, no return value
    li $t0, 4 # row (byte offset)
    mark_loop0:
        li $t1, 12 # column (byte offset)
        mark_loop1:
            sll $t2, $t0, 5      # multiply row by 32 (128/4)
            add $t2, $t2, $t1    # t2 is the actual index
            lw $t3, ADDR_DSPL
            add $t3, $t3, $t2    # t3 now contains current checked cell
            lw $t2, 0($t3)
            beq $t2, $zero, mark_END_IF1 # if empty, skip
            
            # horizontal matching
            li $t4, 1 # chain count
            move $t5, $t0 # row of second checked cell
            addi $t6, $t1, 4 # column of second checked cell
            mark_loop2:
                bge $t6, 36, mark_loop_end2
                lw $t7, ADDR_DSPL
                sll $t2, $t5, 5
                add $t2, $t2, $t6
                add $t7, $t7, $t2
                lw $t2, 0($t3) # extract original tile
                andi $t2, $t2, 0xFFFFFF
                lw $t8, 0($t7) # extract comparison tile
                andi $t8, $t8, 0xFFFFFF
                bne $t2, $t8, mark_loop_end2
                addi $t4, $t4, 1 # add to chain
                addi $t6, $t6, 4 # next column
                j mark_loop2
            mark_loop_end2:
            
            blt $t4, 3, mark_loop_end3 # need at least 3
            
            # Mark all tiles in the match
            move $t5, $t0
            move $t6, $t1
            mark_loop3:
                lw $t7, ADDR_DSPL
                sll $t2, $t5, 5
                add $t2, $t2, $t6
                add $t7, $t7, $t2
                lw $t2, 0($t3) # extract original tile
                andi $t2, $t2, 0xFFFFFF
                lw $t8, 0($t7) # extract comparison tile
                andi $t8, $t8, 0xFFFFFF
                bne $t2, $t8, mark_loop_end3
                ori $t8, $t8, 0x1000000 # add removal identifier
                sw $t8, 0($t7)
                addi $t6, $t6, 4
                blt $t6, 36, mark_loop3
            mark_loop_end3:
            
            # vertical matching
            li $t4, 1 # chain count
            addi $t5, $t0, 4 # row of second checked cell (start from next row)
            move $t6, $t1 # same column
            mark_loop2_vert:
                bge $t5, 56, mark_loop_end2_vert
                lw $t7, ADDR_DSPL
                sll $t2, $t5, 5
                add $t2, $t2, $t6
                add $t7, $t7, $t2
                lw $t2, 0($t3) # extract original tile
                andi $t2, $t2, 0xFFFFFF
                lw $t8, 0($t7) # extract comparison tile
                andi $t8, $t8, 0xFFFFFF
                bne $t2, $t8, mark_loop_end2_vert
                addi $t4, $t4, 1 # add to chain
                addi $t5, $t5, 4 # next row
                j mark_loop2_vert
            mark_loop_end2_vert:
            
            blt $t4, 3, mark_loop_end3_vert # need at least 3
            # li   $v0, 1
            # move $a0, $t4
            # syscall
            # li   $v0, 11
            # li   $a0, 10
            # syscall
            
            # Mark all tiles in the vertical match
            addi $t5, $t0, 0 # start from current row
            move $t6, $t1
            mark_loop3_vert:
                lw $t7, ADDR_DSPL
                sll $t2, $t5, 5
                add $t2, $t2, $t6
                add $t7, $t7, $t2
                lw $t2, 0($t3) # extract original tile
                andi $t2, $t2, 0xFFFFFF
                lw $t8, 0($t7) # extract comparison tile
                andi $t8, $t8, 0xFFFFFF
                bne $t2, $t8, mark_loop_end3_vert
                ori $t8, $t8, 0x1000000 # add removal identifier
                sw $t8, 0($t7)
                addi $t5, $t5, 4
                blt $t5, 56, mark_loop3_vert
            mark_loop_end3_vert:
            
            # diagonal matching (down-right)
            li $t4, 1 # chain count
            addi $t5, $t0, 4 # next row
            addi $t6, $t1, 4 # next column
            mark_loop2_diag1:
                bge $t5, 56, mark_loop_end2_diag1
                bge $t6, 36, mark_loop_end2_diag1
                lw $t7, ADDR_DSPL
                sll $t2, $t5, 5
                add $t2, $t2, $t6
                add $t7, $t7, $t2
                lw $t2, 0($t3) # extract original tile
                andi $t2, $t2, 0xFFFFFF
                lw $t8, 0($t7) # extract comparison tile
                andi $t8, $t8, 0xFFFFFF
                bne $t2, $t8, mark_loop_end2_diag1
                addi $t4, $t4, 1
                addi $t5, $t5, 4 # next row
                addi $t6, $t6, 4 # next column
                j mark_loop2_diag1
            mark_loop_end2_diag1:
            
            blt $t4, 3, mark_loop_end3_diag1
            
            # Mark all tiles in diagonal match (down-right)
            move $t5, $t0
            move $t6, $t1
            mark_loop3_diag1:
                lw $t7, ADDR_DSPL
                sll $t2, $t5, 5
                add $t2, $t2, $t6
                add $t7, $t7, $t2
                lw $t2, 0($t3)
                andi $t2, $t2, 0xFFFFFF
                lw $t8, 0($t7)
                andi $t8, $t8, 0xFFFFFF
                bne $t2, $t8, mark_loop_end3_diag1
                ori $t8, $t8, 0x1000000
                sw $t8, 0($t7)
                addi $t5, $t5, 4
                addi $t6, $t6, 4
                bge $t5, 56, mark_loop_end3_diag1
                blt $t6, 36, mark_loop3_diag1
            mark_loop_end3_diag1:
            
            # diagonal matching (down-left)
            li $t4, 1 # chain count
            addi $t5, $t0, 4 # next row
            addi $t6, $t1, -4 # previous column
            mark_loop2_diag2:
                bge $t5, 56, mark_loop_end2_diag2
                blt $t6, 12, mark_loop_end2_diag2
                lw $t7, ADDR_DSPL
                sll $t2, $t5, 5
                add $t2, $t2, $t6
                add $t7, $t7, $t2
                lw $t2, 0($t3) # extract original tile
                andi $t2, $t2, 0xFFFFFF
                lw $t8, 0($t7) # extract comparison tile
                andi $t8, $t8, 0xFFFFFF
                bne $t2, $t8, mark_loop_end2_diag2
                addi $t4, $t4, 1
                addi $t5, $t5, 4 # next row
                addi $t6, $t6, -4 # previous column
                j mark_loop2_diag2
            mark_loop_end2_diag2:
            
            blt $t4, 3, mark_loop_end3_diag2
            
            # Mark all tiles in diagonal match (down-left)
            move $t5, $t0
            move $t6, $t1
            mark_loop3_diag2:
                lw $t7, ADDR_DSPL
                sll $t2, $t5, 5
                add $t2, $t2, $t6
                add $t7, $t7, $t2
                lw $t2, 0($t3)
                andi $t2, $t2, 0xFFFFFF
                lw $t8, 0($t7)
                andi $t8, $t8, 0xFFFFFF
                bne $t2, $t8, mark_loop_end3_diag2
                ori $t8, $t8, 0x1000000
                sw $t8, 0($t7)
                addi $t5, $t5, 4
                addi $t6, $t6, -4
                bge $t5, 56, mark_loop_end3_diag2
                bge $t6, 12, mark_loop3_diag2
            mark_loop_end3_diag2:
            
            mark_END_IF1:

            addi $t1, $t1, 4
            blt $t1, 36, mark_loop1
        addi $t0, $t0, 4
        blt $t0, 56, mark_loop0
    jr $ra
    
remove_match:
    # Removes marked tiles and returns whether any were found
    # Returns: $v0 = 1 if matches removed, 0 otherwise
    li $v0, 0 # return value (false by default)
    
    li $t0, 4 # row
    remove_loop0:
        li $t1, 12 # column
        remove_loop1:
            sll $t2, $t0, 5
            add $t2, $t2, $t1
            lw $t3, ADDR_DSPL
            add $t3, $t3, $t2
            lw $t4, 0($t3)
            
            # Check if removal tag is set
            andi $t5, $t4, 0xFF000000
            beq $t5, $zero, skip_remove
            
            # Found a marked tile - set return to true
            li $v0, 1
            
            # Remove tile (set to background color)
            lw $t5, bg_palette
            sw $t5, 0($t3)
            
            skip_remove:
            addi $t1, $t1, 4
            blt $t1, 36, remove_loop1
        addi $t0, $t0, 4
        blt $t0, 56, remove_loop0
    jr $ra
    
gravity:
    # Makes tiles fall down if there's empty space below
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    gravity_repeat:
        li $t9, 0 # flag: did anything move?
        
        li $t0, 52 # start from second-to-last row, go upward
        gravity_loop0:
            li $t1, 12 # column
            gravity_loop1:
                sll $t2, $t0, 5
                add $t2, $t2, $t1
                lw $t3, ADDR_DSPL
                add $t3, $t3, $t2 # current cell
                lw $t4, 0($t3)
                
                # Skip if current cell is empty
                lw $t5, bg_palette
                beq $t4, $zero, skip_gravity
                beq $t4, $t5, skip_gravity
                
                # Check cell below (next row is +128 bytes)
                addi $t6, $t2, 128 # one row down
                lw $t7, ADDR_DSPL
                add $t7, $t7, $t6
                lw $t8, 0($t7)
                
                # Skip if cell below is not empty
                bne $t8, $zero, check_bg
                j do_fall
                check_bg:
                    lw $t5, bg_palette
                    bne $t8, $t5, skip_gravity
                
                do_fall:
                    # Move tile down
                    sw $t4, 0($t7) # write to cell below
                    lw $t5, bg_palette
                    sw $t5, 0($t3) # clear current cell
                    li $t9, 1 # set moved flag
                
                skip_gravity:
                addi $t1, $t1, 4
                blt $t1, 36, gravity_loop1
            addi $t0, $t0, -4 # go UP (from bottom to top)
            bge $t0, 4, gravity_loop0
        
        # If anything moved, repeat gravity
        bne $t9, $zero, gravity_repeat
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
    
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