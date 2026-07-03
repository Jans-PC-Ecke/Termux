#!/data/data/com.termux/files/usr/bin/bash

echo "🚀 Starte Termux Power-Installation..."

# 1. System Update & Basis-Tools installieren
pkg update -y && pkg upgrade -y
pkg install -y git nano curl wget tree ncdu ffmpeg jq tmux neofetch

# 2. Speicherzugriff einrichten (Wichtig für Downloads etc.)
termux-setup-storage

# 3. Extra-Keys (Shortcuts) konfigurieren
# Erstellt eine 2-Zeilen-Tastatur mit Pfeiltasten, STRG, ALT, ESC
mkdir -p ~/.termux
cat > ~/.termux/termux.properties << 'EOF'
extra-keys = [['ESC','/','-','HOME','UP','END','PGUP'], \
              ['TAB','CTRL','ALT','LEFT','DOWN','RIGHT','PGDN']]
EOF
termux-reload-settings

# 4. Die .bashrc mit deinen Aliases und Shortcuts füllen
# Wir sichern die alte erst und schreiben dann eine saubere neue
if [ -f ~/.bashrc ]; then
    mv ~/.bashrc ~/.bashrc.backup.$(date +%F)
fi

cat > ~/.bashrc << 'EOF'
# Termux Power Configuration

# --- System Aliases ---
alias update='pkg update && pkg upgrade -y && pkg clean && pkg autoclean'
alias ps='pkg search'
alias pi='pkg install -y'
alias rm='pkg remove && pkg autoremove'

# --- Speicher & Navigation ---
alias dl='cd ~/storage/downloads'
alias pic='cd ~/storage/pictures'
alias dcim='cd ~/storage/dcim'
alias shared='cd ~/storage/shared'
alias ..='cd -'
alias ll='ls -lh --color=auto'
alias la='ls -Ahl --color=auto'

# --- Funktionen ---
# Verzeichnis erstellen und sofort hineingehen
mcd() { mkdir -p "$1" && cd "$1"; }

# Downloads nach Termux kopieren
alias kopiere-downloads='cp -r ~/storage/downloads/* ~/ 2>/dev/null || echo "Keine Dateien gefunden."'

# --- Prompt Verschönerung (Grün/Blau) ---
PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

# --- Historie verbessern ---
HISTSIZE=10000
HISTFILESIZE=20000
shopt -s histappend
EOF

echo "✅ Installation abgeschlossen!"
echo "💡 Bitte starte Termux neu oder führe 'source ~/.bashrc' aus."
echo "⌨️ Deine Extra-Keys (Pfeiltasten, STRG, ALT) sind jetzt aktiv."   