# Candidate 1 publication and validity contract

First-attempt acceptance tick, verify-completion tick, first transaction sequence, group/target context and first failure cause are captured at the original scanner edges into live registers. Storage time is never substituted for measurement time. A terminal entry outcome stages all ten words; successful group verification stages five. The writer drains one word per edge without feeding back into I²C command validity/readiness, scanner transitions or SCL/SDA release.

The complete/frozen status requires all of: same snapshot/telemetry generation, 82 committed entry records, 10 committed group records, 82 exposure records, no pending writer or flush, no service fault, and no overflow. A hard/partial scan never fabricates complete 82-entry exposure coverage. A forced impossible overlap sets service fault/overflow and blocks complete. Reset invalidates metadata rather than resetting all RAM bits; stale bytes cannot be accepted as the new generation.

The legacy snapshot may publish before the final telemetry writer edge, so the host waits boundedly for the complete pair and refuses premature ACK. Before ACK, the extended RTL test reread all 870 frozen words in a shuffled order without mutation. The host persists and fsyncs evidence before it sends the legacy ACK. This contract does not turn recovered NACK count into an overflow: all 82 eligible first-attempt errors in one scan were retained in directed simulation.

Any writer loss, generation mismatch, partial publication accepted as complete, stale reuse, NACK hard error or timeout is a FAIL, not a clean observation.
