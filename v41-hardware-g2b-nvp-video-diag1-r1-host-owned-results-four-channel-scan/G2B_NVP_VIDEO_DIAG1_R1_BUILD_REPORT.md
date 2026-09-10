# Fresh diagnostic build report

Vivado 2025.2 build 6299465 completed project creation, IP generation,
synthesis, opt_design, placement, phys_opt_design, and route_design. The design
is fully routed with zero route errors, zero unrouted nets, and zero partially
routed nets. Source commit/tree were `fcab95726761a0666a67e31c283dbdfb9e775074` / `bbf1a5fee70a2eb68bb96305ed10934a1559ca6a`.

The terminal build result is **FAIL at the formal CDC disposition gate**;
engineering classification is **BLOCKED** because a new diagnostic-netlist
manifest disposition was outside the granted correction authority. Bitstream
generation did not execute.

`CDC-1 critical CDC canonical manifest drift: expected=A7FE533FE9165E714D2CB171265D7653E99C8A1F88CD25942B99C036EB3D564D actual=BFD68E3E735133AFFD546985A382CA83F25A744F8B6E4B0B9A5000202968CF99`
