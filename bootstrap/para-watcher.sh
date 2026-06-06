#!/usr/bin/env bash
# para-watcher — Auto-ingest anything dropped into ~/PARA-Inbox/
# Also watches ~/Desktop/ for files matching known ingestable extensions.
#
# Vectors:
#   1. ~/PARA-Inbox/    — primary drop zone (any file, any URL .txt)
#   2. ~/Desktop/       — new PDFs/DOCXs auto-prompted (opt-in via PARA_WATCH_DESKTOP=1)
#   3. Clipboard poll   — every 60s checks if clipboard has a URL, offers ingest
#
# Runs as a LaunchAgent. Log: /tmp/para-watcher.log
# Start:  launchctl load ~/Library/LaunchAgents/com.tac.para-watcher.plist
# Stop:   launchctl unload ~/Library/LaunchAgents/com.tac.para-watcher.plist
# Status: launchctl list | grep para-watcher

set -euo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:/Users/drive/.claude/bin:$PATH"

INBOX="$HOME/PARA-Inbox"
KB="$HOME/knowledge-base"
LOG="/tmp/para-watcher.log"
LOCK="/tmp/para-watcher-processing.lock"
LAST_CLIP=""
CLIP_INTERVAL=60   # seconds between clipboard URL checks

INGEST_EXTENSIONS="pdf|docx|doc|pptx|ppt|xlsx|csv|md|txt|html|htm|epub"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG"; }

mkdir -p "$INBOX"
log "para-watcher started. Watching: $INBOX"

# ── Clipboard URL poller (background) ──────────────────────────────────
clipboard_poll() {
  while true; do
    sleep "$CLIP_INTERVAL"
    CLIP=$(pbpaste 2>/dev/null | head -1 | tr -d '[:space:]')
    if echo "$CLIP" | grep -qE '^https?://' && [[ "$CLIP" != "$LAST_CLIP" ]]; then
      LAST_CLIP="$CLIP"
      log "📎 Clipboard URL detected: $CLIP"
      # Write to inbox as a .url file for the watcher to pick up
      SLUG=$(echo "$CLIP" | sed 's|https\?://||' | tr '/:?=&' '-' | cut -c1-60)
      echo "$CLIP" > "$INBOX/clip-${SLUG}.url"
    fi
  done
}
clipboard_poll &
CLIP_PID=$!

cleanup() {
  kill "$CLIP_PID" 2>/dev/null || true
  rm -f "$LOCK"
  log "para-watcher stopped."
}
trap cleanup EXIT INT TERM

# ── fswatch — react to new files in PARA-Inbox ─────────────────────────
fswatch -0 -e ".*" -i ".*" --event Created --event Renamed "$INBOX" | \
while IFS= read -r -d '' FILE; do
  # Skip if file no longer exists (fswatch fires twice on rename/delete)
  [[ ! -f "$FILE" ]] && continue
  # Skip directories, hidden files, temp files
  [[ -d "$FILE" ]] && continue
  [[ "$(basename "$FILE")" == .* ]] && continue
  [[ "$(basename "$FILE")" == *~ ]] && continue
  [[ "$(basename "$FILE")" == *.part ]] && continue

  EXT="${FILE##*.}"
  EXT_LOWER=$(echo "$EXT" | tr '[:upper:]' '[:lower:]')
  BASENAME=$(basename "$FILE")

  # Debounce — skip if still being written (file size unstable)
  sleep 0.5
  SIZE1=$(stat -f%z "$FILE" 2>/dev/null || echo 0)
  sleep 0.3
  SIZE2=$(stat -f%z "$FILE" 2>/dev/null || echo 0)
  [[ "$SIZE1" != "$SIZE2" ]] && { log "⏳ $BASENAME still writing — skipping"; continue; }

  log "📥 New file: $BASENAME (.$EXT_LOWER)"

  # Prevent concurrent ingestion of same file
  ITEM_LOCK="$LOCK.$(echo "$BASENAME" | tr -cd '[:alnum:]')"
  [[ -f "$ITEM_LOCK" ]] && continue
  touch "$ITEM_LOCK"

  # ── Classify and ingest ──────────────────────────────────────────────
  EXTRA_FLAGS=""

  # .url files = clipboard or dragged URL
  if [[ "$EXT_LOWER" == "url" ]]; then
    URL=$(cat "$FILE" | head -1 | tr -d '[:space:]')
    log "   🌐 URL ingest: $URL"
    para-ingest "$URL" --quiet >> "$LOG" 2>&1 && \
      log "   ✅ Ingested URL" && rm -f "$FILE" || \
      log "   ❌ URL ingest failed"
    rm -f "$ITEM_LOCK"
    continue
  fi

  # .idea files = fast-path to 5-potential pipeline
  if [[ "$EXT_LOWER" == "idea" ]]; then
    TITLE=$(head -1 "$FILE")
    BODY=$(tail -n +2 "$FILE")
    potential-add "$TITLE" --quiet >> "$LOG" 2>&1 && \
      log "   ✅ Idea added to pipeline: $TITLE" && rm -f "$FILE" || \
      log "   ❌ Idea intake failed"
    rm -f "$ITEM_LOCK"
    continue
  fi

  # Known ingestable extension → auto-ingest to 3-resources/inbox
  if echo "$EXT_LOWER" | grep -qE "^($INGEST_EXTENSIONS)$"; then
    para-ingest "$FILE" --quiet >> "$LOG" 2>&1 && \
      log "   ✅ Ingested → 3-resources/inbox/" && \
      rm -f "$FILE" || \
      log "   ❌ Ingest failed (file left in PARA-Inbox for manual review)"
  else
    log "   ⚠️  Unknown extension .$EXT_LOWER — skipping (move manually)"
  fi

  rm -f "$ITEM_LOCK"
done
