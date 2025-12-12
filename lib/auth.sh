#!/bin/bash
# auth.sh - Authentication functions for Calendly CLI

# Load API key from environment variable or config file
# Priority: CALENDLY_API_KEY env var > ~/.calendly file
load_api_key() {
    if [[ -n "$CALENDLY_API_KEY" ]]; then
        API_KEY="$CALENDLY_API_KEY"
    elif [[ -f "$HOME/.calendly" ]]; then
        API_KEY=$(cat "$HOME/.calendly" | tr -d '[:space:]')
        if [[ -z "$API_KEY" ]]; then
            echo "Error: ~/.calendly file is empty" >&2
            return 1
        fi
    else
        echo "Error: No API key found." >&2
        echo "Set CALENDLY_API_KEY environment variable or create ~/.calendly file" >&2
        return 1
    fi
    export API_KEY
}

# Verify the API key is valid by calling /users/me
verify_auth() {
    local response
    response=$(calendly_api GET "/users/me" 2>&1)
    local exit_code=$?
    
    if [[ $exit_code -ne 0 ]]; then
        echo "Error: Failed to verify authentication" >&2
        return 1
    fi
    
    # Check if response contains an error
    if echo "$response" | jq -e '.message' >/dev/null 2>&1; then
        local error_msg
        error_msg=$(echo "$response" | jq -r '.message')
        echo "Error: $error_msg" >&2
        return 1
    fi
    
    # Check if we got a valid user resource
    if echo "$response" | jq -e '.resource.uri' >/dev/null 2>&1; then
        return 0
    fi
    
    echo "Error: Unexpected response from API" >&2
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
