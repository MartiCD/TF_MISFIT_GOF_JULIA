#!/usr/bin/env python3

import sys
from pathlib import Path

import numpy as np
import pandas as pd
from scipy.interpolate import interp1d


# ------------------------------------------------------------
# User configuration
# ------------------------------------------------------------
VAR = 1                  # column index in CSV after the time column
X_PROBE = 0.22572455617737594
F0 = 10.0

# Analytical periodic Ricker parameters
E0 = 1.0
X0 = 0.5
C = 1.0
L = 1.0

# Export window
# Set T_START = None to use the first available time in the CSV.
# Set T_END   = None to use the last available time in the CSV.
T_START = 0.0
T_END = 10.0

# Target sampling.
# If DT_TARGET is None, the script uses the numerical sampling step.
DT_TARGET = None

# Interpolation kind for the numerical signal
INTERP_KIND = "linear"

# Output names inside the destination folder
SIGNAL1_NAME = "signal1.dat"
SIGNAL2_NAME = "signal2.dat"
WRITE_AUXILIARY_INPUT_FILE = True
AUXILIARY_INPUT_NAME = "HF_TF-MISFIT_GOF"
IS_S2_REFERENCE = True


# ------------------------------------------------------------
# Helpers
# ------------------------------------------------------------
def parse_bool(value: str) -> bool:
    value = value.strip().lower()
    if value in {"true", "1", "yes", "y"}:
        return True
    if value in {"false", "0", "no", "n"}:
        return False
    raise ValueError(f"Invalid boolean value: {value}. Use true or false.")


def get_args():
    if len(sys.argv) != 4:
        print("Usage: python3 build_tf_misfit_signals.py OUTPUT_FILE INPUT_CSV LOCAL_NORM")
        print("Example:")
        print(
            "  python3 build_tf_misfit_signals.py "
            "runs/test/work/HF_TF-MISFIT_GOF "
            "data/probe_signal_10f0_up_P4_Q5_CFL1.0.csv "
            "false"
        )
        sys.exit(1)

    output_file = Path(sys.argv[1]).expanduser().resolve()
    input_csv = Path(sys.argv[2]).expanduser().resolve()
    local_norm = parse_bool(sys.argv[3])

    output_file.parent.mkdir(parents=True, exist_ok=True)

    if not input_csv.exists():
        raise FileNotFoundError(f"Input CSV does not exist: {input_csv}")
    if not input_csv.is_file():
        raise FileNotFoundError(f"Input CSV is not a file: {input_csv}")

    return output_file, input_csv, local_norm


def ricker_Ez_exact_periodic(t, x_probe, *, E0=1.0, f0=10.0, x0=0.5, c=1.0, L=1.0):
    """
    Analytical periodic Ez trace at the probe location.
    This matches the analytical reference used in the original script.
    """
    xc = (x0 + c * t) % L
    dx = ((x_probe - xc + 0.5 * L) % L) - 0.5 * L
    arg = np.pi * f0 * dx
    return E0 * (1.0 - 2.0 * arg**2) * np.exp(-arg**2)


def analytic_reference_trace(tout: np.ndarray) -> np.ndarray:
    return ricker_Ez_exact_periodic(
        tout,
        X_PROBE,
        E0=E0,
        f0=F0,
        x0=X0,
        c=C,
        L=L,
    )


def load_probe_signal(input_csv: Path, var: int):
    """
    Load the full numerical probe signal from CSV.

    The CSV is assumed to contain:
      column 0   -> time
      column VAR -> selected signal component/value
    """
    fname = input_csv

    df = pd.read_csv(fname, usecols=[0, var], dtype=np.float64, engine="c")
    time = df.iloc[:, 0].to_numpy()
    signal = df.iloc[:, 1].to_numpy()

    if len(time) < 2:
        raise ValueError(f"Not enough rows in file: {fname}")

    # Make sure time is strictly increasing.
    sort_idx = np.argsort(time)
    time = time[sort_idx]
    signal = signal[sort_idx]

    # Drop duplicate times if any.
    keep = np.concatenate(([True], np.diff(time) > 0.0))
    time = time[keep]
    signal = signal[keep]

    if len(time) < 2:
        raise ValueError(f"Not enough unique time samples in file: {fname}")

    return fname, time, signal


def build_uniform_grid(t_start: float, t_end: float, dt: float) -> np.ndarray:
    if dt <= 0.0:
        raise ValueError("dt must be positive")
    if t_end < t_start:
        raise ValueError("t_end must be >= t_start")

    mt = int(np.floor((t_end - t_start) / dt)) + 1
    tout = t_start + dt * np.arange(mt, dtype=np.float64)

    # Guard against tiny floating-point overshoots.
    tout = tout[tout <= t_end + 1e-12]
    return tout


def interpolate_to_grid(
    time_src: np.ndarray,
    signal_src: np.ndarray,
    time_dst: np.ndarray,
    kind: str = "linear",
) -> np.ndarray:
    f = interp1d(
        time_src,
        signal_src,
        kind=kind,
        bounds_error=False,
        fill_value=np.nan,
        assume_sorted=True,
    )
    return f(time_dst)


def write_signal_file(path: Path, time: np.ndarray, signal: np.ndarray) -> None:
    data = np.column_stack([time, signal])
    np.savetxt(path, data, fmt="%.16e")


def write_auxiliary_input_file(
    path: Path,
    signal1_name: str,
    signal2_name: str,
    mt: int,
    dt: float,
    local_norm: bool,
) -> None:
    fmin_default = 1.0 / (mt * dt)
    fmax_default = 1.0 / (2.0 * dt)

    text = f"""&INPUT
  S1_NAME = '{signal1_name}',
  S2_NAME = '{signal2_name}',
  NC = 1,
  MT = {mt},
  DT = {dt:.16e},
  FMIN = {fmin_default:.16e},
  FMAX = {fmax_default:.16e},
  IS_S2_REFERENCE = {'.TRUE.' if IS_S2_REFERENCE else '.FALSE.'},
  LOCAL_NORM = {'.TRUE.' if local_norm else '.FALSE.'}
/
"""
    path.write_text(text, encoding="utf-8")


# ------------------------------------------------------------
# Main
# ------------------------------------------------------------
def main():
    output_file, input_csv, local_norm = get_args()

    outdir = output_file.parent
    outdir.mkdir(parents=True, exist_ok=True)

    fname, time_num_raw, signal_num_raw = load_probe_signal(input_csv, VAR)

    dt_num = float(np.median(np.diff(time_num_raw)))
    t_available_start = float(time_num_raw[0])
    t_available_end = float(time_num_raw[-1])

    t_start = t_available_start if T_START is None else max(float(T_START), t_available_start)
    t_end = t_available_end if T_END is None else min(float(T_END), t_available_end)

    if t_end <= t_start:
        raise ValueError(
            f"Invalid export interval: [{t_start}, {t_end}]. "
            f"Available numerical range is [{t_available_start}, {t_available_end}]."
        )

    dt_target = dt_num if DT_TARGET is None else float(DT_TARGET)
    tout = build_uniform_grid(t_start, t_end, dt_target)

    signal1 = interpolate_to_grid(time_num_raw, signal_num_raw, tout, kind=INTERP_KIND)
    signal2 = analytic_reference_trace(tout)

    if np.isnan(signal1).any():
        bad = np.count_nonzero(np.isnan(signal1))
        raise ValueError(
            f"Interpolated numerical signal contains {bad} NaN values. "
            "Choose a smaller export interval or check the source CSV."
        )

    mt = len(tout)
    dt_out = float(tout[1] - tout[0]) if mt >= 2 else dt_target
    t0_out = float(tout[0])

    signal1_path = outdir / SIGNAL1_NAME
    signal2_path = outdir / SIGNAL2_NAME
    aux_path = output_file

    write_signal_file(signal1_path, tout, signal1)
    write_signal_file(signal2_path, tout, signal2)

    if WRITE_AUXILIARY_INPUT_FILE:
        write_auxiliary_input_file(
            aux_path,
            SIGNAL1_NAME,
            SIGNAL2_NAME,
            mt,
            dt_out,
            local_norm,
        )
    else:
        aux_path = None

    print("---------------------------------------------------")
    print("TF_MISFIT_GOF input files created successfully")
    print(f"Source CSV        : {fname}")
    print(f"LOCAL_NORM        : {local_norm}")
    print(f"Output directory  : {outdir}")
    print(f"signal1.dat       : {signal1_path}")
    print(f"signal2.dat       : {signal2_path}")
    if aux_path is not None:
        print(f"Auxiliary input   : {aux_path}")
    print(f"MT                : {mt}")
    print(f"DT                : {dt_out:.16e}")
    print(f"Initial time      : {t0_out:.16e}")
    print(f"Final time        : {tout[-1]:.16e}")
    print("signal1.dat = interpolated numerical signal")
    print("signal2.dat = analytical reference signal")


if __name__ == "__main__":
    main()