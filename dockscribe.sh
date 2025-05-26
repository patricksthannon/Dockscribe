#!/bin/bash

# $$$$$$$\                      $$\                                     $$\ $$\                 
# $$  __$$\                     $$ |                                    \__|$$ |                
# $$ |  $$ | $$$$$$\   $$$$$$$\ $$ |  $$\  $$$$$$$\  $$$$$$$\  $$$$$$\  $$\ $$$$$$$\   $$$$$$\  
# $$ |  $$ |$$  __$$\ $$  _____|$$ | $$  |$$  _____|$$  _____|$$  __$$\ $$ |$$  __$$\ $$  __$$\ 
# $$ |  $$ |$$ /  $$ |$$ /      $$$$$$  / \$$$$$$\  $$ /      $$ |  \__|$$ |$$ |  $$ |$$$$$$$$ |
# $$ |  $$ |$$ |  $$ |$$ |      $$  _$$<   \____$$\ $$ |      $$ |      $$ |$$ |  $$ |$$   ____|
# $$$$$$$  |\$$$$$$  |\$$$$$$$\ $$ | \$$\ $$$$$$$  |\$$$$$$$\ $$ |      $$ |$$$$$$$  |\$$$$$$$\ 
# \_______/  \______/  \_______|\__|  \__|\_______/  \_______|\__|      \__|\_______/  \_______|
# By PatrickstHannon https://github.com/patricksthannon


# === jq dependency check & install ===
check_jq() {
  if command -v jq >/dev/null 2>&1; then
    return 0
  fi

  echo "jq not found. Attempting to install..."

  OS="$(uname -s)"
  ARCH="$(uname -m)"

  get_jq_url() {
    case "$OS" in
      Darwin)
        echo "https://github.com/stedolan/jq/releases/latest/download/jq-osx-amd64"
        ;;
      Linux)
        case "$ARCH" in
          x86_64|amd64) echo "https://github.com/stedolan/jq/releases/latest/download/jq-linux64" ;;
          aarch64|arm64) echo "https://github.com/stedolan/jq/releases/latest/download/jq-linuxarm64" ;;
          armv7*) echo "https://github.com/stedolan/jq/releases/latest/download/jq-linuxarm" ;;
          *) echo "" ;;
        esac
        ;;
      *)
        echo ""
        ;;
    esac
  }

  if [[ "$OS" == "Darwin" ]]; then
    if command -v brew >/dev/null 2>&1; then
      echo "Installing jq via Homebrew..."
      brew install jq && return 0
    else
      echo "Homebrew not found. Will attempt to download static jq binary."
    fi
  fi

  if [[ "$OS" == "Linux" ]]; then
    if command -v apt-get >/dev/null 2>&1; then
      echo "Installing jq via apt-get..."
      sudo apt-get update && sudo apt-get install -y jq && return 0
    elif command -v yum >/dev/null 2>&1; then
      echo "Installing jq via yum..."
      sudo yum install -y jq && return 0
    else
      echo "No supported package manager found."
    fi
  fi

  jq_url=$(get_jq_url)
  if [[ -z "$jq_url" ]]; then
    echo "Unsupported OS or architecture for automatic jq binary download."
    return 1
  fi

  echo "Downloading jq from $jq_url ..."

  tmp_jq="$(mktemp)"
  if curl -L --fail --silent --show-error -o "$tmp_jq" "$jq_url"; then
    chmod +x "$tmp_jq"
    if sudo mv "$tmp_jq" /usr/local/bin/jq 2>/dev/null; then
      echo "jq installed to /usr/local/bin/jq"
      return 0
    else
      local_bin="$HOME/.local/bin"
      mkdir -p "$local_bin"
      mv "$tmp_jq" "$local_bin/jq"
      echo "jq installed to $local_bin/jq"
      echo "Make sure $local_bin is in your PATH."
      return 0
    fi
  else
    echo "Failed to download jq binary."
    rm -f "$tmp_jq"
    return 1
  fi
}

if ! check_jq; then
  echo "jq is required but could not be installed."
  exit 1
fi

# === Docker description fetch functions ===

get_dockerhub_desc() {
  local repo="$1"
  local url="https://hub.docker.com/v2/repositories/${repo}/"
  local json
  json=$(curl -s -f "$url" 2>/dev/null | tr -d '\000-\037') || return 1
  local desc repo_url
  desc=$(echo "$json" | jq -r '.description' 2>/dev/null)
  repo_url=$(echo "$json" | jq -r '.repo_url' 2>/dev/null)
  if [[ "$desc" != "null" && -n "$desc" ]]; then
    echo "$desc"
    return 0
  elif [[ "$repo_url" =~ github\.com ]]; then
    get_github_desc "$repo_url"
    return $?
  fi
  return 1
}

get_github_desc() {
  local repo_url="$1"
  local api_url=${repo_url/https:\/\/github.com\//https:\/\/api.github.com\/repos\/}
  local desc

  desc=$(curl -s -f "$api_url" 2>/dev/null | jq -r '.description' 2>/dev/null)
  if [[ $? -eq 0 && "$desc" != "null" && -n "$desc" ]]; then
    echo "$desc"
    return 0
  fi

  local trimmed="$repo_url"
  while [[ "$trimmed" =~ .*/.*-.* ]]; do
    trimmed=$(echo "$trimmed" | sed -E 's|-?[^/-]+$||')
    local fallback_api_url=${trimmed/https:\/\/github.com\//https:\/\/api.github.com\/repos\/}
    desc=$(curl -s -f "$fallback_api_url" 2>/dev/null | jq -r '.description' 2>/dev/null)
    if [[ $? -eq 0 && "$desc" != "null" && -n "$desc" ]]; then
      echo "$desc"
      return 0
    fi
  done

  return 1
}

get_description() {
  local image="$1"

  if [[ "$image" == lscr.io/* ]]; then
    local repo="${image#lscr.io/}"
    get_dockerhub_desc "$repo" && return 0
  elif [[ "$image" == ghcr.io/* ]]; then
    local repo="${image#ghcr.io/}"
    local url="https://github.com/${repo}"
    get_github_desc "$url" && return 0
  elif [[ "$image" == docker.io/* ]]; then
    local repo="${image#docker.io/}"
    get_dockerhub_desc "$repo" && return 0
  elif [[ "$image" == *"/"* ]]; then
    get_dockerhub_desc "$image" && return 0
  else
    get_dockerhub_desc "library/${image}" && return 0
  fi

  return 1
}

# === Main logic base ===

images=$(docker ps --format '{{.Image}}' | cut -d':' -f1 | sort -u)

for image in $images; do
  desc=$(get_description "$image")
  if [[ -z "$desc" ]]; then
    desc="[no description found]"
  fi
  echo -e "$image — $desc"
done

