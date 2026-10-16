#!/bin/sh
# Publish scrub: no user-specific paths, personal mail addresses or key material in tracked files.
#
# Generic patterns live here. Private tokens (client and employer names,
# colleagues, hostnames) belong in .scrub-private (gitignored, one ERE per
# line) so the scanner never publishes what it scans for. This file is the one
# tracked file excluded from the scan, so review it by hand.
set -e
cd "$(dirname "$0")/.."

GENERIC='/Users/[a-z]+/|~/vault|~/memory|vault-vps|BEGIN (RSA|OPENSSH|EC) PRIVATE KEY|sk-[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|xox[baprs]-[A-Za-z0-9]|hf_[A-Za-z0-9]{30,}|ghp_[A-Za-z0-9]{30,}'
EMAIL='[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}'
PATTERN="$GENERIC|$EMAIL"
if [ -f .scrub-private ]; then
  PRIVATE=$(grep -vE '^[[:space:]]*(#|$)' .scrub-private | paste -sd'|' -)
  [ -n "$PRIVATE" ] && PATTERN="$PATTERN|$PRIVATE"
fi

# Placeholder matches that may stay: /Users/me/, reserved example domains, noreply addresses.
ALLOWED='(^|:)(/Users/me/|noreply@anthropic\.com)$|@([A-Za-z0-9-]+\.)*example\.(com|org|net)$|@users\.noreply\.github\.com$'

# A pattern grep cannot compile would scan nothing and report clean.
rc=0
grep -qE "$PATTERN" /dev/null || rc=$?
if [ "$rc" -gt 1 ]; then echo "SCRUB_PATTERN_INVALID"; exit 1; fi

# Positive control: prove the pipeline detects a planted hit.
control=$(mktemp)
printf '/Users/nobody/leak\njane@corp-mail.io\nok@example.com\n' > "$control"
if [ "$(grep -ohE "$PATTERN" "$control" | grep -vcE "$ALLOWED")" -ne 2 ]; then
  echo "SCRUB_SELFTEST_FAILED"; rm -f "$control"; exit 1
fi
rm -f "$control"

hits=$(git ls-files -z | grep -zv '^scripts/scrub\.sh$' | xargs -0 grep -HoE "$PATTERN" 2>/dev/null | grep -vE "$ALLOWED" | cut -d: -f1 | sort -u || true)
if [ -n "$hits" ]; then
  echo "PRIVATE CONTENT FOUND:"
  echo "$hits"
  exit 1
fi
echo "SCRUB_CLEAN"
