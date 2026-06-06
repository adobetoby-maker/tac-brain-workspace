#!/usr/bin/env bash
# setup-google-oauth — wire Google OAuth to any Supabase project
# Usage: setup-google-oauth <supabase-project-ref> [app-url]
# Requires: Supabase token in keychain, GOOGLE_CLIENT_ID + GOOGLE_CLIENT_SECRET in env or args
#
# Example:
#   setup-google-oauth pollhlkgltdkdskdzsgd https://app.languagethreshold.com
#   setup-google-oauth qnrkifdbkcbacgznoabs https://manage.worker-bee.app

set -e

PROJECT_REF="${1:?Usage: setup-google-oauth <project-ref> [app-url]}"
APP_URL="${2:-}"

GOOGLE_CLIENT_ID="${GOOGLE_CLIENT_ID:-888157046228-92jfuigpfqgqdj4vlpo7k8efd1j0r568.apps.googleusercontent.com}"
GOOGLE_CLIENT_SECRET="${GOOGLE_CLIENT_SECRET:-REDACTED_ROTATE_THIS_SECRET}"

SUPA_TOKEN=$(security find-generic-password -a "supabase" -w 2>/dev/null | sed 's/go-keyring-base64://' | base64 -d 2>/dev/null)
if [ -z "$SUPA_TOKEN" ]; then
  echo "❌  No Supabase token — run: supabase login"
  exit 1
fi

echo "🔧  Enabling Google OAuth on $PROJECT_REF..."

PAYLOAD=$(python3 -c "
import json, sys
d = {
  'external_google_enabled': True,
  'external_google_client_id': '$GOOGLE_CLIENT_ID',
  'external_google_secret': '$GOOGLE_CLIENT_SECRET',
}
if '$APP_URL':
  d['site_url'] = '$APP_URL'
  d['uri_allow_list'] = '$APP_URL,http://localhost:3000,http://localhost:5173'
print(json.dumps(d))
")

RESULT=$(curl -s -X PATCH \
  "https://api.supabase.com/v1/projects/${PROJECT_REF}/config/auth" \
  -H "Authorization: Bearer $SUPA_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD")

if echo "$RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); sys.exit(0 if d.get('external_google_enabled') else 1)" 2>/dev/null; then
  echo "✅  Google OAuth enabled on $PROJECT_REF"
  echo "   Callback URI: https://${PROJECT_REF}.supabase.co/auth/v1/callback"
  echo ""
  echo "⚠️  Add this URI to your Google OAuth client if not already there:"
  echo "   https://${PROJECT_REF}.supabase.co/auth/v1/callback"
  echo "   → console.cloud.google.com/apis/credentials"
else
  echo "❌  Failed:"
  echo "$RESULT" | python3 -m json.tool 2>/dev/null
  exit 1
fi
