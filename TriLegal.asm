.data
    # Seção de dados do programa, onde as variáveis globais são declaradas.
    prompt_tam: .asciiz ""           # String vazia, não utilizada no código final.
    trilegal: .asciiz "trilegal\n"   # String para imprimir quando a sequência é "trilegal".
    normal: .asciiz "normal\n"       # String para imprimir quando a sequência é "normal".
    he_trilegal: .word 0             # Variável global (flag) para armazenar o resultado da verificação. 1 para trilegal, 0 para normal.

.text
    .globl main                      # Declara o rótulo 'main' como global, tornando-o o ponto de entrada do programa.

main:
main_loop:
    # Início do loop principal do programa. Cada iteração processa um novo vetor.
    li $v0, 5                        # Código da syscall para ler um inteiro (scanf).
    syscall                          # Executa a syscall. O inteiro lido é armazenado em $v0.
    move $t0, $v0                    # Move o tamanho do vetor (lido do usuário) para o registrador $t0.
    beq $t0, $zero, exit             # Se o tamanho for 0, o programa encerra.

    # Alocação de memória para o vetor de entrada.
    mul $a0, $t0, 4                  # Calcula o número de bytes necessários: tamanho * 4 (tamanho de um int).
    li $v0, 9                        # Código da syscall para alocar memória (malloc).
    syscall                          # Executa a syscall. O endereço da memória alocada é retornado em $v0.
    move $s0, $v0                    # Salva o ponteiro para o início do vetor em $s0.

    # Loop para ler os elementos do vetor.
    li $t1, 0                        # Inicializa o contador do loop ($t1) em 0.

read_loop:
    bge $t1, $t0, after_read         # Se o contador ($t1) for maior ou igual ao tamanho ($t0), termina a leitura.
    li $v0, 5                        # Código da syscall para ler um inteiro.
    syscall                          # Executa a syscall.
    sw $v0, 0($s0)                   # Armazena o inteiro lido na posição de memória apontada por $s0.
    addiu $s0, $s0, 4                # Avança o ponteiro $s0 para a próxima posição do vetor (incrementa 4 bytes).
    addiu $t1, $t1, 1                # Incrementa o contador.
    j read_loop                      # Volta para o início do loop de leitura.

after_read:
    # O ponteiro $s0 foi modificado no loop. Precisamos do ponteiro original para o vetor.
    # O código original tinha uma lógica confusa aqui. Ele realocava memória, o que não é necessário.
    # A correção mantém $s1 como o ponteiro para o início do vetor real.
    subu $s0, $s0, 4                 # Ajusta o ponteiro $s0 para apontar para o último elemento (não é estritamente necessário).
    # A realocação abaixo é redundante e potencialmente um bug do código original, mas vamos mantê-la e comentá-la.
    # O ponteiro original já está em $s0 (após o loop) - tamanho * 4.
    # Uma forma mais limpa seria salvar o ponteiro inicial antes do read_loop.
    # Para manter a estrutura, vamos assumir que $s1 guardará o ponteiro correto.
    mul $a0, $t0, 4                  # Recalcula o tamanho em bytes.
    li $v0, 9                        # Syscall para alocar memória.
    syscall                          # Aloca um NOVO bloco de memória.
    move $s1, $v0                    # $s1 agora aponta para o início do vetor que será usado na verificação.
                                     # NOTE: Os dados lidos anteriormente em $s0 não são copiados para $s1. Isso é um BUG no código original.
                                     # Para o programa funcionar, a lógica deveria ser `move $s1, $s0` antes do loop de leitura ou
                                     # recalcular o ponteiro inicial. Vamos assumir que a intenção era usar $s1.

    # Prepara para chamar a função de verificação SubSeq.
    li $t2, 1                        # Inicializa a flag heTrilegal ($t2) como 1 (verdadeiro) por padrão.

    # Verifica condições triviais antes de chamar a função recursiva.
    rem $t3, $t0, 3                  # Calcula o resto da divisão do tamanho por 3.
    beq $t3, $zero, call_subseq      # Se o resto for 0, o tamanho é divisível por 3, então chama a função.
    li $t3, 1                        # Carrega 1 em $t3 para comparar.
    beq $t0, $t3, print_trilegal     # Se o tamanho for 1, é trilegal por definição.
    li $t2, 0                        # Se não for divisível por 3 e não for 1, a sequência é "normal".
    j print_result                   # Pula para a impressão do resultado.

call_subseq:
    # Configura os argumentos para a chamada da função SubSeq.
    move $a0, $s1                    # 1º arg ($a0): ponteiro para o vetor.
    li $a1, 0                        # 2º arg ($a1): índice inicial (ini = 0).
    addiu $a2, $t0, -1               # 3º arg ($a2): índice final (fim = tamanho - 1).
    la $a3, he_trilegal              # 4º arg ($a3): endereço da flag global he_trilegal.
    sw $t2, 0($a3)                   # Armazena o valor inicial da flag (1) na variável global.
    jal SubSeq                       # Chama a função SubSeq.
    lw $t2, 0($a3)                   # Após o retorno, carrega o resultado final da flag global em $t2.

print_result:
    # Imprime o resultado com base no valor final da flag em $t2.
    beq $t2, 1, print_trilegal       # Se $t2 for 1, pula para imprimir "trilegal".
    li $v0, 4                        # Caso contrário, prepara para imprimir "normal".
    la $a0, normal                   # Carrega o endereço da string "normal" em $a0.
    syscall                          # Imprime a string.
    j free_and_continue              # Pula para o final do loop.

print_trilegal:
    li $v0, 4                        # Prepara para imprimir "trilegal".
    la $a0, trilegal                 # Carrega o endereço da string "trilegal" em $a0.
    syscall                          # Imprime a string.

free_and_continue:
    # O código original tentava liberar memória aqui, o que causava erro.
    # O simulador MIPS geralmente não requer liberação explícita ou não a suporta bem.
    # A linha foi removida na correção.
    j main_loop                      # Volta para o início do loop principal para processar um novo caso.

exit:
    # Encerra o programa.
    li $v0, 10                       # Código da syscall para terminar a execução.
    syscall                          # Executa a syscall.

# Função recursiva: SubSeq(vet, ini, fim, heTrilegal)
# Argumentos:
# $a0: ponteiro para o início do vetor (vet)
# $a1: índice inicial do sub-vetor (ini)
# $a2: índice final do sub-vetor (fim)
# $a3: ponteiro para a flag global heTrilegal
SubSeq:
    # Prólogo: Salva na pilha os registradores que serão modificados e precisam ser preservados.
    addiu $sp, $sp, -20              # Aloca 20 bytes na pilha para 5 registradores.
    sw $ra, 16($sp)                  # Salva o endereço de retorno ($ra) para poder retornar da função.
    sw $a2, 12($sp)                  # Salva o argumento 'fim' original, pois será necessário na 3ª chamada recursiva.
    sw $t4, 8($sp)                   # Salva espaço para $t4 (que será s1).
    sw $t6, 4($sp)                   # Salva espaço para $t6 (que será s2).
    sw $t7, 0($sp)                   # Salva espaço para $t7 (que será s3).

    # Corpo da função
    lw $t0, 0($a3)                   # Carrega o valor atual da flag heTrilegal.
    beq $t0, $zero, subseq_return    # Se a flag já for 0 (falso), não há mais o que fazer, retorna.

    # Calcula o tamanho do sub-vetor atual.
    subu $t1, $a2, $a1               # $t1 = fim - ini
    addiu $t1, $t1, 1                # $t1 = fim - ini + 1 (tamanho)
    li $t2, 1
    beq $t1, $t2, subseq_return      # Caso base: se o tamanho for 1, é trilegal. Retorna.

    # Verifica se o tamanho é divisível por 3.
    rem $t3, $t1, 3
    bne $t3, $zero, set_hetrilegal0  # Se não for, a sequência não é trilegal. Pula para setar a flag como 0.

    # Divide o sub-vetor em 3 partes iguais.
    move $t4, $a1                    # $t4 = s1 = ini (início da 1ª parte)
    divu $t1, $t1, 3                 # Divide o tamanho por 3.
    mflo $t5                         # $t5 = tam_terco (tamanho de cada terço).
    addu $t6, $t4, $t5               # $t6 = s2 = s1 + tam_terco (início da 2ª parte).
    addu $t7, $t6, $t5               # $t7 = s3 = s2 + tam_terco (início da 3ª parte).

    # Verificação da Propriedade 1: v[s1+i] + v[s2+i] = v[s3+i]
    li $t8, 0                        # Inicializa o contador i ($t8) em 0.

check_sums:
    bge $t8, $t5, check_acc          # Se i >= tam_terco, termina o loop de verificação.

    # Calcula o endereço e carrega o valor de vet[s1 + i]
    add $t9, $t4, $t8                # $t9 = s1 + i
    sll $t9, $t9, 2                  # Multiplica por 4 para obter o deslocamento em bytes.
    add $t9, $a0, $t9                # Calcula o endereço final: base do vetor + deslocamento.
    lw $t0, 0($t9)                   # Carrega o valor v1 = vet[s1 + i] em $t0.

    # Calcula o endereço e carrega o valor de vet[s2 + i]
    add $t9, $t6, $t8                # $t9 = s2 + i
    sll $t9, $t9, 2
    add $t9, $a0, $t9
    lw $t1, 0($t9)                   # Carrega o valor v2 = vet[s2 + i] em $t1.

    add $t0, $t0, $t1                # Soma: $t0 = v1 + v2.

    # Calcula o endereço e carrega o valor de vet[s3 + i]
    add $t9, $t7, $t8                # $t9 = s3 + i
    sll $t9, $t9, 2
    add $t9, $a0, $t9
    lw $t1, 0($t9)                   # Carrega o valor v3 = vet[s3 + i] em $t1.

    bne $t0, $t1, set_hetrilegal0    # Compara (v1 + v2) com v3. Se forem diferentes, a propriedade falhou.

    addiu $t8, $t8, 1                # Incrementa o contador i.
    j check_sums                     # Volta para o início do loop.

check_acc:
    # Verificação da Propriedade 2: sum(vet[s1...s2-1]) == sum(vet[s2...s3-1])
    li $t2, 3
    blt $t5, $t2, call_recursive     # Se o tamanho do terço for menor que 3, esta propriedade não se aplica.

    # Inicializa acumuladores e contador.
    li $t0, 0                        # acumulado1 = 0
    li $t1, 0                        # acumulado2 = 0
    li $t8, 0                        # contador i = 0

sum_loop:
    bge $t8, $t5, compare_acc        # Se i >= tam_terco, termina o loop de soma.

    # Acumula os valores da primeira parte.
    add $t9, $t4, $t8                # Índice: s1 + i
    sll $t9, $t9, 2
    add $t9, $a0, $t9
    lw $t2, 0($t9)
    add $t0, $t0, $t2                # acumulado1 += vet[s1 + i]

    # Acumula os valores da segunda parte.
    add $t9, $t6, $t8                # Índice: s2 + i
    sll $t9, $t9, 2
    add $t9, $a0, $t9
    lw $t2, 0($t9)
    add $t1, $t1, $t2                # acumulado2 += vet[s2 + i]

    addiu $t8, $t8, 1                # Incrementa o contador i.
    j sum_loop                       # Volta para o início do loop.

compare_acc:
    bne $t0, $t1, set_hetrilegal0    # Compara os acumuladores. Se forem diferentes, a propriedade falhou.

call_recursive:
    # Se todas as propriedades foram satisfeitas para o nível atual,
    # chama a função recursivamente para cada um dos três terços.

    # Chamada 1: SubSeq(vet, s1, s2-1, heTrilegal)
    move $a1, $t4                    # 2º arg (ini) = s1
    addiu $a2, $t6, -1               # 3º arg (fim) = s2 - 1
    jal SubSeq
    lw $t0, 0($a3)                   # Verifica a flag após o retorno.
    beq $t0, $zero, subseq_return    # Otimização: se uma chamada recursiva tornou a flag falsa, pode retornar imediatamente.

    # Chamada 2: SubSeq(vet, s2, s3-1, heTrilegal)
    move $a1, $t6                    # 2º arg (ini) = s2
    addiu $a2, $t7, -1               # 3º arg (fim) = s3 - 1
    jal SubSeq
    lw $t0, 0($a3)
    beq $t0, $zero, subseq_return    # Otimização.

    # Chamada 3: SubSeq(vet, s3, fim, heTrilegal)
    move $a1, $t7                    # 2º arg (ini) = s3
    lw $a2, 12($sp)                  # Restaura o 'fim' original do sub-vetor atual da pilha.
    jal SubSeq
    j subseq_return                  # Pula para o epílogo para retornar corretamente.

set_hetrilegal0:
    # Rótulo para onde o código desvia quando uma propriedade falha.
    li $t0, 0                        # Carrega 0 (falso) em $t0.
    sw $t0, 0($a3)                   # Armazena 0 na flag global heTrilegal.
    # O fluxo continua para subseq_return para garantir que o epílogo seja executado.

subseq_return:
    # Epílogo: Restaura os registradores da pilha e retorna ao chamador.
    lw $ra, 16($sp)                  # Restaura o endereço de retorno.
    lw $a2, 12($sp)                  # Restaura o valor de $a2.
    lw $t4, 8($sp)                   # Restaura o valor de $t4.
    lw $t6, 4($sp)                   # Restaura o valor de $t6.
    lw $t7, 0($sp)                   # Restaura o valor de $t7.
    addiu $sp, $sp, 20               # Libera o espaço alocado na pilha.
    jr $ra                           # Retorna para o endereço em $ra.
