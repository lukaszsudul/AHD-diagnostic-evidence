library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;
use work.nvp6134c_diag_pkg_v38ek.all;

entity tb_i25_dump_effective_ops is end entity;

architecture sim of tb_i25_dump_effective_ops is
begin
  process
    variable op : std_logic_vector(23 downto 0);
    variable current_bank : std_logic_vector(7 downto 0) := x"00";
    variable target_writes : natural := 0;
    variable delays : natural := 0;
    variable nops : natural := 0;
    variable bank_changes : natural := 0;
  begin
    for slot in 0 to C_V38EK_LAST_INIT_SLOT loop
      op := c_v38ek_effective_init_op_for_slot(
        slot, "10", x"A", "00", '0', "10", 1);
      report "I25_OP," & integer'image(slot) & "," & to_hstring(op)
        severity note;
      if op(23 downto 16) = x"FD" then
        nops := nops + 1;
      elsif op(23 downto 16) = x"FE" then
        delays := delays + 1;
      else
        target_writes := target_writes + 1;
        if current_bank /= op(23 downto 16) then
          bank_changes := bank_changes + 1;
          current_bank := op(23 downto 16);
        end if;
        if op(15 downto 8) = C_V38EK_BANK_SELECT_REG then
          current_bank := op(7 downto 0);
        end if;
      end if;
    end loop;
    assert target_writes = 187 report "target-write count mismatch" severity failure;
    assert delays = 1 report "delay count mismatch" severity failure;
    assert nops = 26 report "NOP count mismatch" severity failure;
    assert bank_changes = 25 report "bank-change count mismatch" severity failure;
    report "I25_OP_SUMMARY,187,1,26,25" severity note;
    report "PASS_I25_EFFECTIVE_OPERATION_DUMP" severity note;
    stop;
    wait;
  end process;
end architecture;
