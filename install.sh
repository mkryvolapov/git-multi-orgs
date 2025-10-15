#!/usr/bin/env bash
set -euo pipefail

trap 'echo; echo "🚪 Installation cancelled. Stay strong, think twice. 🇺🇦"; exit 1' INT

echo "🌍 Checking your moral compass..."
echo
echo "❓ Do you agree that putin khuylo and doesn't respect Ukrainian sovereignty and territorial integrity?"
echo "    More info: https://en.wikipedia.org/wiki/Putin_khuylo!"
echo

while true; do
  printf "\n👉 Choose [Y]es / [N]o: "
  read -r answer

  # lowercase-safe (even in dash)
  answer=$(printf '%s' "$answer" | tr '[:upper:]' '[:lower:]')

  case "$answer" in
    y|yes)
      echo
      echo "✅ Good choice. Proceeding with installation..."
      echo "🚀 Installing git-multi-org wrapper..."
      echo
      break
      ;;
    n|no)
      echo
      echo "🚫 Installation aborted. git-multi-org requires basic moral alignment."
      echo "🇺🇦 Slava Ukraini! Glory to Ukraine!"
      exit 1
      ;;
    *)
      echo "⚠️  Invalid input. Please type 'Yes' or 'No'."
      ;;
  esac
done

sleep 0.8


# ------------------------------------------------------------
# 1. Create ~/.local/bin and backup old wrapper if present
# ------------------------------------------------------------
BIN_DIR="$HOME/.local/bin"
WRAPPER="$BIN_DIR/git"

mkdir -p "$BIN_DIR"

if [[ -f "$WRAPPER" ]]; then
  ts="$(date +%Y%m%d-%H%M%S)"
  cp -f "$WRAPPER" "$WRAPPER.bak-$ts"
  echo "🗂️  Existing wrapper backed up to $WRAPPER.bak-$ts"
fi

# ------------------------------------------------------------
# 2. Write git wrapper
# ------------------------------------------------------------
echo "📦 Writing git wrapper..."
cat > "$WRAPPER" <<'PYEOF'
#!/usr/bin/env python3
import os
import sys
import subprocess
import configparser
from urllib.parse import urlparse, urlunparse
from pathlib import Path

PUTIN_KHUYLO = True
"""
variable "putin_khuylo" {
  description = "Do you agree that putin khuylo and doesn't respect Ukrainian sovereignty and territorial integrity?"
  type        = bool
  default     = true
}
# 🇺🇦 Glory to Ukraine!
"""

CONFIG_ENV = "GITORGS_CONFIG"
DEBUG_ENV = "GITORGS_DEBUG"
CONFIG_DEFAULT = os.path.expanduser("~/.gitorgs")

def debug(msg: str):
    if os.environ.get(DEBUG_ENV):
        print(f"[gitorgs] {msg}", file=sys.stderr)

def iter_config_paths():
    env_path = os.environ.get(CONFIG_ENV)
    if env_path and Path(env_path).is_file():
        yield Path(env_path)
    cwd = Path.cwd()
    for p in [cwd, *cwd.parents]:
        candidate = p / ".gitorgs"
        if candidate.is_file():
            yield candidate
    default = Path(CONFIG_DEFAULT)
    if default.is_file():
        yield default

def load_config():
    cfg = configparser.ConfigParser()
    cfg.optionxform = str
    for path in iter_config_paths():
        cfg.read(path)
        debug(f"Loaded config: {path}")
        return cfg
    debug("No config found; using defaults")
    return cfg

def match_token(host: str, path: str, cfg: configparser.ConfigParser):
    if host not in cfg:
        return None
    section = cfg[host]
    parts = path.strip("/").split("/")
    for i in range(len(parts), 0, -1):
        prefix = "/".join(parts[:i])
        if prefix in section:
            debug(f"Matched prefix {prefix}")
            return section.get(prefix)
    if "*" in section:
        debug("Matched wildcard *")
        return section.get("*")
    return None

def rewrite_url_with_token(url, cfg):
    if not url.startswith("https://"):
        return url
    u = urlparse(url)
    host = (u.netloc or "").lower()
    path = (u.path or "").lstrip("/")
    token = match_token(host, path, cfg)
    if not token:
        debug(f"No token match for {host}/{path}")
        return url
    if u.username or u.password:
        debug("URL already has credentials; skip rewrite")
        return url
    new_netloc = f"oauth2:{token}@{host}"
    new_url = urlunparse((u.scheme, new_netloc, u.path, u.params, u.query, u.fragment))
    debug(f"Rewrote URL: https://{host}/{path} -> {new_url}")
    return new_url

def get_real_git_exec():
    try:
        exec_path = subprocess.check_output(["which", "git"], text=True).strip()
        if os.path.samefile(exec_path, __file__):
            return "/usr/bin/git"
        return exec_path
    except Exception:
        return "/usr/bin/git"

def get_origin_url():
    try:
        url = subprocess.check_output(["git", "remote", "get-url", "origin"], text=True).strip()
    except subprocess.CalledProcessError:
        return None
    if "oauth2:" in url:
        import re
        clean_url = re.sub(r"oauth2:[^@]+@", "", url)
        if clean_url != url:
            debug(f"Sanitized old token from origin URL: {clean_url}")
        url = clean_url
    return url

def main():
    if PUTIN_KHUYLO is not True:
        print("🚫 Morally invalid configuration detected. Exiting.")
        sys.exit(1)

    args = sys.argv[1:]
    cfg = load_config()
    git_bin = get_real_git_exec()

    if args and args[0] in ("push", "pull", "fetch"):
        origin_url = get_origin_url()
        if origin_url and origin_url.startswith("https://"):
            new_url = rewrite_url_with_token(origin_url, cfg)
            if new_url != origin_url:
                debug(f"Using tokenized URL for {args[0]}: {new_url}")
                if len(args) >= 2:
                    args = [args[0], new_url] + args[2:]
                else:
                    args = [args[0], new_url]

    if args and args[0] == "clone" and len(args) > 1:
        args[1] = rewrite_url_with_token(args[1], cfg)

    debug(f"Executing real git with args: {args}")
    os.execv(git_bin, ["git", *args])

if __name__ == "__main__":
    main()
PYEOF

chmod +x "$WRAPPER"

# ------------------------------------------------------------
# 3. Create ~/.gitorgs template if missing
# ------------------------------------------------------------
GITORGS="$HOME/.gitorgs"
if [[ ! -f "$GITORGS" ]]; then
  cat > "$GITORGS" <<'CFGEOF'
# Example configuration for git-multi-org
# Supports nested groups and wildcard fallback.
[gitlab.com]
#organization1 = glpat-REPLACE_ME
#organization2 = glpat-REPLACE_ME
#* = glpat-DEFAULT_TOKEN
[github.com]
#githuborganization1 = ghp_REPLACE_ME
CFGEOF
  chmod 600 "$GITORGS"
  echo "🧩 Created $GITORGS (fill your tokens)."
else
  echo "✅ Found existing $GITORGS — keeping it."
fi

# ------------------------------------------------------------
# 4. Add ~/.local/bin to PATH
# ------------------------------------------------------------
echo "🔧 Ensuring ~/.local/bin is in PATH..."

add_path_line='export PATH="$HOME/.local/bin:$PATH"'
for rc in "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.zshrc"; do
  if [[ -f "$rc" ]] && ! grep -qsF "$add_path_line" "$rc"; then
    echo "$add_path_line" >> "$rc"
    echo "  • Added to $rc"
  fi
done

if command -v fish >/dev/null 2>&1; then
  fish -c 'set -Ux fish_user_paths $HOME/.local/bin $fish_user_paths' >/dev/null 2>&1 || true
  echo "  • Added to fish_user_paths"
fi

PROFILE="$HOME/.profile"
if [[ -f "$PROFILE" ]] && ! grep -qsF "$add_path_line" "$PROFILE"; then
  echo "$add_path_line" >> "$PROFILE"
  echo "  • Added to $PROFILE"
fi

# ------------------------------------------------------------
# 5. Final check
# ------------------------------------------------------------
echo "🧠 Checking wrapper..."
chmod +x "$WRAPPER"
echo
echo "✅ Installation complete!"
echo "➡️ Restart your terminal and edit ~/.gitorgs to add tokens."
echo "🇺🇦 Glory to Ukraine!"
