#!/bin/bash
# api.sh - Core API request functions for Calendly CLI

# Default Calendly API base URL (can be overridden by config)
# Note: CALENDLY_API_BASE is set by load_api_key() from config or defaults to this
: "${CALENDLY_API_BASE:=https://api.calendly.com}"

# Make an API request to Calendly
# Usage: calendly_api METHOD ENDPOINT [DATA]
# Example: calendly_api GET "/users/me"
# Example: calendly_api POST "/webhook_subscriptions" '{"url":"...","events":["..."]}'
calendly_api() {
    local method="$1"
    local endpoint="$2"
    local data="$3"
    
    if [[ -z "$API_KEY" ]]; then
        log_error "API_KEY not set. Call load_api_key first."
        return 1
    fi
    
    if [[ -z "$method" ]] || [[ -z "$endpoint" ]]; then
        log_error "Method and endpoint are required"
        return 1
    fi
    
    local full_url="${CALENDLY_API_BASE}${endpoint}"
    
    # Debug output for API call
    debug_api "$method" "$full_url" "$data"
    
    # Debug level 3: output reproducible curl command
    debug_curl_command "$method" "$full_url" "$API_KEY" "$data"
    
    local curl_args=(
        -s
        -X "$method"
        "$full_url"
        -H "Authorization: Bearer $API_KEY"
        -H "Content-Type: application/json"
    )
    
    # Add data if provided
    if [[ -n "$data" ]]; then
        curl_args+=(-d "$data")
    fi
    
    local response
    response=$(curl "${curl_args[@]}")
    
    # Debug output for response
    debug_api_response "$response"
    
    # Debug level 3: output raw curl response
    debug_curl_response "$response"
    
    echo "$response"
}

# Make a paginated API request and return all results
# Usage: calendly_api_paginated ENDPOINT [PARAMS]
# Returns all pages concatenated as a JSON array
calendly_api_paginated() {
    local endpoint="$1"
    local params="$2"
    local all_results="[]"
    local next_page=""
    local page_token=""
    
    while true; do
        local url="$endpoint"
        if [[ -n "$params" ]] && [[ -n "$page_token" ]]; then
            url="${endpoint}?${params}&page_token=${page_token}"
        elif [[ -n "$params" ]]; then
            url="${endpoint}?${params}"
        elif [[ -n "$page_token" ]]; then
            url="${endpoint}?page_token=${page_token}"
        fi
        
        local response
        response=$(calendly_api GET "$url")
        
        # Extract collection from response
        local collection
        collection=$(echo "$response" | jq -r '.collection // []')
        
        # Merge with existing results
        all_results=$(echo "$all_results" "$collection" | jq -s 'add')
        
        # Check for next page
        next_page=$(echo "$response" | jq -r '.pagination.next_page_token // empty')
        
        if [[ -z "$next_page" ]]; then
            break
        fi
        
        page_token="$next_page"
    done
    
    echo "$all_results"
}
