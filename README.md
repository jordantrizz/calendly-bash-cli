# Calendly Bash CLI

A bash script for interacting with the Calendly API to create and manage events, as well as to manage webhooks.

## Requirements

- **bash** (4.0+)
- **curl** - for making HTTP requests
- **jq** - for parsing JSON responses

### Install Dependencies

**Ubuntu/Debian:**
```bash
sudo apt-get install curl jq
```

**macOS:**
```bash
brew install curl jq
```

**Fedora/RHEL:**
```bash
sudo dnf install curl jq
```

## Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/jordantrizz/calendly-bash-cli.git
   cd calendly-bash-cli
   ```

2. Make the script executable (if not already):
   ```bash
   chmod +x calendly
   ```

3. Optionally, add to your PATH:
   ```bash
   # Add to ~/.bashrc or ~/.zshrc
   export PATH="$PATH:/path/to/calendly-bash-cli"
   ```

## Authentication

The CLI requires a Calendly Personal Access Token. You can configure it in two ways:

### Option 1: Environment Variable (Recommended for CI/CD)
```bash
export CALENDLY_API_KEY="your_personal_access_token"
```

### Option 2: Config File (Recommended for personal use)
```bash
echo "your_personal_access_token" > ~/.calendly
chmod 600 ~/.calendly  # Secure the file
```

### Generate a Personal Access Token

1. Log in to your [Calendly account](https://calendly.com)
2. Navigate to **Integrations** → **API & Webhooks**
3. Click **Generate New Token**
4. Copy the token immediately (it won't be shown again!)

Direct link: https://calendly.com/integrations/api_webhooks

## Usage

```bash
# Show help
calendly help

# Show version
calendly version

# Test your authentication
calendly auth test

# Display your user information
calendly auth user
```

## Commands

| Command | Description |
|---------|-------------|
| `help` | Show help message |
| `version` | Show version information |
| `auth test` | Verify your API key is valid |
| `auth user` | Display current user information |

## Examples

### Verify Authentication
```bash
$ calendly auth test
Testing authentication...
✓ Authentication successful!
  User URI: https://api.calendly.com/users/abc123...
```

### Get User Information
```bash
$ calendly auth user
{
  "uri": "https://api.calendly.com/users/abc123...",
  "name": "John Doe",
  "email": "john@example.com",
  ...
}
```

## Project Structure

```
calendly-bash-cli/
├── calendly              # Main CLI script
├── lib/
│   ├── auth.sh          # Authentication functions
│   └── api.sh           # Core API request functions
├── config/
│   └── config.example   # Example configuration
├── README.md            # This file
├── CHANGELOG.md         # Release notes
└── TODO.md              # Development roadmap
```

## License

MIT License - see [LICENSE](LICENSE) for details.

## Contributing

Contributions are welcome! Please read the TODO.md file to see planned features.
