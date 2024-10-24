#!/bin/bash
# Created by Lord Madan Babu

# Check if a core dump file was provided as an argument
if [[ $# -eq 0 ]]; then
    echo "Please provide a core dump file as an argument."
    exit 1
fi

CORE_FILE="$1"

# Get the executable name and PID from the core dump file
EXECUTABLE_NAME=$(readlink -f "$CORE_FILE")
PID=$(basename "$CORE_FILE" | cut -d. -f1)

echo "Analyzing core dump file: $CORE_FILE"
echo "Executable: $(readlink -f "$EXECUTABLE_NAME")"
echo "Process ID: $PID"

# Use gdb to analyze the core dump
echo "Using gdb to analyze..."
gdb "$EXECUTABLE_NAME" "$CORE_FILE" -batch <<EOF
set debug-file-directory .
file $EXECUTABLE_NAME
core-file $CORE_FILE

# Print backtrace and register contents
bt full
info registers

# Print memory contents (limited to first 100 bytes of each allocated block)
set pagination off
set print repeats 0
info memory
quit
EOF

# Extract information from gdb output
backtrace=$(gdb "$EXECUTABLE_NAME" "$CORE_FILE" -batch -x backtrace.script)
register_contents=$(gdb "$EXECUTABLE_NAME" "$CORE_FILE" -batch -x register_contents.script)
memory_contents=$(gdb "$EXECUTABLE_NAME" "$CORE_FILE" -batch -x memory_contents.script)

# Process the extracted information and output the results
echo "\nBacktrace:"
echo "$backtrace"

echo "\nRegister contents:"
echo "$register_contents"

echo "\nMemory contents:"
echo "$memory_contents"
