`timescale 1ns / 1ps



// Módulo Registro_de_Datos
//Definicin de N=3 por defecto
module Registro_de_Datos #(parameter N = 3)(
  input wire reg_sel_i,//Señal de selección del Registro
  input wire [N-1:0] addr_in,//Dirección de entrada para acceder a un registro en la matriz.
  input wire [7:0] dato_in,//Dato de entrada para ser almacenado en el registro seleccionado
  output wire [7:0] datos_registros,//Datos almacenados en el registro seleccionado.
  input wire scl,//Señal de reloj de sistema.
  input wire ss,//Selcciona el esclavo en el módulo de control.
  input wire miso,//Señal de entrada del maestro al esclavo (Master In, Slave Out).
  output wire mosi//Señal de salida del maestro al esclavo (Master Out, Slave In).
);

//Matriz de registros con longitud 2**N, cada registro en la matriz representa un dato almacenado en el campo DATO correspondiente.
  reg [7:0] registros [0:2**N-1];
// bloque "always" sensibilizado por el flanco de subida de "scl":
//Comprueba si la dirección de entrada "addr_in" está dentro del rango válido (0 a 2^N-1).
//Si la dirección es válida, asigna el dato de entrada "dato_in" al registro correspondiente en la matriz.
  always @(posedge scl)
  begin
    if (addr_in < 2**N)
      registros[addr_in] <= dato_in;
  end
  
//se asigna el valor del registro correspondiente a la salida datos_registros 
  assign datos_registros = registros[addr_in];//Asigna la salida "datos_registros" como el valor almacenado en el registro seleccionado.
  //La siguiente línea asigna un valor a la señal mosi basándose en las condiciones de los señales ss y miso,
  //así como en el valor de la variable datos_registros.
  //(condición) ? (valor si verdadero) : (valor si falso) y asigna
  assign mosi = (ss) ? 8'b1 : (miso) ? 8'b0 : datos_registros;
endmodule

// Módulo Registro_de_Control
module Registro_de_Control #(parameter N = 3)(
  input wire clk,//Señal de reloj del sistema
  input wire reset,//Señal de reinicio
  input wire send,//Se utiliza como una señal de control para indicar que se desea enviar una transacción.
  input wire cs_ctrl,//control de la señal CS (Chip Select).
  input wire all_1s,//señal de todos unos.
  input wire all_0s,//señal de todos ceros.
  input wire [N-1:0] n_tx_end,//Número de transacciones completadas en la interfaz de transmisión
  output wire [N-1:0] n_rx_end,//Número de transacciones completadas en la interfaz de recepción.
  output reg [7:0] datos_registros,
  output reg CS,//señal de Chip Select
  input wire scl,//Señal de reloj del sistema
  input wire ss,//Selección del esclavo
  input wire miso,//se conecta como entrada al módulo Registro_de_Datos
  output wire mosi//Señal de salida del maestro al esclavo (Master Out, Slave In).
);
  // Contador de transacciones
  reg [N-1:0] transaction_count;

  // Instancia del módulo Registro_de_Datos
  Registro_de_Datos #(N) registro_datos_inst (
    .reg_sel_i(1'b1),
    .addr_in(n_tx_end),
    .dato_in(mosi),
    .datos_registros(datos_registros),
    .scl(scl),
    .ss(ss),
    .miso(miso),
    .mosi(mosi)
  );

  // Asignación de la señal CS según el valor de cs_ctrl
  always @(cs_ctrl)
    CS <= ~cs_ctrl;

  // Lógica para contar transacciones
  always @(posedge clk or posedge reset)
  begin
    if (reset)
      transaction_count <= 0;
    else if (send)
      transaction_count <= transaction_count + 1;
  end

  // Asignación de n_rx_end
  assign n_rx_end = transaction_count;
endmodule

// Módulo TOP
module TOP #(parameter N = 3);
  // Señales del TOP
  wire clk, reset, send, cs_ctrl, all_1s, all_0s;
  wire [N-1:0] n_tx_end, n_rx_end;
  wire [7:0] datos_registros;
  wire CS;
  wire scl, ss, miso, mosi;

  // Generador de reloj de 100 kHz
  reg clk_100kHz;
  always #(5) clk_100kHz = ~clk_100kHz;

  // Instancia del módulo Registro_de_Control
  Registro_de_Control #(N) registro_control_inst (
    .clk(clk_100kHz),
    .reset(reset),
    .send(send),
    .cs_ctrl(cs_ctrl),
    .all_1s(all_1s),
    .all_0s(all_0s),
    .n_tx_end(n_tx_end),
    .n_rx_end(n_rx_end),
    .datos_registros(datos_registros),
    .CS(CS),
    .scl(scl),
    .ss(ss),
    .miso(miso),
    .mosi(mosi)
);

// Instancia del módulo Registro_de_Datos
Registro_de_Datos #(N) registro_datos_inst (
.reg_sel_i(1'b1),
.addr_in(n_tx_end),
.dato_in(datos_registros),
.datos_registros(datos_registros),
.scl(scl),
.ss(ss),
.miso(miso),
.mosi(mosi)
);

// Aquí va el resto de la lógica del módulo TOP que sea necesaria
// ...
endmodule                        
