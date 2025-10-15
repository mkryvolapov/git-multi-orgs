#!/usr/bin/env bash
set -euo pipefail

echo "🧹 Uninstalling git-multi-org wrapper..."
echo

BIN_DIR="$HOME/.local/bin"
WRAPPER="$BIN_DIR/git"

# ------------------------------------------------------------
# 1. Remove git wrapper
# ------------------------------------------------------------
if [[ -f "$WRAPPER" ]]; then
  rm -f "$WRAPPER"
  echo "🗑️  Removed wrapper: $WRAPPER"
else
  echo "ℹ️  No wrapper found at $WRAPPER"
fi

# ------------------------------------------------------------
# 2. Offer to remove backup copies
# ------------------------------------------------------------
if compgen -G "$WRAPPER.bak-*" > /dev/null; then
  echo
  echo "🗂️  Found backup copies:"
  ls -1 "$WRAPPER".bak-* | sed 's/^/   • /'
  read -rp "❓ Remove backups as well? [y/N]: " confirm
  if [[ "${confirm,,}" =~ ^(y|yes)$ ]]; then
    rm -f "$WRAPPER".bak-*
    echo "✅ Backups removed."
  else
    echo "↩️  Backups kept."
  fi
fi

# ------------------------------------------------------------
# 3. Remove PATH entries from shell configs
# ------------------------------------------------------------
echo
echo "🧾 Cleaning PATH entries..."

REMOVE_LINE='export PATH="$HOME/.local/bin:$PATH"'
for rc in "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.zshrc" "$HOME/.profile"; do
  if [[ -f "$rc" ]] && grep -qsF "$REMOVE_LINE" "$rc"; then
    # use | as delimiter to avoid conflicts with / or .
    sed -i.bak "\|$REMOVE_LINE|d" "$rc"
    echo "  • Removed from $rc (backup created: $rc.bak)"
  fi
done

# Fish shell support
if command -v fish >/dev/null 2>&1; then
  fish -c 'set -eU fish_user_paths' >/dev/null 2>&1 || true
  echo "  • Removed from fish_user_paths"
fi

# ------------------------------------------------------------
# 4. Keep or delete ~/.gitorgs
# ------------------------------------------------------------
echo
if [[ -f "$HOME/.gitorgs" ]]; then
  echo "⚠️  File ~/.gitorgs found (contains your tokens)."
  read -rp "❓ Do you also want to delete it? [y/N]: " delcfg
  if [[ "${delcfg,,}" =~ ^(y|yes)$ ]]; then
    rm -f "$HOME/.gitorgs"
    echo "🗑️  Deleted ~/.gitorgs."
  else
    echo "📁 Kept ~/.gitorgs (you can remove it manually later)."
  fi
fi

# ------------------------------------------------------------
# 5. Final check
# ------------------------------------------------------------
echo
echo "✅ Uninstallation complete!"
echo "🧭 System git restored:"
which git || true
echo
echo "🇺🇦 Glory to Ukraine!"
