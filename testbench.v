module sha256_tb();

    reg clk;
    reg rst;
    reg [511:0] data_in;
    wire [255:0] hash_out;

    //instantiate the sha256 core
    sha256_core uut(
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .hash_out(hash_out)
    );

    //clock generation
    initial begin
      clk = 0;
      forever #5 clk = ~clk;
    end

    //test vector from fips pub 180-4
    initial begin
      rst = 1;
      data_in = 512'h61626380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000018;
      #20; // wait for reset
      rst = 0;
      #110; //processing
      $display("Hash Output: %h", hash_out);
      #300;
      $finish;
    end

    initial begin
      $dumpfile("dump.vcd");
      $dumpvars(0);
    end

endmodule