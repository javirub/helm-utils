# Helm Utils

Collection of utilities for working with Helm, Kubernetes, and Helmfile.

## Description

This repository contains a collection of scripts and tools designed to facilitate and automate common tasks when working with Helm, Kubernetes, and Helmfile. Each utility is organized in its own folder with specific documentation.

## Repository Structure

```
helm-utils/
├── helm-schema-generator/    # JSON Schema generator for values.yaml
└── ...                        # More utilities coming soon
```

## Available Utilities

### [Helm Schema Generator](./helm-schema-generator/)

Automatic JSON Schema generator for Helm `values.yaml` files. Facilitates validation and autocompletion of configurations in compatible editors.

**Features:**
- Automatic schema generation from `values.yaml`
- Support for custom definitions
- Intelligent conflict handling with backups
- Compatible with IDE validation
- Cross-platform support (Windows, Linux, macOS)
- Easy installation with global alias

[View full documentation →](./helm-schema-generator/)

---

## General Requirements

Utilities may have different requirements depending on their function. Consult each utility's README for specific information about its dependencies.

Common tools used across utilities:
- Python 3
- Various command-line tools (yq, jq, etc.)

## Contributing

Contributions are welcome! If you have ideas for new utilities or improvements, feel free to open an issue or pull request.

### Adding a New Utility

1. Create a new directory for your utility
2. Include a comprehensive README.md with:
   - Description and features
   - Prerequisites and dependencies
   - Installation instructions
   - Usage examples
   - Troubleshooting guide
3. Add your scripts with proper documentation
4. Update this main README with a link to your utility

## License

This project is licensed under the MIT License. See the [LICENSE](./LICENSE) file for more details.
