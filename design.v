module sha256_core(
    input clk, //clock signal
    input rst, //active high reset
    input [511:0] data_in, //512-bit input block
    output reg [255:0] hash_out //256-bit output block
);

    //internal state registers
    reg [31:0] A, B, C, D, E, F, G, H; //state variables
    reg [31:0] W [0:63]; //message schedule
    reg [31:0] K [0:63]; //round constants
    reg [5:0] round; //round counter
    reg [3:0] stage; //pipeline stage counter
    reg [31:0] T1, T2;

    //sha 256 round constants (Kt)
    //copying from pre prepared document
    initial begin
      K[0]  = 32'h428a2f98;
      K[1]  = 32'h71374491;
      K[2]  = 32'hb5c0fbcf; 
      K[3]  = 32'he9b5dba5;
      K[4]  = 32'h3956c25b;
      K[5]  = 32'h59f111f1;
      K[6]  = 32'h923f82a4;
      K[7]  = 32'hab1c5ed5;
      K[8]  = 32'hd807aa98;
      K[9]  = 32'h12835b01;
      K[10] = 32'h243185be;
      K[11] = 32'h550c7dc3;
      K[12] = 32'h72be5d74;
      K[13] = 32'h80deb1fe;
      K[14] = 32'h9bdc06a7;
      K[15] = 32'hc19bf174;
      K[16] = 32'he49b69c1;
      K[17] = 32'hefbe4786;
      K[18] = 32'h0fc19dc6;
      K[19] = 32'h240ca1cc;
      K[20] = 32'h2de92c6f;
      K[21] = 32'h4a7484aa;
      K[22] = 32'h5cb0a9dc;
      K[23] = 32'h76f988da;
      K[24] = 32'h983e5152;
      K[25] = 32'ha831c66d;
      K[26] = 32'hb00327c8;
      K[27] = 32'hbf597fc7;
      K[28] = 32'hc6e00bf3;
      K[29] = 32'hd5a79147;
      K[30] = 32'h06ca6351;
      K[31] = 32'h14292967;
      K[32] = 32'h27b70a85;
      K[33] = 32'h2e1b2138;
      K[34] = 32'h4d2c6dfc;
      K[35] = 32'h53380d13;
      K[36] = 32'h650a7354;
      K[37] = 32'h766a0abb;
      K[38] = 32'h81c2c92e;
      K[39] = 32'h92722c85;
      K[40] = 32'ha2bfe8a1;
      K[41] = 32'ha81a664b;
      K[42] = 32'hc24b8b70;
      K[43] = 32'hc76c51a3;
      K[44] = 32'hd192e819;
      K[45] = 32'hd6990624;
      K[46] = 32'hf40e3585;
      K[47] = 32'h106aa070;
      K[48] = 32'h19a4c116;
      K[49] = 32'h1e376c08;
      K[50] = 32'h2748774c;
      K[51] = 32'h34b0bcb5;
      K[52] = 32'h391c0cb3;
      K[53] = 32'h4ed8aa4a;
      K[54] = 32'h5b9cca4f;
      K[55] = 32'h682e6ff3;
      K[56] = 32'h748f82ee;
      K[57] = 32'h78a5636f;
      K[58] = 32'h84c87814;
      K[59] = 32'h8cc70208;
      K[60] = 32'h90befffa;
      K[61] = 32'ha4506ceb;
      K[62] = 32'hbef9a3f7;
      K[63] = 32'hc67178f2;
    end

    //sha 256 functions
    function [31:0] Ch;
        input [31:0] x, y, z;
        begin
          Ch = (x & y) ^ (~x & z);
        end
    endfunction

    function [31:0] Maj;
        input [31:0] x, y, z;
        begin
          Maj = (x & y) ^ (x & z) ^ (y & z);
        end
    endfunction

    function [31:0] Sigma0;
        input [31:0] x;
        begin
          Sigma0 = {x[1:0], x[31:2]} ^ {x[12:0], x[31:13]} ^ {x[21:0], x[31:22]};
        end
    endfunction

    function [31:0] Sigma1;
        input [31:0] x;
        begin
          Sigma1 = {x[5:0], x[31:6]} ^ {x[10:0], x[31:11]} ^ {x[24:0], x[31:25]};
        end
    endfunction

    function [31:0] sigma0;
        input [31:0] x;
        begin
          sigma0 = {x[6:0], x[31:7]} ^ {x[17:0], x[31:18]} ^ {x >> 3};
        end
    endfunction

    function [31:0] sigma1;
        input [31:0] x;
        begin
          sigma1 = {x[16:0], x[31:17]} ^ {x[18:0], x[31:19]} ^ {x >> 10};
        end
    endfunction

    //message scheduling computation
    always @(posedge clk or posedge rst) begin
      if (rst) begin
        for (integer i = 0; i <64; i = i + 1) W[i] <= 0;
      end else begin
        for (integer i = 0; i < 16; i = i + 1) W[i] <= data_in[i*32 +: 32];
        for (integer i = 16; i < 64; i = i + 1) W[i] <= sigma1(W[i-2]) + W[i-7] + sigma0(W[i-15]) + W[i-16];
      end
    end

    //sha 256 compression function
    always @(posedge clk or posedge rst) begin
      if (rst) begin
        A <= 32'h6a09e667;
        B <= 32'hbb67ae85;
        C <= 32'h3c6ef372;
        D <= 32'ha54ff53a;
        E <= 32'h510e527f;
        F <= 32'h9b05688c;
        G <= 32'h1f83d9ab;
        H <= 32'h5be0cd19;
        round <= 0;
        stage <= 0;
      end else begin
        if (stage < 10) begin
          //perform 6-7 rounds per stage
          for (integer i = 0; i < 6; i = i + 1) begin
            if (round < 64) begin
              T1 = H + Sigma1(E) + Ch(E, F, G) + K[round] + W[round];
              T2 = Sigma0(A) + Maj(A, B, C);
              H <= G;
              G <= F;
              F <= E;
              E <= D + T1;
              D <= C;
              C <= B;
              B <= A;
              A <= T1 + T2;
              round <= round + 1;
            end
          end
          stage <= stage + 1;
        end else begin
          //final hash output
          hash_out <= {A, B, C, D, E, F, G, H};
        end
      end
    end

endmodule