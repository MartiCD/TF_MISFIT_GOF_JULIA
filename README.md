# TF_MISFIT_GOF_JULIA

Julia implementation of the **time-frequency misfit** and **goodness-of-fit (GOF)** criteria for comparing time signals, based on the methodology of **Kristeková et al. (2006, 2009)**.

This repository contains:

- a Julia implementation of the TF misfit / GOF engine,
- Python helpers for preprocessing and plotting,
- reproducible example runs,
- a CLI-driven workflow for preparing inputs, running the solver, validating examples, and generating figures.

> **Release status:** `v0.1.0` is the first tagged release of the Julia package.
>
> **Supported Julia versions:** Julia `1.9+` is supported, matching `Project.toml`. Julia `1.10+` is recommended for day-to-day use.
>
> **Interface contract:**
> - `results.h5` is the canonical output of a run.
> - Legacy ASCII `.DAT` files are available for backward compatibility via `--legacy-output h5|summary|full`.
> - `TFMisfitGOF.main_cli(...)` is the explicit scripted entrypoint.
> - `TFMisfitGOF.main()` is retained as a compatibility alias.

---

## Overview

This project computes time-frequency misfits between two signals using:

- Continuous Wavelet Transform (CWT) with a Morlet wavelet,
- envelope and phase misfit measures,
- time-frequency, time-dependent, and frequency-dependent diagnostics,
- global or local normalization modes.

It produces both **misfit measures** and **goodness-of-fit (GOF)** criteria for quantitative signal comparison.

Typical use cases include:

- waveform comparison,
- numerical dispersion and dissipation analysis,
- validation of wave propagation simulations,
- signal-processing diagnostics,
- seismological benchmarking.

---

## Features

- Julia-based TF misfit / GOF implementation
- Morlet-based continuous wavelet transform
- Global and local normalization modes
- Split Julia package structure under `src/`
- Julia CLI for `prepare`, `run`, `plot`, `pipeline`, and `validate`
- Canonical `results.h5` output for plotting and downstream inspection
- Configurable legacy ASCII `.DAT` compatibility outputs via `--legacy-output h5|summary|full`
- Split plotting backends:
  - `scripts/Plot.py` for legacy plotting
  - `scripts/plot_windowed.py` for modern HDF5/windowed plotting
- CSV preprocessing that can use either:
  - an analytical reference signal, or
  - a second signal column from the input CSV
- Synthetic demo helpers for controlled TFEM/TFPM experiments with Ricker wavelets
- Reproducible example folders
- Automated tests under `test/`
- CI workflows under `.github/workflows/`

---

## Repository structure

```text
TF_MISFIT_GOF_JULIA/
├── .github/workflows/         # CI workflows
├── data/                      # Input CSVs and working input data
├── examples/                  # Reproducible example runs
├── python/                    # Python dependency specification
├── scripts/                   # preprocessing / plotting helpers
│   ├── build_tf_misfit_signals.py
│   ├── Plot.py                # legacy plotting backend
│   ├── plot_windowed.py       # modern HDF5/windowed plotting backend
│   └── run_windowed_pipeline.jl
├── src/
│   ├── api.jl
│   ├── cli.jl
│   ├── demo_signals.jl        # synthetic TFEM/TFPM demo helpers
│   └── ...
├── test/                      # Julia tests
├── CITATION.cff
├── LICENSE
├── Project.toml
├── Manifest.toml              # Optional, depending on workflow / branch state
├── README.md
├── TF_MISFIT_GOF_CRITERIA_Julia_User_Guide.pdf
├── TF_MISFIT_GOF_CRITERIA_Users_Guide.pdf
└── run_pipeline.sh            # Thin wrapper over the Julia CLI pipeline
```

---

## Requirements

### Julia

- **Supported:** Julia 1.9 or newer
- **Recommended:** Julia 1.10 or newer

This matches the package compatibility declared in `Project.toml`:

```toml
[compat]
julia = "1.9"
```

### Python

Python is only required for the preprocessing / plotting helpers.

- Python 3.8+
- packages listed in `python/requirements.txt`

Install Python dependencies with:

```bash
python -m pip install -r python/requirements.txt
```

---

## Installation

Instantiate the Julia environment:

```bash
julia --project=. -e 'using Pkg; Pkg.instantiate()'
```

Run the test suite:

```bash
julia --project=. -e 'using Pkg; Pkg.test()'
```

---

## Quick start

### Run the full pipeline

Using the shell wrapper:

```bash
./run_pipeline.sh false
```

Or directly through the Julia CLI:

```bash
julia --project=. -e 'using TFMisfitGOF; TFMisfitGOF.main_cli(["pipeline","--local-norm","false"])'
```

This will:

1. create a new dated run directory under `runs/`,
2. build the `HF_TF-MISFIT_GOF` input file from `data/probe_ricker_wavelet.csv`,
3. run the Julia TF misfit / GOF engine,
4. write the canonical `results.h5` output,
5. optionally write legacy `.DAT` outputs depending on `--legacy-output`,
6. generate figures in the run's `figures/` directory.

`TFMisfitGOF.main_cli(...)` is the explicit scripted interface. `TFMisfitGOF.main()` is retained as a compatibility alias.

---

## TFEM / TFPM demo workflow

This branch includes a small pedagogical demo for understanding what the
time-frequency envelope misfit (TFEM) and time-frequency phase misfit (TFPM)
measure under controlled perturbations of a Ricker wavelet.

Available demo cases:
- `amplitude` — scales one signal relative to the reference
- `shift` — advances one signal relative to the reference
- `mixed` — combines amplitude scaling and time shift

The demo CSV layout is:
- column 0: time
- column 1: perturbed / test signal
- column 2: reference signal

For this workflow, preprocessing must use:

- `--reference-source csv`
- `--signal1-col 1`
- `--signal2-col 2`

Programmatic usage:

```julia
using TFMisfitGOF

run_tf_metric_demo("amplitude";
    outdir="runs_demo",
    plot_backend=WindowedPlot(),
)

run_tf_metric_demo("shift";
    outdir="runs_demo",
    plot_backend=WindowedPlot(),
)
```

Scripted usage:

```bash
julia --project=. scripts/run_tf_metric_demo.jl
```


Then update the `prepare` example:

```markdown
### `prepare`

Generate a working `HF_TF-MISFIT_GOF` input file from a CSV:

```bash
julia --project=. -e 'using TFMisfitGOF; TFMisfitGOF.main_cli([
  "prepare",
  "--input-csv","data/probe_ricker_wavelet.csv",
  "--workdir","runs/dev/work",
  "--local-norm","false"
])'
```

Use a CSV-provided reference signal instead of the built-in analytical reference:

```bash
julia --project=. -e 'using TFMisfitGOF; TFMisfitGOF.main_cli([
  "prepare",
  "--input-csv","runs_demo/amplitude/demo_signals.csv",
  "--workdir","runs_demo/amplitude/work",
  "--local-norm","false",
  "--reference-source","csv",
  "--signal1-col","1",
  "--signal2-col","2"
])'
```


And update the `plot` section so it reflects the new backend split:

```markdown
### `plot`

Modern windowed/HDF5 plotting:

```bash
julia --project=. -e 'using TFMisfitGOF; TFMisfitGOF.main_cli([
  "plot",
  "--workdir","runs/dev/work",
  "--figdir","runs/dev/figures",
  "--local-norm","false",
  "--usetex","false",
  "--style","portable",
  "--format","png",
  "--plot-backend","windowed"
])'
```

Legacy plotting:

```bash
julia --project=. -e 'using TFMisfitGOF; TFMisfitGOF.main_cli([
  "plot",
  "--workdir","runs/dev/work",
  "--figdir","runs/dev/figures_legacy",
  "--local-norm","false",
  "--plot-backend","legacy"
])'
```

## CLI usage

The Julia CLI is the recommended interface.

### `pipeline`

Run the full workflow:

```bash
julia --project=. -e 'using TFMisfitGOF; TFMisfitGOF.main_cli([
  "pipeline",
  "--input-csv","data/probe_ricker_wavelet.csv",
  "--local-norm","false"
])'
```

Optional:

```bash
julia --project=. -e 'using TFMisfitGOF; TFMisfitGOF.main_cli([
  "pipeline",
  "--input-csv","data/probe_ricker_wavelet.csv",
  "--local-norm","true",
  "--runs-dir","runs"
])'
```

### `prepare`

Generate a working `HF_TF-MISFIT_GOF` input file from a CSV:

```bash
julia --project=. -e 'using TFMisfitGOF; TFMisfitGOF.main_cli([
  "prepare",
  "--input-csv","data/probe_ricker_wavelet.csv",
  "--workdir","runs/dev/work",
  "--local-norm","false"
])'
```

### `run`

Run the Julia engine inside a working directory:

```bash
julia --project=. -e 'using TFMisfitGOF; TFMisfitGOF.main_cli([
  "run",
  "--workdir","runs/dev/work",
  "--input-file","HF_TF-MISFIT_GOF",
  "--legacy-output","summary"
])'
```

Minimal modern output:

```bash
julia --project=. -e 'using TFMisfitGOF; TFMisfitGOF.main_cli([
  "run",
  "--workdir","runs/dev/work",
  "--input-file","HF_TF-MISFIT_GOF",
  "--legacy-output","h5"
])'
```

### `plot`

Portable default:

```bash
julia --project=. -e 'using TFMisfitGOF; TFMisfitGOF.main_cli([
  "plot",
  "--workdir","runs/dev/work",
  "--figdir","runs/dev/figures",
  "--local-norm","false",
  "--usetex","false",
  "--style","portable",
  "--format","png"
])'
```

Publication-style figures:

```bash
julia --project=. -e 'using TFMisfitGOF; TFMisfitGOF.main_cli([
  "plot",
  "--workdir","runs/dev/work",
  "--figdir","runs/dev/figures",
  "--local-norm","false",
  "--usetex","true",
  "--style","publication",
  "--format","both"
])'
```

### `validate`

Validate one of the bundled examples:

```bash
julia --project=. -e 'using TFMisfitGOF; TFMisfitGOF.main_cli([
  "validate",
  "--example-dir","examples/global"
])'
```

You can also validate the local-normalization example:

```bash
julia --project=. -e 'using TFMisfitGOF; TFMisfitGOF.main_cli([
  "validate",
  "--example-dir","examples/local"
])'
```

### Output policy

`results.h5` is the canonical output format for modern workflows.

Legacy ASCII `.DAT` files remain available for backward compatibility with older workflows, external scripts, and existing users. They are controlled with:

- `--legacy-output h5`      → write only `results.h5`
- `--legacy-output summary` → write `results.h5` + `MISFIT-GOF.DAT`
- `--legacy-output full`    → write `results.h5` + all legacy `.DAT`

The default is `summary`.

For scripted usage, prefer `TFMisfitGOF.main_cli(...)`. `TFMisfitGOF.main()` is supported as a compatibility alias.

Lean modern workflow (`results.h5` only):

```bash
julia --project=. -e 'using TFMisfitGOF; TFMisfitGOF.main_cli([
  "pipeline",
  "--input-csv","data/probe_ricker_wavelet.csv",
  "--local-norm","false",
  "--legacy-output","h5"
])'
```

Full legacy export:

```bash
julia --project=. -e 'using TFMisfitGOF; TFMisfitGOF.main_cli([
  "pipeline",
  "--input-csv","data/probe_ricker_wavelet.csv",
  "--local-norm","false",
  "--legacy-output","full"
])'
```

---

## Example workflow

### Example 1: validate a bundled example

```bash
julia --project=. -e 'using TFMisfitGOF; TFMisfitGOF.main_cli([
  "validate",
  "--example-dir","examples/global"
])'
```

### Example 2: run step-by-step

Prepare input:

```bash
julia --project=. -e 'using TFMisfitGOF; TFMisfitGOF.main_cli([
  "prepare",
  "--input-csv","data/probe_ricker_wavelet.csv",
  "--workdir","runs/manual/work",
  "--local-norm","false"
])'
```

Run solver:

```bash
julia --project=. -e 'using TFMisfitGOF; TFMisfitGOF.main_cli([
  "run",
  "--workdir","runs/manual/work",
  "--input-file","HF_TF-MISFIT_GOF"
])'
```

Plot results:

```bash
julia --project=. -e 'using TFMisfitGOF; TFMisfitGOF.main_cli([
  "plot",
  "--workdir","runs/manual/work",
  "--figdir","runs/manual/figures",
  "--local-norm","false",
  "--usetex","false",
  "--style","portable",
  "--format","png"
])'
```

### Example 3: run the full pipeline

```bash
julia --project=. -e 'using TFMisfitGOF; TFMisfitGOF.main_cli([
  "pipeline",
  "--input-csv","data/probe_ricker_wavelet.csv",
  "--local-norm","false"
])'
```

---

## Inputs

The workflow expects an input description file named `HF_TF-MISFIT_GOF` in the working directory.

This file can be:

- created automatically with the `prepare` command, or
- provided manually for advanced workflows.

The repository also includes:

- `data/` for CSV-based inputs,
- `examples/` for reproducible reference runs.

The generated namelist currently uses keys such as:

- `S1_NAME`
- `S2_NAME`
- `NC`
- `MT`
- `DT`
- `FMIN`
- `FMAX`
- `IS_S2_REFERENCE`
- `LOCAL_NORM`

---

## Outputs

The solver always generates a structured HDF5 output file and can optionally generate legacy ASCII `.DAT` files for compatibility.

### Canonical output

- `results.h5` — canonical structured output for plotting and downstream inspection

### Compatibility summary output

- `MISFIT-GOF.DAT` — written in `summary` and `full` modes

### Full legacy compatibility outputs

Written only in `full` mode:

#### Time-frequency outputs

- `TFEMx.DAT` — envelope misfit
- `TFPMx.DAT` — phase misfit

#### Time-dependent outputs

- `TEMx.DAT`
- `TPMx.DAT`

#### Frequency-dependent outputs

- `FEMx.DAT`
- `FPMx.DAT`

#### Wavelet outputs

- `CWT1x.DAT`
- `CWT2x.DAT`

Depending on the workflow, generated figures are written to the selected figure directory.

---

## Plotting modes

The plotting workflow supports two styles:

- `portable` — recommended default, works without LaTeX
- `publication` — publication-style figures, optionally with `--usetex true`

Recommended portable plotting:

```bash
julia --project=. -e 'using TFMisfitGOF; TFMisfitGOF.main_cli([
  "plot",
  "--workdir","runs/dev/work",
  "--figdir","runs/dev/figures",
  "--local-norm","false",
  "--usetex","false",
  "--style","portable",
  "--format","png"
])'
```

Publication-style plotting:

```bash
julia --project=. -e 'using TFMisfitGOF; TFMisfitGOF.main_cli([
  "plot",
  "--workdir","runs/dev/work",
  "--figdir","runs/dev/figures_pub",
  "--local-norm","false",
  "--usetex","true",
  "--style","publication",
  "--format","both"
])'
```

---

## Methodology

This implementation is based on:

- **Kristeková, M., Kristek, J., Moczo, P., Day, S. M. (2006)** — *Misfit Criteria for Quantitative Comparison of Seismograms*
- **Kristeková, M., Kristek, J., Moczo, P. (2009)** — *Time-frequency misfit and goodness-of-fit criteria for quantitative comparison of time signals*

The main ingredients are:

- Morlet-wavelet CWT,
- envelope misfit,
- phase misfit,
- integrated time, frequency, and time-frequency diagnostics,
- GOF criteria derived from the misfit measures.

---

## Notes on output format

- Output files can be written in legacy ASCII `.DAT` format for compatibility.
- A structured `results.h5` file is always written as the canonical run artifact.
- Time-frequency arrays are logically structured as `(NF_TF × MT)`.
- Large output files are expected for dense runs, especially in `--legacy-output full` mode.

---

## Development and testing

Run tests with:

```bash
julia --project=. -e 'using Pkg; Pkg.test()'
```

Or directly:

```bash
julia --project=. test/runtests.jl
```

Useful checks during development:

```bash
julia --project=. -e 'using TFMisfitGOF; println(TFMisfitGOF.KN)'
julia --project=. -e 'using TFMisfitGOF; TFMisfitGOF.main_cli(["validate","--example-dir","examples/global"])'
julia --project=. -e 'using TFMisfitGOF; TFMisfitGOF.main_cli(["pipeline","--local-norm","false"])'
```

For scripted automation and CI-style usage, prefer `TFMisfitGOF.main_cli(...)` over `TFMisfitGOF.main()`.

CI workflows live under `.github/workflows/`.

---

## Documentation

Additional user guides are included in the repository root:

- `TF_MISFIT_GOF_CRITERIA_Julia_User_Guide.pdf`
- `TF_MISFIT_GOF_CRITERIA_Users_Guide.pdf`

---

## Repository policy

- Generated runs and figures should generally not be committed.
- Example data is kept lightweight for reproducibility.
- Large generated artifacts should remain outside version control unless they are curated fixtures for tests.

---

## Citation

If you use this software, please cite the project metadata in `CITATION.cff` and the original methodological references above.

---

## Author

**Martí Circuns-Duxans**  
Barcelona Supercomputing Center (BSC-CNS)

📧 [marti.circuns@bsc.es](mailto:marti.circuns@bsc.es)

🌐 https://sites.google.com/view/marticircuns

Adapted from the original Fortran95 implementation by  
Miriam Kristeková, Jozef Kristek, and Peter Moczo

---

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
