#!/usr/bin/env bash
set -euo pipefail

APP_NAME="openclow"
INSTALLER_VERSION="0.1.0"

OPENCLOW_REPO="${OPENCLOW_REPO:-openclow/openclow}"
OPENCLOW_VERSION="${OPENCLOW_VERSION:-latest}"
OPENCLOW_DOWNLOAD_URL="${OPENCLOW_DOWNLOAD_URL:-}"
OPENCLOW_EXECUTABLE="${OPENCLOW_EXECUTABLE:-openclow}"

INSTALL_ROOT="${INSTALL_ROOT:-$HOME/.openclow}"
BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"
CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/openclow}"
CONFIG_FILE="${CONFIG_FILE:-$CONFIG_DIR/config.env}"

AUTO_START="${AUTO_START:-true}"
NON_INTERACTIVE="${NON_INTERACTIVE:-false}"
PROMPT_FEISHU="${PROMPT_FEISHU:-false}"
SKIP_DEP_INSTALL="${SKIP_DEP_INSTALL:-false}"
CHECK_NODE="${CHECK_NODE:-true}"
CHECK_PYTHON="${CHECK_PYTHON:-true}"
MIN_NODE_VERSION="${MIN_NODE_VERSION:-22}"
MIN_PYTHON_VERSION="${MIN_PYTHON_VERSION:-3.9}"

FEISHU_APP_ID="${FEISHU_APP_ID:-}"
FEISHU_APP_SECRET="${FEISHU_APP_SECRET:-}"
FEISHU_ENCRYPT_KEY="${FEISHU_ENCRYPT_KEY:-}"
FEISHU_VERIFICATION_TOKEN="${FEISHU_VERIFICATION_TOKEN:-}"
FEISHU_BOT_NAME="${FEISHU_BOT_NAME:-OpenClow Bot}"
FEISHU_BOT_AVATAR="${FEISHU_BOT_AVATAR:-}"

OS=""
ARCH=""
PKG_MANAGER=""
RESOLVED_VERSION=""
RESOLVED_DOWNLOAD_URL=""

log() { printf '[INFO] %s\n' "$*"; }
warn() { printf '[WARN] %s\n' "$*" >&2; }
err() { printf '[ERROR] %s\n' "$*" >&2; exit 1; }

print_lobster_banner() {
  cat <<'EOF'
🦞 OpenClow Installer
EOF
}

usage() {
  cat <<'EOF'
OpenClow Installer

Usage:
  bash install.sh [options]

Options:
  --repo <owner/repo>                GitHub repo, default: openclow/openclow
  --version <tag|latest>             Release tag or latest (default)
  --download-url <url>               Direct download URL (override repo+version)
  --install-root <path>              Install directory (default: ~/.openclow)
  --bin-dir <path>                   Symlink directory (default: ~/.local/bin)
  --config-file <path>               Config file path (default: ~/.config/openclow/config.env)
  --exec-name <name>                 Executable name in package (default: openclow)
  --no-autostart                     Do not enable auto-start service
  --non-interactive                  No prompts; rely on flags/env only
  --prompt-feishu                    Prompt Feishu credentials in terminal
  --skip-deps                        Do not auto install missing dependencies
  --skip-node-check                  Skip Node.js runtime check/install
  --skip-python-check                Skip Python runtime check/install
  --min-node-version <major>         Minimum Node major version (default: 22)
  --min-python-version <major.minor> Minimum Python version (default: 3.9)
  --feishu-app-id <value>            Feishu App ID
  --feishu-app-secret <value>        Feishu App Secret
  --feishu-encrypt-key <value>       Feishu Encrypt Key
  --feishu-verification-token <value> Feishu Verification Token
  --feishu-bot-name <value>          Feishu Bot Name
  --feishu-bot-avatar <value>        Feishu Bot Avatar URL or local file path
  -h, --help                         Show help

Environment variables:
  OPENCLOW_REPO, OPENCLOW_VERSION, OPENCLOW_DOWNLOAD_URL
  INSTALL_ROOT, BIN_DIR, CONFIG_FILE, AUTO_START, NON_INTERACTIVE, PROMPT_FEISHU, SKIP_DEP_INSTALL
  CHECK_NODE, CHECK_PYTHON, MIN_NODE_VERSION, MIN_PYTHON_VERSION
  FEISHU_APP_ID, FEISHU_APP_SECRET, FEISHU_ENCRYPT_KEY, FEISHU_VERIFICATION_TOKEN
  FEISHU_BOT_NAME, FEISHU_BOT_AVATAR
EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --repo) OPENCLOW_REPO="$2"; shift 2 ;;
      --version) OPENCLOW_VERSION="$2"; shift 2 ;;
      --download-url) OPENCLOW_DOWNLOAD_URL="$2"; shift 2 ;;
      --install-root) INSTALL_ROOT="$2"; shift 2 ;;
      --bin-dir) BIN_DIR="$2"; shift 2 ;;
      --config-file)
        CONFIG_FILE="$2"
        CONFIG_DIR="$(dirname "$CONFIG_FILE")"
        shift 2
        ;;
      --exec-name) OPENCLOW_EXECUTABLE="$2"; shift 2 ;;
      --no-autostart) AUTO_START="false"; shift ;;
      --non-interactive) NON_INTERACTIVE="true"; shift ;;
      --prompt-feishu) PROMPT_FEISHU="true"; shift ;;
      --skip-deps) SKIP_DEP_INSTALL="true"; shift ;;
      --skip-node-check) CHECK_NODE="false"; shift ;;
      --skip-python-check) CHECK_PYTHON="false"; shift ;;
      --min-node-version) MIN_NODE_VERSION="$2"; shift 2 ;;
      --min-python-version) MIN_PYTHON_VERSION="$2"; shift 2 ;;
      --feishu-app-id) FEISHU_APP_ID="$2"; shift 2 ;;
      --feishu-app-secret) FEISHU_APP_SECRET="$2"; shift 2 ;;
      --feishu-encrypt-key) FEISHU_ENCRYPT_KEY="$2"; shift 2 ;;
      --feishu-verification-token) FEISHU_VERIFICATION_TOKEN="$2"; shift 2 ;;
      --feishu-bot-name) FEISHU_BOT_NAME="$2"; shift 2 ;;
      --feishu-bot-avatar) FEISHU_BOT_AVATAR="$2"; shift 2 ;;
      -h|--help) usage; exit 0 ;;
      *)
        err "Unknown option: $1"
        ;;
    esac
  done
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

validate_settings() {
  [[ "$MIN_NODE_VERSION" =~ ^[0-9]+$ ]] || err "--min-node-version must be an integer, got: $MIN_NODE_VERSION"
  [[ "$MIN_PYTHON_VERSION" =~ ^[0-9]+\\.[0-9]+$ ]] || err "--min-python-version must be major.minor, got: $MIN_PYTHON_VERSION"
}

run_privileged() {
  if [[ "$(id -u)" -eq 0 ]]; then
    "$@"
    return
  fi
  if command_exists sudo; then
    sudo "$@"
    return
  fi
  err "Need root privileges for dependency install, but sudo is not available."
}

detect_platform() {
  local uname_s uname_m
  uname_s="$(uname -s | tr '[:upper:]' '[:lower:]')"
  uname_m="$(uname -m | tr '[:upper:]' '[:lower:]')"

  case "$uname_s" in
    linux) OS="linux" ;;
    darwin) OS="darwin" ;;
    *) err "Unsupported OS: $uname_s (only Linux/macOS)" ;;
  esac

  case "$uname_m" in
    x86_64|amd64) ARCH="amd64" ;;
    aarch64|arm64) ARCH="arm64" ;;
    *) err "Unsupported architecture: $uname_m (only amd64/arm64)" ;;
  esac
}

detect_package_manager() {
  if [[ "$OS" == "darwin" ]]; then
    PKG_MANAGER="brew"
    return
  fi

  for pm in apt-get dnf yum pacman zypper apk; do
    if command_exists "$pm"; then
      PKG_MANAGER="$pm"
      return
    fi
  done
  PKG_MANAGER=""
}

install_homebrew_if_needed() {
  if command_exists brew; then
    return
  fi
  if [[ "$SKIP_DEP_INSTALL" == "true" ]]; then
    err "Homebrew is required on macOS for auto dependency install. Install brew manually or remove --skip-deps."
  fi
  log "Homebrew not found, installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if ! command_exists brew; then
    if [[ -x /opt/homebrew/bin/brew ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x /usr/local/bin/brew ]]; then
      eval "$(/usr/local/bin/brew shellenv)"
    fi
  fi
  command_exists brew || err "Homebrew install failed."
}

install_missing_deps() {
  local missing=()
  local dep
  for dep in curl tar grep sed awk; do
    command_exists "$dep" || missing+=("$dep")
  done

  if [[ "${#missing[@]}" -eq 0 ]]; then
    return
  fi

  if [[ "$SKIP_DEP_INSTALL" == "true" ]]; then
    err "Missing dependencies: ${missing[*]}. Remove --skip-deps or install them manually."
  fi

  detect_package_manager
  if [[ "$OS" == "darwin" ]]; then
    install_homebrew_if_needed
    for dep in "${missing[@]}"; do
      case "$dep" in
        awk) brew install gawk ;;
        *) brew install "$dep" ;;
      esac
    done
    return
  fi

  [[ -n "$PKG_MANAGER" ]] || err "No supported package manager found. Install dependencies manually: ${missing[*]}"

  case "$PKG_MANAGER" in
    apt-get)
      run_privileged apt-get update -y
      for dep in "${missing[@]}"; do
        case "$dep" in
          awk) run_privileged apt-get install -y gawk ;;
          *) run_privileged apt-get install -y "$dep" ;;
        esac
      done
      ;;
    dnf|yum)
      for dep in "${missing[@]}"; do
        case "$dep" in
          awk) run_privileged "$PKG_MANAGER" install -y gawk ;;
          *) run_privileged "$PKG_MANAGER" install -y "$dep" ;;
        esac
      done
      ;;
    pacman)
      run_privileged pacman -Sy --noconfirm
      for dep in "${missing[@]}"; do
        case "$dep" in
          awk) run_privileged pacman -S --noconfirm gawk ;;
          *) run_privileged pacman -S --noconfirm "$dep" ;;
        esac
      done
      ;;
    zypper)
      for dep in "${missing[@]}"; do
        case "$dep" in
          awk) run_privileged zypper --non-interactive install gawk ;;
          *) run_privileged zypper --non-interactive install "$dep" ;;
        esac
      done
      ;;
    apk)
      for dep in "${missing[@]}"; do
        case "$dep" in
          awk) run_privileged apk add gawk ;;
          *) run_privileged apk add "$dep" ;;
        esac
      done
      ;;
    *)
      err "Unsupported package manager: $PKG_MANAGER"
      ;;
  esac
}

python_version_ge() {
  local current="$1"
  local required="$2"
  awk -v c="$current" -v r="$required" '
    BEGIN {
      split(c, C, ".")
      split(r, R, ".")
      c1 = C[1] + 0
      c2 = C[2] + 0
      r1 = R[1] + 0
      r2 = R[2] + 0
      if (c1 > r1 || (c1 == r1 && c2 >= r2)) exit 0
      exit 1
    }
  '
}

install_node_runtime() {
  detect_package_manager
  if [[ "$OS" == "darwin" ]]; then
    install_homebrew_if_needed
    brew install "node@${MIN_NODE_VERSION}" || brew install node
    brew link --overwrite --force "node@${MIN_NODE_VERSION}" >/dev/null 2>&1 || true
    return
  fi

  [[ -n "$PKG_MANAGER" ]] || err "No supported package manager found for Node.js install."

  case "$PKG_MANAGER" in
    apt-get)
      run_privileged apt-get update -y
      curl -fsSL "https://deb.nodesource.com/setup_${MIN_NODE_VERSION}.x" | run_privileged bash -
      run_privileged apt-get install -y nodejs
      ;;
    dnf|yum)
      curl -fsSL "https://rpm.nodesource.com/setup_${MIN_NODE_VERSION}.x" | run_privileged bash -
      run_privileged "$PKG_MANAGER" install -y nodejs
      ;;
    pacman)
      run_privileged pacman -Sy --noconfirm nodejs npm
      ;;
    zypper)
      run_privileged zypper --non-interactive install nodejs npm
      ;;
    apk)
      run_privileged apk add nodejs npm
      ;;
    *)
      err "Unsupported package manager for Node.js install: $PKG_MANAGER"
      ;;
  esac
}

install_python_runtime() {
  detect_package_manager
  if [[ "$OS" == "darwin" ]]; then
    install_homebrew_if_needed
    brew install python
    return
  fi

  [[ -n "$PKG_MANAGER" ]] || err "No supported package manager found for Python install."

  case "$PKG_MANAGER" in
    apt-get)
      run_privileged apt-get update -y
      run_privileged apt-get install -y python3 python3-pip
      ;;
    dnf|yum)
      run_privileged "$PKG_MANAGER" install -y python3 python3-pip
      ;;
    pacman)
      run_privileged pacman -Sy --noconfirm python python-pip
      ;;
    zypper)
      run_privileged zypper --non-interactive install python3 python3-pip
      ;;
    apk)
      run_privileged apk add python3 py3-pip
      ;;
    *)
      err "Unsupported package manager for Python install: $PKG_MANAGER"
      ;;
  esac
}

ensure_node_runtime() {
  local current_major
  if [[ "$CHECK_NODE" != "true" ]]; then
    log "CHECK_NODE=false, skip Node.js check."
    return
  fi

  if ! command_exists node; then
    if [[ "$SKIP_DEP_INSTALL" == "true" ]]; then
      err "Node.js is required (>=${MIN_NODE_VERSION}) but missing."
    fi
    log "Node.js not found, installing..."
    install_node_runtime
  fi

  command_exists node || err "Node.js install failed."
  current_major="$(node -v | sed 's/^v//' | cut -d. -f1)"
  if [[ -z "$current_major" || "$current_major" -lt "$MIN_NODE_VERSION" ]]; then
    if [[ "$SKIP_DEP_INSTALL" == "true" ]]; then
      err "Node.js version is too low. Need >=${MIN_NODE_VERSION}, current: $(node -v 2>/dev/null || echo unknown)."
    fi
    log "Node.js version too low, upgrading..."
    install_node_runtime
    current_major="$(node -v | sed 's/^v//' | cut -d. -f1)"
  fi

  if [[ -z "$current_major" || "$current_major" -lt "$MIN_NODE_VERSION" ]]; then
    err "Node.js version check failed. Need >=${MIN_NODE_VERSION}, current: $(node -v 2>/dev/null || echo unknown)."
  fi

  if ! command_exists npm; then
    err "npm is missing after Node.js install."
  fi
  log "Node.js OK: $(node -v), npm: $(npm -v)"
}

ensure_python_runtime() {
  local current_py
  if [[ "$CHECK_PYTHON" != "true" ]]; then
    log "CHECK_PYTHON=false, skip Python check."
    return
  fi

  if ! command_exists python3; then
    if [[ "$SKIP_DEP_INSTALL" == "true" ]]; then
      err "Python3 is required (>=${MIN_PYTHON_VERSION}) but missing."
    fi
    log "Python3 not found, installing..."
    install_python_runtime
  fi

  command_exists python3 || err "Python3 install failed."
  current_py="$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")' 2>/dev/null || true)"
  if [[ -z "$current_py" ]] || ! python_version_ge "$current_py" "$MIN_PYTHON_VERSION"; then
    if [[ "$SKIP_DEP_INSTALL" == "true" ]]; then
      err "Python version is too low. Need >=${MIN_PYTHON_VERSION}, current: ${current_py:-unknown}."
    fi
    log "Python version too low, upgrading..."
    install_python_runtime
    current_py="$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")' 2>/dev/null || true)"
  fi

  if [[ -z "$current_py" ]] || ! python_version_ge "$current_py" "$MIN_PYTHON_VERSION"; then
    err "Python version check failed. Need >=${MIN_PYTHON_VERSION}, current: ${current_py:-unknown}."
  fi

  if ! python3 -m pip --version >/dev/null 2>&1; then
    if [[ "$SKIP_DEP_INSTALL" == "true" ]]; then
      err "pip for Python3 is missing."
    fi
    install_python_runtime
  fi
  log "Python OK: $(python3 --version 2>&1), pip: $(python3 -m pip --version | awk '{print $2}')"
}

fetch_latest_version() {
  local api tag
  api="https://api.github.com/repos/${OPENCLOW_REPO}/releases/latest"
  tag="$(curl -fsSL "$api" | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)"
  [[ -n "$tag" ]] || err "Failed to fetch latest release tag from ${OPENCLOW_REPO}."
  printf '%s' "$tag"
}

url_exists() {
  local url="$1"
  curl -fsIL "$url" >/dev/null 2>&1
}

resolve_download_url() {
  local tag base short_tag candidate
  if [[ -n "$OPENCLOW_DOWNLOAD_URL" ]]; then
    RESOLVED_DOWNLOAD_URL="$OPENCLOW_DOWNLOAD_URL"
    return
  fi

  if [[ "$OPENCLOW_VERSION" == "latest" ]]; then
    tag="$(fetch_latest_version)"
  else
    tag="$OPENCLOW_VERSION"
  fi
  RESOLVED_VERSION="$tag"
  short_tag="${tag#v}"
  base="https://github.com/${OPENCLOW_REPO}/releases/download/${tag}"

  for candidate in \
    "${base}/${APP_NAME}_${OS}_${ARCH}.tar.gz" \
    "${base}/${APP_NAME}-${OS}-${ARCH}.tar.gz" \
    "${base}/${APP_NAME}_${short_tag}_${OS}_${ARCH}.tar.gz" \
    "${base}/${APP_NAME}-${short_tag}-${OS}-${ARCH}.tar.gz" \
    "${base}/${APP_NAME}_${OS}_${ARCH}.zip" \
    "${base}/${APP_NAME}-${OS}-${ARCH}.zip" \
    "${base}/${OPENCLOW_EXECUTABLE}_${OS}_${ARCH}.tar.gz"; do
    if url_exists "$candidate"; then
      RESOLVED_DOWNLOAD_URL="$candidate"
      return
    fi
  done

  err "Cannot infer release asset URL. Set --download-url manually."
}

ensure_path_export() {
  local rc
  for rc in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.profile"; do
    [[ -f "$rc" ]] || continue
    if ! grep -q "$BIN_DIR" "$rc"; then
      printf '\nexport PATH="%s:$PATH"\n' "$BIN_DIR" >> "$rc"
      log "Added PATH export to $rc"
      return
    fi
  done

  if [[ ! -f "$HOME/.profile" ]]; then
    printf 'export PATH="%s:$PATH"\n' "$BIN_DIR" > "$HOME/.profile"
    log "Created $HOME/.profile with PATH export"
  fi
}

download_and_install_binary() {
  local tmpdir package_path extracted_bin cleaned_url
  tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' EXIT

  package_path="$tmpdir/package"
  log "Downloading ${RESOLVED_DOWNLOAD_URL}"
  curl -fL "$RESOLVED_DOWNLOAD_URL" -o "$package_path"

  mkdir -p "$INSTALL_ROOT/bin" "$BIN_DIR"

  cleaned_url="${RESOLVED_DOWNLOAD_URL%%\?*}"
  if [[ "$cleaned_url" == *.tar.gz || "$cleaned_url" == *.tgz ]]; then
    tar -xzf "$package_path" -C "$tmpdir"
  elif [[ "$cleaned_url" == *.zip ]]; then
    if ! command_exists unzip; then
      if [[ "$SKIP_DEP_INSTALL" == "true" ]]; then
        err "Need unzip to extract package."
      fi
      detect_package_manager
      case "$PKG_MANAGER" in
        apt-get) run_privileged apt-get update -y && run_privileged apt-get install -y unzip ;;
        dnf|yum) run_privileged "$PKG_MANAGER" install -y unzip ;;
        pacman) run_privileged pacman -S --noconfirm unzip ;;
        zypper) run_privileged zypper --non-interactive install unzip ;;
        apk) run_privileged apk add unzip ;;
        brew) install_homebrew_if_needed; brew install unzip ;;
        *) err "Cannot install unzip automatically on this system." ;;
      esac
    fi
    unzip -q "$package_path" -d "$tmpdir"
  else
    chmod +x "$package_path"
    extracted_bin="$package_path"
  fi

  if [[ -z "${extracted_bin:-}" ]]; then
    extracted_bin="$(find "$tmpdir" -type f -name "$OPENCLOW_EXECUTABLE" -perm -u+x | head -n1 || true)"
  fi
  [[ -n "${extracted_bin:-}" ]] || err "Cannot find executable '${OPENCLOW_EXECUTABLE}' in downloaded package."

  cp "$extracted_bin" "$INSTALL_ROOT/bin/$APP_NAME"
  chmod +x "$INSTALL_ROOT/bin/$APP_NAME"
  ln -sfn "$INSTALL_ROOT/bin/$APP_NAME" "$BIN_DIR/$APP_NAME"
  ensure_path_export
}

prompt_value() {
  local var_name="$1"
  local prompt_text="$2"
  local required="${3:-false}"
  local is_secret="${4:-false}"
  local current_val="${!var_name:-}"
  local input_val

  if [[ -n "$current_val" ]]; then
    return
  fi
  if [[ "$NON_INTERACTIVE" == "true" ]]; then
    return
  fi
  if [[ ! -r /dev/tty ]]; then
    warn "Cannot prompt for ${var_name} because /dev/tty is unavailable."
    return
  fi

  while true; do
    if [[ "$is_secret" == "true" ]]; then
      read -r -s -p "$prompt_text: " input_val < /dev/tty || input_val=""
      printf '\n' > /dev/tty
    else
      read -r -p "$prompt_text: " input_val < /dev/tty || input_val=""
    fi

    if [[ -n "$input_val" || "$required" != "true" ]]; then
      printf -v "$var_name" '%s' "$input_val"
      return
    fi
    warn "${var_name} is required."
  done
}

read_config_value() {
  local key="$1"
  local value=""
  if [[ -f "$CONFIG_FILE" ]]; then
    value="$(grep -E "^${key}=" "$CONFIG_FILE" | tail -n1 | sed "s/^${key}=//" || true)"
  fi
  printf '%s' "$value"
}

hydrate_feishu_from_existing_config() {
  [[ -n "$FEISHU_APP_ID" ]] || FEISHU_APP_ID="$(read_config_value FEISHU_APP_ID)"
  [[ -n "$FEISHU_APP_SECRET" ]] || FEISHU_APP_SECRET="$(read_config_value FEISHU_APP_SECRET)"
  [[ -n "$FEISHU_ENCRYPT_KEY" ]] || FEISHU_ENCRYPT_KEY="$(read_config_value FEISHU_ENCRYPT_KEY)"
  [[ -n "$FEISHU_VERIFICATION_TOKEN" ]] || FEISHU_VERIFICATION_TOKEN="$(read_config_value FEISHU_VERIFICATION_TOKEN)"
  [[ -n "$FEISHU_BOT_NAME" ]] || FEISHU_BOT_NAME="$(read_config_value FEISHU_BOT_NAME)"
  [[ -n "$FEISHU_BOT_AVATAR" ]] || FEISHU_BOT_AVATAR="$(read_config_value FEISHU_BOT_AVATAR)"
}

write_config() {
  umask 077
  mkdir -p "$CONFIG_DIR"
  hydrate_feishu_from_existing_config

  if [[ "$PROMPT_FEISHU" == "true" && "$NON_INTERACTIVE" != "true" ]]; then
    prompt_value FEISHU_APP_ID "请输入飞书 FEISHU_APP_ID (cli_xxx)" true false
    prompt_value FEISHU_APP_SECRET "请输入飞书 FEISHU_APP_SECRET" true true
    prompt_value FEISHU_ENCRYPT_KEY "请输入飞书 FEISHU_ENCRYPT_KEY (可选，直接回车跳过)" false true
    prompt_value FEISHU_VERIFICATION_TOKEN "请输入飞书 FEISHU_VERIFICATION_TOKEN (可选，直接回车跳过)" false true
  fi

  cat > "$CONFIG_FILE" <<EOF
# ${APP_NAME} runtime environment
FEISHU_APP_ID=${FEISHU_APP_ID}
FEISHU_APP_SECRET=${FEISHU_APP_SECRET}
FEISHU_ENCRYPT_KEY=${FEISHU_ENCRYPT_KEY}
FEISHU_VERIFICATION_TOKEN=${FEISHU_VERIFICATION_TOKEN}
FEISHU_BOT_NAME=${FEISHU_BOT_NAME}
FEISHU_BOT_AVATAR=${FEISHU_BOT_AVATAR}
OPENCLOW_HOME=${INSTALL_ROOT}
EOF
  chmod 600 "$CONFIG_FILE"
  log "Wrote config: $CONFIG_FILE"
  [[ -n "$FEISHU_APP_ID" ]] || warn "FEISHU_APP_ID is empty. Set it later in $CONFIG_FILE"
  [[ -n "$FEISHU_APP_SECRET" ]] || warn "FEISHU_APP_SECRET is empty. Set it later in $CONFIG_FILE"
}

write_runner() {
  cat > "$INSTALL_ROOT/run-openclow.sh" <<EOF
#!/usr/bin/env bash
set -euo pipefail
if [[ -f "$CONFIG_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$CONFIG_FILE"
  set +a
fi
exec "$INSTALL_ROOT/bin/$APP_NAME"
EOF
  chmod +x "$INSTALL_ROOT/run-openclow.sh"
}

configure_autostart_linux() {
  local service_dir service_file
  service_dir="$HOME/.config/systemd/user"
  service_file="$service_dir/${APP_NAME}.service"
  mkdir -p "$service_dir"

  cat > "$service_file" <<EOF
[Unit]
Description=${APP_NAME} service
After=network.target

[Service]
Type=simple
ExecStart=$INSTALL_ROOT/run-openclow.sh
Restart=always
RestartSec=3

[Install]
WantedBy=default.target
EOF

  if command_exists systemctl; then
    if systemctl --user daemon-reload >/dev/null 2>&1; then
      systemctl --user enable --now "${APP_NAME}.service" || warn "Failed to start user service. You can run: systemctl --user enable --now ${APP_NAME}.service"
      if command_exists loginctl; then
        loginctl enable-linger "$USER" >/dev/null 2>&1 || warn "Could not enable linger for $USER. Run manually if needed: sudo loginctl enable-linger $USER"
      fi
      log "systemd user service enabled: ${APP_NAME}.service"
    else
      warn "systemctl --user is unavailable in current session; service file created at $service_file"
    fi
  else
    warn "systemctl not found; service file created at $service_file"
  fi
}

configure_autostart_macos() {
  local launch_agents plist uid
  launch_agents="$HOME/Library/LaunchAgents"
  plist="$launch_agents/com.${APP_NAME}.agent.plist"
  uid="$(id -u)"
  mkdir -p "$launch_agents"

  cat > "$plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.${APP_NAME}.agent</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>$INSTALL_ROOT/run-openclow.sh</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
  <key>StandardOutPath</key>
  <string>$INSTALL_ROOT/${APP_NAME}.log</string>
  <key>StandardErrorPath</key>
  <string>$INSTALL_ROOT/${APP_NAME}.err.log</string>
</dict>
</plist>
EOF

  if command_exists launchctl; then
    launchctl bootout "gui/${uid}" "$plist" >/dev/null 2>&1 || true
    launchctl bootstrap "gui/${uid}" "$plist" >/dev/null 2>&1 || true
    launchctl enable "gui/${uid}/com.${APP_NAME}.agent" >/dev/null 2>&1 || true
    launchctl kickstart -k "gui/${uid}/com.${APP_NAME}.agent" >/dev/null 2>&1 || true
    log "LaunchAgent enabled: $plist"
  else
    warn "launchctl not found; created plist at $plist"
  fi
}

configure_autostart() {
  write_runner
  if [[ "$AUTO_START" != "true" ]]; then
    log "AUTO_START=false, skipped autostart setup."
    return
  fi

  case "$OS" in
    linux) configure_autostart_linux ;;
    darwin) configure_autostart_macos ;;
    *) warn "Unsupported autostart platform: $OS" ;;
  esac
}

print_summary() {
  local node_info python_info
  node_info="$(command -v node >/dev/null 2>&1 && node -v || echo skipped)"
  python_info="$(command -v python3 >/dev/null 2>&1 && python3 --version 2>&1 || echo skipped)"
  cat <<EOF

Install complete.

- Installer version: $INSTALLER_VERSION
- Platform: $OS/$ARCH
- Install root: $INSTALL_ROOT
- Binary link: $BIN_DIR/$APP_NAME
- Config file: $CONFIG_FILE
- Repo: $OPENCLOW_REPO
- Version: ${RESOLVED_VERSION:-custom-url}
- Download URL: $RESOLVED_DOWNLOAD_URL
- Node.js: $node_info
- Python: $python_info

Quick checks:
  $BIN_DIR/$APP_NAME --help
EOF
}

main() {
  parse_args "$@"
  validate_settings
  print_lobster_banner
  detect_platform
  install_missing_deps
  ensure_node_runtime
  ensure_python_runtime
  resolve_download_url
  download_and_install_binary
  write_config
  configure_autostart
  print_summary
}

main "$@"
