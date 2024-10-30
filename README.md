# QPoint Preflight

A diagnostic tool that checks if your system meets the requirements for running QPoint.

## What it checks

- Root privileges
- Linux kernel version (≥ 5.10)
- Kernel lockdown status
- Cgroups v2 configuration
- BPF system settings
- Network interface configuration

## Usage

### Quick Run

Run directly using curl:
```bash
curl -sSL https://github.com/qpoint-io/preflight/releases/latest/download/preflight.sh | bash
```

Or wget:
```bash
wget -qO- https://github.com/qpoint-io/preflight/releases/latest/download/preflight.sh | bash
```

### Manual Download

1. Download the script:
```bash
wget https://github.com/qpoint-io/preflight/releases/latest/download/preflight.sh
```

2. (Optional) Verify the checksum:
```bash
# Download the checksum file
wget https://github.com/qpoint-io/preflight/releases/latest/download/checksum.txt

# Verify the file matches the checksum
sha256sum -c checksum.txt
```

3. Make it executable:
```bash
chmod +x preflight.sh
```

4. Run it:
```bash
sudo ./preflight.sh
```

## Development

### Prerequisites

- Docker (required for Mac or Windows development)
- Linux environment (native or containerized)

### Development Commands

Start a development container (required for Mac/Windows):
```bash
make dev
```

Format and lint the code:
```bash
make fmt
```

Install development tools:
```bash
make install-tools
```

### Release Process

To create a new release:

1. Create and push a new version tag:
```bash
git tag v1.0.0  # Increment version number as needed
git push origin v1.0.0
```

2. GitHub Actions will automatically:
   - Build the release artifacts
   - Create a new GitHub release
   - Upload the preflight script and checksum file

## Contributing

Contributions are welcome! Please follow these guidelines:

1. All shell code must pass shellcheck validation
2. Maintain the existing structure in `preflight.sh`
3. For architectural changes, please open an issue first

### Pull Request Process

1. Ensure your code passes `make fmt`
2. Add tests for new checks if applicable
3. Update documentation as needed
4. Submit a pull request with a clear description of the changes