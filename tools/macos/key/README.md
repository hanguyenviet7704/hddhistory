# Key Management Tools

This directory contains scripts for key management in the project.

## SSH Key Generation for Git

The `generate_ssh_key.sh` script creates SSH keys for authentication with GitHub and GitLab repositories.

### Features

- Generates ed25519 SSH key pairs for secure authentication
- Configures sensible defaults that can be customized
- Adds the key to your SSH agent automatically
- Copies the public key to clipboard for easy setup
- Provides step-by-step instructions for GitHub and GitLab setup

### Usage

```bash
# Run from project root
./tools/macos/key/generate_ssh_key.sh
```

### Default Values

- Key name: `git_ssh_key` (stored at `~/.ssh/git_ssh_key`)
- Passphrase: `git_ssh_pass` (configurable during generation)
- Email: Uses your global Git email if available

### Step-by-Step Process

1. Run the script
2. Follow prompts to configure your key details
3. The public key will be copied to your clipboard
4. Add the key to your GitHub/GitLab account
5. Test your connection with `ssh -T git@github.com` or `ssh -T git@gitlab.com`
6. Update your repository remote URLs to use SSH

### Existing Keys

For existing keystore generation tools, see:

- `generate_keystore.sh` - For generating Android keystore files
- `generate_pem.sh` - For generating PEM files for secure connections

## Security Best Practices

- Use a strong, unique passphrase for your SSH key
- Never share your private key
- Consider using different keys for different services
- Regularly rotate your keys for enhanced security 