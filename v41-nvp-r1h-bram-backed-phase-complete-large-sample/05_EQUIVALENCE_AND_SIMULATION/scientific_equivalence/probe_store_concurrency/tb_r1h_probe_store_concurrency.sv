`timescale 1ns/1ps

module tb_r1h_probe_store_concurrency;
  logic clk=0, rst=1, write_valid=0, read_req=0;
  logic [1:0] write_phase=0, read_phase=0;
  logic [8:0] write_address=0, read_address=0;
  logic [15:0] write_data=0, read_data;
  logic read_valid;
  always #5 clk=~clk;
  r1h_probe_index_bram_store dut(.*);

  task automatic read_expect(input logic [1:0] p,input logic [8:0] a,input logic [15:0] d);
    begin
      @(negedge clk);read_req=1;read_phase=p;read_address=a;
      @(posedge clk);#1;if(!read_valid||read_data!==d)$fatal(1,"read mismatch p=%0d a=%0d got=%h expected=%h",p,a,read_data,d);
      @(negedge clk);read_req=0;
    end
  endtask

  initial begin
    repeat(4)@(posedge clk);rst<=0;

    // Continuous valid proves the payload accepts one same-bank write on every
    // consecutive clock edge; there is no serializer/busy gap to lose events.
    @(negedge clk);write_valid=1;write_phase=0;write_address=10;write_data=16'ha00a;
    @(negedge clk);write_address=11;write_data=16'ha00b;
    @(negedge clk);write_address=12;write_data=16'ha00c;
    @(negedge clk);write_valid=0;
    read_expect(0,10,16'ha00a);read_expect(0,11,16'ha00b);read_expect(0,12,16'ha00c);

    // Seed two entries in one bank.
    @(negedge clk);write_valid=1;write_phase=1;write_address=20;write_data=16'h1420;
    @(negedge clk);write_address=21;write_data=16'h1421;
    @(negedge clk);write_valid=0;

    // Same physical RAM, simultaneous host read and probe write, different
    // addresses. The read must return the preserved addressed entry while the
    // independent write is accepted on the same edge.
    @(negedge clk);
    read_req=1;read_phase=1;read_address=20;
    write_valid=1;write_phase=1;write_address=21;write_data=16'hbeef;
    @(posedge clk);#1;
    if(!read_valid||read_data!==16'h1420)$fatal(1,"same-bank concurrent read corrupted got=%h",read_data);
    @(negedge clk);read_req=0;write_valid=0;
    read_expect(1,20,16'h1420);read_expect(1,21,16'hbeef);

    $display("R1H_INDEX_STORE_BACK_TO_BACK_SAME_BANK_WRITES=PASS");
    $display("R1H_INDEX_STORE_SAME_BANK_DIFFERENT_ADDRESS_CONCURRENT_RW=PASS");
    $finish;
  end
endmodule
