.data
board:      .space 9
prompt_x:   .asciiz "Jogador X, escolha uma posição (0-8): "
prompt_o:   .asciiz "Jogador O, escolha uma posição (0-8): "
win_x:      .asciiz "Jogador X venceu!\n"
win_o:      .asciiz "Jogador O venceu!\n"
draw:       .asciiz "Empate!\n"
invalid:    .asciiz "Posição inválida! Tente novamente.\n"
newline:    .asciiz "\n"
titulo:     .asciiz "=== JOGO DA VELHA ===\n\n"
instrucoes: .asciiz "Instruções:\n- Use números de 0-8 para jogar\n- Posições:\n\n0 | 1 | 2\n---------\n3 | 4 | 5\n---------\n6 | 7 | 8\n\n"
x_char:     .asciiz "X "
o_char:     .asciiz "O "
dot_char:   .asciiz ". "
linha:      .asciiz "------\n"

.text
.globl main

main:
    # Imprimir título
    li      $v0, 4
    la      $a0, titulo
    syscall
    
    li      $v0, 4
    la      $a0, instrucoes
    syscall

    li      $s0, 0       
    li      $s1, 'X'   
    
    # Inicializar tabuleiro
    la      $t0, board
    li      $t1, 9
init_board:
    beqz    $t1, game_loop
    li      $t2, '.'
    sb      $t2, 0($t0)
    addi    $t0, $t0, 1
    subi    $t1, $t1, 1
    j       init_board

game_loop:
    jal     print_board
    beq     $s1, 'X', prompt_player_x
    beq     $s1, 'O', prompt_player_o

prompt_player_x:
    li      $v0, 4
    la      $a0, prompt_x
    syscall
    j       get_move

prompt_player_o:
    li      $v0, 4
    la      $a0, prompt_o
    syscall

get_move:
    li      $v0, 5
    syscall
    move    $a0, $v0
    jal     make_move
    beqz    $v0, invalid_move
    jal     check_win
    beq     $v0, 1, player_x_wins
    beq     $v0, 2, player_o_wins
    jal     check_draw
    bnez    $v0, game_draw
    
    beq     $s1, 'X', switch_to_o
    beq     $s1, 'O', switch_to_x
    j       game_loop

invalid_move:
    li      $v0, 4
    la      $a0, invalid
    syscall
    j       game_loop

switch_to_o:
    li      $s1, 'O'
    j       game_loop

switch_to_x:
    li      $s1, 'X'
    j       game_loop

make_move:
    bltz    $a0, make_move_error
    li      $t0, 9
    bge     $a0, $t0, make_move_error
    la      $t2, board
    add     $t2, $t2, $a0
    lb      $t4, 0($t2)
    li      $t5, '.'
    bne     $t4, $t5, make_move_error
    sb      $s1, 0($t2)
    addi    $s0, $s0, 1
    li      $v0, 1
    jr      $ra

make_move_error:
    li      $v0, 0
    jr      $ra

print_board:
    la      $t3, board
    li      $t0, 0
print_rows:
    li      $t1, 3
print_cols:
    lb      $t4, 0($t3)

    beq     $t4, 'X', print_x
    beq     $t4, 'O', print_o

    li      $v0, 4
    la      $a0, dot_char
    syscall
    j       print_continue

print_x:
    li      $v0, 4
    la      $a0, x_char
    syscall
    j       print_continue
    
print_o:
    li      $v0, 4
    la      $a0, o_char
    syscall

print_continue:    
    addi    $t3, $t3, 1
    subi    $t1, $t1, 1
    bnez    $t1, print_cols
    
    li      $v0, 4
    la      $a0, newline
    syscall
    
    addi    $t0, $t0, 3
    blt     $t0, 9, print_rows_line
    jr      $ra

print_rows_line:
    li      $v0, 4
    la      $a0, linha
    syscall
    j       print_rows

check_win:
    # Verificar linhas
    la      $t0, board
    li      $t2, 0
check_rows:
    mul     $t6, $t2, 3
    add     $t7, $t0, $t6
    lb      $t3, 0($t7)
    lb      $t4, 1($t7)
    lb      $t5, 2($t7)
    li      $t8, '.'
    beq     $t3, $t8, next_row
    beq     $t3, $t4, check_row_third
    j       next_row
check_row_third:
    beq     $t3, $t5, win_detected
next_row:
    addi    $t2, $t2, 1
    blt     $t2, 3, check_rows

    # Verificar colunas
    la      $t0, board
    li      $t2, 0
check_cols:
    move    $t7, $t2
    lb      $t3, 0($t0)
    lb      $t4, 3($t0)
    lb      $t5, 6($t0)
    li      $t8, '.'
    beq     $t3, $t8, next_col
    beq     $t3, $t4, check_col_third
    j       next_col
check_col_third:
    beq     $t3, $t5, win_detected
next_col:
    addi    $t0, $t0, 1
    addi    $t2, $t2, 1
    blt     $t2, 3, check_cols

    # Verificar diagonais
    la      $t0, board
    lb      $t3, 0($t0)
    lb      $t4, 4($t0)
    lb      $t5, 8($t0)
    li      $t8, '.'
    beq     $t3, $t8, check_other_diag
    beq     $t3, $t4, check_diag_third
    j       check_other_diag
check_diag_third:
    beq     $t3, $t5, win_detected

check_other_diag:
    lb      $t3, 2($t0)
    lb      $t4, 4($t0)
    lb      $t5, 6($t0)
    li      $t8, '.'
    beq     $t3, $t8, no_win
    beq     $t3, $t4, check_other_diag_third
    j       no_win
check_other_diag_third:
    beq     $t3, $t5, win_detected

no_win:
    li      $v0, 0
    jr      $ra

win_detected:
    beq     $s1, 'X', x_wins
    li      $v0, 2
    jr      $ra
x_wins:
    li      $v0, 1
    jr      $ra

check_draw:
    beq     $s0, 9, draw_detected
    li      $v0, 0
    jr      $ra
draw_detected:
    li      $v0, 1
    jr      $ra

player_x_wins:
    jal     print_board 
    li      $v0, 4
    la      $a0, win_x
    syscall
    j       game_over

player_o_wins:
    jal     print_board 
    li      $v0, 4
    la      $a0, win_o
    syscall
    j       game_over

game_draw:
    jal     print_board 
    li      $v0, 4
    la      $a0, draw
    syscall
    j       game_over

game_over:
    li      $v0, 10
    syscall
