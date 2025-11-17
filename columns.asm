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
# - Display height in pixels:   256
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################

    .data
##############################################################################
# Immutable Data
##############################################################################
# The address of the bitmap display. Don't forget to connect it!
ADDR_DSPL:
    .word 0x10008000
# The address of the keyboard. Don't forget to connect it!
ADDR_KBRD:
    .word 0xffff0000

gem_palette:    
    .word 0xA31621, 0xED7D3A, 0xDCED31, 0x0CCE6B, 0x4E8098, 0x503047  # red, orange, yellow, green, blue, purple gems

gem_pal_len:    
    .word 6

    .include "sprites.asm"

##############################################################################
# Mutable Data
##############################################################################

##############################################################################
# Code
##############################################################################
	.text
	.globl main

    # Run the game.
main:
    # Initialize the game   

    lw   $t0, ADDR_DSPL
    jal draw_background    
    j exit

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

game_loop:
    # 1a. Check if key has been pressed
    # 1b. Check which key has been pressed
    # 2a. Check for collisions
	# 2b. Update locations (capsules)
	# 3. Draw the screen
	# 4. Sleep

    # 5. Go back to Step 1
    # j game_loop

exit:
    li $v0, 10              # terminate the program gracefully
    syscall
