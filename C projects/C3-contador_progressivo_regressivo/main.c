#include <main.h>

const BYTE NUMS_DISPLAY[10] = {0xFE, 0x38, 0xDD, 0x7D, 0x3B,
                               0x77, 0xF7, 0x3C, 0xFF, 0x7F}; // 0-9
const signed int8 v_filtro = 20;                              // Valor do filtro
signed int8 unidade = 0;                                      // Unidade
unsigned int8 contador_filtro = 0;    // Contador para o filtro
unsigned int8 estado_botao_up = 1;    // Estado do botão UP (1 = solto)
unsigned int8 estado_botao_zerar = 1; // Estado do botão ZERAR
unsigned int8 estado_botao_down = 1;  // Estado do botão DOWN

void atualiza_display(unsigned int8 unidade);
void b_zerar_acionado();
void b_up_acionado();
void b_down_acionado();

void main() {
  atualiza_display(unidade);

  while (TRUE) {
    if (input(B_ZERAR) == 0) {
      b_zerar_acionado();
    }

    if (input(B_UP) == 0) {
      if (estado_botao_up == 1) {
        b_up_acionado();
        estado_botao_up = 0;
      }
    } else {
      estado_botao_up = 1;
    }

    if (input(B_DOWN) == 0) {
      if (estado_botao_down == 1) {
        b_down_acionado();
        estado_botao_down = 0;
      }
    } else {
      estado_botao_down = 1;
    }
  }
}

void atualiza_display(unsigned int8 unidade) {
  output_b(NUMS_DISPLAY[unidade]);
}

void b_zerar_acionado() {
  unidade = 0;
  atualiza_display(unidade);
}

void b_up_acionado() {
  if (contador_filtro == 0) {
    unidade++;
    if (unidade > 9) {
      unidade = 0;
    }
    atualiza_display(unidade);
    contador_filtro = v_filtro;
  } else {
    contador_filtro--;
  }
}

void b_down_acionado() {
  if (contador_filtro == 0) {
    unidade--;
    if (unidade < 0) {
      unidade = 9;
    }
    atualiza_display(unidade);
    contador_filtro = v_filtro;
  } else {
    contador_filtro--;
  }
}
