#!/usr/bin/env bash
# usage: scripts/verify.sh <path> [rules.json]  -> prints: CLASS pattern confirmed=<bool>
# Rules are ordered; first match wins. Unmatched paths default to ASK.
set -euo pipefail
D="$(cd "$(dirname "$0")/.." && pwd)"
RULES="${2:-${MACOS_CLEANUP_RULES:-$D/rules.json}}"
[ -f "$RULES" ] || RULES="$D/rules.example.json"
python3 - "$1" "$RULES" <<'P'
import sys,json,os,fnmatch
p=os.path.abspath(os.path.expanduser(sys.argv[1]));h=os.path.expanduser("~")
for r in json.load(open(sys.argv[2]))["rules"]:
    pat=r["pattern"].replace("~",h,1)
    base=pat[:-3] if pat.endswith("/**") else None
    if fnmatch.fnmatch(p,pat) or (base and (p==base or fnmatch.fnmatch(p,base+"/*") or fnmatch.fnmatch(p,base))):
        print(r["class"],r["pattern"],"confirmed=%s"%str(r.get("confirmed_by_human",False)).lower());sys.exit(0)
print("ASK (no rule matched)")
P
