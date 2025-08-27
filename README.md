Análise de Código: Verificador de Sequência "Trilegal"

Este documento detalha a lógica e o funcionamento do programa em Assembly MIPS contido no arquivo `teste.asm`.

## 1. Objetivo do Programa

O programa lê um vetor de números inteiros e determina se ele segue um conjunto de regras recursivas que o classificam como uma sequência "trilegal". Para cada vetor lido, o programa imprime "trilegal" ou "normal" e continua a ler novos vetores até que o usuário insira o tamanho 0.

## 2. Estrutura do Código

O código é dividido em duas partes principais:

1.  **`main`**: A função principal que gerencia o fluxo do programa, incluindo a leitura de dados, alocação de memória, chamada da função de verificação e impressão do resultado final.
2.  **`SubSeq`**: Uma função recursiva que contém a lógica central para verificar se um determinado vetor (ou sub-vetor) é "trilegal".

## 3. Lógica da Função `main`

A função `main` opera em um loop (`main_loop`), permitindo que múltiplos casos de teste sejam processados em uma única execução.

1.  **Leitura do Tamanho**: Pede ao usuário um número inteiro que será o tamanho (`tam`) do vetor. Se o usuário digitar `0`, o programa termina.
2.  **Alocação de Memória**: Aloca espaço na memória heap para armazenar o vetor de inteiros usando a `syscall 9` (equivalente a `malloc`). O tamanho em bytes é `tam * 4`.
3.  **Leitura dos Elementos**: Entra em um loop (`read_loop`) para ler cada um dos `tam` elementos do vetor e armazená-los na memória recém-alocada.
4.  **Chamada da Verificação**:
    *   Primeiro, trata casos simples: se o tamanho do vetor não for divisível por 3 (e não for 1), ele já é considerado "normal". Se o tamanho for 1, é "trilegal".
    *   Se o tamanho for divisível por 3, ele chama a função `SubSeq`, passando o vetor e seus limites (de 0 a `tam - 1`) como argumentos.
5.  **Impressão do Resultado**: Após o retorno de `SubSeq`, a `main` verifica o valor da flag global `he_trilegal` (que foi modificada por `SubSeq`) e imprime "trilegal" ou "normal" de acordo.
6.  **Loop**: O programa então volta ao início do `main_loop` para processar o próximo caso.

## 4. Lógica da Função Recursiva `SubSeq`

Esta é a parte mais complexa do programa. Uma sequência é "trilegal" se ela e todos os seus sub-terços recursivamente satisfazem um conjunto de propriedades.

#### Casos Base da Recursão:

*   Se a flag `he_trilegal` já foi definida como `false` (0) em uma chamada anterior, a função retorna imediatamente.
*   Se o sub-vetor que está sendo analisado tem tamanho 1, ele é considerado "trilegal" por definição e a função retorna.

#### Lógica Principal:

1.  **Divisibilidade**: A primeira verificação é se o tamanho do sub-vetor atual é divisível por 3. Se não for, a sequência não é "trilegal", a flag é setada para `false`, e a função retorna.
2.  **Divisão em Terços**: Se o tamanho é divisível por 3, o sub-vetor é conceitualmente dividido em três partes iguais. Os índices de início de cada terço são chamados de `s1`, `s2` e `s3`.
3.  **Verificação das Propriedades**: Duas propriedades são verificadas neste nível:
    *   **Propriedade 1 (Soma de Elementos)**: Para cada índice `i` (de 0 até o tamanho do terço - 1), o programa verifica se `vetor[s1 + i] + vetor[s2 + i] == vetor[s3 + i]`. Se esta igualdade falhar para qualquer `i`, a sequência não é "trilegal".
    *   **Propriedade 2 (Soma dos Terços)**: Se o tamanho de cada terço for 3 ou mais, o programa verifica se a soma de todos os elementos do primeiro terço é igual à soma de todos os elementos do segundo terço (`soma(vetor[s1...s2-1]) == soma(vetor[s2...s3-1])`). Se as somas forem diferentes, a sequência não é "trilegal".
4.  **Chamadas Recursivas**: Se ambas as propriedades forem verdadeiras para o nível atual, a função `SubSeq` é chamada recursivamente para cada um dos três terços, para garantir que eles também são "trilegais".
    *   `SubSeq(vetor, s1, s2 - 1)`
    *   `SubSeq(vetor, s2, s3 - 1)`
    *   `SubSeq(vetor, s3, fim)`

Se a execução passar por todas as verificações e todas as chamadas recursivas sem que a flag `he_trilegal` seja setada para `false`, a sequência original é considerada "trilegal".

## 5. Gerenciamento de Pilha e Recursão

Como `SubSeq` é uma função recursiva, ela precisa gerenciar a **pilha de execução** corretamente.

*   **Prólogo**: No início da função, um espaço na pilha é alocado. Valores importantes que não podem ser perdidos entre as chamadas recursivas (como o endereço de retorno `$ra` e os argumentos da função) são salvos na pilha.
*   **Epílogo**: Antes de a função retornar (com `jr $ra`), os valores salvos são restaurados da pilha para seus registradores originais, e o espaço alocado na pilha é liberado.

Isso garante que, quando uma chamada recursiva termina, a função "pai" que a chamou possa continuar sua execução com os dados corretos. A falha em gerenciar a pilha corretamente é um erro comum em Assembly e foi um dos problemas no código original.
