#!/bin/bash
# auth.sh - Authentication functions for Calendly CLI

# Default config file location
CALENDLY_CONFIG_FILE="${CALENDLY_CONFIG_FILE:-$HOME/.calendly}"

# Load configuration from config file
# Supports key=value format: CALENDLY_API_KEY=, CALENDLY_API_BASE=, CALENDLY_DEBUG=
load_config() {
    local config_file="$CALENDLY_CONFIG_FILE"
    
    if [[ ! -f "$config_file" ]]; then
        debug "Config file not found: $config_file"
        return 0
    fi
    
    debug "Loading config from: $config_file"
    
    # Check file permissions
    check_file_permissions "$config_file"
    
    # Read config file line by line
    while IFS='=' read -r key value || [[ -n "$key" ]]; do
        # Skip comments and empty lines
        [[ "$key" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$key" ]] && continue
        
        # Trim whitespace
        key=$(echo "$key" | tr -d '[:space:]')
        value=$(echo "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        
        # Remove surrounding quotes if present
        value="${value#\"}"
        value="${value%\"}"
        value="${value#\'}"
        value="${value%\'}"
        
        case "$key" in
            CALENDLY_API_KEY)
                if [[ -z "$CALENDLY_API_KEY" ]]; then
                    CALENDLY_API_KEY="$value"
                    debug "Loaded API key from config (masked): $(mask_token "$value")"
                else
                    debug "API key already set from environment, skipping config"
                fi
                ;;
            CALENDLY_API_BASE)
                if [[ -z "$CALENDLY_API_BASE" ]]; then
                    CALENDLY_API_BASE="$value"
                    debug "Loaded API base URL from config: $value"
                fi
                ;;
            CALENDLY_DEBUG)
                if [[ "$DEBUG_LEVEL" -eq 0 ]] && [[ "$value" -gt 0 ]]; then
                    DEBUG_LEVEL="$value"
                    debug "Loaded debug level from config: $value"
                fi
                ;;
        esac
    done < "$config_file"
}

# Load API key from environment variable or config file
# Priority: CALENDLY_API_KEY env var > ~/.calendly config file
load_api_key() {
    # First load config file (env vars take priority)
    load_config
    
    if [[ -n "$CALENDLY_API_KEY" ]]; then
        API_KEY="$CALENDLY_API_KEY"
        if [[ "$DEBUG_LEVEL" -ge 2 ]]; then
            debug_verbose "Using API key: $(mask_token "$API_KEY")"
        else
            debug "API key loaded successfully"
        fi
    else
        log_error "No API key found."
        log_error "Set CALENDLY_API_KEY environment variable or add CALENDLY_API_KEY=your_token to ~/.calendly"
        return 1
    fi
    
    # Set default API base if not configured
    CALENDLY_API_BASE="${CALENDLY_API_BASE:-https://api.calendly.com}"
    debug "API base URL: $CALENDLY_API_BASE"
    
    export API_KEY CALENDLY_API_BASE
}

# Verify the API key is valid by calling /users/me
verify_auth() {
    debug "Verifying authentication..."
    local response
    # Note: Don't capture stderr (2>&1) as it would swallow debug output
    response=$(calendly_api GET "/users/me")
    local exit_code=$?
    
    if [[ $exit_code -ne 0 ]]; then
        log_error "Failed to verify authentication"
        return 1
    fi
    
    # Check if response contains an error
    if echo "$response" | jq -e '.message' >/dev/null 2>&1; then
        local error_msg
        error_msg=$(echo "$response" | jq -r '.message')
        log_error "$error_msg"
        return 1
    fi
    
    # Check if we got a valid user resource
    if echo "$response" | jq -e '.resource.uri' >/dev/null 2>&1; then
        debug "Authentication verified successfully"
        return 0
    fi
    
    log_error "Unexpected response from API"
    return 1
}

# Get current user URI (needed for many API calls)
get_current_user_uri() {
    local response
    response=$(calendly_api GET "/users/me")
    echo "$response" | jq -r '.resource.uri'
}

# Get current organization URI (needed for many API calls)
get_current_organization_uri() {
    local response
    response=$(calendly_api GET "/users/me")
    echo "$response" | jq -r '.resource.current_organization'
}
