#!/usr/bin/env bash
# Read-only check of everything the guide needs. Changes nothing.
ok()   { printf '  ok       %-14s %s\n' "$1" "$2"; }
miss() { printf '  MISSING  %-14s %s\n' "$1" "$2"; MISSING=1; }
chk()  { # name, command-to-run-for-version
  if command -v "$1" >/dev/null 2>&1; then ok "$1" "$(eval "$2" 2>&1 | head -1)"; else miss "$1" "$3"; fi; }
MISSING=0
echo "Tools"
chk node   'node -v'                 "install Node 22 or 24 (docs/02)"
chk npm    'npm -v'                  "comes with Node"
chk tmux   'tmux -V'                 "sudo apt install tmux"
chk git    'git --version'           "sudo apt install git"
chk rig    'rig --version'           "npm install -g @openrig/cli (docs/03)"
chk claude 'claude --version'        "npm install -g @anthropic-ai/claude-code"
chk herdr  'herdr --version'         "optional terminal provider (docs/05)"
chk agy    'agy --version'           "optional second runtime (docs/05)"
chk go     'go version'              "optional, only for the Go case study"
chk pnpm   'pnpm -v'                 "optional, needed to run DeepSeek Harness from source"
echo "Node version"
v=$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null)
if [ "$v" = 22 ] || [ "$v" = 24 ]; then ok node "major $v supported"; else miss node "OpenRig needs major 22 or 24 (found: ${v:-none})"; fi
echo "OpenRig"
if command -v rig >/dev/null 2>&1; then
  if rig ps >/dev/null 2>&1; then ok daemon "reachable: $(rig ps 2>&1 | head -1)"; else miss daemon "run: rig daemon start"; fi
fi
echo "Runtimes"
command -v claude >/dev/null && { claude auth status >/dev/null 2>&1 && ok claude-auth "logged in" || miss claude-auth "run: claude auth login"; }
echo "DeepSeek"
[ -n "${DEEPSEEK_API_KEY:-}" ] && ok DEEPSEEK_KEY "set (value hidden)" || echo "  note     DEEPSEEK_KEY   not in this shell env; the Harness may hold it in its own config (docs/04). Confirm with dsh-offload.mjs doctor"
ls -d "${DSH_HOME:-$HOME/.dsh}" >/dev/null 2>&1 && ok DSH_HOME "${DSH_HOME:-$HOME/.dsh}" || miss DSH_HOME "start the Harness once (docs/04)"
curl -s -o /dev/null -m 3 -w '%{http_code}' "${DSH_GUI_URL:-http://127.0.0.1:3080}/" | grep -q '^[1-5]' && ok dsh-gui "answers on ${DSH_GUI_URL:-http://127.0.0.1:3080}" || echo "  note     dsh-gui        not running (jobs still work; start with: pnpm dsh web)"
echo
[ "$MISSING" = 0 ] && echo "All required checks passed." || echo "Fix the MISSING lines that apply to you."
exit 0
