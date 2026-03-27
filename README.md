# TF_MISFIT_GOF_JULIA

Julia implementation of the **time-frequency misfit and goodness-of-fit (GOF) criteria** for comparing time signals, based on the methodology of Kristeková et al. (2006, 2009).

This project is a port of the original Fortran code, extended with Python and Julia tools for visualization and analysis.

---

## 📌 Overview

This code computes **time-frequency misfits** between two signals using:

- Continuous Wavelet Transform (CWT) with Morlet wavelet  
- Envelope and phase misfit measures  
- Time-frequency, time-dependent, and frequency-dependent diagnostics  

It produces both:

- **Misfit measures** (TFEM, TFPM, etc.)  
- **Goodness-of-fit (GOF)** criteria  

---

## ⚙️ Features

- Continuous wavelet transform (Morlet-based)  
- Global and local normalization  
- Time-frequency misfit analysis  
- Output compatible with MATLAB / Python plotting scripts  
- Julia-native implementation  

---

## 📂 Repository structure

```
.
├── tf_misfit_port.jl        # Main Julia implementation
├── plotting/                # Python plotting scripts
├── input/                   # Example input files
├── output/                  # Generated results (optional)
├── README.md
```

---

## 🚀 Getting started

### 1. Requirements

- Julia ≥ 1.8  
- (Optional) Python with:
  - numpy  
  - matplotlib  

---

### 2. Prepare input files

Create a control file:

```
HF_TF-MISFIT_GOF
```

Example:

```
&INPUT
  S1_NAME = 'signal1.dat',
  S2_NAME = 'signal2.dat',
  NC = 1,
  MT = 3000,
  DT = 0.01,
  FMIN = 0.1,
  FMAX = 10.0,
  IS_S2_REFERENCE = .FALSE.,
  LOCAL_NORM = .FALSE.
/
```

---

### 3. Run the code

```bash
julia tf_misfit_port.jl HF_TF-MISFIT_GOF
```

---

## 📊 Outputs

The code generates multiple `.DAT` files:

### Time-frequency
- `TFEMx.DAT` – envelope misfit  
- `TFPMx.DAT` – phase misfit  
- `TFEGx.DAT` – GOF (envelope)  
- `TFPGx.DAT` – GOF (phase)  

### Time-dependent
- `TEMx.DAT`, `TPMx.DAT`  
- `TEGx.DAT`, `TPGx.DAT`  

### Frequency-dependent
- `FEMx.DAT`, `FPMx.DAT`  
- `FEGx.DAT`, `FPGx.DAT`  

### Summary
- `MISFIT-GOF.DAT`  

---

## 📈 Visualization

Python scripts can be used to plot:

- Time-frequency GOF maps  
- Time-frequency misfit maps  

Example:

```bash
python PlotTFEM.py
python PlotTFEG.py
```

---

## 🧠 Methodology

Based on:

- Kristeková, M., Kristek, J., Moczo, P., Day, S. M. (2006)  
  *Misfit Criteria for Quantitative Comparison of Seismograms*  

- Kristeková, M., Kristek, J., Moczo, P. (2009)  
  *Time-frequency misfit and goodness-of-fit criteria for quantitative comparison of time signals*  

---

## ⚠️ Notes

- Output files are **not rectangular tables** → must be read sequentially  
- Time-frequency files are logically `(NF_TF × MT)`  
- Large output files are expected  

---

## 🧪 Typical applications

- Numerical dispersion and dissipation analysis  
- Wave propagation validation  
- Seismology waveform comparison  
- Signal processing diagnostics  

---

## 👤 Author

**Your Name**  
Your Affiliation  

📧 your.email@domain.com  
🌐 https://your-website.com  

Adapted from the original Fortran95 guide by  
Miriam Kristeková, Jozef Kristek, and Peter Moczo  

---

## 📄 License

(Add your license here, e.g. MIT License)
