#!/usr/bin/env python3
import argparse
from pathlib import Path

import numpy as np
import pandas as pd
from scipy.interpolate import interp1d

# ------------------------------------------------------------
# User configuration
# ------------------------------------------------------------
VAR = 1  # column index in CSV after the time column
X_PROBE = 0.22572455617737594
F0 = 10.0

# Analytical periodic Ricker parameters
E0 = 1.0
X0 = 0.5
C = 1.0
L = 1.0

# Defaults for optional CLI arguments
DEFAULT_T_START = None
DEFAULT_T_END = None
DEFAULT_DT_TARGET = None

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


def parse_args():
    parser = argparse.ArgumentParser(
        description="Build TF_MISFIT_GOF input files from a numerical CSV signal."
    )
    parser.add_argument(
        "output_file",
        type=Path,
        help="Path to the generated HF_TF-MISFIT_GOF file.",
    )
    parser.add_argument(
        "input_csv",
        type=Path,
        help="Path to the source CSV file containing the numerical signal.",
    )
    parser.add_argument(
        "local_norm",
        type=parse_bool,
        help="true or false",
    )
    parser.add_argument(
        "--t-start",
        type=float,
        default=DEFAULT_T_START,
        help="Start time of exported window. Defaults to first available CSV time.",
    )
    parser.add_argument(
        "--t-end",
        type=float,
        default=DEFAULT_T_END,
        help="End time of exported window. Defaults to last available CSV time.",
    )
    parser.add_argument(
        "--dt-target",
        type=float,
        default=DEFAULT_DT_TARGET,
        help="Optional output time step. Defaults to numerical sampling step.",
    )

    args = parser.parse_args()

    output_file = args.output_file.expanduser().resolve()
    input_csv = args.input_csv.expanduser().resolve()

    output_file.parent.mkdir(parents=True, exist_ok=True)

    if not input_csv.exists():
        raise FileNotFoundError(f"Input CSV does not exist: {input_csv}")
    if not input_csv.is_file():
        raise FileNotFoundError(f"Input CSV is not a file: {input_csv}")

    return output_file, input_csv, args.local_norm, args.t_start, args.t_end, args.dt_target


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
      column 0 -> time column
      VAR      -> selected signal component/value
    """
    fname = input_csv
    df = pd.read_csv(fname, usecols=[0, var], dtype=np.float64, engine="c")
    time = df.iloc[:, 0].to_numpy()
    signal = df.iloc[:, 1].to_numpy()

    if len(time) < 2:
        raise ValueError(f"Not enough rows in file: {fname}")

    sort_idx = np.argsort(time)
    time = time[sort_idx]
    signal = signal[sort_idx]

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
    output_file, input_csv, local_norm, t_start_arg, t_end_arg, dt_target_arg = parse_args()

    outdir = output_file.parent
    outdir.mkdir(parents=True, exist_ok=True)

    fname, time_num_raw, signal_num_raw = load_probe_signal(input_csv, VAR)

    dt_num = float(np.median(np.diff(time_num_raw)))
    t_available_start = float(time_num_raw[0])
    t_available_end = float(time_num_raw[-1])

    t_start = t_available_start if t_start_arg is None else max(float(t_start_arg), t_available_start)
    t_end = t_available_end if t_end_arg is None else min(float(t_end_arg), t_available_end)

    if t_end <= t_start:
        raise ValueError(
            f"Invalid export interval: [{t_start}, {t_end}]. "
            f"Available numerical range is [{t_available_start}, {t_available_end}]."
        )

    dt_target = dt_num if dt_target_arg is None else float(dt_target_arg)
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
    print(f"Window start      : {t_start:.16e}")
    print(f"Window end        : {t_end:.16e}")
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