#!/usr/bin/env bash
set -euo pipefail

INPUT_CSV="probe_ricker_wavelet.csv"
LOCAL_NORM="${1:-false}"

case "${LOCAL_NORM,,}" in
  true|false) ;;
  *)
    echo "Usage: $0 [true|false]"
    exit 1
    ;;
esac

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUNS_DIR="$BASE_DIR/runs"
DATA_DIR="$BASE_DIR/data"
INPUT_CSV_PATH="$DATA_DIR/$INPUT_CSV"

mkdir -p "$RUNS_DIR"

DATE="$(date +%F)"
i=1

while true; do
    RUN_NAME=$(printf "%s_%03d" "$DATE" "$i")
    RUN_DIR="$RUNS_DIR/$RUN_NAME"

    if [ ! -d "$RUN_DIR" ]; then
        break
    fi

    ((i++))
done
RUN_DIR="$RUNS_DIR/$RUN_NAME"

WORK_DIR="$RUN_DIR/work"
FIG_DIR="$RUN_DIR/figures"
LOG_DIR="$RUN_DIR/logs"

mkdir -p "$WORK_DIR" "$FIG_DIR" "$LOG_DIR"

INPUT_PATH="$WORK_DIR/HF_TF-MISFIT_GOF"

echo "Running pipeline with run name: $RUN_NAME"
echo "Work directory: $WORK_DIR"
echo "Figures directory: $FIG_DIR"
echo "Logs directory: $LOG_DIR"

echo "Running pipeline..."
echo "Pre-process..."
python3 "$BASE_DIR/scripts/build_tf_misfit_signals.py" "$INPUT_PATH" "$INPUT_CSV_PATH" "$LOCAL_NORM" \
  > "$LOG_DIR/preprocess.log" 2>&1

echo "Running TF_MISFIT_GOF_JULIA..."
(
  cd "$WORK_DIR"
  julia "$BASE_DIR/src/tf_misfit_port.jl" "HF_TF-MISFIT_GOF"
) > "$LOG_DIR/julia.log" 2>&1

echo "Running post-process..."
(
  /usr/bin/time -v python3 "$BASE_DIR/scripts/Plot.py" "$WORK_DIR" "$FIG_DIR" "$LOCAL_NORM"
) > "$LOG_DIR/plot.log" 2>&1 || {
  echo "Plot step failed. See $LOG_DIR/plot.log"
  exit 1
}

echo "Done."
echo "Run folder: $RUN_DIR"