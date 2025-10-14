# Key Management Tools for Windows

This directory contains scripts for key management in the project.

## SSH Key Generation for Git

The `generate_ssh_key.bat` script creates SSH keys for authentication with GitHub and GitLab repositories.

### Features

- Generates ed25519 SSH key pairs for secure authentication
- Configures sensible defaults that can be customized
- Adds the key to your SSH agent automatically
- Copies the public key to clipboard for easy setup
- Provides step-by-step instructions for GitHub and GitLab setup

### Prerequisites

- Git for Windows installed (which includes SSH)
- OpenSSH installed (included with recent Windows 10/11 versions)

### Usage

```cmd
REM Run from project root
tools\windows\key\generate_ssh_key.bat
```

### Default Values

- Key name: `git_ssh_key` (stored at `%USERPROFILE%\.ssh\git_ssh_key`)
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

- `generate_keystore.bat` - For generating Android keystore files
- `generate_pem.bat` - For generating PEM files for secure connections

## Troubleshooting

### SSH Agent Issues

If the script fails to add the key to the SSH agent, you may need to enable the OpenSSH Authentication Agent service:

1. Press Win+R, type `services.msc` and press Enter
2. Find "OpenSSH Authentication Agent" in the list
3. Right-click and select "Properties"
4. Change "Startup type" to "Automatic" and click "Start"
5. Click "Apply" and "OK"

### Git Bash Alternative

If you prefer using Git Bash, you can run the alternative macOS/Linux script:

```bash
# Run from project root in Git Bash
./tools/macos/key/generate_ssh_key.sh
```

## Security Best Practices

- Use a strong, unique passphrase for your SSH key
- Never share your private key
- Consider using different keys for different services
- Regularly rotate your keys for enhanced security 