#!/bin/bash
# logging.sh - Logging and debug functions for Calendly CLI

# Color codes for terminal output
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Debug levels:
# 0 = off (default)
# 1 = basic debug output (-d)
# 2 = verbose debug with masked tokens (-dd)
# 3 = curl command debug with raw responses (-ddd)
DEBUG_LEVEL="${DEBUG_LEVEL:-0}"

# Set debug level
# Usage: set_debug_level LEVEL
set_debug_level() {
    DEBUG_LEVEL="$1"
    export DEBUG_LEVEL
}

# Mask a token to only show first 4 characters
# Usage: mask_token "eyJhbGci..." -> "eyJh****"
mask_token() {
    local token="$1"
    if [[ ${#token} -gt 4 ]]; then
        echo "${token:0:4}****"
    else
        echo "****"
    fi
}

# Debug output (only shown when DEBUG_LEVEL >= 1)
# Usage: debug "message"
debug() {
    if [[ "$DEBUG_LEVEL" -ge 1 ]]; then
        echo -e "${CYAN}[DEBUG]${NC} $*" >&2
    fi
}

# Verbose debug output (only shown when DEBUG_LEVEL >= 2)
# Usage: debug_verbose "message"
debug_verbose() {
    if [[ "$DEBUG_LEVEL" -ge 2 ]]; then
        echo -e "${CYAN}[DEBUG]${NC} $*" >&2
    fi
}

# Curl command debug output (only shown when DEBUG_LEVEL >= 3)
# Usage: debug_curl "message"
debug_curl() {
    if [[ "$DEBUG_LEVEL" -ge 3 ]]; then
        echo -e "${CYAN}[DEBUG]${NC} $*" >&2
    fi
}

# Debug output for API calls
# Usage: debug_api METHOD URL [DATA]
debug_api() {
    local method="$1"
    local url="$2"
    local data="$3"
    
    if [[ "$DEBUG_LEVEL" -ge 1 ]]; then
        debug "API Request: $method $url"
        if [[ -n "$data" ]] && [[ "$DEBUG_LEVEL" -ge 2 ]]; then
            debug_verbose "Request body: $data"
        fi
    fi
}

# Debug output for API responses
# Usage: debug_api_response RESPONSE
debug_api_response() {
    local response="$1"
    
    if [[ "$DEBUG_LEVEL" -ge 2 ]]; then
        debug_verbose "API Response: $response"
    fi
}

# Output a reproducible curl command (only shown when DEBUG_LEVEL >= 3)
# Usage: debug_curl_command METHOD URL API_KEY [DATA]
debug_curl_command() {
    local method="$1"
    local url="$2"
    local api_key="$3"
    local data="$4"
    
    if [[ "$DEBUG_LEVEL" -ge 3 ]]; then
        local masked_token
        masked_token=$(mask_token "$api_key")
        
        local curl_cmd="curl -s -X $method '$url'"
        curl_cmd+=" -H 'Authorization: Bearer $masked_token'"
        curl_cmd+=" -H 'Content-Type: application/json'"
        if [[ -n "$data" ]]; then
            curl_cmd+=" -d '$data'"
        fi
        
        debug_curl "Reproducible curl command (token masked):"
        debug_curl "$curl_cmd"
    fi
}

# Output raw curl response (only shown when DEBUG_LEVEL >= 3)
# Usage: debug_curl_response RESPONSE
debug_curl_response() {
    local response="$1"
    
    if [[ "$DEBUG_LEVEL" -ge 3 ]]; then
        debug_curl "Raw curl response:"
        debug_curl "$response"
    fi
}

# Log info message (always shown)
# Usage: log_info "message"
log_info() {
    echo "[INFO] $*" >&2
}

# Log error message (always shown)
# Usage: log_error "message"
log_error() {
    echo "[ERROR] $*" >&2
}

# Log warning message (always shown)
# Usage: log_warn "message"
log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*" >&2
}

# Check file permissions and warn if too open
# Usage: check_file_permissions "/path/to/file"
check_file_permissions() {
    local file="$1"
    
    if [[ ! -f "$file" ]]; then
        return 0
    fi
    
    # Get file permissions (last 3 digits of octal)
    local perms
    perms=$(stat -c "%a" "$file" 2>/dev/null || stat -f "%OLp" "$file" 2>/dev/null)
    
    # Check if group or others have any permissions
    if [[ "${perms:1:1}" != "0" ]] || [[ "${perms:2:1}" != "0" ]]; then
        log_warn "Config file $file has insecure permissions ($perms)."
        log_warn "Consider running: chmod 600 $file"
    fi
}
