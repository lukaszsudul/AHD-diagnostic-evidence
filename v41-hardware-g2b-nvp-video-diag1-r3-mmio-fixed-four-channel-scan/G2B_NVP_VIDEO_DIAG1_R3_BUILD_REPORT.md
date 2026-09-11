# Fresh diagnostic build

Vivado 2025.2 build 6299465 completed project regeneration, IP generation, synthesis, opt_design, place_design, phys_opt_design, and route_design without checkpoint reuse. The original full-build wrapper correctly stopped at its stale physical CDC hash; the authorized R3 destination-cone reconciliation and signed-off-DCP finalizer then passed every required gate without source, netlist, route, clock, or constraint mutation and generated the bitstream once.
