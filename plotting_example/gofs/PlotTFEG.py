import numpy as np
import matplotlib.pyplot as plt
from matplotlib.colors import ListedColormap


print("---------------------------------------------------")
print("     Python script for plotting TF envelope GOFs   ")

# ============================================================
# Load colormap
# Equivalent to MATLAB: cmap = load('gof_cmap10_2');
# Assumes the file contains an Nx3 array of RGB values
# ============================================================
cmap_file = True
if cmap_file:
    cmap_data = np.loadtxt("gof_cmap10_2")

    # If colors are in 0-255 range, rescale to 0-1
    if cmap_data.max() > 1.0:
        cmap_data = cmap_data / 255.0

    cmap = ListedColormap(cmap_data)
else:
    cmap = plt.get_cmap("RdBu_r")


# ============================================================
# Read control data from MISFIT-GOF.DAT
# ============================================================
# misfit = np.loadtxt("MISFIT-GOF.DAT").flatten()

# fmin = np.log10(misfit[0])
# fmax = np.log10(misfit[1])
# nfreq = int(misfit[2])
# n = int(misfit[3])
# dt = misfit[4]
# nc = int(misfit[5])  # number of components
with open("MISFIT-GOF.DAT", "r") as f:
    lines = [line.strip() for line in f if line.strip()]

# Parse exactly like Fortran writes it
fmin_val, fmax_val = map(float, lines[0].split())
nfreq, n = map(int, lines[1].split())
dt, nc = map(float, lines[2].split())

# Convert
fmin = np.log10(fmin_val)
fmax = np.log10(fmax_val)
nc = int(nc)

col_max = 10.0
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
    np.arange(10.0, 60.0, 10.0)
])

dy = np.log10(y_lin)

dy_labels = [
    "0.1", "", "", "0.4", "", "", "", "", "",
    "1", "2", "", "", "", "", "", "", "",
    "10", "", "", "", "50"
]

# ============================================================
# Frequency and time vectors for plotting
# ============================================================
freq = ymin + np.arange(nfreq) * df
time = xmin + dt * np.arange(n)

# ============================================================
# Plot each component
# ============================================================
for k in range(1, nc + 1):
    fname = f"TFEG{k}.DAT"

    # MATLAB reads one row per frequency:
    # for i=1:NFREQ
    #   a=fscanf(fid,'%g',[1 N]);
    #   tfa(i,:)=a;
    # end
    tfa = np.loadtxt(fname)

    # Ensure shape is (NFREQ, N)
    if tfa.shape != (nfreq, n):
        raise ValueError(
            f"{fname} has shape {tfa.shape}, but expected ({nfreq}, {n})"
        )

    plt.figure(figsize=(8, 6))

    levels = np.arange(0, 11, 1)

    cf = plt.contourf(time, freq, tfa, levels=levels, cmap=cmap)
    for coll in cf.collections:
        coll.set_edgecolor("none")

    plt.contour(time, freq, tfa, levels=[4, 6, 8], colors="k", linewidths=0.8)

    plt.clim(0, col_max)

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

    plt.colorbar()

    fig_name = f"TFEG{k}.png"
    plt.savefig(fig_name, dpi=300, bbox_inches="tight")
    plt.close()