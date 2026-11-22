# Upload checklist

**Recommended:** upload the contents of this folder to a GitHub repo or a `Week-03/FSMD-Multiplier/` subdirectory.

1. Keep `README.md` at that directory root.
2. Upload the `docs/` directory exactly as laid out so images resolve in GitHub Markdown.
3. Upload `.gitignore` and the `constraints/` directory.
4. From your local Vivado project, copy the **real** `multiplier_controller.sv`, `multiplier_datapath.sv`, `multiplier_top.sv` into `rtl/` and `tb_multiplier_top.sv` into `tb/`. The archive intentionally does not guess missing source files.
5. Check GitHub README preview, then commit.

The original Vivado waveform, schematic, primitive, and timing images included under `docs/evidence/5state_baseline/` are genuinely recovered **five-state** captures, not images from the six-state update.

The 6-state behavioral verification capture is in `docs/evidence/6state_current/`. See `docs/CAPTURE_GUIDE.md` for making fresh 6-state simulation/synthesis screenshots.

Optional cleanup: after copying in your `.sv` files, you can remove `.gitkeep` from `rtl/` and `tb/`.
