#!/usr/bin/env bash
# Syncs the current Claude Code OAuth token into Hermes + Hermes Jr credential pools.
# Run nightly before the ~8-hour token expiry window.

set -euo pipefail

CC_CREDS="$HOME/.claude/.credentials.json"

if [ ! -f "$CC_CREDS" ]; then
  echo "❌ ~/.claude/.credentials.json not found — aborting" >&2
  exit 1
fi

python3 << 'EOF'
import json, time, os

CC_CREDS = os.path.expanduser("~/.claude/.credentials.json")

with open(CC_CREDS) as f:
    cc = json.load(f)

oauth = cc.get("claudeAiOauth", {})
ACCESS = oauth.get("accessToken", "")
REFRESH = oauth.get("refreshToken", "")
EXPIRES = oauth.get("expiresAt", 0)

if not ACCESS:
    print("❌ No accessToken found")
    raise SystemExit(1)

targets = [
    os.path.expanduser("~/.hermes/profiles/claude/auth.json"),
    os.path.expanduser("~/.hermes-jr/auth.json"),
]

for auth_path in targets:
    if not os.path.exists(auth_path):
        print(f"⚠️  Skipping (not found): {auth_path}")
        continue
    with open(auth_path) as f:
        auth = json.load(f)

    updated = False
    pool = auth.setdefault("credential_pool", {})
    creds = pool.setdefault("anthropic", [])
    for cred in creds:
        if cred.get("source") == "claude_code" or cred.get("label") == "claude_code":
            cred["access_token"] = ACCESS
            cred["refresh_token"] = REFRESH
            cred["expires_at_ms"] = EXPIRES
            cred["last_status"] = None
            cred["last_status_at"] = None
            updated = True

    if not updated:
        creds.append({
            "id": "sync_cc01",
            "label": "claude_code",
            "auth_type": "oauth",
            "priority": 0,
            "source": "claude_code",
            "access_token": ACCESS,
            "refresh_token": REFRESH,
            "expires_at_ms": EXPIRES,
            "last_status": None,
            "last_status_at": None,
            "last_error_code": None,
            "last_error_reason": None,
            "last_error_message": None,
            "last_error_reset_at": None,
            "request_count": 0,
        })

    auth["updated_at"] = time.strftime('%Y-%m-%dT%H:%M:%S+00:00', time.gmtime())
    with open(auth_path, "w") as f:
        json.dump(auth, f, indent=2)
    remaining_h = (EXPIRES - time.time() * 1000) / (1000 * 60 * 60)
    print(f"✅ Synced: {auth_path}  ({remaining_h:.1f}h remaining)")
EOF
