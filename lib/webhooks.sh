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
        test)
            webhooks_test "$@"
            ;;
        ""|help)
            webhooks_help
            ;;
        *)
            log_error "Unknown webhooks command: $subcommand"
            echo "Available commands: list, create, delete, events, test" >&2
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
    test --url URL [--event EVENT]
                                Send a test webhook payload to a URL
    help                        Show this help message

OPTIONS for 'test':
    --url URL                   The webhook endpoint URL to test (required)
    --event EVENT               Event type to simulate (default: invitee.created)
                                Options: invitee.created, invitee.canceled

OPTIONS for 'create':
    --url URL                   The webhook endpoint URL (required)
    --events EVENTS             Comma-separated list of events (required)
                                Run 'calendly webhooks events' to see valid events

EXAMPLES:
    calendly webhooks list
    calendly webhooks events
    calendly webhooks create --url https://example.com/webhook --events invitee.created,invitee.canceled
    calendly webhooks delete abc123-def456
    calendly webhooks test --url https://example.com/webhook
    calendly webhooks test --url https://example.com/webhook --event invitee.canceled

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

# Send a test webhook payload to a URL
# This simulates what Calendly sends when an event occurs
webhooks_test() {
    local url=""
    local event_type="invitee.created"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --url)
                url="$2"
                shift 2
                ;;
            --event)
                event_type="$2"
                shift 2
                ;;
            *)
                log_error "Unknown option: $1"
                echo "Usage: calendly webhooks test --url URL [--event EVENT]" >&2
                return 1
                ;;
        esac
    done
    
    # Validate required parameters
    if [[ -z "$url" ]]; then
        log_error "Missing required option: --url"
        echo "Usage: calendly webhooks test --url URL [--event EVENT]" >&2
        return 1
    fi
    
    # Validate event type
    case "$event_type" in
        invitee.created|invitee.canceled)
            ;;
        *)
            log_error "Invalid event type: $event_type"
            echo "Valid event types: invitee.created, invitee.canceled" >&2
            return 1
            ;;
    esac
    
    debug "Sending test webhook to: $url"
    debug "Event type: $event_type"
    
    # Get current user info to make the payload more realistic
    local user_response
    user_response=$(calendly_api GET "/users/me")
    
    local user_uri
    user_uri=$(echo "$user_response" | jq -r '.resource.uri')
    local user_name
    user_name=$(echo "$user_response" | jq -r '.resource.name')
    local user_email
    user_email=$(echo "$user_response" | jq -r '.resource.email')
    local org_uri
    org_uri=$(echo "$user_response" | jq -r '.resource.current_organization')
    
    # Generate UUIDs for the test payload
    local event_uuid
    event_uuid=$(cat /proc/sys/kernel/random/uuid 2>/dev/null || uuidgen 2>/dev/null || echo "test-event-$(date +%s)")
    local invitee_uuid
    invitee_uuid=$(cat /proc/sys/kernel/random/uuid 2>/dev/null || uuidgen 2>/dev/null || echo "test-invitee-$(date +%s)")
    
    local now
    now=$(date -u +"%Y-%m-%dT%H:%M:%S.000000Z")
    
    local event_start
    event_start=$(date -u -d "+1 day" +"%Y-%m-%dT%H:%M:%S.000000Z" 2>/dev/null || date -u -v+1d +"%Y-%m-%dT%H:%M:%S.000000Z" 2>/dev/null || echo "2025-12-13T14:00:00.000000Z")
    local event_end
    event_end=$(date -u -d "+1 day +30 minutes" +"%Y-%m-%dT%H:%M:%S.000000Z" 2>/dev/null || date -u -v+1d -v+30M +"%Y-%m-%dT%H:%M:%S.000000Z" 2>/dev/null || echo "2025-12-13T14:30:00.000000Z")
    
    # Determine status based on event type
    local status="active"
    if [[ "$event_type" == "invitee.canceled" ]]; then
        status="canceled"
    fi
    
    # Build a realistic webhook payload based on Calendly's documented structure
    local payload
    payload=$(jq -n \
        --arg created_at "$now" \
        --arg created_by "$user_uri" \
        --arg event "$event_type" \
        --arg event_uuid "$event_uuid" \
        --arg invitee_uuid "$invitee_uuid" \
        --arg org_uri "$org_uri" \
        --arg user_uri "$user_uri" \
        --arg user_name "$user_name" \
        --arg user_email "$user_email" \
        --arg status "$status" \
        --arg event_start "$event_start" \
        --arg event_end "$event_end" \
        '{
            "created_at": $created_at,
            "created_by": $created_by,
            "event": $event,
            "payload": {
                "cancel_url": ("https://calendly.com/cancellations/" + $invitee_uuid),
                "created_at": $created_at,
                "email": "test-invitee@example.com",
                "event": ("https://api.calendly.com/scheduled_events/" + $event_uuid),
                "first_name": "Test",
                "last_name": "Invitee",
                "name": "Test Invitee",
                "new_invitee": null,
                "old_invitee": null,
                "payment": null,
                "questions_and_answers": [],
                "reschedule_url": ("https://calendly.com/reschedulings/" + $invitee_uuid),
                "rescheduled": false,
                "routing_form_submission": null,
                "scheduled_event": {
                    "created_at": $created_at,
                    "end_time": $event_end,
                    "event_guests": [],
                    "event_memberships": [
                        {
                            "user": $user_uri,
                            "user_email": $user_email,
                            "user_name": $user_name
                        }
                    ],
                    "event_type": "https://api.calendly.com/event_types/TEST-EVENT-TYPE",
                    "invitees_counter": {
                        "active": 1,
                        "limit": 1,
                        "total": 1
                    },
                    "location": {
                        "location": null,
                        "type": "custom"
                    },
                    "name": "Test Meeting (Webhook Test)",
                    "start_time": $event_start,
                    "status": $status,
                    "updated_at": $created_at,
                    "uri": ("https://api.calendly.com/scheduled_events/" + $event_uuid)
                },
                "status": $status,
                "text_reminder_number": null,
                "timezone": "America/New_York",
                "tracking": {
                    "utm_campaign": null,
                    "utm_source": "calendly-cli-test",
                    "utm_medium": null,
                    "utm_content": null,
                    "utm_term": null,
                    "salesforce_uuid": null
                },
                "updated_at": $created_at,
                "uri": ("https://api.calendly.com/scheduled_events/" + $event_uuid + "/invitees/" + $invitee_uuid)
            }
        }')
    
    debug "Payload: $payload"
    
    echo "Sending test '$event_type' webhook to: $url"
    echo ""
    
    # Send the webhook using curl
    local http_code
    local response_body
    
    # Use curl to send the POST request and capture both status code and body
    response_body=$(curl -s -w "\n%{http_code}" -X POST "$url" \
        -H "Content-Type: application/json" \
        -H "X-Calendly-Webhook-Signature: test-signature-not-valid-for-verification" \
        -d "$payload")
    
    # Extract HTTP status code (last line)
    http_code=$(echo "$response_body" | tail -n1)
    # Extract response body (all but last line)
    response_body=$(echo "$response_body" | sed '$d')
    
    echo "HTTP Status Code: $http_code"
    
    if [[ "$http_code" -ge 200 ]] && [[ "$http_code" -lt 300 ]]; then
        log_info "Webhook test successful!"
    else
        log_warn "Webhook returned non-2xx status code"
    fi
    
    if [[ -n "$response_body" ]]; then
        echo ""
        echo "Response Body:"
        # Try to pretty-print if it's JSON, otherwise just print raw
        if echo "$response_body" | jq . >/dev/null 2>&1; then
            echo "$response_body" | jq .
        else
            echo "$response_body"
        fi
    fi
    
    echo ""
    echo "Test payload sent:"
    echo "$payload" | jq .
}