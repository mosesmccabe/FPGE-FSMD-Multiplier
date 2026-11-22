# Multi-Cycle FSMD Multiplier | FPGA Engineering 

> **Status:** Six-state RTL and behavioral verification complete. Updated six-state synthesis/implementation evidence is pending.  
> **Target platform:** Digilent Basys 3 (Xilinx Artix-7 XC7A35T) · **Tools:** AMD Vivado, SystemVerilog  


A small but fully verified **unsigned 4-bit × 4-bit multiplier** implemented using a **finite-state machine with datapath (FSMD)**. Instead of using a single combinational multiplication operator, the hardware computes the result with **repeated addition**, a decrementing loop counter, and a Moore-style controller.

This project demonstrates the separation of **control** from **datapath**, cycle-accurate transaction sequencing, exhaustive behavioral verification, asynchronous reset testing, and request-release protection. Vivado schematic and timing captures from the **earlier five-state version** are retained as historical evidence and explicitly labeled below.

## Architecture at a glance

![Current FSMD multiplier block architecture](docs/diagrams/fsmd_architecture.png)

- **Controller:** six-state Moore FSM; drives `load_operands`, `run_step` and `done`.
- **Datapath:** `A_reg[3:0]`, `count[3:0]`, `product_reg[7:0]`, adder, decrementer and completion flags.
- **Feedback:** datapath returns `count_zero` and `last_iteration` to the controller.
- **Top-level interface:** `clk`, `rst`, `start`, `A[3:0]`, `B[3:0]`, `product[7:0]`, `done`.
- **Reset:** active-HIGH asynchronous assertion; controller returns to IDLE, while datapath registers clear to zero.

### Repeated-addition algorithm

For unsigned operands `A`, `B` in `[0,15]`:

```text
LOAD:   A_reg = A; count = B; product_reg = 0
CHECK:  if count == 0 -> DONE; otherwise -> RUN
RUN:    product_reg = product_reg + zero_extend(A_reg)
        count = count - 1
        if old count == 1 -> DONE; otherwise remain in RUN
DONE:   assert done for one clock cycle
WAIT_RELEASE: do not accept another request until START returns LOW
```

The additions happen once per RUN clock edge. The final addition and transition to DONE occur on the **same rising edge** when `last_iteration` is true. For a zero multiplier (`B=0`), the FSM bypasses RUN and correctly produces zero.

**Latency:** for an accepted request, DONE first asserts after **`B + 2` rising-edge intervals**, whether `B=0` or `B>0`. Because the controller is multicycle, latency depends on the multiplier operand `B` and is not one clock cycle. `done` is a one-cycle pulse; `product` remains stored afterward until another LOAD or reset.

## Six-state controller

![Six-state FSM transition diagram](docs/diagrams/fsm_six_states.png)

| State | Controller behavior | Exit condition |
|:--|:--|:--|
| `IDLE` | Await request | `start=1` → `LOAD` |
| `LOAD` | Assert `load_operands`; capture `A`, `B`, clear accumulator at next rising edge | Unconditional → `CHECK` |
| `CHECK` | Inspect counter without changing datapath | `count_zero=1` → `DONE`; else `RUN` |
| `RUN` | Assert `run_step`; add A and decrement count each cycle | `last_iteration=1` → `DONE`; else stay `RUN` |
| `DONE` | Assert `done=1` for one cycle | Unconditional → `WAIT_RELEASE` |
| `WAIT_RELEASE` | Hold result; suppress repeated START requests | `start=0` → `IDLE`; else remain |

The Moore outputs are decoded directly from state:

```systemverilog
assign load_operands = (state == LOAD);
assign run_step      = (state == RUN);
assign done          = (state == DONE);
```

**Request protocol:** `start` is sampled when the controller is in `IDLE`. Requests presented while busy are not queued. The controller **always** passes through `WAIT_RELEASE` after DONE; another transaction can begin only after `start` has been observed LOW and the FSM has returned to IDLE. The project does **not** yet expose a `ready` output; that is planned for the next lesson.

### Datapath

![Conceptual datapath schematic](docs/diagrams/datapath_detail.png)

**Register budget inferred from RTL:** four A-register bits, four counter bits and eight product bits = **16 datapath flip-flops** (the historical five-state synthesis used another three state flip-flops). The two CARRY4 blocks shown in the historical Vivado schematic implement part of the accumulator addition path; the current six-state implementation has not yet been re-synthesized for this repository snapshot.

## Waveform interpretation

These diagrams are **reconstructed reference timing illustrations from the RTL behavior**, not original Vivado screenshots. Actual original Vivado waveform evidence appears under [historical evidence](#historical-vivado-evidence-five-state-baseline).

**One operation, 9 × 7 = 63:**

![RTL-reconstructed multiplication timing](docs/diagrams/transaction_9x7_reference.png)

**A held-START request should not retrigger the multiplier:**

![RTL-reconstructed held START timing](docs/diagrams/held_start_reference.png)

**Asynchronous reset interrupts an operation:**

![RTL-reconstructed asynchronous reset timing](docs/diagrams/reset_interrupt_reference.png)

The reset reference shows clock-edge samples; in the actual asynchronous implementation, registers respond to the rising edge of reset **before** the next clock edge. The directed testbench checks that behavior with a `#1` observation delay.

## Verification

The current six-state RTL passes the following Vivado behavioral simulation tests.

| Verification exercise | Stimulus or coverage | Observed result |
|:--|:--|:--|
| Exhaustive arithmetic | All `A=0..15` × `B=0..15` pairs (256 cases) | **256 PASS, 0 FAIL** |
| Asynchronous reset interruption | Interrupt 15×15 during RUN after five additions | **PASS:** registers clear; state IDLE; DONE=0 |
| Post-reset recovery | New 9×7 transaction following reset | **PASS:** product 63 |
| Held-START control | Hold `start=1` for 50 cycles after first DONE | **PASS:** no retrigger; result holds |
| Request release | Deassert START and check return to IDLE | **PASS** |

This amounts to **258 successful multiplication operations**: 256 exhaustive tests, one post-reset recovery test, and one held-START test. The reset-interruption test is a separate control-flow check, not an additional completed multiplication. The latest simulation finished normally at **32,860 ns**.

### Original final verification screenshot (six-state RTL)

![Six-state behavioral simulation PASS evidence](docs/evidence/6state_current/final_verification_original.png)

### What the tests establish—and what they don't

- The testbench is **self-checking**: it computes expected products, checks actual values with case inequality (`!==`), and has a watchdog for stalled operations.
- Exhaustive arithmetic coverage is complete **for unsigned 4×4 inputs**, not for wider widths or other interfaces.
- Reset and held-START are **directed tests**, not formal proofs of every possible timing or request sequence.
- The checked simulation demonstrates RTL functionality. Board-level hardware operation has **not** been demonstrated by these screenshots.

## Historical Vivado evidence (five-state baseline)

The following are **original Vivado screenshots recovered from the development conversation**. These were captured **before** `WAIT_RELEASE` was introduced, so they document the earlier controller (`IDLE`, `LOAD`, `CHECK`, `RUN`, `DONE`). They are valuable engineering history, **not** the final six-state synthesis results.

### Behavioral simulation waveform — original capture

![Actual Vivado waveform from initial five-state multiplier](docs/evidence/5state_baseline/behavioral_waveform_original.png)

### Synthesis and hardware mapping — original captures

**Synthesized top-level hierarchy:**

![Original Vivado synthesized top-level schematic](docs/evidence/5state_baseline/synthesized_top_original.png)

**Controller logic (LUTs and state registers):**

![Original five-state controller schematic](docs/evidence/5state_baseline/synthesized_controller_original.png)

**Datapath schematic, including the accumulator carry chain:**

![Original datapath synthesis schematic](docs/evidence/5state_baseline/synthesized_datapath_original.png)

**Primitive utilization, historical five-state build:**

![Five-state synthesis primitive inventory](docs/evidence/5state_baseline/synthesis_primitives_original.png)

The historical five-state implementation reported **19 FDCE registers** (16 datapath + 3 controller state bits) and **2 CARRY4 blocks**. These numbers must be measured again for the six-state version; Vivado may choose a different state encoding or resource mapping.

### Timing-constraint experiment — original captures

| Post-route metric | Five-state build at 100 MHz | Five-state build at 300 MHz |
|:--|--:|--:|
| Clock period | 10.000 ns | 3.333 ns |
| Setup WNS | **+6.806 ns** | **+0.640 ns** |
| Hold WHS | +0.268 ns | +0.226 ns |
| Pulse-width WPWS | +4.500 ns | +1.166 ns |
| Failing setup endpoints | 0 | 0 |

**100 MHz post-route timing summary:**

![100 MHz timing report](docs/evidence/5state_baseline/postroute_timing_100mhz_original.png)

**300 MHz post-route timing summary:**

![300 MHz timing report](docs/evidence/5state_baseline/postroute_timing_300mhz_original.png)

<details>
<summary>Expand original 100 MHz post-route critical-path screenshots</summary>

![100 MHz critical path, source and datapath](docs/evidence/5state_baseline/critical_path_100mhz_source_original.png)

![100 MHz critical path, destination clock and required time](docs/evidence/5state_baseline/critical_path_100mhz_destination_original.png)

</details>

The 100 MHz post-route critical path went from **`u_controller/FSM_sequential_state_reg[2]/C`** to **`u_datapath/product_reg_reg[5]/D`** through **LUT5 → CARRY4 → CARRY4**, with **3.193 ns** total data-path delay (1.602 ns cell, 1.591 ns route).

The 300 MHz timing report identified a critical path from **`u_controller/FSM_sequential_state_reg[1]/C`** to **`u_datapath/product_reg_reg[5]/D`** traversing **LUT5 → CARRY4 → CARRY4**. The report listed total data-path delay **2.693 ns**, comprising **1.446 ns cell delay** and **1.247 ns routed delay**.

<details>
<summary>Expand original 300 MHz critical-path screenshots</summary>

![300 MHz critical path, source and datapath](docs/evidence/5state_baseline/critical_path_300mhz_source_original.png)

![300 MHz critical path, destination clock and required time](docs/evidence/5state_baseline/critical_path_300mhz_destination_original.png)

</details>

> **Timing evidence scope:** The 300 MHz result is a **constraint experiment** on the earlier five-state routed design. It does not change the physical Basys 3 oscillator from 100 MHz and does **not** establish 300 MHz board operation. Both historical timing runs used a clock-only XDC without a verified Basys 3 pin/IOSTANDARD mapping, so they are not hardware sign-off evidence.

## Repository layout

```text
.
├── README.md
├── .gitignore
├── rtl/                      # COPY YOUR ACTUAL SystemVerilog files here
│   ├── multiplier_controller.sv
│   ├── multiplier_datapath.sv
│   └── multiplier_top.sv
├── tb/                       # COPY YOUR ACTUAL self-checking testbench here
│   └── tb_multiplier_top.sv
├── constraints/
│   ├── clock_only_100mhz.xdc
│   └── clock_only_300mhz_experiment.xdc
└── docs/
    ├── CAPTURE_GUIDE.md
    ├── diagrams/             # Architecture, FSM, datapath and reference timing
    └── evidence/
        ├── 5state_baseline/   # ORIGINAL historical screenshots
        └── 6state_current/   # ORIGINAL final behavioral PASS screenshot
```

**Important packaging note:** The documentation archive intentionally does **not** invent missing RTL or testbench source. Copy the four **actual** `.sv` files from your Vivado project's source directories into `rtl/` and `tb/` before publishing the repository as a complete reproducing project. The empty folders in the archive contain `.gitkeep` files.

## Reproduce in Vivado

1. Create a new RTL project targeting the Digilent Basys 3 Artix-7 (`xc7a35tcpg236-1`), or open the existing project.
2. Add the **three actual RTL files** to **Design Sources**; set `multiplier_top` as the design top.
3. Add the **actual** `tb_multiplier_top.sv` to **Simulation Sources**; set it as simulation top.
4. Use **only one** clock constraint. The provided `clock_only_100mhz.xdc` is for timing experiments; the 300 MHz version is historical. Do not enable both.
5. Run **Behavioral Simulation** and confirm the exhaustive arithmetic, reset, recovery and held-START checks pass.
6. Run synthesis and implementation with the six-state RTL to obtain **new** utilization and timing measurements; do not reuse five-state measurements as six-state results.
7. Before programming an FPGA board, add the **correct physical package pin and IOSTANDARD constraints**, confirm clocking and I/O requirements, and verify the implementation/DRCs.

See [`docs/CAPTURE_GUIDE.md`](docs/CAPTURE_GUIDE.md) for exact instructions to add genuine six-state waveform and synthesis screenshots later.

## Design decisions and limitations

- **Multicycle by design:** repeated addition trades latency for a small, inspectable controller/datapath structure.
- **Unsigned 4-bit operands:** accepts 0–15, result fits in 8 bits (maximum 225).
- **Single operation in flight:** no pipelining, request queue, or overlapped requests.
- **START-release protocol:** prevents repeated transactions caused by a continuously HIGH request, but does not yet implement `ready`/`valid` or backpressure.
- **One-cycle DONE pulse:** completion must be sampled or otherwise captured by the requester; completed product remains held.
- **Asynchronous reset assertion:** safe, synchronized release strategy is a future hardware-integration consideration.
- **No board demonstration yet:** the included XDCs specify clocks only, not full Basys 3 pins.

## Next step

**Interface protocols and READY:** extend the controller interface with a `ready` signal and define exactly when a caller may submit a new request. Follow that with new directed and self-checking testbench cases and updated six-state synthesis artifacts.

---

*Personal FPGA learning project. All included evidence images are either recovered original Vivado screenshots (clearly labeled by design revision) or new conceptual/RTL-reconstructed illustrations. No simulated example is presented as an actual hardware screenshot.*
