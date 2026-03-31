import sys 
from pathlib import Path
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.colors import SymLogNorm

params = {
    "text.usetex": True,
    "font.family": "serif",
    "font.serif": ["TeX Gyre Schola"],
    "font.size": 16,
    "axes.labelsize": 18,
    "axes.titlesize": 18,
    "legend.fontsize": 14,
    "xtick.labelsize": 12,
    "ytick.labelsize": 12,
    "axes.linewidth": 1.0,
    "axes.grid": True,
    "axes.grid.which": "both",
    "grid.color": "0.85",
    "grid.linestyle": "--",
    "grid.linewidth": 0.8,
    "axes.axisbelow": True,
    "lines.linewidth": 1.2,
    "lines.markersize": 6,
    "lines.markeredgewidth": 0.8,
    "xtick.direction": "in",
    "ytick.direction": "in",
    "xtick.major.size": 6,
    "ytick.major.size": 6,
    "xtick.minor.size": 3,
    "ytick.minor.size": 3,
    "xtick.major.width": 1.0,
    "ytick.major.width": 1.0,
    "xtick.minor.width": 0.8,
    "ytick.minor.width": 0.8,
    "legend.frameon": True,
    "legend.handlelength": 2.5,
    "legend.handletextpad": 0.4,
    "savefig.dpi": 300,
    "savefig.pad_inches": 0.03,
}
plt.rcParams.update(params)


print("---------------------------------------------------")
print("       Python script for plotting TFPM misfits      ")

def parse_bool(value: str) -> bool:
    value = value.strip().lower()
    if value in {"true", "1", "yes", "y"}:
        return True
    if value in {"false", "0", "no", "n"}:
        return False
    raise ValueError(f"Invalid boolean value: {value}. Use true or false.")


def get_args():
    if len(sys.argv) != 4:
        print("Usage: python3 Plot.py INPUT_DIR FIG_DIR LOCAL_NORM")
        sys.exit(1)

    input_dir = Path(sys.argv[1]).resolve()
    fig_dir = Path(sys.argv[2]).resolve()
    local_norm = parse_bool(sys.argv[3])

    if not input_dir.exists():
        raise FileNotFoundError(f"Input directory does not exist: {input_dir}")

    fig_dir.mkdir(parents=True, exist_ok=True)

    return input_dir, fig_dir, local_norm

def read_misfit_file(filename="MISFIT-GOF.DAT"):
    """
    Read MISFIT-GOF.DAT written by the Fortran/Julia code.

    Structure:
        line 1: FMIN FMAX
        line 2: NF_TF MT
        line 3: DT NC
        line 4: max(abs(signal))
        next NC lines: EM PM
        next NC lines: EG PG
        next 4 lines:
            TFEMmax TFPMmax
            FEMmax  FPMmax
            TEMmax  TPMmax
            CWT1max CWT2max
    """
    with open(filename, "r") as f:
        lines = [line.strip() for line in f if line.strip()]

    fmin_val, fmax_val = map(float, lines[0].split())
    nfreq, n = map(int, lines[1].split())
    dt, nc = lines[2].split()
    dt = float(dt)
    nc = int(float(nc))

    tf_line_index = 4 + 2 * nc
    tfem_max, tfpm_max = map(float, lines[tf_line_index].split())

    return {
        "fmin_log": np.log10(fmin_val),
        "fmax_log": np.log10(fmax_val),
        "nfreq": nfreq,
        "n": n,
        "dt": dt,
        "nc": nc,
        "tfem_max": tfem_max,
        "tfpm_max": tfpm_max,
    }


def read_fortran_matrix(filename, nrows, ncols):
    """
    Read a Fortran-written matrix from ASCII, ignoring line wrapping.
    """
    data = np.fromfile(filename, sep=" ")
    expected_size = nrows * ncols

    if data.size != expected_size:
        raise ValueError(
            f"{filename}: found {data.size} values, expected {expected_size}"
        )

    return data.reshape((nrows, ncols))


# ------------------------------------------------------------
# Read control data
# ------------------------------------------------------------
input_dir, fig_dir, local_norm = get_args()

misfit_file = input_dir / "MISFIT-GOF.DAT"
misfit = read_misfit_file(misfit_file)

fmin = misfit["fmin_log"]
fmax = misfit["fmax_log"]
nfreq = misfit["nfreq"]
n = misfit["n"]
dt = misfit["dt"]
nc = misfit["nc"]
tfpm_max = misfit["tfpm_max"]

print(nfreq, n, dt, nc)

# Same style as TFEM script, but using TFPM max
col_max = (np.floor(tfpm_max * 100.0) + 1.0) / 100.0
col_max_tic = (np.floor(tfpm_max * 10.0) - 1.0) / 10.0

# If you want to force the colorbar to ±120%, uncomment:
# col_max = 1.2
# col_max_tic = 1.2

df = (fmax - fmin) / (nfreq - 1)

tfem = read_fortran_matrix(input_dir / "TFEM1.DAT", nfreq, n)
tfpm = read_fortran_matrix(input_dir / "TFPM1.DAT", nfreq, n)
fem = np.loadtxt(input_dir / "FEM1.DAT")
fpm = np.loadtxt(input_dir / "FPM1.DAT")
tem = np.loadtxt(input_dir / "TEM1.DAT")
tpm = np.loadtxt(input_dir / "TPM1.DAT")
signal1 = np.loadtxt(input_dir / "S1.DAT")
signal2 = np.loadtxt(input_dir / "S2.DAT")


print("Data read successfully. Ready to plot.")
print("---------------------------------------------------")

# ------------------------------------------------------------
# Build axes coordinates
# ------------------------------------------------------------
time = np.arange(n) * dt
freq_log = np.linspace(fmin, fmax, nfreq)
freq = 10.0 ** freq_log

if signal1.ndim == 2 and signal1.shape[1] >= 2:
    t_sig = signal1[:, 0]
    s1 = signal1[:, 1]
else:
    t_sig = time
    s1 = signal1

if signal2.ndim == 2 and signal2.shape[1] >= 2:
    s2 = signal2[:, 1]
else:
    s2 = signal2

# ------------------------------------------------------------
# Convert to percent
# ------------------------------------------------------------
tfem_pct = 100.0 * tfem
tfpm_pct = 100.0 * tfpm
fem_pct  = 100.0 * fem
fpm_pct  = 100.0 * fpm
tem_pct  = 100.0 * tem
tpm_pct  = 100.0 * tpm

# ------------------------------------------------------------
# Color normalization
# ------------------------------------------------------------
pct = 99.5

tfem_vlim = np.nanpercentile(np.abs(tfem_pct), pct)
tfpm_vlim = np.nanpercentile(np.abs(tfpm_pct), pct)

if not np.isfinite(tfem_vlim) or tfem_vlim == 0:
    tfem_vlim = 1.0
if not np.isfinite(tfpm_vlim) or tfpm_vlim == 0:
    tfpm_vlim = 1.0

print(f"TFEM color limit = ±{tfem_vlim:.3g} %")
print(f"TFPM color limit = ±{tfpm_vlim:.3g} %")
print(f"LOCAL_NORM       = {local_norm}")

if not local_norm:
    shared_vlim = max(tfem_vlim, tfpm_vlim)
    print(f"Shared color limit = ±{shared_vlim:.3g} %")

    tfem_norm = SymLogNorm(
        linthresh=max(1e-6, 0.05 * shared_vlim),
        linscale=1.0,
        vmin=-shared_vlim,
        vmax=shared_vlim,
        base=10
    )
    tfpm_norm = tfem_norm
else:
    tfem_norm = SymLogNorm(
        linthresh=max(1e-6, 0.05 * tfem_vlim),
        linscale=1.0,
        vmin=-tfem_vlim,
        vmax=tfem_vlim,
        base=10
    )

    tfpm_norm = SymLogNorm(
        linthresh=max(1e-6, 0.05 * tfpm_vlim),
        linscale=1.0,
        vmin=-tfpm_vlim,
        vmax=tfpm_vlim,
        base=10
    )

# ------------------------------------------------------------
# Figure 4 layout
# ------------------------------------------------------------
fig = plt.figure(figsize=(8.4, 9.4))

outer = fig.add_gridspec(
    nrows=2,
    ncols=1,
    height_ratios=[1.18, 0.82],
    hspace=0.11,
)

gs_top = outer[0].subgridspec(
    nrows=3,
    ncols=2,
    width_ratios=[1.0, 8.0],
    height_ratios=[3.5, 1.05, 1.45],
    wspace=0.02,
    hspace=0.04,
)

gs_bot = outer[1].subgridspec(
    nrows=2,
    ncols=2,
    width_ratios=[1.0, 8.0],
    height_ratios=[3.5, 1.05],
    wspace=0.02,
    hspace=0.04,
)

ax_fem  = fig.add_subplot(gs_top[0, 0])
ax_tfem = fig.add_subplot(gs_top[0, 1], sharey=ax_fem)
ax_tem  = fig.add_subplot(gs_top[1, 1], sharex=ax_tfem)
ax_sig  = fig.add_subplot(gs_top[2, 1], sharex=ax_tfem)

ax_fpm  = fig.add_subplot(gs_bot[0, 0], sharey=ax_fem)
ax_tfpm = fig.add_subplot(gs_bot[0, 1], sharex=ax_tfem, sharey=ax_tfem)
ax_tpm  = fig.add_subplot(gs_bot[1, 1], sharex=ax_tfem)

# ------------------------------------------------------------
# TF panels
# ------------------------------------------------------------
T, F = np.meshgrid(time, freq)

if not local_norm:
    im1 = ax_tfem.pcolormesh(
        T, F, tfem_pct,
        shading="auto",
        cmap="RdBu_r",
        norm=tfem_norm
    )

    im2 = ax_tfpm.pcolormesh(
        T, F, tfpm_pct,
        shading="auto",
        cmap="RdBu_r",
        norm=tfpm_norm
    )
else:
    im1 = ax_tfem.pcolormesh(
        T, F, tfem_pct,
        shading="auto",
        cmap="Spectral_r",
        norm=tfem_norm
    )

    im2 = ax_tfpm.pcolormesh(
        T, F, tfpm_pct,
        shading="auto",
        cmap="Spectral_r",
        norm=tfpm_norm
    )


# ------------------------------------------------------------
# Left marginal frequency plots
# ------------------------------------------------------------
ax_fem.plot(fem_pct, freq, color="k", lw=1.0)
ax_fpm.plot(fpm_pct, freq, color="k", lw=1.0)

for ax in (ax_fem, ax_fpm):
    ax.set_yscale("log")
    ax.invert_xaxis()

    ax.tick_params(
        axis="y",
        which="both",
        left=True,
        right=False,
        labelleft=True,
        labelright=False
    )

    ax.tick_params(
        axis="x",
        which="both",
        top=True,
        bottom=True
    )

# ------------------------------------------------------------
# Main TF axes styling
# ------------------------------------------------------------
for ax in (ax_tfem, ax_tfpm):
    ax.set_yscale("log")
    ax.tick_params(axis="both", which="both", direction="in", top=True, right=True)
    ax.tick_params(axis="y", labelleft=False, labelright=False)
    ax.tick_params(axis="x", labelbottom=False)

# Explicitly hide only TF-panel y tick labels
plt.setp(ax_tfem.get_yticklabels(), visible=False)
plt.setp(ax_tfpm.get_yticklabels(), visible=False)

ax_fem.text(0.04, 0.90, r"$FEM$", transform=ax_fem.transAxes, fontsize=18)
ax_tfem.text(0.98, 0.90, r"$TFEM$", transform=ax_tfem.transAxes,
             ha="right", fontsize=18)

ax_fpm.text(0.04, 0.90, r"$FPM$", transform=ax_fpm.transAxes, fontsize=18)
ax_tfpm.text(0.98, 0.90, r"$TFPM$", transform=ax_tfpm.transAxes,
             ha="right", fontsize=18)

ax_fem.text(-0.62, 1.02, r"[Hz]", transform=ax_fem.transAxes, fontsize=18)
ax_fpm.text(-0.62, 1.02, r"[Hz]", transform=ax_fpm.transAxes, fontsize=18)

# ------------------------------------------------------------
# Time marginals
# ------------------------------------------------------------
ax_tem.plot(time, tem_pct, color="k", lw=1.0)
ax_tpm.plot(time, tpm_pct, color="k", lw=1.0)

ax_tem.text(0.98, 0.72, r"$TEM$", transform=ax_tem.transAxes,
            ha="right", fontsize=18)
ax_tpm.text(0.98, 0.72, r"$TPM$", transform=ax_tpm.transAxes,
            ha="right", fontsize=18)

# Hide x tick labels on upper shared-x panels
ax_tem.tick_params(axis="x", which="both", labelbottom=False)
ax_sig.tick_params(axis="x", which="both", labelbottom=False)
ax_tfem.tick_params(axis="x", which="both", labelbottom=False)
ax_tfpm.tick_params(axis="x", which="both", labelbottom=False)

# Show x tick labels explicitly on TPM
ax_tpm.tick_params(
    axis="x",
    which="both",
    direction="in",
    top=True,
    bottom=True,
    labelbottom=True
)
plt.setp(ax_tpm.get_xticklabels(), visible=True)

# ------------------------------------------------------------
# Signal panel
# ------------------------------------------------------------
ax_sig.plot(t_sig, s1, color="red", lw=1.0)
ax_sig.plot(t_sig, s2, color="black", lw=1.0)

ax_sig.tick_params(axis="both", which="both", direction="in", top=True, right=True)
ax_sig.set_xlabel(r"$[s]$", x=0.98, ha="right")
ax_tpm.set_xlabel(r"$[s]$", x=0.98, ha="right")

# ------------------------------------------------------------
# Colorbar(s)
# ------------------------------------------------------------
if not local_norm:
    cax = fig.add_axes([0.93, 0.30, 0.03, 0.40])
    cb = fig.colorbar(im1, cax=cax)
    cb.ax.text(0.0, -0.075, r"[\%]", transform=cb.ax.transAxes,
               ha="left", va="top", fontsize=16)
else:
    cax1 = fig.add_axes([0.93, 0.56, 0.03, 0.26])
    cb1 = fig.colorbar(im1, cax=cax1)
    cb1.ax.set_title(r"$TFEM$", fontsize=14, pad=6)
    cb1.ax.text(0.0, -0.075, r"[\%]", transform=cb1.ax.transAxes,
                ha="left", va="top", fontsize=16)

    cax2 = fig.add_axes([0.93, 0.18, 0.03, 0.26])
    cb2 = fig.colorbar(im2, cax=cax2)
    cb2.ax.set_title(r"$TFPM$", fontsize=14, pad=6)
    cb2.ax.text(0.0, -0.075, r"[\%]", transform=cb2.ax.transAxes,
                ha="left", va="top", fontsize=16)

# Give a bit more room at the bottom so TPM labels are not clipped
fig.subplots_adjust(bottom=0.08)

output_path = fig_dir / f"tf_misfit_{input_dir.name}.png"
plt.savefig(output_path,  bbox_inches="tight", pad_inches=0.08, dpi=300)
print(f"Figure saved to: {output_path}")