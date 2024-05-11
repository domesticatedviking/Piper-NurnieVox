#!/bin/bash

# Default values
echo "**********************************"
echo "start_tts_server.sh is now running"
echo "**********************************" 
VOICEDIR=""
PATH_TO_ONNX="/home/erik/code/installer_nurnie/NurnieVox/piper_voices/optimus2309/optimus.onnx"

# Get the directory where this script is located
SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")
echo "Running piper HTTP server located in: $SCRIPT_DIR"

# Function to recursively kill child processes
kill_children() {
    local pid=$1
    local children=$(pgrep -P "$pid")

    for child_pid in $children; do
        kill_children "$child_pid"
        kill "$child_pid"
    done
}

# Path to store PID of server process
PID_FILE="/tmp/tts_server.pid"

# Check if .NURNIEVOX_DIR file exists
if [ -f "$SCRIPT_DIR/.NURNIEVOX_DIR" ]; then
    # Read the path from the file and store it in a variable
    NURNIEVOX_DIR=$(<"$SCRIPT_DIR/.NURNIEVOX_DIR")
    echo "NURNIEVOX_DIR read from .NURNIEVOX_DIR: $NURNIEVOX_DIR"
else
    echo "Error: .NURNIEVOX_DIR file not found"
    exit 1
fi


# Check if NURNIEVOX_DIR is provided
if [ -z "$NURNIEVOX_DIR" ]; then
  echo "Error: NURNIEVOX_DIR not provided"
  usage
fi

echo "Got NURNIEVOX_DIR: $NURNIEVOX_DIR"
echo "STARTING TTS SERVER in $SCRIPT_DIR"


# Write VOICEDIR to a hidden file if provided
if [ -n "$VOICEDIR" ]; then
  echo "$VOICEDIR" > "$SCRIPT_DIR/.VOICEDIR"
fi


# Path to the ONNX model (absolute path)
if [ -f "$PATH_TO_ONNX" ]; then
  # Run the Python command with the module and specified model
  echo "About to run script: SCRIPT_DIR =   ${SCRIPT_DIR}"
  cd "$SCRIPT_DIR"
  python -m piper.http_server --model "${PATH_TO_ONNX}" &
  PID=$!
  echo "PID of TTS server is: ${PID}"
  echo ${PID} > "$PID_FILE" # saves it in case another process needs it
else
  echo "Error: ONNX model not found at $PATH_TO_ONNX!"
  exit 1
fi

echo "*****************************************"
echo
echo "Press <Enter> to exit and kill TTS server"
echo
echo "*****************************************"

read
kill ${PID}

sleep 3 

if ps -p $PID > /dev/null; then
    echo "Process with PID $PID is still running."
else
    echo "Process with PID $PID has been successfully killed."
fi

kill_children "${PID}"
