# R1f offline host-tool fixture results

## Environment

```text
EXECUTION_CLASS=OFFLINE_ONLY
HARDWARE_MMIO_EXECUTED=NO
JTAG_EXECUTED=NO
SSH_EXECUTED=NO
NETWORK_EXECUTED=NO
PYTHON=3.12_EMBEDDED_CODEX_RUNTIME
TEST_FRAMEWORK=PYTHON_STDLIB_UNITTEST
```

## Primary fixture run

Command:

```text
python.exe -B -m unittest discover -s tests/python -p test_nvp_r1f_tools.py -v
```

Result:

```text
TESTS_RUN=16
TESTS_PASSED=16
TESTS_FAILED=0
TESTS_ERRORED=0
RESULT=PASS_ALL
```

Passing fixtures cover:

1. exact valid R1f header/map and complete scientific sample;
2. explicit invalid-field rendering and authoritative transaction-index-16;
3. magic/version mismatch and all-ones identity rejection;
4. record validity, reserved bits, kind/data-validity, and unused-zero gates;
5. failed total/stored/overflow consistency;
6. structurally valid 65-failure overflow decoding plus mandatory scientific
   rejection without losing the first-64/legacy-prefix evidence;
7. legacy first-eight phase/register/data/bank reconciliation failure;
8. probe index, first/last, streak, adjacency, run, and ten-block consistency;
9. complete exact-formal R1f-range zero behavior;
10. expected evidence output set and absence of an MMIO-write primitive;
11. complete offline CLI sparse-map/two-snapshot path;
12. Wilson boundary and fixed-family Holm behavior;
13. exact runs and adjacency tails versus brute-force binary enumeration;
14. exact equal-block tail versus brute-force allocation enumeration;
15. Fisher/Fisher-Freeman-Halton and general fixed-margin RxC agreement;
16. Miettinen-Nurminen/profile-RR intervals, zero-event rules, global 27-test
    Holm, incomplete-index handling, and the exact three-pair sign result.

## Independent small-state enumeration

The exact runs and adjacency functions were exhaustively compared with all
binary sequences for every `N=2..9` and every feasible event count. The exact
equal-block dynamic program was exhaustively compared with all allocations for
2..4 equal blocks of size 1..4.

```text
SMALL_EXACT_SEQUENCE_ENUMERATION=PASS
SMALL_EXACT_BLOCK_ENUMERATION=PASS
```

## Frozen-plan binding

```text
STATISTICAL_PLAN_MD_SHA256=B1593C23EE1BFFDF4591BF8CAC3B0A2330B44A47B196CCA42E88474CB1816321
STATISTICAL_PLAN_JSON_SHA256=56D60EC5AB457DCA3C58D4D4587926C857CCD51B9C753A6455D98717E0F04278
MID_P=NO
PSEUDOCOUNT=NO
MONTE_CARLO_PRIMARY_TEST=NO
ASYMPTOTIC_PRIMARY_SUBSTITUTION=NO
STRICT_P_COMPARISON=YES
```
