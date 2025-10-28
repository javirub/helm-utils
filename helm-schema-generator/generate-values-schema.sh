#!/bin/bash

# Default values
VALUES_FILE="values.yaml"
OUTPUT_FILE="values.schema.json"
DEFINITIONS_FILE=""
FORCE=false

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Print colored message
print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${CYAN}→ $1${NC}"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Show usage
usage() {
    cat << EOF
Usage: $0 [options]

Options:
    -d, --definitions FILE    JSON file with custom definitions
    -v, --values FILE         Input values.yaml file (default: values.yaml)
    -o, --output FILE         Output file (default: values.schema.json)
    -f, --force               Force overwrite without prompting
    -h, --help                Show this help

Examples:
    $0                                          # Basic usage
    $0 -d definitions.json                      # With definitions
    $0 -v custom-values.yaml -o custom.json     # Custom files
    $0 -f                                       # Force overwrite

EOF
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--definitions)
            DEFINITIONS_FILE="$2"
            shift 2
            ;;
        -v|--values)
            VALUES_FILE="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            print_error "Unknown option: $1"
            usage
            ;;
    esac
done

# Check dependencies
print_info "Checking dependencies..."
MISSING_DEPS=()

if ! command_exists yq; then
    MISSING_DEPS+=("yq")
fi

if ! command_exists jq; then
    MISSING_DEPS+=("jq")
fi

if ! command_exists python3 && ! command_exists python; then
    MISSING_DEPS+=("python")
fi

if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
    print_error "Missing dependencies: ${MISSING_DEPS[*]}"
    echo ""
    echo -e "${YELLOW}Please install:${NC}"
    for dep in "${MISSING_DEPS[@]}"; do
        case $dep in
            yq)
                echo "  - yq: https://github.com/mikefarah/yq (or sudo apt install yq / brew install yq)"
                ;;
            jq)
                echo "  - jq: sudo apt install jq / brew install jq"
                ;;
            python)
                echo "  - python: sudo apt install python3 / brew install python"
                ;;
        esac
    done
    exit 1
fi

# Determine python command
if command_exists python3; then
    PYTHON_CMD="python3"
else
    PYTHON_CMD="python"
fi

# Check genson
if ! $PYTHON_CMD -c "import genson" 2>/dev/null; then
    print_error "genson is not installed"
    echo -e "${YELLOW}Install with: pip install genson (or pip3 install genson)${NC}"
    exit 1
fi

print_success "All dependencies are installed"
echo ""

# Check if values file exists
if [ ! -f "$VALUES_FILE" ]; then
    print_error "File not found: $VALUES_FILE"
    exit 1
fi

# Check if output file already exists
if [ -f "$OUTPUT_FILE" ] && [ "$FORCE" = false ]; then
    print_warning "File $OUTPUT_FILE already exists"
    echo ""
    echo "Options:"
    echo "  [R] Replace existing file"
    echo "  [B] Create backup with timestamp"
    echo "  [C] Cancel operation"
    echo ""

    read -p "Choose an option (R/B/C): " choice

    case ${choice^^} in
        R)
            print_info "Replacing file..."
            ;;
        B)
            TIMESTAMP=$(date +%Y%m%d_%H%M%S)
            BACKUP_NAME="${OUTPUT_FILE}.${TIMESTAMP}.bak"
            cp "$OUTPUT_FILE" "$BACKUP_NAME"
            print_info "Backup created: $BACKUP_NAME"
            ;;
        C)
            print_error "Operation cancelled"
            exit 0
            ;;
        *)
            print_error "Invalid option. Operation cancelled"
            exit 1
            ;;
    esac
elif [ -f "$OUTPUT_FILE" ] && [ "$FORCE" = true ]; then
    print_info "Force mode: Replacing existing file..."
fi

# Generate basic schema
print_info "Generating schema from $VALUES_FILE..."
yq -o=json "$VALUES_FILE" | \
    $PYTHON_CMD -m genson | \
    jq '. + {"$schema": "http://json-schema.org/draft-07/schema#"}' > "$OUTPUT_FILE"

if [ $? -ne 0 ]; then
    print_error "Error generating schema"
    exit 1
fi

# Add definitions if provided
if [ -n "$DEFINITIONS_FILE" ]; then
    if [ -f "$DEFINITIONS_FILE" ]; then
        print_info "Adding definitions from $DEFINITIONS_FILE..."

        # Read schema and definitions
        TEMP_FILE=$(mktemp)
        jq --slurpfile defs "$DEFINITIONS_FILE" \
           'if $defs[0].definitions then .definitions = $defs[0].definitions else . end' \
           "$OUTPUT_FILE" > "$TEMP_FILE"

        if [ $? -eq 0 ]; then
            mv "$TEMP_FILE" "$OUTPUT_FILE"
            print_success "Schema generated with definitions from $DEFINITIONS_FILE"
        else
            print_error "Error adding definitions"
            rm -f "$TEMP_FILE"
            exit 1
        fi
    else
        print_error "File not found: $DEFINITIONS_FILE"
        exit 1
    fi
else
    print_success "Schema generated"
fi
