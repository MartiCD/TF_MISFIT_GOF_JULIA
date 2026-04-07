# TF_MISFIT_GOF_JULIA

Julia implementation of the **time-frequency misfit** and **goodness-of-fit (GOF)** criteria for comparing time signals, based on the methodology of **Kristeková et al. (2006, 2009)**.

This repository contains:

- a Julia implementation of the TF misfit / GOF engine,
- Python helpers for preprocessing and plotting,
- reproducible example runs,
- a CLI-driven workflow for preparing inputs, running the solver, validating examples, and generating figures.

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
- Legacy `.DAT` outputs for compatibility
- `results.h5` output for plotting and downstream inspection
- Python preprocessing and plotting helpers
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
├── scripts/                   # Python preprocessing / plotting helpers
├── src/                       # Julia source code
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

- Julia 1.9 or newer supported
- Julia 1.10 or newer recommended

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
4. write legacy `.DAT` outputs and `results.h5`,
5. generate figures in the run's `figures/` directory.

`TFMisfitGOF.main()` is kept as a compatibility alias for the CLI entrypoint, but `main_cli(...)` is the most explicit interface for scripted usage.

---

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
  "--input-file","HF_TF-MISFIT_GOF"
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

Lean modern workflow:

```bash
julia --project=. -e 'using TFMisfitGOF; TFMisfitGOF.main_cli([
  "pipeline",
  "--input-csv","data/probe_ricker_wavelet.csv",
  "--local-norm","false",
  "--legacy-output","h5"
])'
```

Full legacy export
```bash
julia --project=. -e 'using TFMisfitGOF; TFMisfitGOF.main_cli([
  "pipeline",
  "--input-csv","data/probe_ricker_wavelet.csv",
  "--local-norm","false",
  "--legacy-output","full"
])'
```


### Output policy

`results.h5` is the canonical output format.

Legacy ASCII `.DAT` files remain available for backward compatibility and can be controlled with:

- `--legacy-output h5`      → write only `results.h5`
- `--legacy-output summary` → write `results.h5` + `MISFIT-GOF.DAT`
- `--legacy-output full`    → write `results.h5` + all legacy `.DAT`

The default is `summary`.

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

The solver generates legacy `.DAT` files and a structured HDF5 file.

### Time-frequency outputs

- `TFEMx.DAT` — envelope misfit
- `TFPMx.DAT` — phase misfit
- `TFEGx.DAT` — GOF from envelope misfit
- `TFPGx.DAT` — GOF from phase misfit

### Time-dependent outputs

- `TEMx.DAT`
- `TPMx.DAT`
- `TEGx.DAT`
- `TPGx.DAT`

### Frequency-dependent outputs

- `FEMx.DAT`
- `FPMx.DAT`
- `FEGx.DAT`
- `FPGx.DAT`

### Wavelet outputs

- `CWT1x.DAT`
- `CWT2x.DAT`

### Summary output

- `MISFIT-GOF.DAT`

### Structured output

- `results.h5`

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

- Output files are written in legacy ASCII `.DAT` format.
- A structured `results.h5` file is also written for plotting and downstream inspection.
- Time-frequency arrays are logically structured as `(NF_TF × MT)`.
- Large output files are expected for dense runs.

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
