`timescale 1ns/1ps

// Generated only from the byte-exact frozen SCAN0 manifest.
// CSV_SHA256=C7211D562F7B932CFF023331E34A0D3507A9904B73A85EC357FEF19B7136626C
// JSON_SHA256=69C6C3518A737C33E5DBC654D20616D5FEC4B9A828EA5CE52061001D564112B5
// SEMANTIC_MANIFEST_SHA256=2773DFA86ABEC87EF1E5BFB6F093D83BD8FCB4382B51B1792F3B7E8E302A1B2B
package g2b_nvp_camera_scan1_manifest_pkg;
  localparam int unsigned SCAN1_ENTRY_COUNT = 82;
  localparam int unsigned SCAN1_GROUP_COUNT = 10;
  localparam int unsigned SCAN1_CLEAN_TRANSACTION_COUNT = 105;
  localparam int unsigned SCAN1_RAW_SEMANTICS_PARTIAL_COUNT = 40;
  localparam logic [31:0] SCAN1_MAGIC = 32'h4E565343;
  localparam logic [31:0] SCAN1_VERSION = 32'h00010001;
  localparam logic [31:0] SCAN1_CAPABILITIES = 32'h0000000F;

  function automatic logic [7:0] scan1_entry_bank(input logic [6:0] index);
    begin
      case (index)
        7'd0: scan1_entry_bank = 8'h00;
        7'd1: scan1_entry_bank = 8'h00;
        7'd2: scan1_entry_bank = 8'h00;
        7'd3: scan1_entry_bank = 8'h00;
        7'd4: scan1_entry_bank = 8'h00;
        7'd5: scan1_entry_bank = 8'h00;
        7'd6: scan1_entry_bank = 8'h00;
        7'd7: scan1_entry_bank = 8'h00;
        7'd8: scan1_entry_bank = 8'h00;
        7'd9: scan1_entry_bank = 8'h00;
        7'd10: scan1_entry_bank = 8'h00;
        7'd11: scan1_entry_bank = 8'h00;
        7'd12: scan1_entry_bank = 8'h00;
        7'd13: scan1_entry_bank = 8'h00;
        7'd14: scan1_entry_bank = 8'h00;
        7'd15: scan1_entry_bank = 8'h00;
        7'd16: scan1_entry_bank = 8'h00;
        7'd17: scan1_entry_bank = 8'h00;
        7'd18: scan1_entry_bank = 8'h00;
        7'd19: scan1_entry_bank = 8'h00;
        7'd20: scan1_entry_bank = 8'h00;
        7'd21: scan1_entry_bank = 8'h00;
        7'd22: scan1_entry_bank = 8'h00;
        7'd23: scan1_entry_bank = 8'h00;
        7'd24: scan1_entry_bank = 8'h00;
        7'd25: scan1_entry_bank = 8'h00;
        7'd26: scan1_entry_bank = 8'h00;
        7'd27: scan1_entry_bank = 8'h01;
        7'd28: scan1_entry_bank = 8'h01;
        7'd29: scan1_entry_bank = 8'h01;
        7'd30: scan1_entry_bank = 8'h01;
        7'd31: scan1_entry_bank = 8'h01;
        7'd32: scan1_entry_bank = 8'h01;
        7'd33: scan1_entry_bank = 8'h01;
        7'd34: scan1_entry_bank = 8'h01;
        7'd35: scan1_entry_bank = 8'h01;
        7'd36: scan1_entry_bank = 8'h01;
        7'd37: scan1_entry_bank = 8'h05;
        7'd38: scan1_entry_bank = 8'h05;
        7'd39: scan1_entry_bank = 8'h05;
        7'd40: scan1_entry_bank = 8'h05;
        7'd41: scan1_entry_bank = 8'h05;
        7'd42: scan1_entry_bank = 8'h05;
        7'd43: scan1_entry_bank = 8'h05;
        7'd44: scan1_entry_bank = 8'h05;
        7'd45: scan1_entry_bank = 8'h05;
        7'd46: scan1_entry_bank = 8'h05;
        7'd47: scan1_entry_bank = 8'h05;
        7'd48: scan1_entry_bank = 8'h06;
        7'd49: scan1_entry_bank = 8'h06;
        7'd50: scan1_entry_bank = 8'h06;
        7'd51: scan1_entry_bank = 8'h06;
        7'd52: scan1_entry_bank = 8'h06;
        7'd53: scan1_entry_bank = 8'h06;
        7'd54: scan1_entry_bank = 8'h06;
        7'd55: scan1_entry_bank = 8'h06;
        7'd56: scan1_entry_bank = 8'h06;
        7'd57: scan1_entry_bank = 8'h06;
        7'd58: scan1_entry_bank = 8'h06;
        7'd59: scan1_entry_bank = 8'h07;
        7'd60: scan1_entry_bank = 8'h07;
        7'd61: scan1_entry_bank = 8'h07;
        7'd62: scan1_entry_bank = 8'h07;
        7'd63: scan1_entry_bank = 8'h07;
        7'd64: scan1_entry_bank = 8'h07;
        7'd65: scan1_entry_bank = 8'h07;
        7'd66: scan1_entry_bank = 8'h07;
        7'd67: scan1_entry_bank = 8'h07;
        7'd68: scan1_entry_bank = 8'h07;
        7'd69: scan1_entry_bank = 8'h07;
        7'd70: scan1_entry_bank = 8'h08;
        7'd71: scan1_entry_bank = 8'h08;
        7'd72: scan1_entry_bank = 8'h08;
        7'd73: scan1_entry_bank = 8'h08;
        7'd74: scan1_entry_bank = 8'h08;
        7'd75: scan1_entry_bank = 8'h08;
        7'd76: scan1_entry_bank = 8'h08;
        7'd77: scan1_entry_bank = 8'h08;
        7'd78: scan1_entry_bank = 8'h08;
        7'd79: scan1_entry_bank = 8'h08;
        7'd80: scan1_entry_bank = 8'h08;
        7'd81: scan1_entry_bank = 8'h00;
        default: scan1_entry_bank = 8'h00;
      endcase
    end
  endfunction

  function automatic logic [7:0] scan1_entry_register(input logic [6:0] index);
    begin
      case (index)
        7'd0: scan1_entry_register = 8'hA8;
        7'd1: scan1_entry_register = 8'hF4;
        7'd2: scan1_entry_register = 8'hF5;
        7'd3: scan1_entry_register = 8'h80;
        7'd4: scan1_entry_register = 8'hA8;
        7'd5: scan1_entry_register = 8'hB0;
        7'd6: scan1_entry_register = 8'hE0;
        7'd7: scan1_entry_register = 8'hE1;
        7'd8: scan1_entry_register = 8'hE2;
        7'd9: scan1_entry_register = 8'h7A;
        7'd10: scan1_entry_register = 8'h7B;
        7'd11: scan1_entry_register = 8'hE8;
        7'd12: scan1_entry_register = 8'h81;
        7'd13: scan1_entry_register = 8'h85;
        7'd14: scan1_entry_register = 8'h23;
        7'd15: scan1_entry_register = 8'hE9;
        7'd16: scan1_entry_register = 8'h82;
        7'd17: scan1_entry_register = 8'h86;
        7'd18: scan1_entry_register = 8'h27;
        7'd19: scan1_entry_register = 8'hEA;
        7'd20: scan1_entry_register = 8'h83;
        7'd21: scan1_entry_register = 8'h87;
        7'd22: scan1_entry_register = 8'h2B;
        7'd23: scan1_entry_register = 8'hEB;
        7'd24: scan1_entry_register = 8'h84;
        7'd25: scan1_entry_register = 8'h88;
        7'd26: scan1_entry_register = 8'h2F;
        7'd27: scan1_entry_register = 8'h97;
        7'd28: scan1_entry_register = 8'h98;
        7'd29: scan1_entry_register = 8'h84;
        7'd30: scan1_entry_register = 8'h8C;
        7'd31: scan1_entry_register = 8'h85;
        7'd32: scan1_entry_register = 8'h8D;
        7'd33: scan1_entry_register = 8'h86;
        7'd34: scan1_entry_register = 8'h8E;
        7'd35: scan1_entry_register = 8'h87;
        7'd36: scan1_entry_register = 8'h8F;
        7'd37: scan1_entry_register = 8'hF0;
        7'd38: scan1_entry_register = 8'hF2;
        7'd39: scan1_entry_register = 8'hF3;
        7'd40: scan1_entry_register = 8'hF4;
        7'd41: scan1_entry_register = 8'hF5;
        7'd42: scan1_entry_register = 8'hE2;
        7'd43: scan1_entry_register = 8'hE3;
        7'd44: scan1_entry_register = 8'hE8;
        7'd45: scan1_entry_register = 8'hE9;
        7'd46: scan1_entry_register = 8'hEA;
        7'd47: scan1_entry_register = 8'hEB;
        7'd48: scan1_entry_register = 8'hF0;
        7'd49: scan1_entry_register = 8'hF2;
        7'd50: scan1_entry_register = 8'hF3;
        7'd51: scan1_entry_register = 8'hF4;
        7'd52: scan1_entry_register = 8'hF5;
        7'd53: scan1_entry_register = 8'hE2;
        7'd54: scan1_entry_register = 8'hE3;
        7'd55: scan1_entry_register = 8'hE8;
        7'd56: scan1_entry_register = 8'hE9;
        7'd57: scan1_entry_register = 8'hEA;
        7'd58: scan1_entry_register = 8'hEB;
        7'd59: scan1_entry_register = 8'hF0;
        7'd60: scan1_entry_register = 8'hF2;
        7'd61: scan1_entry_register = 8'hF3;
        7'd62: scan1_entry_register = 8'hF4;
        7'd63: scan1_entry_register = 8'hF5;
        7'd64: scan1_entry_register = 8'hE2;
        7'd65: scan1_entry_register = 8'hE3;
        7'd66: scan1_entry_register = 8'hE8;
        7'd67: scan1_entry_register = 8'hE9;
        7'd68: scan1_entry_register = 8'hEA;
        7'd69: scan1_entry_register = 8'hEB;
        7'd70: scan1_entry_register = 8'hF0;
        7'd71: scan1_entry_register = 8'hF2;
        7'd72: scan1_entry_register = 8'hF3;
        7'd73: scan1_entry_register = 8'hF4;
        7'd74: scan1_entry_register = 8'hF5;
        7'd75: scan1_entry_register = 8'hE2;
        7'd76: scan1_entry_register = 8'hE3;
        7'd77: scan1_entry_register = 8'hE8;
        7'd78: scan1_entry_register = 8'hE9;
        7'd79: scan1_entry_register = 8'hEA;
        7'd80: scan1_entry_register = 8'hEB;
        7'd81: scan1_entry_register = 8'hA8;
        default: scan1_entry_register = 8'h00;
      endcase
    end
  endfunction

  function automatic logic [0:0] scan1_entry_raw_semantics_partial(input logic [6:0] index);
    begin
      case (index)
        7'd0: scan1_entry_raw_semantics_partial = 1'h0;
        7'd1: scan1_entry_raw_semantics_partial = 1'h0;
        7'd2: scan1_entry_raw_semantics_partial = 1'h0;
        7'd3: scan1_entry_raw_semantics_partial = 1'h0;
        7'd4: scan1_entry_raw_semantics_partial = 1'h0;
        7'd5: scan1_entry_raw_semantics_partial = 1'h0;
        7'd6: scan1_entry_raw_semantics_partial = 1'h0;
        7'd7: scan1_entry_raw_semantics_partial = 1'h0;
        7'd8: scan1_entry_raw_semantics_partial = 1'h0;
        7'd9: scan1_entry_raw_semantics_partial = 1'h0;
        7'd10: scan1_entry_raw_semantics_partial = 1'h0;
        7'd11: scan1_entry_raw_semantics_partial = 1'h0;
        7'd12: scan1_entry_raw_semantics_partial = 1'h0;
        7'd13: scan1_entry_raw_semantics_partial = 1'h0;
        7'd14: scan1_entry_raw_semantics_partial = 1'h0;
        7'd15: scan1_entry_raw_semantics_partial = 1'h0;
        7'd16: scan1_entry_raw_semantics_partial = 1'h0;
        7'd17: scan1_entry_raw_semantics_partial = 1'h0;
        7'd18: scan1_entry_raw_semantics_partial = 1'h0;
        7'd19: scan1_entry_raw_semantics_partial = 1'h0;
        7'd20: scan1_entry_raw_semantics_partial = 1'h0;
        7'd21: scan1_entry_raw_semantics_partial = 1'h0;
        7'd22: scan1_entry_raw_semantics_partial = 1'h0;
        7'd23: scan1_entry_raw_semantics_partial = 1'h0;
        7'd24: scan1_entry_raw_semantics_partial = 1'h0;
        7'd25: scan1_entry_raw_semantics_partial = 1'h0;
        7'd26: scan1_entry_raw_semantics_partial = 1'h0;
        7'd27: scan1_entry_raw_semantics_partial = 1'h0;
        7'd28: scan1_entry_raw_semantics_partial = 1'h0;
        7'd29: scan1_entry_raw_semantics_partial = 1'h0;
        7'd30: scan1_entry_raw_semantics_partial = 1'h0;
        7'd31: scan1_entry_raw_semantics_partial = 1'h0;
        7'd32: scan1_entry_raw_semantics_partial = 1'h0;
        7'd33: scan1_entry_raw_semantics_partial = 1'h0;
        7'd34: scan1_entry_raw_semantics_partial = 1'h0;
        7'd35: scan1_entry_raw_semantics_partial = 1'h0;
        7'd36: scan1_entry_raw_semantics_partial = 1'h0;
        7'd37: scan1_entry_raw_semantics_partial = 1'h0;
        7'd38: scan1_entry_raw_semantics_partial = 1'h1;
        7'd39: scan1_entry_raw_semantics_partial = 1'h1;
        7'd40: scan1_entry_raw_semantics_partial = 1'h1;
        7'd41: scan1_entry_raw_semantics_partial = 1'h1;
        7'd42: scan1_entry_raw_semantics_partial = 1'h1;
        7'd43: scan1_entry_raw_semantics_partial = 1'h1;
        7'd44: scan1_entry_raw_semantics_partial = 1'h1;
        7'd45: scan1_entry_raw_semantics_partial = 1'h1;
        7'd46: scan1_entry_raw_semantics_partial = 1'h1;
        7'd47: scan1_entry_raw_semantics_partial = 1'h1;
        7'd48: scan1_entry_raw_semantics_partial = 1'h0;
        7'd49: scan1_entry_raw_semantics_partial = 1'h1;
        7'd50: scan1_entry_raw_semantics_partial = 1'h1;
        7'd51: scan1_entry_raw_semantics_partial = 1'h1;
        7'd52: scan1_entry_raw_semantics_partial = 1'h1;
        7'd53: scan1_entry_raw_semantics_partial = 1'h1;
        7'd54: scan1_entry_raw_semantics_partial = 1'h1;
        7'd55: scan1_entry_raw_semantics_partial = 1'h1;
        7'd56: scan1_entry_raw_semantics_partial = 1'h1;
        7'd57: scan1_entry_raw_semantics_partial = 1'h1;
        7'd58: scan1_entry_raw_semantics_partial = 1'h1;
        7'd59: scan1_entry_raw_semantics_partial = 1'h0;
        7'd60: scan1_entry_raw_semantics_partial = 1'h1;
        7'd61: scan1_entry_raw_semantics_partial = 1'h1;
        7'd62: scan1_entry_raw_semantics_partial = 1'h1;
        7'd63: scan1_entry_raw_semantics_partial = 1'h1;
        7'd64: scan1_entry_raw_semantics_partial = 1'h1;
        7'd65: scan1_entry_raw_semantics_partial = 1'h1;
        7'd66: scan1_entry_raw_semantics_partial = 1'h1;
        7'd67: scan1_entry_raw_semantics_partial = 1'h1;
        7'd68: scan1_entry_raw_semantics_partial = 1'h1;
        7'd69: scan1_entry_raw_semantics_partial = 1'h1;
        7'd70: scan1_entry_raw_semantics_partial = 1'h0;
        7'd71: scan1_entry_raw_semantics_partial = 1'h1;
        7'd72: scan1_entry_raw_semantics_partial = 1'h1;
        7'd73: scan1_entry_raw_semantics_partial = 1'h1;
        7'd74: scan1_entry_raw_semantics_partial = 1'h1;
        7'd75: scan1_entry_raw_semantics_partial = 1'h1;
        7'd76: scan1_entry_raw_semantics_partial = 1'h1;
        7'd77: scan1_entry_raw_semantics_partial = 1'h1;
        7'd78: scan1_entry_raw_semantics_partial = 1'h1;
        7'd79: scan1_entry_raw_semantics_partial = 1'h1;
        7'd80: scan1_entry_raw_semantics_partial = 1'h1;
        7'd81: scan1_entry_raw_semantics_partial = 1'h0;
        default: scan1_entry_raw_semantics_partial = 1'h0;
      endcase
    end
  endfunction

  function automatic logic [7:0] scan1_group_bank(input logic [3:0] index);
    begin
      case (index)
        4'd0: scan1_group_bank = 8'h00;
        4'd1: scan1_group_bank = 8'h00;
        4'd2: scan1_group_bank = 8'h00;
        4'd3: scan1_group_bank = 8'h00;
        4'd4: scan1_group_bank = 8'h01;
        4'd5: scan1_group_bank = 8'h05;
        4'd6: scan1_group_bank = 8'h06;
        4'd7: scan1_group_bank = 8'h07;
        4'd8: scan1_group_bank = 8'h08;
        4'd9: scan1_group_bank = 8'h00;
        default: scan1_group_bank = 8'h00;
      endcase
    end
  endfunction

  function automatic logic [6:0] scan1_group_start(input logic [3:0] index);
    begin
      case (index)
        4'd0: scan1_group_start = 7'h00;
        4'd1: scan1_group_start = 7'h01;
        4'd2: scan1_group_start = 7'h04;
        4'd3: scan1_group_start = 7'h0B;
        4'd4: scan1_group_start = 7'h1B;
        4'd5: scan1_group_start = 7'h25;
        4'd6: scan1_group_start = 7'h30;
        4'd7: scan1_group_start = 7'h3B;
        4'd8: scan1_group_start = 7'h46;
        4'd9: scan1_group_start = 7'h51;
        default: scan1_group_start = 7'h00;
      endcase
    end
  endfunction

  function automatic logic [6:0] scan1_group_count(input logic [3:0] index);
    begin
      case (index)
        4'd0: scan1_group_count = 7'h01;
        4'd1: scan1_group_count = 7'h03;
        4'd2: scan1_group_count = 7'h07;
        4'd3: scan1_group_count = 7'h10;
        4'd4: scan1_group_count = 7'h0A;
        4'd5: scan1_group_count = 7'h0B;
        4'd6: scan1_group_count = 7'h0B;
        4'd7: scan1_group_count = 7'h0B;
        4'd8: scan1_group_count = 7'h0B;
        4'd9: scan1_group_count = 7'h01;
        default: scan1_group_count = 7'h00;
      endcase
    end
  endfunction

  function automatic logic [31:0] scan1_manifest_digest_word(input logic [2:0] index);
    begin
      case (index)
        3'd0: scan1_manifest_digest_word = 32'h2773DFA8;
        3'd1: scan1_manifest_digest_word = 32'h6ABEC87E;
        3'd2: scan1_manifest_digest_word = 32'hF1E5BFB6;
        3'd3: scan1_manifest_digest_word = 32'hF093D83B;
        3'd4: scan1_manifest_digest_word = 32'hD8FCB438;
        3'd5: scan1_manifest_digest_word = 32'h2B51B179;
        3'd6: scan1_manifest_digest_word = 32'h2F3B7E8E;
        3'd7: scan1_manifest_digest_word = 32'h302A1B2B;
        default: scan1_manifest_digest_word = 32'h00000000;
      endcase
    end
  endfunction

endpackage
