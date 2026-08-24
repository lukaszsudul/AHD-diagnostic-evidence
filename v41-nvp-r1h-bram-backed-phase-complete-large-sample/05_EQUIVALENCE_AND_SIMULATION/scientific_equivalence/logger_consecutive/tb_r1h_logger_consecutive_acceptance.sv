`timescale 1ns/1ps
module tb_r1h_logger_consecutive_acceptance;
  logic clk=0,reset=1,r1f_failed_txn_valid=0,record_read_enable=0;
  logic [191:0] r1f_failed_txn_record=0;
  logic [5:0] record_read_index=0;logic [2:0] record_read_word=0;
  logic record_read_valid;logic [31:0] record_read_data;logic [31:0] total_count;
  logic [6:0] stored_count;logic overflow;logic [15:0] first_failed_txn_index,last_failed_txn_index;
  logic first_failed_txn_index_valid,last_failed_txn_index_valid,total_count_saturated,input_protocol_error;
  always #5 clk=~clk;
  v41_r1f_failed_txn_logger dut(.*);
  function automatic [191:0] make_record(input integer txn);
    reg [191:0] v;begin v='0;v[15:0]=txn;v[31:16]=16'hffff;v[39:32]=txn;
      v[47:44]=1;v[51:48]=1;v[55:52]=1;v[58:56]=1;v[60]=1;v[61]=1;
      v[71:64]=8'hff;v[88]=1;v[95:88]=v[95:88]|8'h01;v[103:96]=8'h5a;
      v[135:128]=8'h5a;v[144]=1;v[159:152]=8'h1e;make_record=v;end
  endfunction
  task automatic read_expect(input integer row,input integer word_no,input logic [31:0] expected);
    begin @(negedge clk);record_read_index=row;record_read_word=word_no;record_read_enable=1;
      @(posedge clk);#1;if(!record_read_valid||record_read_data!==expected)$fatal(1,"row=%0d word=%0d got=%h expected=%h",row,word_no,record_read_data,expected);
      @(negedge clk);record_read_enable=0;end
  endtask
  initial begin integer row,word_no;logic [191:0] expected;
    repeat(3)@(posedge clk);@(negedge clk);reset=0;
    // Three finalized 192-bit records on three consecutive clock edges.
    @(negedge clk);r1f_failed_txn_valid=1;r1f_failed_txn_record=make_record(100);
    @(negedge clk);r1f_failed_txn_record=make_record(101);
    @(negedge clk);r1f_failed_txn_record=make_record(102);
    @(negedge clk);r1f_failed_txn_valid=0;r1f_failed_txn_record=0;
    if(total_count!==3||stored_count!==3||overflow||input_protocol_error)$fatal(1,"consecutive acceptance metadata mismatch");
    for(row=0;row<3;row=row+1)begin expected=make_record(100+row);
      for(word_no=0;word_no<6;word_no=word_no+1)read_expect(row,word_no,expected[word_no*32+:32]);end
    $display("R1H_FAILED_RECORD_BACK_TO_BACK_FULL_RECORD_ACCEPTANCE=PASS");$finish;
  end
endmodule
