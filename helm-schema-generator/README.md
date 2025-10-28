# Helm Schema Generator

Automatic JSON Schema generator for Helm charts `values.yaml` files.

## Description

This utility automates the generation of `values.schema.json` files from your Helm `values.yaml` files. The generated schema enables:

- Automatic value validation during development
- Intelligent autocompletion in compatible IDEs (VS Code, IntelliJ IDEA, etc.)
- Documentation of expected configuration structure
- Early detection of configuration errors

## Prerequisites

This utility requires the following tools installed on your system:

### Common Tools (Windows/Linux/macOS)

1. **Python 3** - Required to run genson
   - Windows: Download from [python.org](https://www.python.org/downloads/)
   - Linux: `sudo apt install python3` or `sudo yum install python3`
   - macOS: `brew install python3`

2. **yq** - YAML processor
   - Windows: `choco install yq`
   - Linux: `sudo apt install yq` or download from [GitHub](https://github.com/mikefarah/yq)
   - macOS: `brew install yq`

3. **jq** - JSON processor
   - Windows: `choco install jq`
   - Linux: `sudo apt install jq`
   - macOS: `brew install jq`

4. **genson** - JSON Schema generator (requires Python)
   - Installation: `pip install genson` or `pip3 install genson`

### Verify Installation

**Windows (PowerShell):**
```powershell
python --version
yq --version
jq --version
python -c "import genson; print('genson OK')"
```

**Linux/macOS (Bash):**
```bash
python3 --version
yq --version
jq --version
python3 -c "import genson; print('genson OK')"
```

## Installation

### Method 1: Quick Installation with Alias (Recommended)

This method installs a global `helmschema` alias that you can use from any directory.

#### Windows

```powershell
git clone https://github.com/your-username/helm-utils.git
cd helm-utils/helm-schema-generator
.\install.ps1
```

Then reload your profile:
```powershell
. $PROFILE
```

#### Linux/macOS

```bash
git clone https://github.com/your-username/helm-utils.git
cd helm-utils/helm-schema-generator
chmod +x install.sh
./install.sh
```

Then reload your profile:
```bash
source ~/.bashrc  # or ~/.zshrc if using zsh
```

### Method 2: Manual Usage

Download the script for your system:
- Windows: `Generate-ValuesSchema.ps1`
- Linux/macOS: `generate-values-schema.sh`

## Usage

### With Installed Alias (Recommended)

Once the alias is installed, navigate to your Helm chart directory and run:

```bash
# Basic usage
helmschema

# With custom definitions
helmschema definitions.json

# Force overwrite without prompting
helmschema --force
helmschema definitions.json --force
```

### Manual Usage

#### Windows (PowerShell)

```powershell
# Navigate to chart directory
cd C:\charts\my-app

# Basic usage
.\Generate-ValuesSchema.ps1

# With custom definitions
.\Generate-ValuesSchema.ps1 -DefinitionsFile definitions.json

# Custom files
.\Generate-ValuesSchema.ps1 -ValuesFile custom-values.yaml -OutputFile custom.schema.json

# Force overwrite
.\Generate-ValuesSchema.ps1 -Force
```

#### Linux/macOS (Bash)

```bash
# Navigate to chart directory
cd ~/charts/my-app

# Basic usage
./generate-values-schema.sh

# With custom definitions
./generate-values-schema.sh -d definitions.json

# Custom files
./generate-values-schema.sh -v custom-values.yaml -o custom.schema.json

# Force overwrite
./generate-values-schema.sh -f

# Show full help
./generate-values-schema.sh --help
```

## Available Options

### PowerShell (Generate-ValuesSchema.ps1)

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `-DefinitionsFile` | String | JSON file with custom definitions | - |
| `-ValuesFile` | String | Input values.yaml file | `values.yaml` |
| `-OutputFile` | String | Output file | `values.schema.json` |
| `-Force` | Switch | Force overwrite without prompting | `false` |

### Bash (generate-values-schema.sh)

| Option | Description | Default |
|--------|-------------|---------|
| `-d, --definitions FILE` | JSON file with custom definitions | - |
| `-v, --values FILE` | Input values.yaml file | `values.yaml` |
| `-o, --output FILE` | Output file | `values.schema.json` |
| `-f, --force` | Force overwrite without prompting | `false` |
| `-h, --help` | Show help | - |

## Custom Definitions

You can create a JSON file with reusable definitions to improve validation:

**definitions.json:**
```json
{
  "definitions": {
    "port": {
      "type": "integer",
      "minimum": 1,
      "maximum": 65535,
      "description": "Valid TCP/UDP port"
    },
    "imagePullPolicy": {
      "type": "string",
      "enum": ["Always", "IfNotPresent", "Never"],
      "description": "Image pull policy"
    },
    "resourceRequirements": {
      "type": "object",
      "properties": {
        "cpu": { "type": "string", "pattern": "^[0-9]+m?$" },
        "memory": { "type": "string", "pattern": "^[0-9]+[MGT]i?$" }
      }
    }
  }
}
```

Usage:
```bash
helmschema definitions.json
```

## Conflict Handling

If the `values.schema.json` file already exists, the script will offer interactive options:

- **[R] Replace**: Overwrite existing file
- **[B] Backup**: Create a timestamped backup before replacing
- **[C] Cancel**: Abort the operation

Example backup generated: `values.schema.json.20241028_143022.bak`

To avoid the interactive prompt, use the `--force` or `-Force` option.

## Examples

### Example 1: Basic generation with alias

```bash
$ cd ~/charts/my-application
$ helmschema
→ Checking dependencies...
✓ All dependencies are installed

→ Generating schema from values.yaml...
✓ Schema generated
```

### Example 2: With custom definitions

```bash
$ helmschema definitions.json
→ Checking dependencies...
✓ All dependencies are installed

→ Generating schema from values.yaml...
→ Adding definitions from definitions.json...
✓ Schema generated with definitions from definitions.json
```

### Example 3: Multiple values files

```bash
# PowerShell
.\Generate-ValuesSchema.ps1 -ValuesFile values-dev.yaml -OutputFile values-dev.schema.json

# Bash
./generate-values-schema.sh -v values-dev.yaml -o values-dev.schema.json
```

### Example 4: CI/CD usage

```yaml
# GitHub Actions example
- name: Generate Helm Schema
  run: |
    cd charts/my-app
    helmschema --force
    git add values.schema.json
```

## IDE Integration

### Visual Studio Code

1. Install the "YAML" extension by Red Hat
2. The schema will automatically apply to `values.yaml`
3. Enjoy real-time autocompletion and validation

### IntelliJ IDEA / PyCharm

1. The IDE will automatically detect the schema
2. Or configure manually at: `Settings → Languages & Frameworks → Schemas and DTDs → JSON Schema Mappings`

### Neovim / Vim

With plugins like `coc.nvim` or `yaml-language-server`:
```vim
" The schema will be automatically detected
```

## Generated Schema Structure

The generated schema includes:

- `$schema`: Reference to JSON Schema draft-07
- `type` and `properties`: Automatically inferred from `values.yaml`
- `definitions`: Custom definitions (if provided)

**Example generated schema:**

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "properties": {
    "replicaCount": {
      "type": "integer"
    },
    "image": {
      "type": "object",
      "properties": {
        "repository": { "type": "string" },
        "tag": { "type": "string" },
        "pullPolicy": { "type": "string" }
      }
    },
    "service": {
      "type": "object",
      "properties": {
        "type": { "type": "string" },
        "port": { "type": "integer" }
      }
    }
  }
}
```

## Dependency Verification

The scripts include automatic dependency verification. If any are missing, it will indicate what to install:

```bash
$ helmschema
→ Checking dependencies...
✗ Missing dependencies: genson

Please install:
  - genson: pip install genson (or pip3 install genson)
```

## Troubleshooting

### Error: "python not recognized as command"

Make sure Python is installed and in your PATH:

**Windows:**
```powershell
python --version
# If it doesn't work, reinstall Python from python.org and check "Add to PATH"
```

**Linux/macOS:**
```bash
python3 --version
# If not installed: sudo apt install python3 (Ubuntu) or brew install python3 (macOS)
```

### Error: "genson is not installed"

Install genson with pip:

```bash
# Windows
pip install genson

# Linux/macOS
pip3 install genson

# Or user-specific
pip install --user genson
```

### Error: "yq/jq not recognized as command"

Make sure the tools are installed and in your PATH:

**Windows:**
```powershell
choco install yq jq
```

**Linux:**
```bash
sudo apt install yq jq
```

**macOS:**
```bash
brew install yq jq
```

### Error: "File not found: values.yaml"

Run the script from the directory containing your `values.yaml` file, or specify the path:

```bash
helmschema -v /path/to/values.yaml
```

### Schema not automatically applied

1. Verify your IDE has JSON Schema support
2. Make sure the file is named exactly `values.schema.json`
3. Restart your IDE
4. In VS Code, verify the YAML extension is installed

### Alias not working after installation

**Windows:**
```powershell
# Reload profile
. $PROFILE

# Or verify the function exists
Get-Command helmschema
```

**Linux/macOS:**
```bash
# Reload profile
source ~/.bashrc  # or ~/.zshrc

# Verify the function exists
type helmschema
```

## Uninstallation

### Windows

Edit your PowerShell profile and remove the "Helm Schema Generator" section:
```powershell
notepad $PROFILE
```

### Linux/macOS

Edit your profile file and remove the `helmschema` function:
```bash
nano ~/.bashrc  # or ~/.zshrc
```

## Contributing

If you find bugs or have suggestions for improvements, please open an issue in the main repository.

## License

MIT - See [LICENSE](../LICENSE) in the root directory.
