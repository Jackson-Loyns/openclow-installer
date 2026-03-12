#!/usr/bin/env bash
set -euo pipefail

APP_NAME="openclow"
INSTALLER_VERSION="0.1.0"

INSTALL_METHOD="${INSTALL_METHOD:-npm}"
NPM_PACKAGE="${NPM_PACKAGE:-openclaw}"
NPM_VERSION="${NPM_VERSION:-latest}"
NPM_BIN_NAME="${NPM_BIN_NAME:-openclaw}"

OPENCLOW_REPO="${OPENCLOW_REPO:-openclaw/openclaw}"
OPENCLOW_VERSION="${OPENCLOW_VERSION:-latest}"
OPENCLOW_DOWNLOAD_URL="${OPENCLOW_DOWNLOAD_URL:-}"
OPENCLOW_EXECUTABLE="${OPENCLOW_EXECUTABLE:-openclow}"

INSTALL_ROOT="${INSTALL_ROOT:-$HOME/.openclow}"
BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"
CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/openclow}"
CONFIG_FILE="${CONFIG_FILE:-$CONFIG_DIR/config.env}"
RUNTIME_BIN_DIR="${RUNTIME_BIN_DIR:-$INSTALL_ROOT/runtime/bin}"
NPM_GLOBAL_DIR="${NPM_GLOBAL_DIR:-$INSTALL_ROOT/npm-global}"
NPM_GLOBAL_BIN_DIR="${NPM_GLOBAL_BIN_DIR:-$NPM_GLOBAL_DIR/bin}"

AUTO_START="${AUTO_START:-true}"
NON_INTERACTIVE="${NON_INTERACTIVE:-false}"
PROMPT_FEISHU="${PROMPT_FEISHU:-true}"
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
STEP_INDEX=0

MISSING_BASE_DEPS=()
NODE_STATUS="unknown"
NODE_VERSION=""
NODE_NEEDS_INSTALL="false"
PYTHON_STATUS="unknown"
PYTHON_VERSION=""
PYTHON_NEEDS_INSTALL="false"

log() { printf '[INFO] %s\n' "$*"; }
warn() { printf '[WARN] %s\n' "$*" >&2; }
err() { printf '[ERROR] %s\n' "$*" >&2; exit 1; }
step() {
  STEP_INDEX=$((STEP_INDEX + 1))
  printf '\n[STEP %d] %s\n' "$STEP_INDEX" "$*"
}

activate_local_paths() {
  export PATH="$RUNTIME_BIN_DIR:$NPM_GLOBAL_BIN_DIR:$BIN_DIR:$HOME/.local/bin:$PATH"
}

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
  --repo <owner/repo>                GitHub repo, default: openclaw/openclaw
  --version <tag|latest>             Release tag or latest (default)
  --download-url <url>               Direct download URL (override repo+version)
  --install-method <npm|release>     Install method, default: npm
  --npm-package <name>               npm package name, default: openclaw
  --npm-version <version>            npm package version/tag, default: latest
  --npm-bin-name <name>              installed CLI bin name, default: openclaw
  --install-root <path>              Install directory (default: ~/.openclow)
  --bin-dir <path>                   Symlink directory (default: ~/.local/bin)
  --config-file <path>               Config file path (default: ~/.config/openclow/config.env)
  --exec-name <name>                 Executable name in package (default: openclow)
  --no-autostart                     Do not enable auto-start service
  --prompt-feishu                    Prompt Feishu credentials in terminal (default on)
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
  INSTALL_METHOD, NPM_PACKAGE, NPM_VERSION, NPM_BIN_NAME
  OPENCLOW_REPO, OPENCLOW_VERSION, OPENCLOW_DOWNLOAD_URL
  INSTALL_ROOT, BIN_DIR, CONFIG_FILE, AUTO_START
  PROMPT_FEISHU, SKIP_DEP_INSTALL
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
      --install-method) INSTALL_METHOD="$2"; shift 2 ;;
      --npm-package) NPM_PACKAGE="$2"; shift 2 ;;
      --npm-version) NPM_VERSION="$2"; shift 2 ;;
      --npm-bin-name) NPM_BIN_NAME="$2"; shift 2 ;;
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

trim_value() {
  local v="$1"
  # Remove CR and leading/trailing whitespace.
  v="${v//$'\r'/}"
  v="${v#"${v%%[![:space:]]*}"}"
  v="${v%"${v##*[![:space:]]}"}"
  printf '%s' "$v"
}

normalize_settings() {
  MIN_NODE_VERSION="$(trim_value "$MIN_NODE_VERSION")"
  MIN_PYTHON_VERSION="$(trim_value "$MIN_PYTHON_VERSION")"
  MIN_PYTHON_VERSION="${MIN_PYTHON_VERSION%\"}"
  MIN_PYTHON_VERSION="${MIN_PYTHON_VERSION#\"}"
  MIN_PYTHON_VERSION="${MIN_PYTHON_VERSION%\'}"
  MIN_PYTHON_VERSION="${MIN_PYTHON_VERSION#\'}"

  if [[ -z "$MIN_NODE_VERSION" ]]; then
    MIN_NODE_VERSION="22"
  fi
  if [[ -z "$MIN_PYTHON_VERSION" ]]; then
    MIN_PYTHON_VERSION="3.9"
  fi
  if [[ "$MIN_PYTHON_VERSION" =~ ^[0-9]+$ ]]; then
    MIN_PYTHON_VERSION="${MIN_PYTHON_VERSION}.0"
  fi
}

validate_settings() {
  [[ "$MIN_NODE_VERSION" =~ ^[0-9]+$ ]] || err "--min-node-version must be an integer, got: $MIN_NODE_VERSION"
  [[ "$MIN_PYTHON_VERSION" =~ ^[0-9]+\.[0-9]+$ ]] || err "--min-python-version must be major.minor, got: $MIN_PYTHON_VERSION"
  [[ "$INSTALL_METHOD" == "npm" || "$INSTALL_METHOD" == "release" ]] || err "--install-method must be npm or release, got: $INSTALL_METHOD"
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

has_admin_sudo() {
  if [[ "$(id -u)" -eq 0 ]]; then
    return 0
  fi
  if ! command_exists sudo; then
    return 1
  fi
  sudo -n true >/dev/null 2>&1
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
    if command_exists brew; then
      PKG_MANAGER="brew"
    else
      PKG_MANAGER=""
    fi
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

collect_base_dependency_status() {
  local dep
  MISSING_BASE_DEPS=()
  for dep in curl tar grep sed awk; do
    command_exists "$dep" || MISSING_BASE_DEPS+=("$dep")
  done
}

collect_node_status() {
  local current_major
  NODE_STATUS="skipped"
  NODE_VERSION=""
  NODE_NEEDS_INSTALL="false"
  if [[ "$CHECK_NODE" != "true" ]]; then
    return
  fi
  if ! command_exists node; then
    NODE_STATUS="missing"
    NODE_NEEDS_INSTALL="true"
    return
  fi
  NODE_VERSION="$(node -v 2>/dev/null || true)"
  current_major="$(printf '%s' "$NODE_VERSION" | sed 's/^v//' | cut -d. -f1)"
  if [[ -z "$current_major" || "$current_major" -lt "$MIN_NODE_VERSION" ]]; then
    NODE_STATUS="too_low"
    NODE_NEEDS_INSTALL="true"
    return
  fi
  NODE_STATUS="ok"
}

collect_python_status() {
  PYTHON_STATUS="skipped"
  PYTHON_VERSION=""
  PYTHON_NEEDS_INSTALL="false"
  if [[ "$CHECK_PYTHON" != "true" ]]; then
    return
  fi
  if ! command_exists python3; then
    PYTHON_STATUS="missing"
    PYTHON_NEEDS_INSTALL="true"
    return
  fi
  PYTHON_VERSION="$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")' 2>/dev/null || true)"
  if [[ -z "$PYTHON_VERSION" ]] || ! python_version_ge "$PYTHON_VERSION" "$MIN_PYTHON_VERSION"; then
    PYTHON_STATUS="too_low"
    PYTHON_NEEDS_INSTALL="true"
    return
  fi
  if ! python3 -m pip --version >/dev/null 2>&1; then
    PYTHON_STATUS="pip_missing"
    PYTHON_NEEDS_INSTALL="true"
    return
  fi
  PYTHON_STATUS="ok"
}

print_preflight_report() {
  printf '\n=== 环境检查报告 ===\n'
  printf '系统: %s/%s\n' "$OS" "$ARCH"
  printf '安装方式: %s\n' "$INSTALL_METHOD"
  printf '包管理器: %s\n' "${PKG_MANAGER:-未检测到}"

  if [[ "${#MISSING_BASE_DEPS[@]}" -eq 0 ]]; then
    printf '基础依赖: OK (curl tar grep sed awk)\n'
  else
    printf '基础依赖: 缺失 -> %s\n' "${MISSING_BASE_DEPS[*]}"
  fi

  case "$NODE_STATUS" in
    ok) printf 'Node.js: OK (%s)\n' "${NODE_VERSION:-unknown}" ;;
    missing) printf 'Node.js: 缺失 (需要 >= %s)\n' "$MIN_NODE_VERSION" ;;
    too_low) printf 'Node.js: 版本过低 (%s, 需要 >= %s)\n' "${NODE_VERSION:-unknown}" "$MIN_NODE_VERSION" ;;
    skipped) printf 'Node.js: 已跳过检查\n' ;;
    *) printf 'Node.js: 未知\n' ;;
  esac

  case "$PYTHON_STATUS" in
    ok) printf 'Python3: OK (%s, pip 可用)\n' "${PYTHON_VERSION:-unknown}" ;;
    missing) printf 'Python3: 缺失 (需要 >= %s)\n' "$MIN_PYTHON_VERSION" ;;
    too_low) printf 'Python3: 版本过低 (%s, 需要 >= %s)\n' "${PYTHON_VERSION:-unknown}" "$MIN_PYTHON_VERSION" ;;
    pip_missing) printf 'Python3: pip 缺失 (Python %s)\n' "${PYTHON_VERSION:-unknown}" ;;
    skipped) printf 'Python3: 已跳过检查\n' ;;
    *) printf 'Python3: 未知\n' ;;
  esac

  printf '====================\n'
}

preflight_checks() {
  detect_package_manager
  collect_base_dependency_status
  collect_node_status
  collect_python_status
  print_preflight_report
}

try_install_homebrew_if_needed() {
  if command_exists brew; then
    return 0
  fi
  if [[ "$SKIP_DEP_INSTALL" == "true" ]]; then
    return 1
  fi
  if ! has_admin_sudo; then
    return 1
  fi
  log "Homebrew not found, installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || return 1
  if ! command_exists brew; then
    if [[ -x /opt/homebrew/bin/brew ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x /usr/local/bin/brew ]]; then
      eval "$(/usr/local/bin/brew shellenv)"
    fi
  fi
  command_exists brew
}

install_homebrew_if_needed() {
  if try_install_homebrew_if_needed; then
    return
  fi
  err "Homebrew install failed, and no usable admin sudo was detected on macOS."
}

install_node_runtime_userland_macos() {
  local node_arch node_tag node_url tmpdir extract_dir
  case "$ARCH" in
    arm64) node_arch="arm64" ;;
    amd64) node_arch="x64" ;;
    *) err "Unsupported macOS arch for user-local Node.js runtime: $ARCH" ;;
  esac

  node_tag="$(curl -fsSL "https://nodejs.org/dist/index.json" | sed -n "s/.*\"version\":\"\\(v${MIN_NODE_VERSION}\\.[0-9][0-9]*\\.[0-9][0-9]*\\)\".*/\\1/p" | head -n1)"
  [[ -n "$node_tag" ]] || err "Cannot resolve a Node.js v${MIN_NODE_VERSION}.x release from nodejs.org."

  node_url="https://nodejs.org/dist/${node_tag}/node-${node_tag}-darwin-${node_arch}.tar.gz"
  log "Installing user-local Node.js runtime from ${node_url}"

  tmpdir="$(mktemp -d)"
  curl -fL "$node_url" -o "$tmpdir/node.tar.gz"
  tar -xzf "$tmpdir/node.tar.gz" -C "$tmpdir"
  extract_dir="$(find "$tmpdir" -maxdepth 1 -type d -name "node-${node_tag}-darwin-${node_arch}" | head -n1 || true)"
  if [[ -z "$extract_dir" ]]; then
    rm -rf "$tmpdir"
    err "Failed to extract user-local Node.js runtime."
  fi

  mkdir -p "$INSTALL_ROOT/runtime" "$RUNTIME_BIN_DIR"
  rm -rf "$INSTALL_ROOT/runtime/node"
  cp -R "$extract_dir" "$INSTALL_ROOT/runtime/node"
  rm -rf "$tmpdir"
  ln -sfn "$INSTALL_ROOT/runtime/node/bin/node" "$RUNTIME_BIN_DIR/node"
  ln -sfn "$INSTALL_ROOT/runtime/node/bin/npm" "$RUNTIME_BIN_DIR/npm"
  ln -sfn "$INSTALL_ROOT/runtime/node/bin/npx" "$RUNTIME_BIN_DIR/npx"
  activate_local_paths
}

install_python_runtime_userland_macos() {
  local uv_bin py_exec
  activate_local_paths
  uv_bin="$(command -v uv || true)"
  if [[ -z "$uv_bin" ]]; then
    log "Installing uv (user-local) to provision Python..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    activate_local_paths
    uv_bin="$(command -v uv || true)"
  fi
  [[ -n "$uv_bin" ]] || err "uv install failed; cannot provision Python in user space."

  "$uv_bin" python install "$MIN_PYTHON_VERSION"
  py_exec="$("$uv_bin" python find "$MIN_PYTHON_VERSION" 2>/dev/null | head -n1 || true)"
  [[ -n "$py_exec" && -x "$py_exec" ]] || err "uv installed Python but executable was not found."

  mkdir -p "$RUNTIME_BIN_DIR"
  ln -sfn "$py_exec" "$RUNTIME_BIN_DIR/python3"
  "$RUNTIME_BIN_DIR/python3" -m ensurepip --upgrade >/dev/null 2>&1 || true
  cat > "$RUNTIME_BIN_DIR/pip3" <<EOF
#!/usr/bin/env bash
exec "$RUNTIME_BIN_DIR/python3" -m pip "\$@"
EOF
  chmod +x "$RUNTIME_BIN_DIR/pip3"
  activate_local_paths
}

install_missing_deps() {
  local missing=()
  local dep
  for dep in curl tar grep sed awk; do
    command_exists "$dep" || missing+=("$dep")
  done

  if [[ "${#missing[@]}" -eq 0 ]]; then
    log "Base dependencies OK: curl tar grep sed awk"
    return
  fi

  log "Missing base dependencies: ${missing[*]}"

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
    if command_exists brew || try_install_homebrew_if_needed; then
      brew install "node@${MIN_NODE_VERSION}" || brew install node
      brew link --overwrite --force "node@${MIN_NODE_VERSION}" >/dev/null 2>&1 || true
    else
      warn "No admin sudo for Homebrew. Falling back to user-local Node.js runtime."
      install_node_runtime_userland_macos
    fi
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
    if command_exists brew || try_install_homebrew_if_needed; then
      brew install python
    else
      warn "No admin sudo for Homebrew. Falling back to user-local Python runtime."
      install_python_runtime_userland_macos
    fi
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
  local rc updated runtime_export npm_global_export bin_export
  runtime_export="export PATH=\"$RUNTIME_BIN_DIR:\$PATH\""
  npm_global_export="export PATH=\"$NPM_GLOBAL_BIN_DIR:\$PATH\""
  bin_export="export PATH=\"$BIN_DIR:\$PATH\""
  for rc in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.profile"; do
    updated="false"
    [[ -f "$rc" ]] || continue
    if [[ -d "$RUNTIME_BIN_DIR" ]] && ! grep -q "$RUNTIME_BIN_DIR" "$rc"; then
      printf '\n%s\n' "$runtime_export" >> "$rc"
      updated="true"
    fi
    if [[ -d "$NPM_GLOBAL_BIN_DIR" ]] && ! grep -q "$NPM_GLOBAL_BIN_DIR" "$rc"; then
      printf '\n%s\n' "$npm_global_export" >> "$rc"
      updated="true"
    fi
    if ! grep -q "$BIN_DIR" "$rc"; then
      printf '\n%s\n' "$bin_export" >> "$rc"
      updated="true"
    fi
    if [[ "$updated" == "true" ]]; then
      log "Updated PATH export in $rc"
      return
    fi
  done

  if [[ ! -f "$HOME/.profile" ]]; then
    {
      printf '%s\n' "$runtime_export"
      printf '%s\n' "$npm_global_export"
      printf '%s\n' "$bin_export"
    } > "$HOME/.profile"
    log "Created $HOME/.profile with PATH exports"
  fi
}

install_with_npm() {
  local pkg spec npm_bin
  pkg="$NPM_PACKAGE"
  spec="${pkg}@${NPM_VERSION}"

  activate_local_paths
  command_exists npm || err "npm not found. Node.js install seems incomplete."

  log "Installing via npm: $spec"
  mkdir -p "$NPM_GLOBAL_DIR" "$NPM_GLOBAL_BIN_DIR"
  if ! npm install -g --prefix "$NPM_GLOBAL_DIR" "$spec"; then
    err "npm install failed for $spec (user-local prefix: $NPM_GLOBAL_DIR)."
  fi

  npm_bin="$NPM_GLOBAL_BIN_DIR/$NPM_BIN_NAME"
  [[ -x "$npm_bin" ]] || npm_bin="$(command -v "$NPM_BIN_NAME" || true)"
  [[ -n "$npm_bin" ]] || err "Installed package but CLI '$NPM_BIN_NAME' not found."

  mkdir -p "$INSTALL_ROOT/bin" "$BIN_DIR"
  cat > "$INSTALL_ROOT/bin/$APP_NAME" <<EOF
#!/usr/bin/env bash
set -euo pipefail
if [[ -x "$NPM_GLOBAL_BIN_DIR/$NPM_BIN_NAME" ]]; then
  exec "$NPM_GLOBAL_BIN_DIR/$NPM_BIN_NAME" "\$@"
fi
if command -v "$NPM_BIN_NAME" >/dev/null 2>&1; then
  exec "\$(command -v "$NPM_BIN_NAME")" "\$@"
fi
if command -v npx >/dev/null 2>&1; then
  exec npx --yes "$NPM_PACKAGE@${NPM_VERSION}" "\$@"
fi
echo "[ERROR] $NPM_BIN_NAME not found. Try reinstalling: npm install -g $spec" >&2
exit 1
EOF
  chmod +x "$INSTALL_ROOT/bin/$APP_NAME"
  ln -sfn "$INSTALL_ROOT/bin/$APP_NAME" "$BIN_DIR/$APP_NAME"
  ensure_path_export
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
    if [[ ! -r /dev/tty ]]; then
      err "Cannot prompt Feishu config because /dev/tty is unavailable."
    fi
    prompt_value FEISHU_APP_ID "请输入飞书 FEISHU_APP_ID (cli_xxx)" true false
    prompt_value FEISHU_APP_SECRET "请输入飞书 FEISHU_APP_SECRET" true true
    prompt_value FEISHU_ENCRYPT_KEY "请输入飞书 FEISHU_ENCRYPT_KEY (可选，直接回车跳过)" false true
    prompt_value FEISHU_VERIFICATION_TOKEN "请输入飞书 FEISHU_VERIFICATION_TOKEN (可选，直接回车跳过)" false true
  fi

  [[ -n "$FEISHU_APP_ID" ]] || err "FEISHU_APP_ID is required."
  [[ -n "$FEISHU_APP_SECRET" ]] || err "FEISHU_APP_SECRET is required."

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

write_manager() {
  cat > "$INSTALL_ROOT/openclow-manager.sh" <<EOF
#!/usr/bin/env bash
set -euo pipefail

APP_NAME="$APP_NAME"
CONFIG_FILE="$CONFIG_FILE"
INSTALL_ROOT="$INSTALL_ROOT"
BIN_DIR="$BIN_DIR"
OS="\$(uname -s | tr '[:upper:]' '[:lower:]')"
CUR_UID="\$(id -u)"
SERVICE_NAME="\${APP_NAME}.service"
PLIST="\$HOME/Library/LaunchAgents/com.\${APP_NAME}.agent.plist"
MENU_ITEMS=(
  "查看当前配置"
  "设置飞书配置"
  "启动并开启自启动"
  "暂停服务"
  "恢复服务"
  "关闭自启动"
  "重启服务"
  "查看服务状态"
  "查看最近日志"
  "删除 OpenClow"
  "退出"
)

command_exists() { command -v "\$1" >/dev/null 2>&1; }

if [[ -t 1 ]]; then
  C_CYAN="\$(printf '\033[36m')"
  C_BLUE="\$(printf '\033[34m')"
  C_GREEN="\$(printf '\033[32m')"
  C_YELLOW="\$(printf '\033[33m')"
  C_RED="\$(printf '\033[31m')"
  C_WHITE="\$(printf '\033[37m')"
  C_MAGENTA="\$(printf '\033[35m')"
  C_BOLD="\$(printf '\033[1m')"
  C_DIM="\$(printf '\033[2m')"
  C_RESET="\$(printf '\033[0m')"
else
  C_CYAN=""; C_BLUE=""; C_GREEN=""; C_YELLOW=""; C_RED=""; C_WHITE=""; C_MAGENTA=""; C_BOLD=""; C_DIM=""; C_RESET=""
fi

press_enter() {
  read -r -p "按回车继续..." _
}

read_key() {
  local key rest
  IFS= read -rsn1 key || return 1
  if [[ "\$key" == \$'\\e' ]]; then
    IFS= read -rsn2 -t 0.05 rest || true
    key="\$key\$rest"
  fi
  printf '%s' "\$key"
}

render_header() {
  clear || true
  echo -e "\${C_CYAN}╔══════════════════════════════════════════════════════════════════════╗\${C_RESET}"
  echo -e "\${C_CYAN}║\${C_RESET}  \${C_BOLD}\${C_WHITE} ██████   ██████  ███████ ███    ██  ██████  ██████  ██████ \${C_RESET} \${C_CYAN}║\${C_RESET}"
  echo -e "\${C_CYAN}║\${C_RESET}  \${C_BOLD}\${C_WHITE}██      ██    ██ ██      ████   ██ ██      ██    ██ ██   ██\${C_RESET} \${C_CYAN}║\${C_RESET}"
  echo -e "\${C_CYAN}║\${C_RESET}  \${C_BOLD}\${C_WHITE}██      ██    ██ █████   ██ ██  ██ ██      ████████ ██████ \${C_RESET} \${C_CYAN}║\${C_RESET}"
  echo -e "\${C_CYAN}║\${C_RESET}  \${C_BOLD}\${C_WHITE}██      ██    ██ ██      ██  ██ ██ ██      ██    ██ ██   ██\${C_RESET} \${C_CYAN}║\${C_RESET}"
  echo -e "\${C_CYAN}║\${C_RESET}  \${C_BOLD}\${C_WHITE} ██████   ██████  ███████ ██   ████  ██████ ██    ██ ██   ██\${C_RESET} \${C_CYAN}║\${C_RESET}"
  echo -e "\${C_CYAN}║\${C_RESET}  \${C_BOLD}\${C_MAGENTA}🦞 OPENCLOW MANAGER\${C_RESET}  \${C_DIM}Coding Helper 本地管理面板\${C_RESET}                  \${C_CYAN}║\${C_RESET}"
  echo -e "\${C_CYAN}╚══════════════════════════════════════════════════════════════════════╝\${C_RESET}"
  echo -e "\${C_DIM}安装目录: \$INSTALL_ROOT\${C_RESET}"
  echo -e "\${C_DIM}配置文件: \$CONFIG_FILE\${C_RESET}"
  echo
}

mask_secret() {
  local v="\$1"
  local n="\${#v}"
  if [[ "\$n" -le 4 ]]; then
    printf '%s' "\$v"
  else
    printf '%s****' "\${v:0:4}"
  fi
}

read_cfg() {
  local key="\$1"
  [[ -f "\$CONFIG_FILE" ]] || return 0
  grep -E "^\\\${key}=" "\$CONFIG_FILE" | tail -n1 | sed "s/^\\\${key}=//" || true
}

write_cfg_key() {
  local key="\$1"
  local val="\$2"
  local tmp
  mkdir -p "\$(dirname "\$CONFIG_FILE")"
  [[ -f "\$CONFIG_FILE" ]] || touch "\$CONFIG_FILE"
  tmp="\$(mktemp)"
  awk -v k="\$key" -v v="\$val" '
    BEGIN{found=0}
    \$0 ~ "^"k"=" {print k"="v; found=1; next}
    {print}
    END{if(!found) print k"="v}
  ' "\$CONFIG_FILE" > "\$tmp"
  mv "\$tmp" "\$CONFIG_FILE"
  chmod 600 "\$CONFIG_FILE"
}

configure_feishu() {
  local app_id app_secret encrypt_key verify_token bot_name bot_avatar
  app_id="\$(read_cfg FEISHU_APP_ID)"
  app_secret="\$(read_cfg FEISHU_APP_SECRET)"
  encrypt_key="\$(read_cfg FEISHU_ENCRYPT_KEY)"
  verify_token="\$(read_cfg FEISHU_VERIFICATION_TOKEN)"
  bot_name="\$(read_cfg FEISHU_BOT_NAME)"
  bot_avatar="\$(read_cfg FEISHU_BOT_AVATAR)"

  echo "请输入飞书配置（可直接回车保留当前值）"
  read -r -p "FEISHU_APP_ID [\$app_id]: " v; app_id="\${v:-\$app_id}"
  read -r -s -p "FEISHU_APP_SECRET [隐藏]: " v; echo; app_secret="\${v:-\$app_secret}"
  read -r -s -p "FEISHU_ENCRYPT_KEY [隐藏]: " v; echo; encrypt_key="\${v:-\$encrypt_key}"
  read -r -s -p "FEISHU_VERIFICATION_TOKEN [隐藏]: " v; echo; verify_token="\${v:-\$verify_token}"
  read -r -p "FEISHU_BOT_NAME [\$bot_name]: " v; bot_name="\${v:-\$bot_name}"
  read -r -p "FEISHU_BOT_AVATAR [\$bot_avatar]: " v; bot_avatar="\${v:-\$bot_avatar}"

  [[ -n "\$app_id" ]] || { echo "[ERROR] FEISHU_APP_ID 不能为空"; return 1; }
  [[ -n "\$app_secret" ]] || { echo "[ERROR] FEISHU_APP_SECRET 不能为空"; return 1; }

  write_cfg_key FEISHU_APP_ID "\$app_id"
  write_cfg_key FEISHU_APP_SECRET "\$app_secret"
  write_cfg_key FEISHU_ENCRYPT_KEY "\$encrypt_key"
  write_cfg_key FEISHU_VERIFICATION_TOKEN "\$verify_token"
  write_cfg_key FEISHU_BOT_NAME "\${bot_name:-OpenClow Bot}"
  write_cfg_key FEISHU_BOT_AVATAR "\$bot_avatar"
  write_cfg_key OPENCLOW_HOME "$INSTALL_ROOT"
  echo "[INFO] 配置已保存到 \$CONFIG_FILE"
}

show_config() {
  local app_id app_secret bot_name bot_avatar
  app_id="\$(read_cfg FEISHU_APP_ID)"
  app_secret="\$(read_cfg FEISHU_APP_SECRET)"
  bot_name="\$(read_cfg FEISHU_BOT_NAME)"
  bot_avatar="\$(read_cfg FEISHU_BOT_AVATAR)"
  echo -e "\${C_BOLD}当前配置\${C_RESET}"
  echo "  FEISHU_APP_ID: \$app_id"
  echo "  FEISHU_APP_SECRET: \$(mask_secret "\$app_secret")"
  echo "  FEISHU_BOT_NAME: \$bot_name"
  echo "  FEISHU_BOT_AVATAR: \$bot_avatar"
  echo "  CONFIG_FILE: \$CONFIG_FILE"
  echo
}

service_state_raw() {
  if [[ "\$OS" == "linux" ]] && command_exists systemctl; then
    systemctl --user is-active "\$SERVICE_NAME" 2>/dev/null || echo "inactive"
    return 0
  fi
  if [[ "\$OS" == "darwin" ]] && command_exists launchctl; then
    if launchctl print "gui/\$CUR_UID/com.\${APP_NAME}.agent" 2>/dev/null | grep -q "state = running"; then
      echo "running"
    elif [[ -f "\$PLIST" ]]; then
      echo "loaded"
    else
      echo "inactive"
    fi
    return 0
  fi
  echo "unknown"
}

autostart_state_raw() {
  if [[ "\$OS" == "linux" ]] && command_exists systemctl; then
    systemctl --user is-enabled "\$SERVICE_NAME" 2>/dev/null || echo "disabled"
    return 0
  fi
  if [[ "\$OS" == "darwin" ]] && command_exists launchctl; then
    if [[ ! -f "\$PLIST" ]]; then
      echo "disabled"
    elif launchctl print-disabled "gui/\$CUR_UID" 2>/dev/null | grep -q "\"com.\${APP_NAME}.agent\" => true"; then
      echo "disabled"
    else
      echo "enabled"
    fi
    return 0
  fi
  echo "unknown"
}

service_state_text() {
  case "\$(service_state_raw)" in
    active|running) echo -e "\${C_GREEN}运行中\${C_RESET}" ;;
    inactive|failed|loaded) echo -e "\${C_YELLOW}已停止\${C_RESET}" ;;
    *) echo -e "\${C_YELLOW}未知\${C_RESET}" ;;
  esac
}

autostart_state_text() {
  case "\$(autostart_state_raw)" in
    enabled) echo -e "\${C_GREEN}已开启\${C_RESET}" ;;
    disabled) echo -e "\${C_YELLOW}已关闭\${C_RESET}" ;;
    *) echo -e "\${C_YELLOW}未知\${C_RESET}" ;;
  esac
}

runtime_node() {
  if command_exists node; then
    node -v 2>/dev/null || echo "unknown"
  else
    echo "未安装"
  fi
}

runtime_python() {
  if command_exists python3; then
    python3 --version 2>/dev/null | awk '{print \$2}'
  else
    echo "未安装"
  fi
}

render_status_panel() {
  local app_id bot_name
  app_id="\$(read_cfg FEISHU_APP_ID)"
  bot_name="\$(read_cfg FEISHU_BOT_NAME)"
  [[ -n "\$bot_name" ]] || bot_name="OpenClow Bot"
  echo -e "\${C_CYAN}┏━━━━━━━━━━━━━━━━━━━━━━━━ 当前状态 ━━━━━━━━━━━━━━━━━━━━━━━━┓\${C_RESET}"
  echo -e "\${C_CYAN}┃\${C_RESET} 服务状态: \$(service_state_text)   自启动: \$(autostart_state_text)"
  echo -e "\${C_CYAN}┃\${C_RESET} 飞书应用: \${C_BOLD}\${app_id:-未配置}\${C_RESET}   机器人: \${bot_name}"
  echo -e "\${C_CYAN}┃\${C_RESET} Node: \${C_BOLD}\$(runtime_node)\${C_RESET}   Python: \${C_BOLD}\$(runtime_python)\${C_RESET}"
  echo -e "\${C_CYAN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛\${C_RESET}"
  echo
}

render_menu_panel() {
  local selected="\$1"
  local i idx label
  echo -e "\${C_CYAN}┏━━━━━━━━━━━━━━━━━━━━━━━━ 主菜单 ━━━━━━━━━━━━━━━━━━━━━━━━┓\${C_RESET}"
  for i in "\${!MENU_ITEMS[@]}"; do
    label="\${MENU_ITEMS[\$i]}"
    if [[ "\$i" -eq 10 ]]; then
      idx=0
    else
      idx=\$((i + 1))
    fi
    if [[ "\$i" -eq "\$selected" ]]; then
      echo -e "\${C_CYAN}┃\${C_RESET} \${C_GREEN}\${C_BOLD}❯ [\${idx}] \${label}\${C_RESET}"
    else
      echo -e "\${C_CYAN}┃\${C_RESET}   [\${idx}] \${label}"
    fi
  done
  echo -e "\${C_CYAN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛\${C_RESET}"
  echo -e "\${C_DIM}操作: ↑↓ 选择 | Enter 确认 | 数字直达 | q 退出\${C_RESET}"
}

ensure_service_definition() {
  if [[ "\$OS" == "linux" ]] && command_exists systemctl; then
    local service_dir="\$HOME/.config/systemd/user"
    local service_file="\$service_dir/\$SERVICE_NAME"
    mkdir -p "\$service_dir"
    if [[ ! -f "\$service_file" ]]; then
      cat > "\$service_file" <<LINUX_EOF
[Unit]
Description=\${APP_NAME} service
After=network.target

[Service]
Type=simple
ExecStart=\$INSTALL_ROOT/run-openclow.sh
Restart=always
RestartSec=3

[Install]
WantedBy=default.target
LINUX_EOF
    fi
    systemctl --user daemon-reload >/dev/null 2>&1 || true
    return 0
  fi

  if [[ "\$OS" == "darwin" ]] && command_exists launchctl; then
    mkdir -p "\$HOME/Library/LaunchAgents"
    if [[ ! -f "\$PLIST" ]]; then
      cat > "\$PLIST" <<MAC_EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.\${APP_NAME}.agent</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>\$INSTALL_ROOT/run-openclow.sh</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
  <key>StandardOutPath</key>
  <string>\$INSTALL_ROOT/\${APP_NAME}.log</string>
  <key>StandardErrorPath</key>
  <string>\$INSTALL_ROOT/\${APP_NAME}.err.log</string>
</dict>
</plist>
MAC_EOF
    fi
    return 0
  fi
  return 1
}

service_enable_autostart() {
  ensure_service_definition || true
  if [[ "\$OS" == "linux" ]] && command_exists systemctl; then
    if ! systemctl --user enable --now "\$SERVICE_NAME"; then
      echo "[ERROR] 启动失败，请执行: systemctl --user status \$SERVICE_NAME"
      return 1
    fi
  elif [[ "\$OS" == "darwin" ]] && command_exists launchctl; then
    launchctl bootstrap "gui/\$CUR_UID" "\$PLIST" >/dev/null 2>&1 || true
    launchctl enable "gui/\$CUR_UID/com.\${APP_NAME}.agent" >/dev/null 2>&1 || true
    if ! launchctl kickstart -k "gui/\$CUR_UID/com.\${APP_NAME}.agent"; then
      echo "[ERROR] 启动失败，请执行: launchctl print gui/\$CUR_UID/com.\${APP_NAME}.agent"
      return 1
    fi
  else
    echo "[WARN] 当前系统不支持自动启动管理命令"
    return 1
  fi
  echo -e "\${C_GREEN}[OK]\${C_RESET} 已启动并开启自启动"
}

service_disable_autostart() {
  if [[ "\$OS" == "linux" ]] && command_exists systemctl; then
    systemctl --user disable --now "\$SERVICE_NAME" || true
  elif [[ "\$OS" == "darwin" ]] && command_exists launchctl; then
    launchctl disable "gui/\$CUR_UID/com.\${APP_NAME}.agent" >/dev/null 2>&1 || true
    launchctl bootout "gui/\$CUR_UID/com.\${APP_NAME}.agent" >/dev/null 2>&1 || true
  else
    echo "[WARN] 当前系统不支持自动启动管理命令"
    return 1
  fi
  echo -e "\${C_YELLOW}[OK]\${C_RESET} 已关闭自启动并停止服务"
}

service_pause() {
  if [[ "\$OS" == "linux" ]] && command_exists systemctl; then
    systemctl --user stop "\$SERVICE_NAME" || true
  elif [[ "\$OS" == "darwin" ]] && command_exists launchctl; then
    launchctl bootout "gui/\$CUR_UID/com.\${APP_NAME}.agent" >/dev/null 2>&1 || true
  else
    echo "[WARN] 当前系统不支持自动启动管理命令"
    return 1
  fi
  echo -e "\${C_YELLOW}[OK]\${C_RESET} 已暂停服务"
}

service_resume() {
  ensure_service_definition || true
  if [[ "\$OS" == "linux" ]] && command_exists systemctl; then
    if ! systemctl --user start "\$SERVICE_NAME"; then
      echo "[ERROR] 恢复失败，请执行: systemctl --user status \$SERVICE_NAME"
      return 1
    fi
  elif [[ "\$OS" == "darwin" ]] && command_exists launchctl; then
    launchctl bootstrap "gui/\$CUR_UID" "\$PLIST" >/dev/null 2>&1 || true
    if ! launchctl kickstart -k "gui/\$CUR_UID/com.\${APP_NAME}.agent"; then
      echo "[ERROR] 恢复失败，请执行: launchctl print gui/\$CUR_UID/com.\${APP_NAME}.agent"
      return 1
    fi
  else
    echo "[WARN] 当前系统不支持自动启动管理命令"
    return 1
  fi
  echo -e "\${C_GREEN}[OK]\${C_RESET} 已恢复服务"
}

service_restart() {
  ensure_service_definition || true
  if [[ "\$OS" == "linux" ]] && command_exists systemctl; then
    if ! systemctl --user restart "\$SERVICE_NAME"; then
      echo "[ERROR] 重启失败，请执行: systemctl --user status \$SERVICE_NAME"
      return 1
    fi
  elif [[ "\$OS" == "darwin" ]] && command_exists launchctl; then
    if ! launchctl kickstart -k "gui/\$CUR_UID/com.\${APP_NAME}.agent"; then
      echo "[ERROR] 重启失败，请执行: launchctl print gui/\$CUR_UID/com.\${APP_NAME}.agent"
      return 1
    fi
  else
    echo "[WARN] 当前系统不支持自动启动管理命令"
    return 1
  fi
  echo -e "\${C_GREEN}[OK]\${C_RESET} 服务已重启"
}

service_status() {
  if [[ "\$OS" == "linux" ]] && command_exists systemctl; then
    systemctl --user status "\$SERVICE_NAME" --no-pager || true
  elif [[ "\$OS" == "darwin" ]] && command_exists launchctl; then
    launchctl print "gui/\$CUR_UID/com.\${APP_NAME}.agent" || true
  else
    echo "[WARN] 当前系统不支持自动启动管理命令"
  fi
}

show_logs() {
  if [[ "\$OS" == "linux" ]] && command_exists journalctl; then
    journalctl --user -u "\$SERVICE_NAME" -n 50 --no-pager || true
  elif [[ "\$OS" == "darwin" ]]; then
    echo "== stdout =="
    tail -n 50 "$INSTALL_ROOT/\${APP_NAME}.log" 2>/dev/null || true
    echo "== stderr =="
    tail -n 50 "$INSTALL_ROOT/\${APP_NAME}.err.log" 2>/dev/null || true
  else
    echo "[WARN] 当前系统不支持日志命令"
  fi
}

delete_openclow() {
  local confirm keep_cfg
  echo -e "\${C_RED}危险操作：将删除本机 OpenClow 安装。\${C_RESET}"
  read -r -p "输入 DELETE 确认删除: " confirm
  [[ "\$confirm" == "DELETE" ]] || { echo "已取消"; return 0; }

  service_disable_autostart || true
  rm -f "\$BIN_DIR/openclow" "\$BIN_DIR/openclow-manager"

  if [[ "\$OS" == "linux" ]]; then
    rm -f "\$HOME/.config/systemd/user/\$SERVICE_NAME"
    command_exists systemctl && systemctl --user daemon-reload >/dev/null 2>&1 || true
  elif [[ "\$OS" == "darwin" ]]; then
    rm -f "\$PLIST"
  fi

  rm -rf "\$INSTALL_ROOT"

  read -r -p "是否同时删除配置文件 \$CONFIG_FILE ? [y/N]: " keep_cfg
  case "\$keep_cfg" in
    y|Y|yes|YES) rm -f "\$CONFIG_FILE" ;;
  esac
  echo -e "\${C_GREEN}[OK]\${C_RESET} 已删除 OpenClow。"
}

run_menu_action() {
  case "\$1" in
    0) show_config ;;
    1) configure_feishu ;;
    2) service_enable_autostart ;;
    3) service_pause ;;
    4) service_resume ;;
    5) service_disable_autostart ;;
    6) service_restart ;;
    7) service_status ;;
    8) show_logs ;;
    9) delete_openclow ;;
    10) exit 0 ;;
    *) echo "无效选项"; return 1 ;;
  esac
}

menu_interactive() {
  local selected=0
  local max_index=\$((\${#MENU_ITEMS[@]} - 1))
  local key
  while true; do
    render_header
    render_status_panel
    render_menu_panel "\$selected"
    key="\$(read_key || true)"
    case "\$key" in
      \$'\\e[A') selected=\$((selected - 1)); [[ "\$selected" -lt 0 ]] && selected="\$max_index" ;;
      \$'\\e[B') selected=\$((selected + 1)); [[ "\$selected" -gt "\$max_index" ]] && selected=0 ;;
      \$'\\n'|\$'\\r') run_menu_action "\$selected"; press_enter ;;
      1) selected=0 ;;
      2) selected=1 ;;
      3) selected=2 ;;
      4) selected=3 ;;
      5) selected=4 ;;
      6) selected=5 ;;
      7) selected=6 ;;
      8) selected=7 ;;
      9) selected=8 ;;
      0) selected=10 ;;
      q|Q) exit 0 ;;
      *) ;;
    esac
  done
}

menu_basic() {
  while true; do
    render_header
    render_status_panel
    echo "1) 查看当前配置"
    echo "2) 设置飞书配置"
    echo "3) 启动并开启自启动"
    echo "4) 暂停服务"
    echo "5) 恢复服务"
    echo "6) 关闭自启动"
    echo "7) 重启服务"
    echo "8) 查看服务状态"
    echo "9) 查看最近日志"
    echo "10) 删除 OpenClow"
    echo "0) 退出"
    read -r -p "请选择: " choice
    case "\$choice" in
      1) show_config; press_enter ;;
      2) configure_feishu; press_enter ;;
      3) service_enable_autostart; press_enter ;;
      4) service_pause; press_enter ;;
      5) service_resume; press_enter ;;
      6) service_disable_autostart; press_enter ;;
      7) service_restart; press_enter ;;
      8) service_status; press_enter ;;
      9) show_logs; press_enter ;;
      10) delete_openclow; press_enter ;;
      0) exit 0 ;;
      *) echo "无效选项"; press_enter ;;
    esac
  done
}

menu() {
  if [[ -t 0 && -t 1 ]]; then
    menu_interactive
  else
    menu_basic
  fi
}

menu
EOF
  chmod +x "$INSTALL_ROOT/openclow-manager.sh"
  ln -sfn "$INSTALL_ROOT/openclow-manager.sh" "$BIN_DIR/openclow-manager"
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
  write_manager
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
  local node_info python_info start_cmd
  node_info="$(command -v node >/dev/null 2>&1 && node -v || echo skipped)"
  python_info="$(command -v python3 >/dev/null 2>&1 && python3 --version 2>&1 || echo skipped)"
  start_cmd="$INSTALL_ROOT/run-openclow.sh"
  cat <<EOF

Install complete.

- Installer version: $INSTALLER_VERSION
- Platform: $OS/$ARCH
- Install root: $INSTALL_ROOT
- Binary link: $BIN_DIR/$APP_NAME
- Config file: $CONFIG_FILE
- Install method: $INSTALL_METHOD
- Repo: $OPENCLOW_REPO
- Version: ${RESOLVED_VERSION:-custom-url}
- Download URL: $RESOLVED_DOWNLOAD_URL
- Node.js: $node_info
- Python: $python_info

Run commands:
  前台直接运行:
    $start_cmd
  菜单管理（推荐）:
    $BIN_DIR/openclow-manager
    然后选择 [3] 启动并开启自启动

Quick checks:
  $BIN_DIR/$APP_NAME --help
  $BIN_DIR/openclow-manager
EOF
}

launch_manager_after_install() {
  if [[ "$NON_INTERACTIVE" == "true" ]]; then
    return
  fi
  if [[ ! -t 0 || ! -t 1 ]]; then
    return
  fi
  if [[ ! -x "$BIN_DIR/openclow-manager" ]]; then
    warn "openclow-manager not found at $BIN_DIR/openclow-manager"
    return
  fi
  printf '\n[INFO] 正在启动管理界面: openclow-manager\n\n'
  "$BIN_DIR/openclow-manager" || warn "openclow-manager exited with non-zero status."
}

main() {
  parse_args "$@"
  normalize_settings
  validate_settings
  print_lobster_banner
  activate_local_paths

  step "检测系统信息"
  detect_platform

  step "执行环境预检查（随后自动安装）"
  preflight_checks

  step "安装/修复基础依赖"
  install_missing_deps
  step "检查并安装 Node.js / Python"
  ensure_node_runtime
  ensure_python_runtime

  step "安装 OpenClow"
  if [[ "$INSTALL_METHOD" == "npm" ]]; then
    RESOLVED_VERSION="$NPM_VERSION"
    RESOLVED_DOWNLOAD_URL="npm:${NPM_PACKAGE}@${NPM_VERSION}"
    install_with_npm
  else
    resolve_download_url
    download_and_install_binary
  fi

  step "写入配置并生成管理命令"
  write_config
  configure_autostart

  step "安装完成"
  print_summary
  launch_manager_after_install
}

main "$@"
