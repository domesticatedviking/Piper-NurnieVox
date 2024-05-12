#!/bin/bash

# Default values
echo "**********************************"
echo "start_tts_server.sh is now running"
echo "**********************************" 
VOICEDIR="./VOICE_LINKS"

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
DEFAULT_VOICE_LOCATION="${NURNIEVOX_DIR}/.SERVER_TTS_VOICE"
echo "DEFAULT_VOICE_LOCATION  = ${DEFAULT_VOICE_LOCATION}"

DEFAULT_VOICE_PATH=$(<$DEFAULT_VOICE_LOCATION)

#if [ -n "$DEFAULT_VOICE_LOCATION" ]; then#
#  echo "no default voice provided in ${NURNIEVOX_DIR}/.SERVER_TTS_VOICE"
#  echo "please put a path to a default ONNX file in there"
#fi

echo "creating symbolic link to voice file."
echo "simulating symlink command ln -s ${DEFAULT_VOICE_PATH} $VOICEDIR/voice.onnx"
echo "simulating symlink command ln -s ${DEFAULT_VOICE_PATH}.json $VOICEDIR/voice.onnx.json"
ONNX_PATH=$VOICEDIR/voice.onnx
ONNX_JSON_PATH=$VOICEDIR/voice.onnx.json
rm $ONNX_PATH
rm $ONNX_JSON_PATH

ln -s ${DEFAULT_VOICE_PATH} $ONNX_PATH
ln -s ${DEFAULT_VOICE_PATH}.json $ONNX_JSON_PATH
echo "STARTING TTS SERVER in $SCRIPT_DIR"



# Write VOICEDIR to a hidden file if provided
if [ -n "$VOICEDIR" ]; then
  echo "$VOICEDIR" > "$SCRIPT_DIR/.VOICEDIR"
fi


# Path to the ONNX model (absolute path)
if [ -f "$ONNX_PATH" ]; then
  # Run the Python command with the module and specified model
  echo "About to run script: SCRIPT_DIR =   ${SCRIPT_DIR}"
  cd "$SCRIPT_DIR"
  python -m piper.http_server --model "${ONNX_PATH}" &
  PID=$!
  echo "PID of TTS server is: ${PID}"
  echo ${PID} > "$PID_FILE" # saves it in case another process needs it
else
  echo "Error: ONNX model not found at ${ONNX_PATH} !"
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
