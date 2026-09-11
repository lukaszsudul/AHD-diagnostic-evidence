
# Route-specific VBI-tail decision

All eight attempted captures passed the bounded 0..21 tail-interval contract.
CH1 was stable at 21 tail intervals (capture-sequence delta 22); CH3 was stable
at 1 tail interval (delta 2). The difference is repeatable and route-specific,
not corruption: active-frame integrity, complete-frame reconstruction, transport
continuity, overflow, malformed, and source-drop gates all passed.
