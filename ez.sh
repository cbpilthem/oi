https://claude.ai/share/975f2627-6c88-4770-af03-1f893615cba1


KV_PARSE() {
  local KV_INPUT="$1"
  local -A KV_MAP=()
  local KV_RE='([a-z_]+):'
  local KV_REST="$KV_INPUT"
  while [[ $KV_REST =~ $KV_RE ]]; do
    local KV_KEY="${BASH_REMATCH[1]}"
    local KV_AFTER_KEY="${KV_REST#*${KV_KEY}:}"
    if [[ $KV_AFTER_KEY =~ $KV_RE ]]; then
      local KV_VALUE="${KV_AFTER_KEY%%${BASH_REMATCH[1]}:*}"
      KV_MAP["$KV_KEY"]="${KV_VALUE%;}"
      KV_REST="${KV_AFTER_KEY#*$KV_VALUE}"
    else
      KV_MAP["$KV_KEY"]="${KV_AFTER_KEY%;}"
      break
    fi
  done
  declare -p KV_MAP
}

KV_TEMPLATE() {
  local KV_TEMPLATE_INPUT="$1"
  local -n KV_MAP_REF=$2
  local KV_TEMPLATE_OUTPUT="$KV_TEMPLATE_INPUT"
  for KV_KEY in "${!KV_MAP_REF[@]}"; do
    KV_TEMPLATE_OUTPUT="${KV_TEMPLATE_OUTPUT//\{\{$KV_KEY\}\}/${KV_MAP_REF[$KV_KEY]}}"
  done
  printf '%s\n' "$KV_TEMPLATE_OUTPUT"
}

KV_FLAGS() {
  local -n KV_MAP_REF=$1
  local KV_ARGS=()
  for KV_KEY in "${!KV_MAP_REF[@]}"; do
    KV_ARGS+=("-$KV_KEY" "${KV_MAP_REF[$KV_KEY]}")
  done
  printf '%s\n' "${KV_ARGS[@]}"
}

EVKV() {
  local KV_INPUT_OR_NAME="$1"
  local KV_TEMPLATE_INPUT="$2"
  local -A KV_MAP=()

  if declare -p "$KV_INPUT_OR_NAME" 2>/dev/null | grep -q 'declare \-A'; then
    local -n KV_MAP_REF="$KV_INPUT_OR_NAME"
    KV_MAP=()
    for KV_KEY in "${!KV_MAP_REF[@]}"; do
      KV_MAP["$KV_KEY"]="${KV_MAP_REF[$KV_KEY]}"
    done
  else
    eval "$(KV_PARSE "$KV_INPUT_OR_NAME")"
    local -n KV_MAP_REF=KV_MAP
  fi

  KV_TEMPLATE "$KV_TEMPLATE_INPUT" KV_MAP
}

KV_PARSE() {
  local KV_INPUT="$1"
  local -A KV_MAP=()
  local KV_RE='([a-z_]+):'
  local KV_REST="$KV_INPUT"
  while [[ $KV_REST =~ $KV_RE ]]; do
    local KV_KEY="${BASH_REMATCH[1]}"
    local KV_AFTER_KEY="${KV_REST#*${KV_KEY}:}"
    if [[ $KV_AFTER_KEY =~ $KV_RE ]]; then
      local KV_VALUE="${KV_AFTER_KEY%%${BASH_REMATCH[1]}:*}"
      KV_MAP["$KV_KEY"]="${KV_VALUE%;}"
      KV_REST="${KV_AFTER_KEY#*$KV_VALUE}"
    else
      KV_MAP["$KV_KEY"]="${KV_AFTER_KEY%;}"
      break
    fi
  done
  declare -p KV_MAP
}

KV_TEMPLATE() {
  local KV_TEMPLATE_INPUT="$1"
  local -n KV_MAP_REF=$2
  local KV_OUT="$KV_TEMPLATE_INPUT"
  for KV_KEY in "${!KV_MAP_REF[@]}"; do
    KV_OUT="${KV_OUT//\{\{$KV_KEY\}\}/${KV_MAP_REF[$KV_KEY]}}"
  done
  printf '%s\n' "$KV_OUT"
}

KV_ROWS_FROM_HEAD() {
  local KV_INPUT_STREAM="$1"
  local KV_DELIM="${2:- }"
  local KV_HAS_HEAD="${3:-1}"
  local -a KV_LINES=()
  mapfile -t KV_LINES <<< "$KV_INPUT_STREAM"
  local -a KV_HEAD=()
  if [[ "$KV_HAS_HEAD" == "1" ]]; then
    read -ra KV_HEAD <<< "${KV_LINES[0]}"
    KV_LINES=("${KV_LINES[@]:1}")
  fi
  for KV_LINE in "${KV_LINES[@]}"; do
    [[ -z "$KV_LINE" ]] && continue
    local -A KV_ROW=()
    read -ra KV_COLS <<< "$KV_LINE"
    for KV_I in "${!KV_COLS[@]}"; do
      local KV_VAL="${KV_COLS[$KV_I]}"
      KV_ROW["$KV_I"]="$KV_VAL"
      [[ ${#KV_HEAD[@]} -gt "$KV_I" ]] && KV_ROW["${KV_HEAD[$KV_I]}"]="$KV_VAL"
    done
    declare -p KV_ROW
  done
}

EVKV() {
  local KV_INPUT="$1"
  local KV_TEMPLATE_INPUT="$2"

  if declare -p "$KV_INPUT" 2>/dev/null | grep -q 'declare \-A'; then
    local -n KV_MAP_REF="$KV_INPUT"
    KV_TEMPLATE "$KV_TEMPLATE_INPUT" KV_MAP_REF
    return
  fi

  if declare -p "$KV_INPUT" 2>/dev/null | grep -q 'declare \-a'; then
    local -n KV_ARR_REF="$KV_INPUT"
    for KV_NAME in "${KV_ARR_REF[@]}"; do
      local -n KV_ROW_REF="$KV_NAME"
      KV_TEMPLATE "$KV_TEMPLATE_INPUT" KV_ROW_REF
    done
    return
  fi

  if [[ "$KV_INPUT" == *$'\n'* ]]; then
    while read -r KV_ROW_DECL; do
      eval "$KV_ROW_DECL"
      KV_TEMPLATE "$KV_TEMPLATE_INPUT" KV_ROW
    done < <(KV_ROWS_FROM_HEAD "$KV_INPUT")
    return
  fi

  eval "$(KV_PARSE "$KV_INPUT")"
  local -n KV_MAP_REF=KV_MAP
  KV_TEMPLATE "$KV_TEMPLATE_INPUT" KV_MAP_REF
}


KV_PARSE() {
  local KV_INPUT="$1"
  local -A KV_MAP=()
  local KV_RE='([a-z_]+):'
  local KV_REST="$KV_INPUT"
  while [[ $KV_REST =~ $KV_RE ]]; do
    local KV_KEY="${BASH_REMATCH[1]}"
    local KV_AFTER_KEY="${KV_REST#*${KV_KEY}:}"
    if [[ $KV_AFTER_KEY =~ $KV_RE ]]; then
      local KV_VALUE="${KV_AFTER_KEY%%${BASH_REMATCH[1]}:*}"
      KV_MAP["$KV_KEY"]="${KV_VALUE%;}"
      KV_REST="${KV_AFTER_KEY#*$KV_VALUE}"
    else
      KV_MAP["$KV_KEY"]="${KV_AFTER_KEY%;}"
      break
    fi
  done
  declare -p KV_MAP
}

KV_EXTEND() {
  local KV_SRC_NAME="$1"
  local KV_BASE_NAME="$2"

  local -n KV_BASE_REF="$KV_BASE_NAME"

  if declare -p "$KV_SRC_NAME" 2>/dev/null | grep -q 'declare \-A'; then
    local -n KV_SRC_REF="$KV_SRC_NAME"
  else
    eval "$(KV_PARSE "$KV_SRC_NAME")"
    local -n KV_SRC_REF=KV_MAP
  fi

  for KV_KEY in "${!KV_SRC_REF[@]}"; do
    KV_BASE_REF["$KV_KEY"]="${KV_SRC_REF[$KV_KEY]}"
  done
}

KV_ALIAS_APPLY() {
  local -n KV_MAP_REF=$1
  local -n KV_ALIAS_REF=$2
  for KV_ALIAS_KEY in "${!KV_ALIAS_REF[@]}"; do
    if [[ -n "${KV_MAP_REF[$KV_ALIAS_KEY]+x}" ]]; then
      local KV_TARGET_KEY="${KV_ALIAS_REF[$KV_ALIAS_KEY]}"
      KV_MAP_REF["$KV_TARGET_KEY"]="${KV_MAP_REF[$KV_ALIAS_KEY]}"
      unset KV_MAP_REF["$KV_ALIAS_KEY"]
    fi
  done
}

KV_TEMPLATE() {
  local KV_TEMPLATE_INPUT="$1"
  local -n KV_MAP_REF=$2
  local KV_OUT="$KV_TEMPLATE_INPUT"
  for KV_KEY in "${!KV_MAP_REF[@]}"; do
    KV_OUT="${KV_OUT//\{\{$KV_KEY\}\}/${KV_MAP_REF[$KV_KEY]}}"
  done
  printf '%s\n' "$KV_OUT"
}

KV_ROWS_FROM_HEAD() {
  local KV_INPUT_STREAM="$1"
  local KV_DELIM="${2:- }"
  local KV_HAS_HEAD="${3:-1}"
  local -a KV_LINES=()
  mapfile -t KV_LINES <<< "$KV_INPUT_STREAM"
  local -a KV_HEAD=()
  if [[ "$KV_HAS_HEAD" == "1" ]]; then
    read -ra KV_HEAD <<< "${KV_LINES[0]}"
    KV_LINES=("${KV_LINES[@]:1}")
  fi
  for KV_LINE in "${KV_LINES[@]}"; do
    [[ -z "$KV_LINE" ]] && continue
    local -A KV_ROW=()
    read -ra KV_COLS <<< "$KV_LINE"
    for KV_I in "${!KV_COLS[@]}"; do
      local KV_VAL="${KV_COLS[$KV_I]}"
      KV_ROW["$KV_I"]="$KV_VAL"
      [[ ${#KV_HEAD[@]} -gt "$KV_I" ]] && KV_ROW["${KV_HEAD[$KV_I]}"]="$KV_VAL"
    done
    declare -p KV_ROW
  done
}

EVKV() {
  local KV_INPUT="$1"
  local KV_TEMPLATE_INPUT="$2"
  local KV_ALIAS_NAME="$3"

  if declare -p "$KV_ALIAS_NAME" 2>/dev/null | grep -q 'declare \-A'; then
    local -n KV_ALIAS_REF="$KV_ALIAS_NAME"
  else
    local -A KV_ALIAS_REF=()
  fi

  if declare -p "$KV_INPUT" 2>/dev/null | grep -q 'declare \-A'; then
    local -n KV_MAP_REF="$KV_INPUT"
    KV_ALIAS_APPLY KV_MAP_REF KV_ALIAS_REF
    KV_TEMPLATE "$KV_TEMPLATE_INPUT" KV_MAP_REF
    return
  fi

  if declare -p "$KV_INPUT" 2>/dev/null | grep -q 'declare \-a'; then
    local -n KV_ARR_REF="$KV_INPUT"
    for KV_NAME in "${KV_ARR_REF[@]}"; do
      local -n KV_ROW_REF="$KV_NAME"
      KV_ALIAS_APPLY KV_ROW_REF KV_ALIAS_REF
      KV_TEMPLATE "$KV_TEMPLATE_INPUT" KV_ROW_REF
    done
    return
  fi

  if [[ "$KV_INPUT" == *$'\n'* ]]; then
    while read -r KV_ROW_DECL; do
      eval "$KV_ROW_DECL"
      KV_ALIAS_APPLY KV_ROW KV_ALIAS_REF
      KV_TEMPLATE "$KV_TEMPLATE_INPUT" KV_ROW
    done < <(KV_ROWS_FROM_HEAD "$KV_INPUT")
    return
  fi

  eval "$(KV_PARSE "$KV_INPUT")"
  local -n KV_MAP_REF=KV_MAP
  KV_ALIAS_APPLY KV_MAP_REF KV_ALIAS_REF
  KV_TEMPLATE "$KV_TEMPLATE_INPUT" KV_MAP_REF
}

KV_PARSE() {
  local KV_INPUT="$1"
  local -A KV_MAP=()
  local KV_RE='([a-z_]+):'
  local KV_REST="$KV_INPUT"
  while [[ $KV_REST =~ $KV_RE ]]; do
    local KV_KEY="${BASH_REMATCH[1]}"
    local KV_AFTER_KEY="${KV_REST#*${KV_KEY}:}"
    if [[ $KV_AFTER_KEY =~ $KV_RE ]]; then
      local KV_VALUE="${KV_AFTER_KEY%%${BASH_REMATCH[1]}:*}"
      KV_MAP["$KV_KEY"]="${KV_VALUE%;}"
      KV_REST="${KV_AFTER_KEY#*$KV_VALUE}"
    else
      KV_MAP["$KV_KEY"]="${KV_AFTER_KEY%;}"
      break
    fi
  done
  declare -p KV_MAP
}

KV_EXTEND() {
  local KV_SRC_NAME="$1"
  local KV_DST_NAME="$2"

  local -n KV_DST_REF="$KV_DST_NAME"

  if declare -p "$KV_SRC_NAME" 2>/dev/null | grep -q 'declare \-A'; then
    local -n KV_SRC_REF="$KV_SRC_NAME"
    for KV_KEY in "${!KV_SRC_REF[@]}"; do
      KV_DST_REF["$KV_KEY"]="${KV_SRC_REF[$KV_KEY]}"
    done
    return
  fi

  eval "$(KV_PARSE "$KV_SRC_NAME")"
  local -n KV_SRC_REF=KV_MAP
  for KV_KEY in "${!KV_SRC_REF[@]}"; do
    KV_DST_REF["$KV_KEY"]="${KV_SRC_REF[$KV_KEY]}"
  done
}

KV_ALIAS_APPLY() {
  local -n KV_MAP_REF=$1
  local -n KV_ALIAS_REF=$2
  for KV_ALIAS_KEY in "${!KV_ALIAS_REF[@]}"; do
    if [[ -n "${KV_MAP_REF[$KV_ALIAS_KEY]+x}" ]]; then
      local KV_TARGET_KEY="${KV_ALIAS_REF[$KV_ALIAS_KEY]}"
      KV_MAP_REF["$KV_TARGET_KEY"]="${KV_MAP_REF[$KV_ALIAS_KEY]}"
      unset KV_MAP_REF["$KV_ALIAS_KEY"]
    fi
  done
}

KV_TEMPLATE() {
  local KV_TEMPLATE_INPUT="$1"
  local -n KV_MAP_REF=$2
  local KV_OUT="$KV_TEMPLATE_INPUT"
  for KV_KEY in "${!KV_MAP_REF[@]}"; do
    KV_OUT="${KV_OUT//\{\{$KV_KEY\}\}/${KV_MAP_REF[$KV_KEY]}}"
  done
  printf '%s\n' "$KV_OUT"
}

KV_ROWS_FROM_HEAD() {
  local KV_INPUT_STREAM="$1"
  local KV_DELIM="${2:- }"
  local KV_HAS_HEAD="${3:-1}"
  local -a KV_LINES=()
  mapfile -t KV_LINES <<< "$KV_INPUT_STREAM"
  local -a KV_HEAD=()
  if [[ "$KV_HAS_HEAD" == "1" ]]; then
    read -ra KV_HEAD <<< "${KV_LINES[0]}"
    KV_LINES=("${KV_LINES[@]:1}")
  fi
  for KV_LINE in "${KV_LINES[@]}"; do
    [[ -z "$KV_LINE" ]] && continue
    local -A KV_ROW=()
    read -ra KV_COLS <<< "$KV_LINE"
    for KV_I in "${!KV_COLS[@]}"; do
      local KV_VAL="${KV_COLS[$KV_I]}"
      KV_ROW["$KV_I"]="$KV_VAL"
      [[ ${#KV_HEAD[@]} -gt "$KV_I" ]] && KV_ROW["${KV_HEAD[$KV_I]}"]="$KV_VAL"
    done
    declare -p KV_ROW
  done
}

EVKV() {
  local KV_INPUT="$1"
  local KV_TEMPLATE_INPUT="$2"
  local KV_ALIAS_NAME="$3"

  if declare -p "$KV_ALIAS_NAME" 2>/dev/null | grep -q 'declare \-A'; then
    local -n KV_ALIAS_REF="$KV_ALIAS_NAME"
  else
    local -A KV_ALIAS_REF=()
  fi

  if declare -p "$KV_INPUT" 2>/dev/null | grep -q 'declare \-A'; then
    local -n KV_MAP_REF="$KV_INPUT"
    KV_ALIAS_APPLY KV_MAP_REF KV_ALIAS_REF
    KV_TEMPLATE "$KV_TEMPLATE_INPUT" KV_MAP_REF
    return
  fi

  if declare -p "$KV_INPUT" 2>/dev/null | grep -q 'declare \-a'; then
    local -n KV_ARR_REF="$KV_INPUT"
    for KV_NAME in "${KV_ARR_REF[@]}"; do
      local -n KV_ROW_REF="$KV_NAME"
      KV_ALIAS_APPLY KV_ROW_REF KV_ALIAS_REF
      KV_TEMPLATE "$KV_TEMPLATE_INPUT" KV_ROW_REF
    done
    return
  fi

  if [[ "$KV_INPUT" == *$'\n'* ]]; then
    while read -r KV_ROW_DECL; do
      eval "$KV_ROW_DECL"
      KV_ALIAS_APPLY KV_ROW KV_ALIAS_REF
      KV_TEMPLATE "$KV_TEMPLATE_INPUT" KV_ROW
    done < <(KV_ROWS_FROM_HEAD "$KV_INPUT")
    return
  fi

  eval "$(KV_PARSE "$KV_INPUT")"
  local -n KV_MAP_REF=KV_MAP
  KV_ALIAS_APPLY KV_MAP_REF KV_ALIAS_REF
  KV_TEMPLATE "$KV_TEMPLATE_INPUT" KV_MAP_REF
}


manage_mac() {
    echo -n "🔍 Enter search term (e.g., 'telemetry', 'safari', 'apple'): "
    read search_term
    
    # 1. Find all keys matching the search term across all domains
    echo "Gathering data... this may take a moment."
    local results=()
    # We loop through every domain and grep for the key
    for domain in $(defaults domains | tr ',' '\n' | sed 's/ //g'); do
        local matching_keys=$(defaults read "$domain" 2>/dev/null | grep -iE "$search_term" | grep "=" | sed 's/^[[:space:]]*//;s/[[:space:]]*=[[:space:]]*.*//;s/;//' | sort -u)
        
        while read -r key; do
            [[ -z "$key" ]] && continue
            results+=("$domain|$key")
        done <<< "$matching_keys"
    done

    if [[ ${#results[@]} -eq 0 ]]; then
        echo "❌ No keys found matching '$search_term'."
        return
    fi

    # 2. Display the Results
    echo "\nID  | Setting (Domain > Key) | Current Value"
    echo "--------------------------------------------"
    local i=1
    for entry in "${results[@]}"; do
        local d=$(echo "$entry" | cut -d'|' -f1)
        local k=$(echo "$entry" | cut -d'|' -f2)
        local val=$(defaults read "$d" "$k" 2>/dev/null | tr -d '\n' | cut -c1-30)
        printf "[%d] | %s > %s | %s\n" "$i" "$d" "$k" "$val"
        ((i++))
    done

    # 3. Interactive Toggle
    echo "\n👉 Enter the ID to modify (or 'q' to quit):"
    read choice
    [[ "$choice" == "q" ]] && return

    if [[ "$choice" -gt 0 && "$choice" -le ${#results[@]} ]]; then
        local selection="${results[$((choice-1))]}"
        local sel_domain=$(echo "$selection" | cut -d'|' -f1)
        local sel_key=$(echo "$selection" | cut -d'|' -f2)

        echo "Enter new value (e.g., 0, 1, true, false, or a string):"
        read new_val

        # Apply change
        sudo defaults write "$sel_domain" "$sel_key" "$new_val"
        echo "✅ Updated $sel_key to $new_val."
        
        # Proactive Restart
        echo "Do you want to restart affected services (Finder/Dock/ControlCenter)? (y/n)"
        read restart_choice
        if [[ "$restart_choice" == "y" ]]; then
            killall Finder Dock ControlCenter 2>/dev/null
            echo "🔄 Services restarted."
        fi
    else
        echo "❌ Invalid selection."
    fi
}


