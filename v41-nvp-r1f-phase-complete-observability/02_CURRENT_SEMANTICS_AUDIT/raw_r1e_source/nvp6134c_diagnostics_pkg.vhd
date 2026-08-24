library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package nvp6134c_diag_pkg_v38ek is
  -- v38EK staged NVP6134C bring-up with channel/AUTO control, SRAM-only, no-XDMA.
  -- Stage 0: overlay-only runtime patch (AUTO, profile, VDO1 channel, clock phase), no hardware reset.
  -- Stage 1: system/common preamble + profile overlay.
  -- Stage 2: system/common + AFE/EQ/geometry + profile overlay (recommended first test).
  -- Stage 3: stage 2 + ACP/coax compatibility block from the known source firmware.

  constant C_PAGE_SUMMARY        : std_logic_vector(7 downto 0) := x"00";
  constant C_PAGE_I2C_ACK_00_1F  : std_logic_vector(7 downto 0) := x"01";
  constant C_PAGE_I2C_ACK_20_3F  : std_logic_vector(7 downto 0) := x"02";
  constant C_PAGE_I2C_ACK_40_5F  : std_logic_vector(7 downto 0) := x"03";
  constant C_PAGE_I2C_ACK_60_7F  : std_logic_vector(7 downto 0) := x"04";
  constant C_PAGE_POWER_RESET    : std_logic_vector(7 downto 0) := x"05";
  constant C_PAGE_VCLK           : std_logic_vector(7 downto 0) := x"06";
  constant C_PAGE_VDO1_BT656     : std_logic_vector(7 downto 0) := x"07";
  constant C_PAGE_VDO2_BT656     : std_logic_vector(7 downto 0) := x"08";
  constant C_PAGE_VIN1_VIRTUAL   : std_logic_vector(7 downto 0) := x"09";
  constant C_PAGE_STATUS_SUMMARY : std_logic_vector(7 downto 0) := x"0A";
  constant C_PAGE_W0             : std_logic_vector(7 downto 0) := x"0B";
  constant C_PAGE_W1             : std_logic_vector(7 downto 0) := x"0C";
  constant C_PAGE_W2             : std_logic_vector(7 downto 0) := x"0D";
  constant C_PAGE_W3             : std_logic_vector(7 downto 0) := x"0E";
  constant C_PAGE_VERSION        : std_logic_vector(7 downto 0) := x"0F";
  constant C_PAGE_EXTRA0         : std_logic_vector(7 downto 0) := x"10";
  constant C_PAGE_EXTRA1         : std_logic_vector(7 downto 0) := x"11";
  constant C_PAGE_EXTRA2         : std_logic_vector(7 downto 0) := x"12";
  constant C_PAGE_EXTRA3         : std_logic_vector(7 downto 0) := x"13";
  constant C_PAGE_STATUS_META    : std_logic_vector(7 downto 0) := x"14";
  constant C_PAGE_REG_TABLE_A    : std_logic_vector(7 downto 0) := x"15";
  constant C_PAGE_READERR_LO     : std_logic_vector(7 downto 0) := x"16";
  constant C_PAGE_READERR_HI     : std_logic_vector(7 downto 0) := x"17";
  constant C_PAGE_FOCUS_R0       : std_logic_vector(7 downto 0) := x"18";
  constant C_PAGE_FOCUS_R1       : std_logic_vector(7 downto 0) := x"19";
  constant C_PAGE_FOCUS_R2       : std_logic_vector(7 downto 0) := x"1A";
  constant C_PAGE_FOCUS_ERR      : std_logic_vector(7 downto 0) := x"1B";
  constant C_PAGE_FOCUS_STABLE   : std_logic_vector(7 downto 0) := x"1C";
  constant C_PAGE_VIDEO_SUMMARY  : std_logic_vector(7 downto 0) := x"1D";
  constant C_PAGE_DEV_SUMMARY    : std_logic_vector(7 downto 0) := x"1E";
  constant C_PAGE_STAGE_SUMMARY  : std_logic_vector(7 downto 0) := x"1F";
  constant C_PAGE_AFE_R0         : std_logic_vector(7 downto 0) := x"20";
  constant C_PAGE_AFE_R1         : std_logic_vector(7 downto 0) := x"21";
  constant C_PAGE_AFE_R2         : std_logic_vector(7 downto 0) := x"22";
  constant C_PAGE_AFE_R3         : std_logic_vector(7 downto 0) := x"23";
  constant C_PAGE_AFE_ERR        : std_logic_vector(7 downto 0) := x"24";

  constant C_V38EK_VERSION_WORD    : std_logic_vector(31 downto 0) := x"A9D903F4";
  constant C_V38EK_BANK_SELECT_REG : std_logic_vector(7 downto 0) := x"FF";
  constant C_V38EK_BANK0           : std_logic_vector(7 downto 0) := x"00";
  constant C_V38EK_BANK1           : std_logic_vector(7 downto 0) := x"01";
  constant C_V38EK_BANK5           : std_logic_vector(7 downto 0) := x"05";
  constant C_V38EK_BANK6           : std_logic_vector(7 downto 0) := x"06";
  constant C_V38EK_BANK7           : std_logic_vector(7 downto 0) := x"07";
  constant C_V38EK_BANK8           : std_logic_vector(7 downto 0) := x"08";
  constant C_V38EK_OP_NOP          : std_logic_vector(23 downto 0) := x"FD0000";
  constant C_V38EK_MAREK_SLOT_COUNT: integer := 148;
  constant C_V38EK_LAST_INIT_SLOT  : integer := 213;

  constant B_POWER_DONE        : integer := 2;
  constant B_RESET_RELEASED    : integer := 3;
  constant B_I2C_SCAN_DONE     : integer := 4;
  constant B_I2C_ANY_ACK       : integer := 5;
  constant B_VCLK1_ALIVE       : integer := 6;
  constant B_VCLK2_ALIVE       : integer := 7;
  constant B_VDO1_TOGGLE       : integer := 8;
  constant B_VDO2_TOGGLE       : integer := 9;
  constant B_VDO1_BT656_MARKER : integer := 10;
  constant B_VDO2_BT656_MARKER : integer := 11;
  constant B_SCL_HIGH_IDLE     : integer := 12;
  constant B_SDA_HIGH_IDLE     : integer := 13;
  constant B_IRQ_LEVEL         : integer := 14;
  constant B_STATUS_DONE       : integer := 15;
  constant B_STATUS_ANY_ERROR  : integer := 16;

  subtype t_v38ek_op is std_logic_vector(23 downto 0);
  subtype t_v38ek_byte is std_logic_vector(7 downto 0);

  function c_v38ek_mode_for_profile(profile : std_logic_vector(1 downto 0)) return t_v38ek_byte;
  function c_v38ek_init_op_for_slot(slot : natural; profile : std_logic_vector(1 downto 0); phase_sel : std_logic_vector(3 downto 0); channel_sel : std_logic_vector(1 downto 0); auto_enable : std_logic; stage : std_logic_vector(1 downto 0)) return t_v38ek_op;
  function c_v38ek_effective_init_op_for_slot(slot : natural; profile : std_logic_vector(1 downto 0); phase_sel : std_logic_vector(3 downto 0); channel_sel : std_logic_vector(1 downto 0); auto_enable : std_logic; stage : std_logic_vector(1 downto 0); enable_marek_init_table : natural) return t_v38ek_op;
  function c_v38ek_bank0_window_reg(window_sel : std_logic_vector(2 downto 0); idx : natural) return t_v38ek_byte;
  function c_v38ek_bank1_output_reg(idx : natural) return t_v38ek_byte;
  function c_v38ek_format_bank(idx : natural) return t_v38ek_byte;
end package;

package body nvp6134c_diag_pkg_v38ek is
  function c_v38ek_mode_for_profile(profile : std_logic_vector(1 downto 0)) return t_v38ek_byte is
  begin
    -- NVP6134C Bank0 0x81..0x84 AHD_MD_x values:
    -- 0x0A=720P30_EX, 0x0B=720P25_EX, 0x03=1080P25, 0x02=1080P30.
    case profile is
      when "00" => return x"0A";
      when "01" => return x"0B";
      when "10" => return x"03";
      when others => return x"02";
    end case;
  end function;

  function out_c2(channel_sel : std_logic_vector(1 downto 0)) return t_v38ek_byte is
  begin
    -- Bank1 0xC2[3:0] VPORT_1_SEQ1. In 1-port/1CH mode this selects
    -- which decoder channel is routed to VDO1.
    case channel_sel is
      when "00" => return x"00";
      when "01" => return x"01";
      when "10" => return x"02";
      when others => return x"03";
    end case;
  end function;

  function out_c3(phase_sel : std_logic_vector(3 downto 0)) return t_v38ek_byte is
  begin
    -- v38EK audit fixes the output topology; the nibble controls only clock phase.
    return x"00"; -- no VDO1 multiplex continuation
  end function;

  function out_c4(phase_sel : std_logic_vector(3 downto 0)) return t_v38ek_byte is
  begin
    -- v38EK audit fixes the output topology; the nibble controls only clock phase.
    return x"00"; -- VDO2 unused
  end function;

  function out_c5(phase_sel : std_logic_vector(3 downto 0)) return t_v38ek_byte is
  begin
    -- v38EK audit fixes the output topology; the nibble controls only clock phase.
    return x"00"; -- VDO2 unused
  end function;

  function out_c8(phase_sel : std_logic_vector(3 downto 0)) return t_v38ek_byte is
  begin
    -- v38EK audit fixes the output topology; the nibble controls only clock phase.
    return x"00"; -- 1-port 1-channel on VDO1
  end function;

  function out_c9(phase_sel : std_logic_vector(3 downto 0)) return t_v38ek_byte is
  begin
    -- v38EK audit fixes the output topology; the nibble controls only clock phase.
    return x"00"; -- VDO2 single/disabled
  end function;

  function out_ca(phase_sel : std_logic_vector(3 downto 0)) return t_v38ek_byte is
  begin
    -- v38EK audit fixes the output topology; the nibble controls only clock phase.
    return x"22"; -- enable VCLK1 and VDO1 only
  end function;

  function adc_clk_ch(profile : std_logic_vector(1 downto 0); ch : natural) return t_v38ek_byte is
  begin
    if profile = "00" or profile = "01" then
      case ch is
        when 0 => return x"08";
        when 1 => return x"09";
        when 2 => return x"0A";
        when others => return x"0B";
      end case;
    else
      case ch is
        when 0 => return x"00";
        when 1 => return x"01";
        when 2 => return x"02";
        when others => return x"03";
      end case;
    end if;
  end function;

  function pre_dec_clk_ch(profile : std_logic_vector(1 downto 0); ch : natural) return t_v38ek_byte is
    variable pre : std_logic_vector(3 downto 0);
  begin
    if profile = "00" or profile = "01" then
      case ch is
        when 0 => pre := x"8";
        when 1 => pre := x"9";
        when 2 => pre := x"A";
        when others => pre := x"B";
      end case;
    else
      case ch is
        when 0 => pre := x"0";
        when 1 => pre := x"1";
        when 2 => pre := x"2";
        when others => pre := x"3";
      end case;
    end if;
    return x"4" & pre;
  end function;

  function fsc_byte(profile : std_logic_vector(1 downto 0); idx : natural) return t_v38ek_byte is
  begin
    case profile is
      when "00" => -- AHD 720P30_EX / 720P30
        case idx is
          when 0 => return x"ED";
          when 1 => return x"00";
          when 2 => return x"E5";
          when others => return x"4E";
        end case;
      when "01" => -- AHD 720P25_EX / 720P25
        case idx is
          when 0 => return x"45";
          when 1 => return x"08";
          when 2 => return x"10";
          when others => return x"4F";
        end case;
      when "10" => -- AHD 1080P25
        case idx is
          when 0 => return x"AB";
          when 1 => return x"7D";
          when 2 => return x"C3";
          when others => return x"52";
        end case;
      when others => -- AHD 1080P30
        case idx is
          when 0 => return x"2C";
          when 1 => return x"F0";
          when 2 => return x"CA";
          when others => return x"52";
        end case;
    end case;
  end function;


  function stage_enabled(stage : std_logic_vector(1 downto 0); minimum : natural) return boolean is
  begin
    return to_integer(unsigned(stage)) >= minimum;
  end function;

  function c_v38ek_marek_op_for_slot(slot : natural; stage : std_logic_vector(1 downto 0)) return t_v38ek_op is
  begin
    case slot is
      when   0 => if stage_enabled(stage, 1) then return x"00800F"; else return C_V38EK_OP_NOP; end if; -- EACH_REG_SET
      when   1 => if stage_enabled(stage, 1) then return x"01CA66"; else return C_V38EK_OP_NOP; end if; -- enable both output ports; final overlay may narrow
      when   2 => if stage_enabled(stage, 1) then return x"036B00"; else return C_V38EK_OP_NOP; end if; -- common
      when   3 => if stage_enabled(stage, 1) then return x"033A01"; else return C_V38EK_OP_NOP; end if; -- clean pulse assert
      when   4 => if stage_enabled(stage, 1) then return x"FE03E8"; else return C_V38EK_OP_NOP; end if; -- 10 ms
      when   5 => if stage_enabled(stage, 1) then return x"033A00"; else return C_V38EK_OP_NOP; end if; -- clean pulse release
      when   6 => if stage_enabled(stage, 1) then return x"000010"; else return C_V38EK_OP_NOP; end if; -- common
      when   7 => if stage_enabled(stage, 1) then return x"002343"; else return C_V38EK_OP_NOP; end if;
      when   8 => if stage_enabled(stage, 1) then return x"003010"; else return C_V38EK_OP_NOP; end if;
      when   9 => if stage_enabled(stage, 1) then return x"003402"; else return C_V38EK_OP_NOP; end if;
      when  10 => if stage_enabled(stage, 1) then return x"009300"; else return C_V38EK_OP_NOP; end if;
      when  11 => if stage_enabled(stage, 1) then return x"0500C0"; else return C_V38EK_OP_NOP; end if;
      when  12 => if stage_enabled(stage, 1) then return x"050102"; else return C_V38EK_OP_NOP; end if;
      when  13 => if stage_enabled(stage, 1) then return x"050850"; else return C_V38EK_OP_NOP; end if;
      when  14 => if stage_enabled(stage, 1) then return x"051106"; else return C_V38EK_OP_NOP; end if;
      when  15 => if stage_enabled(stage, 1) then return x"052300"; else return C_V38EK_OP_NOP; end if;
      when  16 => if stage_enabled(stage, 1) then return x"052A52"; else return C_V38EK_OP_NOP; end if;
      when  17 => if stage_enabled(stage, 1) then return x"055802"; else return C_V38EK_OP_NOP; end if;
      when  18 => if stage_enabled(stage, 1) then return x"055911"; else return C_V38EK_OP_NOP; end if;
      when  19 => if stage_enabled(stage, 1) then return x"05B8B9"; else return C_V38EK_OP_NOP; end if;
      when  20 => if stage_enabled(stage, 1) then return x"05C804"; else return C_V38EK_OP_NOP; end if;
      when  21 => if stage_enabled(stage, 1) then return x"0A7402"; else return C_V38EK_OP_NOP; end if;
      when  22 => if stage_enabled(stage, 1) then return x"096498"; else return C_V38EK_OP_NOP; end if;
      when  23 => if stage_enabled(stage, 1) then return x"096A18"; else return C_V38EK_OP_NOP; end if;
      when  24 => if stage_enabled(stage, 1) then return x"096BFF"; else return C_V38EK_OP_NOP; end if;
      when  25 => if stage_enabled(stage, 1) then return x"098000"; else return C_V38EK_OP_NOP; end if;
      when  26 => if stage_enabled(stage, 1) then return x"098100"; else return C_V38EK_OP_NOP; end if;
      when  27 => if stage_enabled(stage, 2) then return x"000000"; else return C_V38EK_OP_NOP; end if; -- common video normal
      when  28 => if stage_enabled(stage, 2) then return x"0500C0"; else return C_V38EK_OP_NOP; end if;
      when  29 => if stage_enabled(stage, 2) then return x"050100"; else return C_V38EK_OP_NOP; end if;
      when  30 => if stage_enabled(stage, 2) then return x"055800"; else return C_V38EK_OP_NOP; end if;
      when  31 => if stage_enabled(stage, 2) then return x"055900"; else return C_V38EK_OP_NOP; end if;
      when  32 => if stage_enabled(stage, 2) then return x"055B03"; else return C_V38EK_OP_NOP; end if;
      when  33 => if stage_enabled(stage, 2) then return x"0008DD"; else return C_V38EK_OP_NOP; end if; -- source compatibility value; final AHD overlay overwrites
      when  34 => if stage_enabled(stage, 2) then return x"000C08"; else return C_V38EK_OP_NOP; end if;
      when  35 => if stage_enabled(stage, 2) then return x"001088"; else return C_V38EK_OP_NOP; end if;
      when  36 => if stage_enabled(stage, 2) then return x"001490"; else return C_V38EK_OP_NOP; end if;
      when  37 => if stage_enabled(stage, 2) then return x"001808"; else return C_V38EK_OP_NOP; end if;
      when  38 => if stage_enabled(stage, 2) then return x"002102"; else return C_V38EK_OP_NOP; end if;
      when  39 => if stage_enabled(stage, 2) then return x"003C84"; else return C_V38EK_OP_NOP; end if;
      when  40 => if stage_enabled(stage, 2) then return x"004400"; else return C_V38EK_OP_NOP; end if;
      when  41 => if stage_enabled(stage, 2) then return x"004800"; else return C_V38EK_OP_NOP; end if;
      when  42 => if stage_enabled(stage, 2) then return x"004C00"; else return C_V38EK_OP_NOP; end if;
      when  43 => if stage_enabled(stage, 2) then return x"005000"; else return C_V38EK_OP_NOP; end if;
      when  44 => if stage_enabled(stage, 2) then return x"01ED00"; else return C_V38EK_OP_NOP; end if; -- deterministic equivalent of source RMW & 0xFE
      when  45 => if stage_enabled(stage, 2) then return x"056900"; else return C_V38EK_OP_NOP; end if;
      when  46 => if stage_enabled(stage, 2) then return x"054704"; else return C_V38EK_OP_NOP; end if;
      when  47 => if stage_enabled(stage, 2) then return x"055084"; else return C_V38EK_OP_NOP; end if;
      when  48 => if stage_enabled(stage, 2) then return x"058400"; else return C_V38EK_OP_NOP; end if;
      when  49 => if stage_enabled(stage, 2) then return x"058600"; else return C_V38EK_OP_NOP; end if;
      when  50 => if stage_enabled(stage, 2) then return x"05D110"; else return C_V38EK_OP_NOP; end if;
      when  51 => if stage_enabled(stage, 2) then return x"055700"; else return C_V38EK_OP_NOP; end if;
      when  52 => if stage_enabled(stage, 2) then return x"059001"; else return C_V38EK_OP_NOP; end if;
      when  53 => if stage_enabled(stage, 2) then return x"050870"; else return C_V38EK_OP_NOP; end if;
      when  54 => if stage_enabled(stage, 2) then return x"051104"; else return C_V38EK_OP_NOP; end if;
      when  55 => if stage_enabled(stage, 2) then return x"051B20"; else return C_V38EK_OP_NOP; end if;
      when  56 => if stage_enabled(stage, 2) then return x"052410"; else return C_V38EK_OP_NOP; end if;
      when  57 => if stage_enabled(stage, 2) then return x"0525CA"; else return C_V38EK_OP_NOP; end if;
      when  58 => if stage_enabled(stage, 2) then return x"052630"; else return C_V38EK_OP_NOP; end if;
      when  59 => if stage_enabled(stage, 2) then return x"052930"; else return C_V38EK_OP_NOP; end if;
      when  60 => if stage_enabled(stage, 2) then return x"052A30"; else return C_V38EK_OP_NOP; end if;
      when  61 => if stage_enabled(stage, 2) then return x"052BA8"; else return C_V38EK_OP_NOP; end if;
      when  62 => if stage_enabled(stage, 2) then return x"055F70"; else return C_V38EK_OP_NOP; end if;
      when  63 => if stage_enabled(stage, 2) then return x"055600"; else return C_V38EK_OP_NOP; end if;
      when  64 => if stage_enabled(stage, 2) then return x"05900D"; else return C_V38EK_OP_NOP; end if;
      when  65 => if stage_enabled(stage, 2) then return x"059B80"; else return C_V38EK_OP_NOP; end if;
      when  66 => if stage_enabled(stage, 2) then return x"05B500"; else return C_V38EK_OP_NOP; end if;
      when  67 => if stage_enabled(stage, 2) then return x"05B7FF"; else return C_V38EK_OP_NOP; end if;
      when  68 => if stage_enabled(stage, 2) then return x"05B8B8"; else return C_V38EK_OP_NOP; end if;
      when  69 => if stage_enabled(stage, 2) then return x"05BBB8"; else return C_V38EK_OP_NOP; end if;
      when  70 => if stage_enabled(stage, 2) then return x"05D120"; else return C_V38EK_OP_NOP; end if;
      when  71 => if stage_enabled(stage, 2) then return x"052084"; else return C_V38EK_OP_NOP; end if;
      when  72 => if stage_enabled(stage, 2) then return x"052757"; else return C_V38EK_OP_NOP; end if;
      when  73 => if stage_enabled(stage, 2) then return x"057601"; else return C_V38EK_OP_NOP; end if;
      when  74 => if stage_enabled(stage, 2) then return x"056E00"; else return C_V38EK_OP_NOP; end if;
      when  75 => if stage_enabled(stage, 2) then return x"056F00"; else return C_V38EK_OP_NOP; end if;
      when  76 => if stage_enabled(stage, 2) then return x"094000"; else return C_V38EK_OP_NOP; end if;
      when  77 => if stage_enabled(stage, 2) then return x"094400"; else return C_V38EK_OP_NOP; end if; -- deterministic equivalent of source RMW & 0xFE
      when  78 => if stage_enabled(stage, 2) then return x"0950CB"; else return C_V38EK_OP_NOP; end if;
      when  79 => if stage_enabled(stage, 2) then return x"09518A"; else return C_V38EK_OP_NOP; end if;
      when  80 => if stage_enabled(stage, 2) then return x"095209"; else return C_V38EK_OP_NOP; end if;
      when  81 => if stage_enabled(stage, 2) then return x"09532A"; else return C_V38EK_OP_NOP; end if;
      when  82 => if stage_enabled(stage, 2) then return x"099700"; else return C_V38EK_OP_NOP; end if;
      when  83 => if stage_enabled(stage, 2) then return x"099800"; else return C_V38EK_OP_NOP; end if;
      when  84 => if stage_enabled(stage, 2) then return x"099900"; else return C_V38EK_OP_NOP; end if;
      when  85 => if stage_enabled(stage, 2) then return x"020203"; else return C_V38EK_OP_NOP; end if;
      when  86 => if stage_enabled(stage, 2) then return x"022801"; else return C_V38EK_OP_NOP; end if;
      when  87 => if stage_enabled(stage, 2) then return x"02293C"; else return C_V38EK_OP_NOP; end if;
      when  88 => if stage_enabled(stage, 2) then return x"022A0C"; else return C_V38EK_OP_NOP; end if;
      when  89 => if stage_enabled(stage, 2) then return x"022B06"; else return C_V38EK_OP_NOP; end if;
      when  90 => if stage_enabled(stage, 2) then return x"022C36"; else return C_V38EK_OP_NOP; end if;
      when  91 => if stage_enabled(stage, 2) then return x"110000"; else return C_V38EK_OP_NOP; end if;
      when  92 => if stage_enabled(stage, 2) then return x"018447"; else return C_V38EK_OP_NOP; end if; -- source 720h clock setup; final profile overlay overwrites
      when  93 => if stage_enabled(stage, 2) then return x"018CA7"; else return C_V38EK_OP_NOP; end if; -- source 720h clock setup; final profile overlay overwrites
      when  94 => if stage_enabled(stage, 2) then return x"004000"; else return C_V38EK_OP_NOP; end if;
      when  95 => if stage_enabled(stage, 2) then return x"008170"; else return C_V38EK_OP_NOP; end if; -- source 720h mode; final profile overlay overwrites
      when  96 => if stage_enabled(stage, 2) then return x"008500"; else return C_V38EK_OP_NOP; end if;
      when  97 => if stage_enabled(stage, 2) then return x"001814"; else return C_V38EK_OP_NOP; end if;
      when  98 => if stage_enabled(stage, 2) then return x"003010"; else return C_V38EK_OP_NOP; end if;
      when  99 => if stage_enabled(stage, 2) then return x"005830"; else return C_V38EK_OP_NOP; end if;
      when 100 => if stage_enabled(stage, 2) then return x"005C1E"; else return C_V38EK_OP_NOP; end if;
      when 101 => if stage_enabled(stage, 2) then return x"00642D"; else return C_V38EK_OP_NOP; end if;
      when 102 => if stage_enabled(stage, 2) then return x"008910"; else return C_V38EK_OP_NOP; end if;
      when 103 => if stage_enabled(stage, 2) then return x"008E30"; else return C_V38EK_OP_NOP; end if;
      when 104 => if stage_enabled(stage, 2) then return x"00A018"; else return C_V38EK_OP_NOP; end if;
      when 105 => if stage_enabled(stage, 2) then return x"00A400"; else return C_V38EK_OP_NOP; end if;
      when 106 => if stage_enabled(stage, 2) then return x"056400"; else return C_V38EK_OP_NOP; end if;
      when 107 => if stage_enabled(stage, 2) then return x"022800"; else return C_V38EK_OP_NOP; end if;
      when 108 => if stage_enabled(stage, 2) then return x"02292D"; else return C_V38EK_OP_NOP; end if;
      when 109 => if stage_enabled(stage, 2) then return x"022A0C"; else return C_V38EK_OP_NOP; end if;
      when 110 => if stage_enabled(stage, 2) then return x"022C27"; else return C_V38EK_OP_NOP; end if;
      when 111 => if stage_enabled(stage, 3) then return x"01A801"; else return C_V38EK_OP_NOP; end if;
      when 112 => if stage_enabled(stage, 3) then return x"01BC07"; else return C_V38EK_OP_NOP; end if;
      when 113 => if stage_enabled(stage, 3) then return x"052F00"; else return C_V38EK_OP_NOP; end if;
      when 114 => if stage_enabled(stage, 3) then return x"053000"; else return C_V38EK_OP_NOP; end if;
      when 115 => if stage_enabled(stage, 3) then return x"053143"; else return C_V38EK_OP_NOP; end if;
      when 116 => if stage_enabled(stage, 3) then return x"0532A2"; else return C_V38EK_OP_NOP; end if;
      when 117 => if stage_enabled(stage, 3) then return x"057C11"; else return C_V38EK_OP_NOP; end if;
      when 118 => if stage_enabled(stage, 3) then return x"057D80"; else return C_V38EK_OP_NOP; end if;
      when 119 => if stage_enabled(stage, 3) then return x"057C11"; else return C_V38EK_OP_NOP; end if;
      when 120 => if stage_enabled(stage, 3) then return x"03021B"; else return C_V38EK_OP_NOP; end if;
      when 121 => if stage_enabled(stage, 3) then return x"03070E"; else return C_V38EK_OP_NOP; end if;
      when 122 => if stage_enabled(stage, 3) then return x"030B06"; else return C_V38EK_OP_NOP; end if;
      when 123 => if stage_enabled(stage, 3) then return x"030D20"; else return C_V38EK_OP_NOP; end if;
      when 124 => if stage_enabled(stage, 3) then return x"030E06"; else return C_V38EK_OP_NOP; end if;
      when 125 => if stage_enabled(stage, 3) then return x"032F01"; else return C_V38EK_OP_NOP; end if;
      when 126 => if stage_enabled(stage, 3) then return x"030507"; else return C_V38EK_OP_NOP; end if;
      when 127 => if stage_enabled(stage, 3) then return x"036055"; else return C_V38EK_OP_NOP; end if;
      when 128 => if stage_enabled(stage, 3) then return x"030B10"; else return C_V38EK_OP_NOP; end if;
      when 129 => if stage_enabled(stage, 3) then return x"036205"; else return C_V38EK_OP_NOP; end if;
      when 130 => if stage_enabled(stage, 3) then return x"036870"; else return C_V38EK_OP_NOP; end if;
      when 131 => if stage_enabled(stage, 3) then return x"036301"; else return C_V38EK_OP_NOP; end if;
      when 132 => if stage_enabled(stage, 3) then return x"036400"; else return C_V38EK_OP_NOP; end if;
      when 133 => if stage_enabled(stage, 3) then return x"036701"; else return C_V38EK_OP_NOP; end if;
      when 134 => if stage_enabled(stage, 3) then return x"033A01"; else return C_V38EK_OP_NOP; end if;
      when 135 => if stage_enabled(stage, 3) then return x"FE03E8"; else return C_V38EK_OP_NOP; end if; -- 10 ms
      when 136 => if stage_enabled(stage, 3) then return x"033A00"; else return C_V38EK_OP_NOP; end if;
      when 137 => if stage_enabled(stage, 2) then return x"055911"; else return C_V38EK_OP_NOP; end if;
      when 138 => if stage_enabled(stage, 2) then return x"050100"; else return C_V38EK_OP_NOP; end if;
      when 139 => if stage_enabled(stage, 2) then return x"055800"; else return C_V38EK_OP_NOP; end if;
      when 140 => if stage_enabled(stage, 2) then return x"055900"; else return C_V38EK_OP_NOP; end if;
      when 141 => if stage_enabled(stage, 2) then return x"000000"; else return C_V38EK_OP_NOP; end if;
      when 142 => if stage_enabled(stage, 2) then return x"005610"; else return C_V38EK_OP_NOP; end if;
      when 143 => if stage_enabled(stage, 2) then return x"01C200"; else return C_V38EK_OP_NOP; end if;
      when 144 => if stage_enabled(stage, 2) then return x"01C300"; else return C_V38EK_OP_NOP; end if;
      when 145 => if stage_enabled(stage, 2) then return x"01C800"; else return C_V38EK_OP_NOP; end if; -- deterministic source RMW result; final overlay overwrites
      when 146 => if stage_enabled(stage, 2) then return x"01CD86"; else return C_V38EK_OP_NOP; end if; -- source clock setting; final overlay overwrites
      when 147 => if stage_enabled(stage, 2) then return x"000000"; else return C_V38EK_OP_NOP; end if;
      when others => return C_V38EK_OP_NOP;
    end case;
  end function;

  function c_v38ek_overlay_op_for_slot(slot : natural; profile : std_logic_vector(1 downto 0); phase_sel : std_logic_vector(3 downto 0); channel_sel : std_logic_vector(1 downto 0); auto_enable : std_logic) return t_v38ek_op is
    variable mode      : std_logic_vector(7 downto 0);
    variable auto_byte : std_logic_vector(7 downto 0);
  begin
    mode := c_v38ek_mode_for_profile(profile);
    if auto_enable = '1' then auto_byte := x"80"; else auto_byte := x"00"; end if;
    case slot is
      -- Bank0: document-driven video mode and channel enable. All four channels stay enabled so mux profiles are legal.
      when  0 => return x"00FF00"; -- bank 0
      when  1 => return x"00800F"; -- EACH_REG_SET: per-channel control enabled
      when  2 => return x"00B800"; -- live status, not latched/held
      when  3 => return x"000000"; -- CH1 AFE normal operation
      when  4 => return x"000100"; -- CH2 AFE normal operation
      when  5 => return x"000200"; -- CH3 AFE normal operation
      when  6 => return x"000300"; -- CH4 AFE normal operation
      when  7 => return x"0008" & auto_byte; -- VIDEO_FORMAT/AUTO CH1; forced AHD via 0x81..0x84
      when  8 => return x"0009" & auto_byte;
      when  9 => return x"000A" & auto_byte;
      when 10 => return x"000B" & auto_byte;
      when 11 => return x"0081" & mode; -- HD_MD CH1
      when 12 => return x"0082" & mode; -- HD_MD CH2
      when 13 => return x"0083" & mode; -- HD_MD CH3
      when 14 => return x"0084" & mode; -- HD_MD CH4
      when 15 => return x"008500"; -- SP_MD CH1 = 0 for AHD
      when 16 => return x"008600"; -- SP_MD CH2 = 0 for AHD
      when 17 => return x"008700"; -- SP_MD CH3 = 0 for AHD
      when 18 => return x"008800"; -- SP_MD CH4 = 0 for AHD
      when 19 => return x"007888"; -- background color pair CH1/CH2 default
      when 20 => return x"007988"; -- background color pair CH3/CH4 default
      when 21 => return x"007A11"; -- data output mode default
      when 22 => return x"007B11";

      -- Bank1: Chapter 7 clock selector family plus documented output mux.
      when 23 => return x"01FF01"; -- bank 1
      when 24 => return x"0184" & adc_clk_ch(profile, 0); -- ADC_CLK CH1
      when 25 => return x"0185" & adc_clk_ch(profile, 1); -- ADC_CLK CH2
      when 26 => return x"0186" & adc_clk_ch(profile, 2); -- ADC_CLK CH3
      when 27 => return x"0187" & adc_clk_ch(profile, 3); -- ADC_CLK CH4
      when 28 => return x"018C" & pre_dec_clk_ch(profile, 0); -- DEC/PRE CLK CH1
      when 29 => return x"018D" & pre_dec_clk_ch(profile, 1); -- DEC/PRE CLK CH2
      when 30 => return x"018E" & pre_dec_clk_ch(profile, 2); -- DEC/PRE CLK CH3
      when 31 => return x"018F" & pre_dec_clk_ch(profile, 3); -- DEC/PRE CLK CH4
      when 32 => return x"01970F"; -- CH_RST bits: keep documented 30P/25P value until verified otherwise
      when 33 => return x"019800"; -- PD_DEC1..4 = 0, decoder not powered down
      when 34 => return x"01C2" & out_c2(channel_sel);
      when 35 => return x"01C3" & out_c3(phase_sel);
      when 36 => return x"01C4" & out_c4(phase_sel);
      when 37 => return x"01C5" & out_c5(phase_sel);
      when 38 => return x"01C8" & out_c8(phase_sel);
      when 39 => return x"01C9" & out_c9(phase_sel);
      when 40 => return x"01CA" & out_ca(phase_sel);
      when 41 => return x"01CB00"; -- normal data bit order
      when 42 => return x"01CD" & (x"4" & phase_sel); -- VCLK1 selector 4, delay sweep 0..15
      when 43 => return x"01CE46"; -- VCLK selector/delay port 2

      -- Bank9: Chapter 7.2 FSC table, repeated for CH1..CH4.
      when 44 => return x"09FF09"; -- bank 9
      when 45 => return x"094000"; -- common FSC/control helper, conservative
      when 46 => return x"094400"; -- clear low bit like Marek old&FE, but without RMW
      when 47 => return x"0950" & fsc_byte(profile, 0); -- CH1 FSC byte0
      when 48 => return x"0951" & fsc_byte(profile, 1);
      when 49 => return x"0952" & fsc_byte(profile, 2);
      when 50 => return x"0953" & fsc_byte(profile, 3);
      when 51 => return x"0954" & fsc_byte(profile, 0); -- CH2
      when 52 => return x"0955" & fsc_byte(profile, 1);
      when 53 => return x"0956" & fsc_byte(profile, 2);
      when 54 => return x"0957" & fsc_byte(profile, 3);
      when 55 => return x"0958" & fsc_byte(profile, 0); -- CH3
      when 56 => return x"0959" & fsc_byte(profile, 1);
      when 57 => return x"095A" & fsc_byte(profile, 2);
      when 58 => return x"095B" & fsc_byte(profile, 3);
      when 59 => return x"095C" & fsc_byte(profile, 0); -- CH4
      when 60 => return x"095D" & fsc_byte(profile, 1);
      when 61 => return x"095E" & fsc_byte(profile, 2);
      when 62 => return x"095F" & fsc_byte(profile, 3);

      -- Return to Bank0 for status readback.
      when 63 => return x"00FF00";
      when 64 => return x"00B800";
      when 65 => return x"00FF00";
      when others => return x"00FF00";
    end case;
  end function;


  function c_v38ek_patch_op_for_slot(slot : natural; phase_sel : std_logic_vector(3 downto 0); channel_sel : std_logic_vector(1 downto 0); auto_enable : std_logic) return t_v38ek_op is
    variable auto_byte : std_logic_vector(7 downto 0);
  begin
    if auto_enable = '1' then auto_byte := x"80"; else auto_byte := x"00"; end if;
    -- True runtime patch: only AUTO bits, VDO1 source and VCLK1 phase.
    -- It deliberately avoids the full profile/front-end/FSC overlay so a channel
    -- sweep does not perturb the analog decoder configuration under test.
    case slot is
      when 0 => return x"00FF00"; -- Bank0
      when 1 => return x"0008" & auto_byte;
      when 2 => return x"0009" & auto_byte;
      when 3 => return x"000A" & auto_byte;
      when 4 => return x"000B" & auto_byte;
      when 5 => return x"01FF01"; -- Bank1
      when 6 => return x"01C2" & out_c2(channel_sel);
      when 7 => return x"01CD" & (x"4" & phase_sel);
      when 8 => return x"00FF00"; -- restore Bank0 for status phase
      when others => return C_V38EK_OP_NOP;
    end case;
  end function;

  function c_v38ek_init_op_for_slot(slot : natural; profile : std_logic_vector(1 downto 0); phase_sel : std_logic_vector(3 downto 0); channel_sel : std_logic_vector(1 downto 0); auto_enable : std_logic; stage : std_logic_vector(1 downto 0)) return t_v38ek_op is
  begin
    if stage = "00" then
      return c_v38ek_patch_op_for_slot(slot, phase_sel, channel_sel, auto_enable);
    elsif slot < C_V38EK_MAREK_SLOT_COUNT then
      return c_v38ek_marek_op_for_slot(slot, stage);
    else
      return c_v38ek_overlay_op_for_slot(slot - C_V38EK_MAREK_SLOT_COUNT, profile, phase_sel, channel_sel, auto_enable);
    end if;
  end function;

  function c_v38ek_effective_init_op_for_slot(slot : natural; profile : std_logic_vector(1 downto 0); phase_sel : std_logic_vector(3 downto 0); channel_sel : std_logic_vector(1 downto 0); auto_enable : std_logic; stage : std_logic_vector(1 downto 0); enable_marek_init_table : natural) return t_v38ek_op is
  begin
    -- D2b is the controlled D1 + Z5-ALT diagnostic.  Operation 0 is the
    -- separate entry-bank read in the sequencer; table slots 0..147 are
    -- therefore operations 1..148 and become NOPs.  Overlay slot 0 is
    -- operation 149 and remains enabled together with all later operations.
    if enable_marek_init_table = 0 and slot < C_V38EK_MAREK_SLOT_COUNT then
      return C_V38EK_OP_NOP;
    end if;
    return c_v38ek_init_op_for_slot(slot, profile, phase_sel, channel_sel, auto_enable, stage);
  end function;

  function c_v38ek_bank0_window_reg(window_sel : std_logic_vector(2 downto 0); idx : natural) return t_v38ek_byte is
  begin
    -- v38EK always reads a fixed, per-channel lock/status table. window_sel is
    -- retained only as the latched AUTO/channel metadata from VIO control[6:4].
    case idx is
      when  0 => return x"08"; -- AUTO_1 / VIDEO_FORMAT_1
      when  1 => return x"09"; -- AUTO_2 / VIDEO_FORMAT_2
      when  2 => return x"0A"; -- AUTO_3 / VIDEO_FORMAT_3
      when  3 => return x"0B"; -- AUTO_4 / VIDEO_FORMAT_4
      when  4 => return x"81"; -- HD_MD_1
      when  5 => return x"82"; -- HD_MD_2
      when  6 => return x"83"; -- HD_MD_3
      when  7 => return x"84"; -- HD_MD_4
      when  8 => return x"A8"; -- NOVID_01..04 in bits[3:0]
      when  9 => return x"E0"; -- AGC_LOCK_01..04 in bits[3:0]
      when 10 => return x"E8"; -- NOVIDEO_01
      when 11 => return x"E9"; -- NOVIDEO_02
      when 12 => return x"EA"; -- NOVIDEO_03
      when 13 => return x"EB"; -- NOVIDEO_04
      when 14 => return x"54"; -- CHID type
      when others => return x"55"; -- CHID VIN1
    end case;
  end function;

  function c_v38ek_bank1_output_reg(idx : natural) return t_v38ek_byte is
  begin
    case idx is
      when 0 => return x"C2";
      when 1 => return x"C3";
      when 2 => return x"C4";
      when 3 => return x"C5";
      when 4 => return x"C8";
      when 5 => return x"C9";
      when 6 => return x"CA";
      when others => return x"CD";
    end case;
  end function;

  function c_v38ek_format_bank(idx : natural) return t_v38ek_byte is
  begin
    -- Datasheet section 7.3: Bank5..8 0xF0 are the per-channel
    -- Video Format Classifier read registers when Auto Detection is active.
    -- Values are still retained raw because invalid codes (for example 3F/FF)
    -- must not be coerced into a documented format.
    case idx is
      when 0 => return C_V38EK_BANK5;
      when 1 => return C_V38EK_BANK6;
      when 2 => return C_V38EK_BANK7;
      when others => return C_V38EK_BANK8;
    end case;
  end function;
end package body;
