#!/bin/bash

# Default values
VOICEDIR=""
PATH_TO_ONNX=""

# Get the directory where this script is located
SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")
echo "Running piper HTTP server located in: $SCRIPT_DIR"

# Function to display usage information
usage() {
  echo "Usage: $0 [--VOICEDIR </path/to/voices>] [--PATH_TO_ONNX </path/to/<yourvoice.onnx>]"
}

# Parse command line options
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    --VOICEDIR)
      VOICEDIR="$2"
      shift 2
      ;;
    --PATH_TO_ONNX)
      PATH_TO_ONNX="$2"
      shift 2
      ;;
    *)
      usage
      exit 1
      ;;
  esac
done

# Write VOICEDIR to a hidden file if provided
if [ -n "$VOICEDIR" ]; then
  echo "$VOICEDIR" > "$SCRIPT_DIR/.VOICEDIR"
fi

# Check if virtual environment directory exists
VENV_PATH="$SCRIPT_DIR/../python/.venv"
if [ -d "$VENV_PATH" ]; then
  # Activate the virtual environment
  source "$VENV_PATH/bin/activate"
else
  echo "Error: Virtual environment not found at $VENV_PATH! Exiting."
  exit 1
fi

# Path to the ONNX model (absolute path)
if [ -f "$PATH_TO_ONNX" ]; then
  # Run the Python command with the module and specified model
  cd "$SCRIPT_DIR" || exit
  python -m piper.http_server --model "$PATH_TO_ONNX"
else
  echo "Error: ONNX model not found at $PATH_TO_ONNX!"
  exit 1
fi

