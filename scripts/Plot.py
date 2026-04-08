# import sys
# from pathlib import Path
# import numpy as np
# import matplotlib.pyplot as plt
# from matplotlib.colors import SymLogNorm
# import h5py

# def configure_matplotlib(*, usetex: bool, style: str = "portable", dpi: int = 300):
#     params = {
#         "font.size": 16,
#         "axes.labelsize": 18,
#         "axes.titlesize": 18,
#         "legend.fontsize": 14,
#         "savefig.dpi": dpi,
#         "savefig.pad_inches": 0.03,
#     }

#     if style == "publication":
#         params.update({
#             "font.family": "serif",
#             "axes.grid": True,
#             "axes.grid.which": "both",
#         })

#     if usetex:
#         params["text.usetex"] = True
#         params["font.family"] = "serif"
#         params["font.serif"] = ["TeX Gyre Schola"]
#     else:
#         params["text.usetex"] = False

#     plt.rcParams.update(params)

# print("Starting Plot.py", flush=True)
# print("---------------------------------------------------")
# print("       Python script for plotting TFPM misfits      ")


# def parse_bool(value: str) -> bool:
#     value = value.strip().lower()
#     if value in {"true", "1", "yes", "y"}:
#         return True
#     if value in {"false", "0", "no", "n"}:
#         return False
#     raise ValueError(f"Invalid boolean value: {value}. Use true or false.")


# def get_args():
#     if len(sys.argv) != 4:
#         print("Usage: python3 Plot.py INPUT_DIR FIG_DIR LOCAL_NORM")
#         sys.exit(1)

#     input_dir = Path(sys.argv[1]).resolve()
#     fig_dir = Path(sys.argv[2]).resolve()
#     local_norm = parse_bool(sys.argv[3])

#     if not input_dir.exists():
#         raise FileNotFoundError(f"Input directory does not exist: {input_dir}")

#     fig_dir.mkdir(parents=True, exist_ok=True)

#     return input_dir, fig_dir, local_norm


# def extract_tf_component(arr: np.ndarray, mt_expected: int) -> np.ndarray:
#     """
#     Returns a 2D array with shape (nf, mt) for component 0.

#     Handles typical layouts seen when Julia writes HDF5 and Python reads it:
#       - (nc, mt, nf)  -> take [0, :, :].T
#       - (nf, mt, nc)  -> take [:, :, 0]
#       - (mt, nf, nc)  -> take[:, :, 0].T
#       - (nf, mt)      -> already OK
#       - (mt, nf)      -> transpose
#     """
#     arr = np.asarray(arr)

#     if arr.ndim == 3:
#         # Case A: (nc, mt, nf)
#         if arr.shape[1] == mt_expected:
#             if arr.shape[0] == 1 or arr.shape[0] < arr.shape[2]:
#                 return arr[0, :, :].T
#             else:
#                 # likely (nf, mt, nc)
#                 return arr[:, :, 0]

#         # Case B: (mt, nf, nc)
#         if arr.shape[0] == mt_expected:
#             return arr[:, :, 0].T

#         # Fallback: try component-last
#         if arr.shape[2] == 1:
#             return arr[:, :, 0]

#         raise ValueError(f"Unexpected 3D TF array shape: {arr.shape}")

#     if arr.ndim == 2:
#         # (nf, mt)
#         if arr.shape[1] == mt_expected:
#             return arr
#         # (mt, nf)
#         if arr.shape[0] == mt_expected:
#             return arr.T

#         raise ValueError(f"Unexpected 2D TF array shape: {arr.shape}")

#     raise ValueError(f"Unexpected TF array rank: {arr.ndim}")


# def extract_time_marginal(arr: np.ndarray, mt_expected: int) -> np.ndarray:
#     """
#     Returns a 1D array with shape (mt,) for component 0.
#     Handles:
#       - (nc, mt) -> arr[0, :]
#       - (mt, nc) -> arr[:, 0]
#       - (mt,)    -> arr
#     """
#     arr = np.asarray(arr)

#     if arr.ndim == 1:
#         if arr.shape[0] != mt_expected:
#             raise ValueError(f"Unexpected time marginal shape: {arr.shape}")
#         return arr

#     if arr.ndim == 2:
#         if arr.shape[1] == mt_expected:
#             return arr[0, :]
#         if arr.shape[0] == mt_expected:
#             return arr[:, 0]

#     raise ValueError(f"Unexpected time marginal shape: {arr.shape}")


# def extract_freq_marginal(arr: np.ndarray, nf_expected: int) -> np.ndarray:
#     """
#     Returns a 1D array with shape (nf,) for component 0.
#     Handles:
#       - (nc, nf) -> arr[0, :]
#       - (nf, nc) -> arr[:, 0]
#       - (nf,)    -> arr
#     """
#     arr = np.asarray(arr)

#     if arr.ndim == 1:
#         if arr.shape[0] != nf_expected:
#             raise ValueError(f"Unexpected frequency marginal shape: {arr.shape}")
#         return arr

#     if arr.ndim == 2:
#         if arr.shape[1] == nf_expected:
#             return arr[0, :]
#         if arr.shape[0] == nf_expected:
#             return arr[:, 0]

#     raise ValueError(f"Unexpected frequency marginal shape: {arr.shape}")


# def extract_signal_component(arr: np.ndarray) -> np.ndarray:
#     """
#     Returns a 1D signal for component 0.

#     Handles:
#       - (nc, mt) -> arr[0, :]
#       - (mt, nc) -> arr[:, 0]
#       - (mt,)    -> arr
#     """
#     arr = np.asarray(arr)

#     if arr.ndim == 1:
#         return arr

#     if arr.ndim == 2:
#         # (nc, mt)
#         if arr.shape[0] <= arr.shape[1]:
#             return arr[0, :]
#         # (mt, nc)
#         return arr[:, 0]

#     raise ValueError(f"Unexpected signal shape: {arr.shape}")


# # ------------------------------------------------------------
# # Read control data
# # ------------------------------------------------------------
# input_dir, fig_dir, local_norm = get_args()

# h5file = input_dir / "results.h5"
# if not h5file.exists():
#     raise FileNotFoundError(f"HDF5 file not found: {h5file}")

# print("Reading HDF5...", flush=True)

# with h5py.File(h5file, "r") as f:
#     signal1_raw = f["S1"][:]
#     signal2_raw = f["S2"][:]

#     tfem_raw = f["TFEM"][:]
#     tfpm_raw = f["TFPM"][:]
#     tem_raw = f["TEM"][:]
#     tpm_raw = f["TPM"][:]
#     fem_raw = f["FEM"][:]
#     fpm_raw = f["FPM"][:]

#     dt = float(f["dt"][()])
#     fmin = float(f["fmin"][()])
#     fmax = float(f["fmax"][()])

# s1 = extract_signal_component(signal1_raw)
# s2 = extract_signal_component(signal2_raw)

# n = s1.shape[0]

# tfem = extract_tf_component(tfem_raw, n)
# tfpm = extract_tf_component(tfpm_raw, n)

# nfreq, n_from_tf = tfem.shape
# if n_from_tf != n:
#     raise ValueError(
#         f"Inconsistent time dimension: TF data has mt={n_from_tf}, "
#         f"but signal data has n={n}"
#     )

# tem = extract_time_marginal(tem_raw, n)
# tpm = extract_time_marginal(tpm_raw, n)
# fem = extract_freq_marginal(fem_raw, nfreq)
# fpm = extract_freq_marginal(fpm_raw, nfreq)

# if tfem_raw.ndim == 3:
#     if tfem_raw.shape[1] == n:
#         nc = tfem_raw.shape[0] if tfem_raw.shape[0] <= tfem_raw.shape[2] else tfem_raw.shape[2]
#     elif tfem_raw.shape[0] == n:
#         nc = tfem_raw.shape[2]
#     else:
#         nc = 1
# else:
#     nc = 1

# print(f"Loaded HDF5: raw TFEM shape={tfem_raw.shape}")
# print(f"Loaded HDF5: raw S1 shape={signal1_raw.shape}")
# print(f"Using component 1 -> TF shape = {tfem.shape}, nc = {nc}, n = {n}, nf = {nfreq}")
# print("Data read successfully. Ready to plot.")
# print("---------------------------------------------------")

# # ------------------------------------------------------------
# # Build axes coordinates
# # ------------------------------------------------------------
# time = np.arange(n) * dt
# freq = np.logspace(np.log10(fmin), np.log10(fmax), nfreq)

# t_sig = time

# # ------------------------------------------------------------
# # Convert to percent
# # ------------------------------------------------------------
# if not local_norm:
#     tfem *= 100.0
#     tfpm *= 100.0
#     fem *= 100.0
#     fpm *= 100.0
#     tem *= 100.0
#     tpm *= 100.0

# # ------------------------------------------------------------
# # Color normalization
# # ------------------------------------------------------------
# pct = 99.5

# tfem_vlim = np.nanpercentile(np.abs(tfem), pct)
# tfpm_vlim = np.nanpercentile(np.abs(tfpm), pct)

# if not np.isfinite(tfem_vlim) or tfem_vlim == 0:
#     tfem_vlim = 1.0
# if not np.isfinite(tfpm_vlim) or tfpm_vlim == 0:
#     tfpm_vlim = 1.0

# if not local_norm:
#     print(f"TFEM color limit = ±{tfem_vlim:.3g} %")
#     print(f"TFPM color limit = ±{tfpm_vlim:.3g} %")
# else:
#     print(f"TFEM color limit = ±{tfem_vlim:.3g}")
#     print(f"TFPM color limit = ±{tfpm_vlim:.3g}")

# print(f"LOCAL_NORM       = {local_norm}")

# if not local_norm:
#     shared_vlim = max(tfem_vlim, tfpm_vlim)
#     print(f"Shared color limit = ±{shared_vlim:.3g} %")

#     tfem_norm = SymLogNorm(
#         linthresh=max(1e-6, 0.05 * shared_vlim),
#         linscale=1.0,
#         vmin=-shared_vlim,
#         vmax=shared_vlim,
#         base=10
#     )
#     tfpm_norm = tfem_norm
# else:
#     tfem_norm = SymLogNorm(
#         linthresh=max(1e-6, 0.05 * tfem_vlim),
#         linscale=1.0,
#         vmin=-tfem_vlim,
#         vmax=tfem_vlim,
#         base=10
#     )

#     tfpm_norm = SymLogNorm(
#         linthresh=max(1e-6, 0.05 * tfpm_vlim),
#         linscale=1.0,
#         vmin=-tfpm_vlim,
#         vmax=tfpm_vlim,
#         base=10
#     )

# # ------------------------------------------------------------
# # Figure 4 layout
# # ------------------------------------------------------------
# fig = plt.figure(figsize=(8.4, 9.4))

# outer = fig.add_gridspec(
#     nrows=2,
#     ncols=1,
#     height_ratios=[1.18, 0.82],
#     hspace=0.11,
# )

# gs_top = outer[0].subgridspec(
#     nrows=3,
#     ncols=2,
#     width_ratios=[1.0, 8.0],
#     height_ratios=[3.5, 1.05, 1.45],
#     wspace=0.02,
#     hspace=0.04,
# )

# gs_bot = outer[1].subgridspec(
#     nrows=2,
#     ncols=2,
#     width_ratios=[1.0, 8.0],
#     height_ratios=[3.5, 1.05],
#     wspace=0.02,
#     hspace=0.04,
# )

# ax_fem  = fig.add_subplot(gs_top[0, 0])
# ax_tfem = fig.add_subplot(gs_top[0, 1], sharey=ax_fem)
# ax_tem  = fig.add_subplot(gs_top[1, 1], sharex=ax_tfem)
# ax_sig  = fig.add_subplot(gs_top[2, 1], sharex=ax_tfem)

# ax_fpm  = fig.add_subplot(gs_bot[0, 0], sharey=ax_fem)
# ax_tfpm = fig.add_subplot(gs_bot[0, 1], sharex=ax_tfem, sharey=ax_tfem)
# ax_tpm  = fig.add_subplot(gs_bot[1, 1], sharex=ax_tfem)

# # ------------------------------------------------------------
# # TF panels
# # ------------------------------------------------------------
# # Avoid Matplotlib warning with pcolormesh + grid
# ax_tfem.grid(False)
# ax_tfpm.grid(False)

# if not local_norm:
#     im1 = ax_tfem.pcolormesh(
#         time, freq, tfem,
#         shading="auto",
#         cmap="RdBu_r",
#         norm=tfem_norm
#     )

#     im2 = ax_tfpm.pcolormesh(
#         time, freq, tfpm,
#         shading="auto",
#         cmap="RdBu_r",
#         norm=tfpm_norm
#     )
# else:
#     im1 = ax_tfem.pcolormesh(
#         time, freq, tfem,
#         shading="auto",
#         cmap="bwr",
#         norm=tfem_norm
#     )

#     im2 = ax_tfpm.pcolormesh(
#         time, freq, tfpm,
#         shading="auto",
#         cmap="bwr",
#         norm=tfpm_norm
#     )

# # ------------------------------------------------------------
# # Left marginal frequency plots
# # ------------------------------------------------------------
# ax_fem.plot(fem, freq, color="k", lw=1.0)
# ax_fpm.plot(fpm, freq, color="k", lw=1.0)

# for ax in (ax_fem, ax_fpm):
#     ax.set_yscale("log")
#     ax.invert_xaxis()

#     ax.tick_params(
#         axis="y",
#         which="both",
#         left=True,
#         right=False,
#         labelleft=True,
#         labelright=False
#     )

#     ax.tick_params(
#         axis="x",
#         which="both",
#         top=True,
#         bottom=True
#     )

# # ------------------------------------------------------------
# # Main TF axes styling
# # ------------------------------------------------------------
# for ax in (ax_tfem, ax_tfpm):
#     ax.set_yscale("log")
#     ax.tick_params(axis="both", which="both", direction="in", top=True, right=True)
#     ax.tick_params(axis="y", labelleft=False, labelright=False)
#     ax.tick_params(axis="x", labelbottom=False)

# # Explicitly hide only TF-panel y tick labels
# plt.setp(ax_tfem.get_yticklabels(), visible=False)
# plt.setp(ax_tfpm.get_yticklabels(), visible=False)

# ax_fem.text(0.04, 0.90, r"$FEM$", transform=ax_fem.transAxes, fontsize=18)
# ax_tfem.text(0.98, 0.90, r"$TFEM$", transform=ax_tfem.transAxes,
#              ha="right", fontsize=18)

# ax_fpm.text(0.04, 0.90, r"$FPM$", transform=ax_fpm.transAxes, fontsize=18)
# ax_tfpm.text(0.98, 0.90, r"$TFPM$", transform=ax_tfpm.transAxes,
#              ha="right", fontsize=18)

# ax_fem.text(-0.62, 1.02, r"[Hz]", transform=ax_fem.transAxes, fontsize=18)
# ax_fpm.text(-0.62, 1.02, r"[Hz]", transform=ax_fpm.transAxes, fontsize=18)

# # ------------------------------------------------------------
# # Time marginals
# # ------------------------------------------------------------
# ax_tem.plot(time, tem, color="k", lw=1.0)
# ax_tpm.plot(time, tpm, color="k", lw=1.0)

# ax_tem.text(0.98, 0.72, r"$TEM$", transform=ax_tem.transAxes,
#             ha="right", fontsize=18)
# ax_tpm.text(0.98, 0.72, r"$TPM$", transform=ax_tpm.transAxes,
#             ha="right", fontsize=18)

# # Hide x tick labels on upper shared-x panels
# ax_tem.tick_params(axis="x", which="both", labelbottom=False)
# ax_sig.tick_params(axis="x", which="both", labelbottom=False)
# ax_tfem.tick_params(axis="x", which="both", labelbottom=False)
# ax_tfpm.tick_params(axis="x", which="both", labelbottom=False)

# # Show x tick labels explicitly on TPM
# ax_tpm.tick_params(
#     axis="x",
#     which="both",
#     direction="in",
#     top=True,
#     bottom=True,
#     labelbottom=True
# )
# plt.setp(ax_tpm.get_xticklabels(), visible=True)

# # ------------------------------------------------------------
# # Signal panel
# # ------------------------------------------------------------
# ax_sig.plot(t_sig, s1, color="red", lw=1.0)
# ax_sig.plot(t_sig, s2, color="black", lw=1.0)

# ax_sig.tick_params(axis="both", which="both", direction="in", top=True, right=True)
# ax_sig.set_xlabel(r"$[s]$", x=0.98, ha="right")
# ax_tpm.set_xlabel(r"$[s]$", x=0.98, ha="right")

# # ------------------------------------------------------------
# # Colorbar(s)
# # ------------------------------------------------------------
# if not local_norm:
#     cax = fig.add_axes([0.93, 0.30, 0.03, 0.40])
#     cb = fig.colorbar(im1, cax=cax)
#     cb.ax.text(0.0, -0.075, r"[\%]", transform=cb.ax.transAxes,
#                ha="left", va="top", fontsize=16)
# else:
#     cax1 = fig.add_axes([0.93, 0.56, 0.03, 0.26])
#     cb1 = fig.colorbar(im1, cax=cax1)
#     cb1.ax.set_title(r"$TFEM$", fontsize=14, pad=6)
#     cb1.ax.text(0.0, -0.075, r"[-]", transform=cb1.ax.transAxes,
#                 ha="left", va="top", fontsize=16)

#     cax2 = fig.add_axes([0.93, 0.18, 0.03, 0.26])
#     cb2 = fig.colorbar(im2, cax=cax2)
#     cb2.ax.set_title(r"$TFPM$", fontsize=14, pad=6)
#     cb2.ax.text(0.0, -0.075, r"[-]", transform=cb2.ax.transAxes,
#                 ha="left", va="top", fontsize=16)

# # Give a bit more room at the bottom so TPM labels are not clipped
# fig.subplots_adjust(bottom=0.08)

# output_path = fig_dir / f"tf_misfit_{input_dir.name}.png"
# fig.savefig(output_path, bbox_inches="tight", pad_inches=0.08, dpi=300)
# plt.close(fig)
# print(f"Figure saved to: {output_path}")

#!/usr/bin/env python3
import argparse
import shutil
import sys
from pathlib import Path
import h5py
import matplotlib.pyplot as plt
import numpy as np
from matplotlib.colors import SymLogNorm
import os

def _get_env_bool(name: str, default: bool) -> bool:
    value = os.getenv(name)
    if value is None:
        return default
    return value.strip().lower() in {"1", "true", "yes", "y"}

def _get_env_float(name: str, default=None):
    value = os.getenv(name)
    if value is None or value.strip() == "":
        return default
    return float(value)

def _get_env_str(name: str, default=""):
    value = os.getenv(name)
    return default if value is None else value

def _get_env_ylim(prefix: str):
    ymin = _get_env_float(f"{prefix}_YMIN", None)
    ymax = _get_env_float(f"{prefix}_YMAX", None)
    if ymin is None or ymax is None:
        return None
    return (ymin, ymax)


def parse_bool(value: str) -> bool:
    value = value.strip().lower()
    if value in {"true", "1", "yes", "y"}:
        return True
    if value in {"false", "0", "no", "n"}:
        return False
    raise ValueError(f"Invalid boolean value: {value}. Use true or false.")


def latex_available() -> bool:
    return shutil.which("latex") is not None


def configure_matplotlib(*, usetex: bool, style: str, dpi: int) -> bool:
    actual_usetex = usetex and latex_available()
    if usetex and not actual_usetex:
        print("Warning: LaTeX requested but not found. Falling back to non-TeX rendering.", flush=True)

    params = {
        "text.usetex": actual_usetex,
        "font.size": 16,
        "axes.labelsize": 18,
        "axes.titlesize": 18,
        "legend.fontsize": 14,
        "xtick.labelsize": 12,
        "ytick.labelsize": 12,
        "axes.linewidth": 1.0,
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
        "savefig.dpi": dpi,
        "savefig.pad_inches": 0.03,
    }

    if style == "publication":
        params.update(
            {
                "font.family": "serif",
                "axes.grid": True,
                "axes.grid.which": "both",
                "grid.color": "0.85",
                "grid.linestyle": "--",
                "grid.linewidth": 0.8,
            }
        )
        if actual_usetex:
            params["font.serif"] = ["TeX Gyre Schola"]
    else:
        params.update(
            {
                "font.family": "sans-serif",
                "axes.grid": True,
                "axes.grid.which": "both",
                "grid.color": "0.90",
                "grid.linestyle": ":",
                "grid.linewidth": 0.7,
            }
        )

    plt.rcParams.update(params)
    return actual_usetex


def get_args():
    parser = argparse.ArgumentParser(description="Plot TF misfit results from results.h5")
    parser.add_argument("input_dir", type=Path, help="Directory containing results.h5")
    parser.add_argument("fig_dir", type=Path, help="Directory where figures will be written")
    parser.add_argument("local_norm", type=parse_bool, help="Whether local normalization was used")
    parser.add_argument("--usetex", type=parse_bool, default=False, help="Use LaTeX text rendering")
    parser.add_argument(
        "--style",
        choices=["portable", "publication"],
        default="portable",
        help="Plot styling preset",
    )
    parser.add_argument("--dpi", type=int, default=300, help="Figure DPI")
    parser.add_argument(
        "--format",
        choices=["png", "pdf", "both"],
        default="png",
        help="Output figure format",
    )
    args = parser.parse_args()

    input_dir = args.input_dir.resolve()
    fig_dir = args.fig_dir.resolve()

    if not input_dir.exists():
        raise FileNotFoundError(f"Input directory does not exist: {input_dir}")

    fig_dir.mkdir(parents=True, exist_ok=True)
    return args, input_dir, fig_dir


def extract_tf_component(arr: np.ndarray, mt_expected: int) -> np.ndarray:
    arr = np.asarray(arr)

    if arr.ndim == 3:
        if arr.shape[1] == mt_expected:
            if arr.shape[0] == 1 or arr.shape[0] < arr.shape[2]:
                return arr[0, :, :].T
            return arr[:, :, 0]
        if arr.shape[0] == mt_expected:
            return arr[:, :, 0].T
        if arr.shape[2] == 1:
            return arr[:, :, 0]
        raise ValueError(f"Unexpected 3D TF array shape: {arr.shape}")

    if arr.ndim == 2:
        if arr.shape[1] == mt_expected:
            return arr
        if arr.shape[0] == mt_expected:
            return arr.T
        raise ValueError(f"Unexpected 2D TF array shape: {arr.shape}")

    raise ValueError(f"Unexpected TF array rank: {arr.ndim}")


def extract_time_marginal(arr: np.ndarray, mt_expected: int) -> np.ndarray:
    arr = np.asarray(arr)

    if arr.ndim == 1:
        if arr.shape[0] != mt_expected:
            raise ValueError(f"Unexpected time marginal shape: {arr.shape}")
        return arr

    if arr.ndim == 2:
        if arr.shape[1] == mt_expected:
            return arr[0, :]
        if arr.shape[0] == mt_expected:
            return arr[:, 0]
        raise ValueError(f"Unexpected time marginal shape: {arr.shape}")

    raise ValueError(f"Unexpected time marginal rank: {arr.ndim}")


def extract_freq_marginal(arr: np.ndarray, nf_expected: int) -> np.ndarray:
    arr = np.asarray(arr)

    if arr.ndim == 1:
        if arr.shape[0] != nf_expected:
            raise ValueError(f"Unexpected frequency marginal shape: {arr.shape}")
        return arr

    if arr.ndim == 2:
        if arr.shape[1] == nf_expected:
            return arr[0, :]
        if arr.shape[0] == nf_expected:
            return arr[:, 0]
        raise ValueError(f"Unexpected frequency marginal shape: {arr.shape}")

    raise ValueError(f"Unexpected frequency marginal rank: {arr.ndim}")


def extract_signal_component(arr: np.ndarray) -> np.ndarray:
    arr = np.asarray(arr)

    if arr.ndim == 1:
        return arr

    if arr.ndim == 2:
        if arr.shape[0] <= arr.shape[1]:
            return arr[0, :]
        return arr[:, 0]

    raise ValueError(f"Unexpected signal shape: {arr.shape}")


def read_required_dataset(h5file: h5py.File, name: str):
    if name not in h5file:
        raise KeyError(f"Missing HDF5 dataset '{name}' in file: {h5file.filename}")
    return h5file[name][:]


def save_figure(fig, outbase: Path, fmt: str):
    if fmt in {"png", "both"}:
        fig.savefig(outbase.with_suffix(".png"), bbox_inches="tight")
    if fmt in {"pdf", "both"}:
        fig.savefig(outbase.with_suffix(".pdf"), bbox_inches="tight")


def main():
    print("Starting Plot.py", flush=True)
    print("---------------------------------------------------")
    print(" Python script for plotting TFPM misfits ")

    args, input_dir, fig_dir = get_args()
    actual_usetex = configure_matplotlib(usetex=args.usetex, style=args.style, dpi=args.dpi)

    h5file = input_dir / "results.h5"
    if not h5file.exists():
        raise FileNotFoundError(f"HDF5 file not found: {h5file}")

    print("Reading HDF5...", flush=True)
    with h5py.File(h5file, "r") as f:
        signal1_raw = read_required_dataset(f, "S1")
        signal2_raw = read_required_dataset(f, "S2")
        tfem_raw = read_required_dataset(f, "TFEM")
        tfpm_raw = read_required_dataset(f, "TFPM")
        tem_raw = read_required_dataset(f, "TEM")
        tpm_raw = read_required_dataset(f, "TPM")
        fem_raw = read_required_dataset(f, "FEM")
        fpm_raw = read_required_dataset(f, "FPM")

        for scalar_name in ("dt", "fmin", "fmax"):
            if scalar_name not in f:
                raise KeyError(f"Missing HDF5 scalar '{scalar_name}' in file: {h5file}")

        dt = float(f["dt"][()])
        fmin = float(f["fmin"][()])
        fmax = float(f["fmax"][()])

    s1 = extract_signal_component(signal1_raw)
    s2 = extract_signal_component(signal2_raw)
    n = s1.shape[0]

    tfem = extract_tf_component(tfem_raw, n)
    tfpm = extract_tf_component(tfpm_raw, n)
    nfreq, n_from_tf = tfem.shape

    if n_from_tf != n:
        raise ValueError(
            f"Inconsistent time dimension: TF data has mt={n_from_tf}, but signal data has n={n}"
        )

    tem = extract_time_marginal(tem_raw, n)
    tpm = extract_time_marginal(tpm_raw, n)
    fem = extract_freq_marginal(fem_raw, nfreq)
    fpm = extract_freq_marginal(fpm_raw, nfreq)

    t = np.arange(n) * dt
    freqs = np.geomspace(fmin, fmax, nfreq)

    print(f"Using style={args.style}, usetex={actual_usetex}, format={args.format}, dpi={args.dpi}")
    print(f"Loaded results: n={n}, nf={nfreq}, local_norm={args.local_norm}", flush=True)

    window_label = _get_env_str("TFMISFIT_WINDOW_LABEL", "")
    window_start = _get_env_float("TFMISFIT_WINDOW_START", None)
    window_end = _get_env_float("TFMISFIT_WINDOW_END", None)
    use_global_time = _get_env_bool("TFMISFIT_USE_GLOBAL_TIME", True)

    signals_ylim = _get_env_ylim("TFMISFIT_SIGNALS")
    tem_ylim = _get_env_ylim("TFMISFIT_TEM")
    tpm_ylim = _get_env_ylim("TFMISFIT_TPM")
    fem_ylim = _get_env_ylim("TFMISFIT_FEM")
    fpm_ylim = _get_env_ylim("TFMISFIT_FPM")

    tfem_vmin = _get_env_float("TFMISFIT_TFEM_VMIN", None)
    tfem_vmax = _get_env_float("TFMISFIT_TFEM_VMAX", None)
    tfpm_vmin = _get_env_float("TFMISFIT_TFPM_VMIN", None)
    tfpm_vmax = _get_env_float("TFMISFIT_TFPM_VMAX", None)

    # Figure 1: signals + time marginals
    # window_label = _get_env_str("TFMISFIT_WINDOW_LABEL", "")
    # window_start = _get_env_float("TFMISFIT_WINDOW_START", None)
    # window_end = _get_env_float("TFMISFIT_WINDOW_END", None)
    # use_global_time = _get_env_bool("TFMISFIT_USE_GLOBAL_TIME", True)

    # signals_ylim = _get_env_ylim("TFMISFIT_SIGNALS")
    # # tem_ylim = _get_env_ylim("TFMISFIT_TEM")
    # # tpm_ylim = _get_env_ylim("TFMISFIT_TPM")
    # tem_ylim=(-1,1)
    # tpm_ylim=(-1,1)

    # fig1, axs = plt.subplots(3, 1, figsize=(11, 9), constrained_layout=True)


    # axs[0].plot(t, s1, label="S1")
    # axs[0].plot(t, s2, label="S2")
    # axs[0].set_xlabel("Time [s]")
    # axs[0].set_ylabel("Amplitude")
    # axs[0].set_title("Signals")
    # axs[0].legend()

    # axs[1].plot(t, tem)
    # axs[1].set_xlabel("Time [s]")
    # axs[1].set_ylabel("TEM")
    # axs[1].set_title("Time-dependent envelope misfit")

    # axs[2].plot(t, tpm)
    # axs[2].set_xlabel("Time [s]")
    # axs[2].set_ylabel("TPM")
    # axs[2].set_title("Time-dependent phase misfit")

    # save_figure(fig1, fig_dir / "signals_time_marginals", args.format)
    # plt.close(fig1)

    fig, axs = plt.subplots(
        3, 1,
        figsize=(11, 8.5),
        sharex=True,
        gridspec_kw={"height_ratios": [1.0, 1.15, 1.15]}
    )

    # Assume time array is t
    # If your current variable is called something else, use that instead.
    if use_global_time and window_start is not None:
        x = t + window_start
        xlabel = "Global simulation time [s]"
    else:
        x = t
        xlabel = "Local time in window [s]"

    # Top panel: signals
    axs[0].plot(x, s1, label="S1", linewidth=1.8)
    axs[0].plot(x, s2, label="S2", linewidth=1.8)
    axs[0].set_ylabel("Amplitude", fontsize=16)
    axs[0].set_title("Signals", fontsize=18)
    axs[0].legend(fontsize=13)
    axs[0].tick_params(labelsize=13)
    if signals_ylim is not None:
        axs[0].set_ylim(*signals_ylim)

    # Middle panel: TEM
    axs[1].plot(x, tem, linewidth=1.8)
    axs[1].set_ylabel("TEM", fontsize=16)
    axs[1].set_title("Envelope misfit (TEM)", fontsize=18)
    axs[1].tick_params(labelsize=13)
    if tem_ylim is not None:
        axs[1].set_ylim(*tem_ylim)

    # Bottom panel: TPM
    axs[2].plot(x, tpm, linewidth=1.8)
    axs[2].set_ylabel("TPM", fontsize=16)
    axs[2].set_title("Phase misfit (TPM)", fontsize=18)
    axs[2].set_xlabel(xlabel, fontsize=16)
    axs[2].tick_params(labelsize=13)
    if tpm_ylim is not None:
        axs[2].set_ylim(*tpm_ylim)

    # Shared x-labels on all panels if you prefer
    axs[0].set_xlabel(xlabel, fontsize=16)
    axs[1].set_xlabel(xlabel, fontsize=16)

    for ax in axs:
        ax.grid(True, alpha=0.25)

    if window_label:
        fig.suptitle(
            f"Signal time marginals — {window_label}",
            fontsize=20,
            y=0.98
        )

    fig.tight_layout(rect=[0, 0, 1, 0.96])
    save_figure(fig, fig_dir / "signals_time_marginals", args.format)
    plt.close(fig)

    # # Figure 2: frequency marginals
    # fig2, axs = plt.subplots(2, 1, figsize=(9, 8), constrained_layout=True)

    # axs[0].plot(freqs, fem)
    # axs[0].set_xscale("log")
    # axs[0].set_xlabel("Frequency [Hz]")
    # axs[0].set_ylabel("FEM")
    # axs[0].set_title("Frequency-dependent envelope misfit")

    # axs[1].plot(freqs, fpm)
    # axs[1].set_xscale("log")
    # axs[1].set_xlabel("Frequency [Hz]")
    # axs[1].set_ylabel("FPM")
    # axs[1].set_title("Frequency-dependent phase misfit")

    # save_figure(fig2, fig_dir / "frequency_marginals", args.format)
    # plt.close(fig2)

    fig, axs = plt.subplots(
        2, 1,
        figsize=(11, 6.8),
        sharex=True,
        gridspec_kw={"height_ratios": [1.0, 1.0]}
    )

    freq = np.linspace(fmin, fmax, len(fem))

    axs[0].plot(freq, fem, linewidth=1.8)
    axs[0].set_xscale("log")
    axs[0].set_ylabel("FEM", fontsize=16)
    axs[0].set_title("Frequency marginal — envelope misfit (FEM)", fontsize=18)
    axs[0].tick_params(labelsize=13)
    axs[0].axhline(0.0, linewidth=1.0, alpha=0.4)
    if fem_ylim is not None:
        axs[0].set_ylim(*fem_ylim)

    axs[1].plot(freq, fpm, linewidth=1.8)
    axs[1].set_xscale("log")
    axs[1].set_ylabel("FPM", fontsize=16)
    axs[1].set_xlabel("Frequency [Hz]", fontsize=16)
    axs[1].set_title("Frequency marginal — phase misfit (FPM)", fontsize=18)
    axs[1].tick_params(labelsize=13)
    axs[1].axhline(0.0, linewidth=1.0, alpha=0.4)
    if fpm_ylim is not None:
        axs[1].set_ylim(*fpm_ylim)

    for ax in axs:
        ax.grid(True, alpha=0.25)
        ax.set_xlim(fmin, fmax)

    if window_label:
        fig.suptitle(f"Frequency marginals — {window_label}", fontsize=20, y=0.98)

    fig.tight_layout(rect=[0, 0, 1, 0.95])
    save_figure(fig, fig_dir / "frequency_marginals", args.format)
    plt.close(fig)

    # Figure 3: time-frequency maps
    # fig3, axs = plt.subplots(2, 1, figsize=(12, 9), constrained_layout=True)

    # im1 = axs[0].pcolormesh(
    #     t,
    #     freqs,
    #     tfem,
    #     shading="auto",
    #     norm=SymLogNorm(linthresh=1e-3, vmin=np.nanmin(tfem), vmax=np.nanmax(tfem)),
    # )
    # axs[0].set_yscale("log")
    # axs[0].set_xlabel("Time [s]")
    # axs[0].set_ylabel("Frequency [Hz]")
    # axs[0].set_title("TFEM")
    # fig3.colorbar(im1, ax=axs[0], label="TFEM")

    # im2 = axs[1].pcolormesh(
    #     t,
    #     freqs,
    #     tfpm,
    #     shading="auto",
    #     norm=SymLogNorm(linthresh=1e-3, vmin=np.nanmin(tfpm), vmax=np.nanmax(tfpm)),
    # )
    # axs[1].set_yscale("log")
    # axs[1].set_xlabel("Time [s]")
    # axs[1].set_ylabel("Frequency [Hz]")
    # axs[1].set_title("TFPM")
    # fig3.colorbar(im2, ax=axs[1], label="TFPM")

    # save_figure(fig3, fig_dir / "tf_maps", args.format)
    # plt.close(fig3)

    fig, axs = plt.subplots(
        2, 1,
        figsize=(11.5, 8.2),
        sharex=True,
        sharey=True,
        gridspec_kw={"height_ratios": [1.0, 1.0]}
    )

    if use_global_time and window_start is not None:
        t_plot = t + window_start
        x_label = "Global simulation time [s]"
        tmin_plot = window_start if window_start is not None else t_plot[0]
        tmax_plot = window_end if window_end is not None else t_plot[-1]
    else:
        t_plot = t
        x_label = "Local time in window [s]"
        tmin_plot = t_plot[0]
        tmax_plot = t_plot[-1]

    freq = np.linspace(fmin, fmax, tfem.shape[0])

    im0 = axs[0].imshow(
        tfem,
        origin="lower",
        aspect="auto",
        extent=[tmin_plot, tmax_plot, fmin, fmax],
        vmin=tfem_vmin,
        vmax=tfem_vmax,
    )

    axs[0].set_ylabel("Frequency [Hz]", fontsize=16)
    axs[0].set_title("Time-frequency envelope misfit (TFEM)", fontsize=18)
    axs[0].tick_params(labelsize=13)

    im1 = axs[1].imshow(
        tfpm,
        origin="lower",
        aspect="auto",
        extent=[tmin_plot, tmax_plot, fmin, fmax],
        vmin=tfpm_vmin,
        vmax=tfpm_vmax,
    )

    axs[1].set_ylabel("Frequency [Hz]", fontsize=16)
    axs[1].set_xlabel(x_label, fontsize=16)
    axs[1].set_title("Time-frequency phase misfit (TFPM)", fontsize=18)
    axs[1].tick_params(labelsize=13)

    for ax in axs:
        ax.set_xlim(tmin_plot, tmax_plot)
        ax.set_ylim(fmin, fmax)

    cbar0 = fig.colorbar(im0, ax=axs[0], pad=0.015)
    cbar0.ax.tick_params(labelsize=12)
    cbar0.set_label("TFEM", fontsize=14)

    cbar1 = fig.colorbar(im1, ax=axs[1], pad=0.015)
    cbar1.ax.tick_params(labelsize=12)
    cbar1.set_label("TFPM", fontsize=14)

    if window_label:
        fig.suptitle(f"Time-frequency maps — {window_label}", fontsize=20, y=0.98)

    fig.tight_layout(rect=[0, 0, 1, 0.95])
    save_figure(fig, fig_dir / "tf_maps", args.format)
    plt.close(fig)

    print(f"Figures written to: {fig_dir}", flush=True)


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        print(f"Plot.py failed: {exc}", file=sys.stderr, flush=True)
        raise