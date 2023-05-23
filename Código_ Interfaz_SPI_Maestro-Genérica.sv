`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//MODULO REGITRO DE CONTROL
module control_register (
  input wire clk,
  input wire reset,
  input wire send,
  input wire [7:0] addr_in,
  input wire [7:0] data_in,
  output reg [7:0] data_out,
  output reg cs_ctrl,
  output reg [7:0] n_tx_end,
  output reg [7:0] n_rx_end
);

  reg [7:0] data_reg [0:255]; // Registro de datos de 8 bits, se asume N=8 (256 registros)

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      data_out <= 8'h00;
      cs_ctrl <= 1'b0;
      n_tx_end <= 8'h00;
      n_rx_end <= 8'h00;
    end else begin
      if (send) begin
        data_out <= data_reg[addr_in];
        cs_ctrl <= 1'b1;
        n_tx_end <= n_tx_end + 1;
        n_rx_end <= n_rx_end + 1;

        if (n_tx_end == 8'hFF) begin
          n_tx_end <= 8'h00;
        end
      end else begin
        cs_ctrl <= 1'b0;
      end
    end
  end

  always @(posedge clk) begin
    if (send) begin
      data_reg[addr_in] <= data_in;
    end
  end

endmodule
//MODULO REGISTRO DE DATOS
module  data_logging(
  input wire clk,
  input wire reset,
  input wire send,
  input wire [7:0] addr_in,
  input wire [7:0] data_in,
  output reg [7:0] data_out,
  output reg cs_ctrl,
  output reg [7:0] n_tx_end,
  output reg [7:0] n_rx_end,
  output reg [7:0] data_log
);

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      data_out <= 0;
      cs_ctrl <= 0;
      n_tx_end <= 0;
      n_rx_end <= 0;
      data_log <= 0;
    end else begin
      if (send) begin
        data_out <= data_in[addr_in];
        cs_ctrl <= 1;
        n_tx_end <= n_tx_end + 1;
      end else begin
        cs_ctrl <= 0;
      end
      if (n_tx_end == 8) begin
        n_tx_end <= 0;
        data_log <= data_out;
      end
      if (n_rx_end == 8) begin
        n_rx_end <= 0;
      end
    end
  end

endmodule
//MODULO DE CONTROL Y GENERACION DE RELOJ 
module spi_clock_generator (
  input wire clk,
  input wire reset,
  output reg clk_out,
  output reg [7:0] clk_div
);

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      clk_out <= 0;
      clk_div <= 0;
    end else begin
      if (clk_div == 8) begin
        clk_out <= 1;
        clk_div <= 0;
      end else begin
        clk_out <= 0;
        clk_div <= clk_div + 1;
      end
    end
  end

endmodule
//MODULO DE SEÑAL DE SELECCION DE ESCLAVO
module spi_slave_select (
  input wire clk,
  input wire reset,
  input wire [7:0] addr_in,
  output reg slave_select
);
always @(posedge clk or posedge reset) begin
    if (reset) begin
       slave_select <= 0;
   end else begin
      if (addr_in == 0) begin
          slave_select <= 1;
      end else begin

        slave_select <= 0;
      end
   end
end
endmodule
//MODULO DE SEÑALES DE ENTRADA Y SALIDA DE DATOS
module spi_data_io (
  input wire clk,
  input wire reset,
  input wire [7:0] data_in,
  output reg [7:0] data_out,
  input wire slave_select,
  input wire sck,
  input wire miso,
  output reg mosi
);

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      data_out <= 0;
      mosi <= 0;
    end else begin
      if (slave_select) begin
        if (sck) begin
          mosi <= data_in;
        end else begin
          data_out <= miso;
        end
      end
    end
  end

endmodule
//MODULO DE ALMACENAMIENTO EN BUFER DE DATOS
module spi_data_buffer (
  input wire clk,
  input wire reset,
  input wire [7:0] data_in,
  output reg [7:0] data_out,
  input wire slave_select,
  input wire sck,
  input wire miso,
  output reg mosi
);

  reg [7:0] data_buffer;

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      data_buffer <= 0;
    end else begin
      if (slave_select) begin
        if (sck) begin
          data_buffer <= data_in;
        end else begin
          data_out <= data_buffer;
        end
      end
    end
  end

endmodule
//MODULO DE MANEJO Y DETECCION DE ERRORES
module spi_error_detection (
  input wire clk,
  input wire reset,
  input wire [7:0] data_in,
  output reg [7:0] data_out,
  input wire slave_select,
  input wire sck,
  input wire miso,
  output reg mosi,
  output reg error
);

  reg [7:0] data_buffer;
  reg [7:0] expected_data;
  reg [7:0] received_data;
  reg error_flag;
//El alwaysbloque se utiliza para implementar la máquina de estado.
//El alwaysbloque se activa por un flanco ascendente o descendente de la señal del reloj.
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      data_buffer <= 0;
      expected_data <= 0;
      received_data <= 0;
      error_flag <= 0;
    end else begin
      if (slave_select) begin
        if (sck) begin
          data_buffer <= data_in;
        end else begin
          received_data <= miso;
          if (data_buffer != expected_data) begin
            error_flag <= 1;
          end
        end
      end
    end
  end

  assign data_out = data_buffer;
  assign mosi = (error_flag) ? 0 : data_in;
  assign error = error_flag;

endmodule

