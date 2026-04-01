# TF_MISFIT_GOF_JULIA

Julia implementation of the **time-frequency misfit and goodness-of-fit (GOF) criteria** for comparing time signals, based on the methodology of Kristeková et al. (2006, 2009).

This project provides a **Julia reimplementation of the original Fortran code**, extended with tools for visualization and analysis in Python and Julia.

---

## 📌 Overview

This code computes **time-frequency misfits** between two signals using:

* Continuous Wavelet Transform (CWT) with Morlet wavelet
* Envelope and phase misfit measures
* Time-frequency, time-dependent, and frequency-dependent diagnostics

It produces:

* **Misfit measures** (TFEM, TFPM, etc.)
* **Goodness-of-fit (GOF)** criteria

---

## ⚙️ Features

* Continuous wavelet transform (Morlet-based)
* Global and local normalization
* Time-frequency misfit analysis
* Output compatible with MATLAB / Python plotting scripts
* Julia-native implementation

---

## 📂 Repository structure

```
.
├── src/                     # Core Julia implementation
├── scripts/                 # Execution / pipeline scripts
├── examples                 # Examples datasets
├── plotting_example/        # Visualization scripts (Python)
├── output_data/             # Generated results (ignored by git)
├── runs/                    # Batch runs (ignored by git)
├── README.md
```

---

## 🚀 Getting started

### 1. Requirements

* Julia ≥ 1.8

(Optional) for visualization:

* Python ≥ 3.8

  * numpy
  * matplotlib

---

### 2. Install Julia environment

```bash
julia
]
activate .
instantiate
```

---

### 3. Minimal example

Run the code using the provided example:

```bash
julia src/tf_misfit_port.jl input_data_example/HF_TF-MISFIT_GOF
```

---

### 4. Visualization

Example plotting:

```bash
python plotting_example/PlotTFEM.py
python plotting_example/PlotTFEG.py
```

---

## 📁 Data

* `input_data_example/` → small datasets for testing and reproducibility
* `ricker_wavelet_example/` → synthetic signals for demonstration
* `data/` → (optional) larger datasets (not included in the repository)

⚠️ Large datasets and generated outputs are not version-controlled.

---

## 📊 Outputs

The code generates multiple `.DAT` files:

### Time-frequency

* `TFEMx.DAT` – envelope misfit
* `TFPMx.DAT` – phase misfit
* `TFEGx.DAT` – GOF (envelope)
* `TFPGx.DAT` – GOF (phase)

### Time-dependent

* `TEMx.DAT`, `TPMx.DAT`
* `TEGx.DAT`, `TPGx.DAT`

### Frequency-dependent

* `FEMx.DAT`, `FPMx.DAT`
* `FEGx.DAT`, `FPGx.DAT`

### Summary

* `MISFIT-GOF.DAT`

---

## 🧠 Methodology

Based on:

* Kristeková, M., Kristek, J., Moczo, P., Day, S. M. (2006)
  *Misfit Criteria for Quantitative Comparison of Seismograms*

* Kristeková, M., Kristek, J., Moczo, P. (2009)
  *Time-frequency misfit and goodness-of-fit criteria for quantitative comparison of time signals*

---

## ⚠️ Notes

* Output files are **not rectangular tables** → must be read sequentially
* Time-frequency arrays are logically structured as `(NF_TF × MT)`
* Large output files are expected

---

## ⚠️ Repository policy

* `output_data/` and `runs/` are **not tracked** (see `.gitignore`)
* Only lightweight example data is included
* Generated figures and intermediate files are excluded

---

## 🧪 Typical applications

* Numerical dispersion and dissipation analysis
* Wave propagation validation
* Seismology waveform comparison
* Signal processing diagnostics

---

## 📚 Citation

If you use this code, please cite:

Kristeková et al. (2006, 2009)

and optionally this repository:

```
@software{tf_misfit_julia,
  author = {Martí Circuns-Duxans},
  title = {TF Misfit GOF Julia},
  year = {2026},
  url = {https://github.com/MartiCD/TF_MISFIT_GOF_JULIA}
}
```

---

## 👤 Author

**Martí Circuns-Duxans**
Barcelona Supercomputing Center (BSC-CNS)

📧 [marti.circuns@bsc.es](mailto:marti.circuns@bsc.es)

🌐 https://sites.google.com/view/marticircuns

Adapted from the original Fortran95 implementation by
Miriam Kristeková, Jozef Kristek, and Peter Moczo

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
