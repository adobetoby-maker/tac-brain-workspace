#!/bin/bash
# PostToolUse — Write|Edit
# When a visual file (.tsx/.css/.svg/.png) is edited:
#   1. Write marker so PreToolUse block gate fires on next commit/deploy/done
#   2. Announce what changed and what is required

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_input', {}).get('file_path', ''))
except:
    print('')
" 2>/dev/null)

# Only fire on visual file types
if ! echo "$FILE_PATH" | grep -qE '\.(tsx|css|scss|svg|png|jpg|html)$'; then
  exit 0
fi

# Write marker — project-scoped by directory hash
PROJECT_DIR=$(python3 -c "import os; print(os.path.dirname('$FILE_PATH'))" 2>/dev/null || dirname "$FILE_PATH")
MARKER="/tmp/visual-gate-$(echo "$PROJECT_DIR" | md5 2>/dev/null || echo "$PROJECT_DIR" | md5sum | cut -c1-8)"
echo "$FILE_PATH" >> "$MARKER"

echo "┌─────────────────────────────────────────────────────────────┐"
echo "│  VISUAL GATE ARMED                                          │"
printf "│  Changed: %-50s│\n" "$(basename "$FILE_PATH")"
echo "│                                                             │"
echo "│  REQUIRED before commit / deploy / done:                   │"
echo "│    node ~/screenshot.js <port> 0,540,1080                  │"
echo "│    node ~/record.js <port>       (desktop scroll)          │"
echo "│    node ~/record.js <port> --mobile                        │"
echo "│    Read all PNGs with Read tool. Describe what is visible. │"
echo "│                                                             │"
echo "│  Gate clears automatically when screenshot.js runs.        │"
echo "└─────────────────────────────────────────────────────────────┘"
