#!/bin/bash
# events.sh - Event-related functions for Calendly CLI

# Events command handler
# Usage: cmd_events <subcommand> [args]
cmd_events() {
    local subcommand="$1"
    shift || true
    
    case "$subcommand" in
        list)
            events_list "$@"
            ;;
        get)
            events_get "$@"
            ;;
        invitees)
            events_invitees "$@"
            ;;
        ""|help)
            events_help
            ;;
        *)
            log_error "Unknown events command: $subcommand"
            echo "Available commands: list, get, invitees" >&2
            exit 1
            ;;
    esac
}

# Show events help
events_help() {
    cat <<EOF
calendly events - Manage scheduled events

USAGE:
    calendly events <command> [arguments]

COMMANDS:
    list                List scheduled events for current user
    get <uuid>          Get details of a specific event
    invitees <uuid>     List invitees for a specific event
    help                Show this help message

EXAMPLES:
    calendly events list
    calendly events get abc123-def456
    calendly events invitees abc123-def456

EOF
}

# List scheduled events
# GET /scheduled_events?user=<user_uri>
events_list() {
    debug "Fetching scheduled events..."
    
    local user_uri
    user_uri=$(get_current_user_uri)
    
    if [[ -z "$user_uri" ]] || [[ "$user_uri" == "null" ]]; then
        log_error "Failed to get current user URI"
        return 1
    fi
    
    debug "Using user URI: $user_uri"
    
    # URL encode the user URI parameter
    local encoded_user_uri
    encoded_user_uri=$(echo "$user_uri" | jq -sRr @uri)
    
    local response
    response=$(calendly_api GET "/scheduled_events?user=${encoded_user_uri}")
    
    # Output the collection
    echo "$response" | jq '.collection'
}

# Get a specific event by UUID
# GET /scheduled_events/{uuid}
events_get() {
    local uuid="$1"
    
    if [[ -z "$uuid" ]]; then
        log_error "Event UUID is required"
        echo "Usage: calendly events get <uuid>" >&2
        return 1
    fi
    
    debug "Fetching event: $uuid"
    
    local response
    response=$(calendly_api GET "/scheduled_events/${uuid}")
    
    # Output the resource
    echo "$response" | jq '.resource'
}

# List invitees for a specific event
# GET /scheduled_events/{uuid}/invitees
events_invitees() {
    local uuid="$1"
    
    if [[ -z "$uuid" ]]; then
        log_error "Event UUID is required"
        echo "Usage: calendly events invitees <uuid>" >&2
        return 1
    fi
    
    debug "Fetching invitees for event: $uuid"
    
    local response
    response=$(calendly_api GET "/scheduled_events/${uuid}/invitees")
    
    # Output the collection
    echo "$response" | jq '.collection'
}
