#!/bin/bash
# webhooks.sh - Webhook-related functions for Calendly CLI

# Webhooks command handler
# Usage: cmd_webhooks <subcommand> [args]
cmd_webhooks() {
    local subcommand="$1"
    shift || true
    
    case "$subcommand" in
        list)
            webhooks_list "$@"
            ;;
        create)
            webhooks_create "$@"
            ;;
        delete)
            webhooks_delete "$@"
            ;;
        events)
            webhooks_events "$@"
            ;;
        ""|help)
            webhooks_help
            ;;
        *)
            log_error "Unknown webhooks command: $subcommand"
            echo "Available commands: list, create, delete, events" >&2
            exit 1
            ;;
    esac
}

# Show webhooks help
webhooks_help() {
    cat <<EOF
calendly webhooks - Manage webhook subscriptions

USAGE:
    calendly webhooks <command> [arguments]

COMMANDS:
    list                        List webhook subscriptions
    create --url URL --events EVENTS
                                Create a new webhook subscription
    delete <uuid>               Delete a webhook subscription
    events                      List available webhook event types
    help                        Show this help message

OPTIONS for 'create':
    --url URL                   The webhook endpoint URL (required)
    --events EVENTS             Comma-separated list of events (required)
                                Run 'calendly webhooks events' to see valid events

EXAMPLES:
    calendly webhooks list
    calendly webhooks events
    calendly webhooks create --url https://example.com/webhook --events invitee.created,invitee.canceled
    calendly webhooks delete abc123-def456

EOF
}

# List available webhook event types
webhooks_events() {
    cat <<EOF
Available webhook event types:

  invitee.created                    - Triggered when a new invitee is created (someone books)
  invitee.canceled                   - Triggered when an invitee cancels their booking
  routing_form_submission.created    - Triggered when a routing form is submitted

Usage with 'webhooks create':
  calendly webhooks create --url https://example.com/hook --events invitee.created
  calendly webhooks create --url https://example.com/hook --events invitee.created,invitee.canceled

EOF
}

# List webhook subscriptions
# Shows both organization-scoped and user-scoped webhooks
webhooks_list() {
    debug "Fetching webhook subscriptions..."
    
    local org_uri
    org_uri=$(get_current_organization_uri)
    
    if [[ -z "$org_uri" ]] || [[ "$org_uri" == "null" ]]; then
        log_error "Failed to get current organization URI"
        return 1
    fi
    
    local user_uri
    user_uri=$(get_current_user_uri)
    
    if [[ -z "$user_uri" ]] || [[ "$user_uri" == "null" ]]; then
        log_error "Failed to get current user URI"
        return 1
    fi
    
    debug "Using organization URI: $org_uri"
    debug "Using user URI: $user_uri"
    
    # URL encode the URI parameters (use -n with echo to avoid trailing newline)
    local encoded_org_uri
    encoded_org_uri=$(echo -n "$org_uri" | jq -sRr @uri)
    local encoded_user_uri
    encoded_user_uri=$(echo -n "$user_uri" | jq -sRr @uri)
    
    # Fetch organization-scoped webhooks
    echo "Organization Webhooks:"
    local org_response
    org_response=$(calendly_api GET "/webhook_subscriptions?organization=${encoded_org_uri}&scope=organization")
    echo "$org_response" | jq '.collection'
    
    echo ""
    
    # Fetch user-scoped webhooks
    echo "User Webhooks:"
    local user_response
    user_response=$(calendly_api GET "/webhook_subscriptions?organization=${encoded_org_uri}&user=${encoded_user_uri}&scope=user")
    echo "$user_response" | jq '.collection'
}

# Create a webhook subscription
# POST /webhook_subscriptions
webhooks_create() {
    local url=""
    local events=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --url)
                url="$2"
                shift 2
                ;;
            --events)
                events="$2"
                shift 2
                ;;
            *)
                log_error "Unknown option: $1"
                echo "Usage: calendly webhooks create --url URL --events EVENTS" >&2
                return 1
                ;;
        esac
    done
    
    # Validate required parameters
    if [[ -z "$url" ]]; then
        log_error "Missing required option: --url"
        echo "Usage: calendly webhooks create --url URL --events EVENTS" >&2
        return 1
    fi
    
    if [[ -z "$events" ]]; then
        log_error "Missing required option: --events"
        echo "Usage: calendly webhooks create --url URL --events EVENTS" >&2
        return 1
    fi
    
    debug "Creating webhook subscription..."
    debug "URL: $url"
    debug "Events: $events"
    
    # Get organization URI
    local org_uri
    org_uri=$(get_current_organization_uri)
    
    if [[ -z "$org_uri" ]] || [[ "$org_uri" == "null" ]]; then
        log_error "Failed to get current organization URI"
        return 1
    fi
    
    debug "Using organization URI: $org_uri"
    
    # Convert comma-separated events to JSON array
    local events_json
    events_json=$(echo "$events" | tr ',' '\n' | jq -R . | jq -s .)
    
    # Build the JSON payload
    local payload
    payload=$(jq -n \
        --arg url "$url" \
        --arg org "$org_uri" \
        --argjson events "$events_json" \
        '{
            url: $url,
            events: $events,
            organization: $org,
            scope: "organization"
        }')
    
    debug "Payload: $payload"
    
    local response
    response=$(calendly_api POST "/webhook_subscriptions" "$payload")
    
    # Check for errors
    if echo "$response" | jq -e '.message' >/dev/null 2>&1; then
        local error_msg
        error_msg=$(echo "$response" | jq -r '.message')
        log_error "$error_msg"
        return 1
    fi
    
    # Output the created resource
    echo "$response" | jq '.resource'
}

# Delete a webhook subscription
# DELETE /webhook_subscriptions/{uuid}
webhooks_delete() {
    local uuid="$1"
    
    if [[ -z "$uuid" ]]; then
        log_error "Webhook UUID is required"
        echo "Usage: calendly webhooks delete <uuid>" >&2
        return 1
    fi
    
    debug "Deleting webhook subscription: $uuid"
    
    local response
    response=$(calendly_api DELETE "/webhook_subscriptions/${uuid}")
    
    # DELETE returns empty response on success (204 No Content)
    if [[ -z "$response" ]]; then
        echo "Webhook subscription deleted successfully"
    else
        # Check for errors
        if echo "$response" | jq -e '.message' >/dev/null 2>&1; then
            local error_msg
            error_msg=$(echo "$response" | jq -r '.message')
            log_error "$error_msg"
            return 1
        fi
        echo "$response" | jq '.'
    fi
}
