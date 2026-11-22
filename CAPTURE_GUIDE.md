# Capturing updated six-state Vivado evidence

The included **original** waveform, synthesis schematic, utilization, and timing screenshots were taken while the multiplier used the earlier **five-state** controller. They are historical evidence and must **not** be described as the implementation results of the final six-state `WAIT_RELEASE` controller.

## A. Six-state waveform
1. Open the Vivado project and ensure the current `multiplier_controller.sv` contains `WAIT_RELEASE`.
2. Set `tb_multiplier_top` as the simulation top and run **Behavioral Simulation**.
3. Add `clk`, `rst`, `start`, `A`, `B`, `product`, `done` and, via hierarchy, `DUT.u_controller.state`, `DUT.u_datapath.count`, and `DUT.u_datapath.product_reg` to the Wave window (adapt `DUT` if your instance differs).
4. Zoom into one transaction, and separately the held-START segment. Use the operating system's screenshot tool to save `six_state_waveform.png` and `held_start_waveform.png` into `docs/evidence/6state_current/`.
5. Ensure the waveform illustrates the **DONE** one-cycle pulse followed by **WAIT_RELEASE**, with `start` held HIGH and no retriggering.

## B. Six-state synthesized schematic
1. Restore the 100 MHz clock constraint and rerun synthesis **after** saving the updated RTL.
2. Select **Open Synthesized Design**, then **Schematic**; capture top-level architecture.
3. Expand the controller and datapath hierarchies to capture their synthesized logic, if helpful.
4. Save screenshots under `docs/evidence/6state_current/` and record new FF/LUT/CARRY4 counts.

## C. Six-state implementation timing
1. Run implementation with the intended 100 MHz constraint, and inspect **Report Timing Summary**.
2. Capture setup WNS, hold WHS, pulse width WPWS, endpoints, and a representative critical path.
3. Keep the historical 300 MHz timing experiment in the baseline folder; it is not proof of the new six-state implementation's operating speed or a board hardware test.
4. Do not claim board-ready constraints until you have added the correct Basys 3 package pins and I/O standards.

## D. Repository maintenance
- Commit only source files, reproducible constraints, text documentation, and selected evidence.
- Exclude generated Vivado `.runs`, `.sim`, `.cache`, `.Xil`, and large tool-generated artifacts.
- Update the README evidence table when genuine six-state synthesis and waveform screenshots are available.
