import numpy as np
import matplotlib.pyplot as plt
from matplotlib.colors import ListedColormap


print("---------------------------------------------------")
print("       Python script for plotting TFEM misfits      ")


def read_misfit_file(filename="MISFIT-GOF.DAT"):
    """
    Read MISFIT-GOF.DAT written by the Fortran/Julia code.

    Expected structure:
        line 1: FMIN FMAX
        line 2: NF_TF MT
        line 3: DT NC
        line 4: ...
        ...
        after EM/PM and GOF lines:
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

    # In the original MATLAB indexing:
    # TFEMmax = MISFIT(7+4*nc+1)
    # TFPMmax = MISFIT(7+4*nc+2)
    #
    # With 0-based Python line indexing and the actual file structure:
    # line 0: FMIN FMAX
    # line 1: NF_TF MT
    # line 2: DT NC
    # line 3: max(abs(S))
    # lines 4..(4+nc-1): EM PM
    # lines ... next nc lines: GOF(EM) GOF(PM)
    # next four lines:
    #   TFEMmax TFPMmax
    #   FEMmax  FPMmax
    #   TEMmax  TPMmax
    #   CWT1max CWT2max
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
    data = np.fromfile(filename, sep=' ')
    if data.size != nrows * ncols:
        raise ValueError(
            f"{filename}: found {data.size} values, expected {nrows*ncols}"
        )
    return data.reshape((nrows, ncols))


# ============================================================
# Load colormap
# Equivalent to MATLAB: cmap=load('jet_modn');
# Assumes Nx3 RGB text file
# ============================================================
cmap_file = True
if cmap_file:
    cmap_data = np.loadtxt("jet_modn")
    if cmap_data.max() > 1.0:
        cmap_data = cmap_data / 255.0
    cmap = ListedColormap(cmap_data)
else: 
    cmap = plt.get_cmap("RdBu_r")

# ============================================================
# Read control data
# ============================================================
misfit = read_misfit_file("MISFIT-GOF.DAT")

fmin = misfit["fmin_log"]
fmax = misfit["fmax_log"]
nfreq = misfit["nfreq"]
n = misfit["n"]
dt = misfit["dt"]
nc = misfit["nc"]
tfem_max = misfit["tfem_max"]
tfpm_max = misfit["tfpm_max"]

col_max = (np.floor(tfem_max * 100.0) + 1.0) / 100.0
col_max_tic = (np.floor(tfem_max * 10.0) - 1.0) / 10.0

# For locally normalized TFEM, col_max would instead be computed
# after reading each TFEMk.DAT file.

df = (fmax - fmin) / (nfreq - 1)

xmin = 0.0
xmax = dt * (n - 1)
ymin = fmin
ymax = fmax

# ============================================================
# Time ticks
# ============================================================
dx = np.arange(xmin, xmax + 1e-12, 2.0)

# ============================================================
# Frequency ticks
# ============================================================
y_lin = np.concatenate([
    np.arange(0.1, 1.0, 0.1),
    np.arange(1.0, 10.0, 1.0),
    np.arange(10.0, 60.0, 10.0),
])
dy = np.log10(y_lin)
dy_labels = [
    "0.1", "", "", "0.4", "", "", "", "", "",
    "1", "2", "", "", "", "", "", "", "",
    "10", "", "", "", "50"
]

# ============================================================
# Frequency and time vectors
# ============================================================
freq = ymin + np.arange(nfreq) * df
time = xmin + dt * np.arange(n)

# ============================================================
# Plot each component
# ============================================================
for k in range(1, nc + 1):
    fname = f"TFEM{k}.DAT"

    data = np.fromfile(fname, sep=' ')
    expected_size = nfreq * n
    if data.size != expected_size:
        raise ValueError(
            f"{fname} contains {data.size} values, but expected {expected_size}"
        )

    # tfa = data.reshape((nfreq, n))
    tfa = read_fortran_matrix(fname, nfreq, n)

    levels = np.arange(-col_max, col_max + col_max / 20.0, col_max / 20.0)

    plt.figure(figsize=(8, 6))
    cf = plt.contourf(time, freq, tfa, levels=levels, cmap=cmap)
    for coll in cf.collections:
        coll.set_edgecolor("none")

    plt.clim(-col_max, col_max)

    ax = plt.gca()
    ax.set_xticks(dx)
    ax.set_xticklabels([f"{x:g}" for x in dx])
    ax.tick_params(direction="out")
    ax.set_yticks(dy)
    ax.set_yticklabels(dy_labels)

    ax.set_xlim(xmin, xmax)
    ax.set_ylim(ymin, ymax)
    ax.set_xlabel("time [s]", fontsize=12)
    ax.set_ylabel("frequency [Hz]", fontsize=12)
    ax.tick_params(labelsize=8)

    cbar = plt.colorbar()
    cbar_ticks = np.arange(
        -col_max_tic,
        col_max_tic + col_max_tic / 4.0,
        col_max_tic / 4.0
    )
    cbar.set_ticks(cbar_ticks)
    cbar.set_ticklabels([f"{100.0 * x:g}" for x in cbar_ticks])
    cbar.set_label("[%]", fontsize=12)

    fig_name = f"TFEM{k}.png"
    plt.savefig(fig_name, dpi=300, bbox_inches="tight")
    plt.close()