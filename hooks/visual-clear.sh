#!/bin/bash
# PostToolUse — Bash
# Clears visual gate markers when screenshot.js or record.js runs successfully

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_input', {}).get('command', ''))
except:
    print('')
" 2>/dev/null)

EXIT_CODE=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_response', {}).get('exit_code', 1))
except:
    print(1)
" 2>/dev/null)

# Only clear on successful screenshot/record runs
if ! echo "$COMMAND" | grep -qE "(screenshot\.js|record\.js)"; then
  exit 0
fi

if [ "$EXIT_CODE" != "0" ]; then
  exit 0
fi

# Clear all visual gate markers
COUNT=$(ls /tmp/visual-gate-* 2>/dev/null | wc -l | tr -d ' ')
if [ "$COUNT" -gt 0 ]; then
  rm -f /tmp/visual-gate-* 2>/dev/null
  echo "✅ Visual gate cleared ($COUNT marker(s) removed) — now Read the PNGs and describe what you see."
fi
