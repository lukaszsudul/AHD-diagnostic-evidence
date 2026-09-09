# Append-only erratum for G2B-BT656-DIAG1-R1

This file does not rewrite or amend evidence commit
`1994e3a03ab41361f685b57f8e47e0d8349bfc93`.

1. `G2B_BT656_DIAG1_R1_ROOT_CAUSE_DECISION.md` contains a stale final sentence
   saying that no correction candidate was created.
2. Later work in the same governed DIAG1-R1 run did create and publish the
   candidate.
3. The authoritative candidate identity is branch
   `fix/v41-g2b-bt656-line0-sof`, commit `bf19702beca9bd85e950fa7ee59fd8ed08b1b2dc`, tree
   `2f72f4fa5dd756443c2d79eb7b75d75badefe921`.
4. The DIAG1-R1 main report, correction-candidate report, and actual Git commit
   establish the candidate's existence.
5. DIAG1-R1 remained globally BLOCKED only because drain AIO cleanup was
   unresolved.
6. Functional result:
   `PASS_ROOT_CAUSE_PROVEN_CORRECTION_CANDIDATE_READY`.
7. Operational cleanup result: `BLOCKED`.

This FIX1 run resolved the retained operational cleanup separately before any
new build or hardware qualification.
