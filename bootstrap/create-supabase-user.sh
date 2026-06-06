#!/usr/bin/env bash
# create-supabase-user — create a confirmed user on any Supabase project
# Usage: create-supabase-user <project-ref> <email> <password> [full-name]
#
# Example:
#   create-supabase-user pollhlkgltdkdskdzsgd adobetoby@gmail.com "Adelaide.3" "Toby Anderton"

set -e

PROJECT_REF="${1:?Usage: create-supabase-user <project-ref> <email> <password> [full-name]}"
EMAIL="${2:?email required}"
PASSWORD="${3:?password required}"
FULL_NAME="${4:-}"

SERVICE_ROLE=$(supabase --experimental projects api-keys --project-ref "$PROJECT_REF" 2>/dev/null \
  | grep "service_role" | awk -F'|' '{gsub(/ /,"",$2); print $2}')

if [ -z "$SERVICE_ROLE" ]; then
  echo "❌  Could not get service role key for $PROJECT_REF"
  exit 1
fi

echo "👤  Creating $EMAIL on $PROJECT_REF..."

RESULT=$(curl -s -X POST \
  "https://${PROJECT_REF}.supabase.co/auth/v1/admin/users" \
  -H "Authorization: Bearer $SERVICE_ROLE" \
  -H "apikey: $SERVICE_ROLE" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$EMAIL\",
    \"password\": \"$PASSWORD\",
    \"email_confirm\": true,
    \"user_metadata\": {\"full_name\": \"$FULL_NAME\"}
  }")

ID=$(echo "$RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('id','ERROR'))" 2>/dev/null)

if [ "$ID" = "ERROR" ] || [ -z "$ID" ]; then
  echo "❌  Failed:"
  echo "$RESULT" | python3 -m json.tool 2>/dev/null
  exit 1
fi

echo "✅  User created: $EMAIL (id: $ID)"
