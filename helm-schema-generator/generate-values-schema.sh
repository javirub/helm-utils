#!/usr/bin/env bash
#
# Generate a JSON Schema (draft-07) for a Helm values.yaml file.
#
# The schema is built in a temporary file and only moved over the output once
# every step succeeded, so a failing run never leaves a truncated or empty
# values.schema.json behind.

set -euo pipefail

# Default values
VALUES_FILE="values.yaml"
OUTPUT_FILE="values.schema.json"
DEFINITIONS_FILE=""
FORCE=false

# Colors (disabled when stdout is not a terminal)
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    CYAN='\033[0;36m'
    NC='\033[0m'
else
    RED='' GREEN='' YELLOW='' CYAN='' NC=''
fi

print_error()   { echo -e "${RED}✗ $1${NC}" >&2; }
print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠ $1${NC}"; }
print_info()    { echo -e "${CYAN}→ $1${NC}"; }

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

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
            [ $# -ge 2 ] || { print_error "Missing value for $1"; exit 1; }
            DEFINITIONS_FILE="$2"
            shift 2
            ;;
        -v|--values)
            [ $# -ge 2 ] || { print_error "Missing value for $1"; exit 1; }
            VALUES_FILE="$2"
            shift 2
            ;;
        -o|--output)
            [ $# -ge 2 ] || { print_error "Missing value for $1"; exit 1; }
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

command_exists yq || MISSING_DEPS+=("yq")
command_exists jq || MISSING_DEPS+=("jq")
if ! command_exists python3 && ! command_exists python; then
    MISSING_DEPS+=("python")
fi

if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
    print_error "Missing dependencies: ${MISSING_DEPS[*]}"
    echo ""
    echo -e "${YELLOW}Please install:${NC}"
    for dep in "${MISSING_DEPS[@]}"; do
        case $dep in
            yq)     echo "  - yq: https://github.com/mikefarah/yq (or sudo apt install yq / brew install yq)" ;;
            jq)     echo "  - jq: sudo apt install jq / brew install jq" ;;
            python) echo "  - python: sudo apt install python3 / brew install python" ;;
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

if ! "$PYTHON_CMD" -c "import genson" 2>/dev/null; then
    print_error "genson is not installed"
    echo -e "${YELLOW}Install with: pip install genson (or pip3 install genson)${NC}"
    exit 1
fi

print_success "All dependencies are installed"
echo ""

if [ ! -f "$VALUES_FILE" ]; then
    print_error "File not found: $VALUES_FILE"
    exit 1
fi

if [ -n "$DEFINITIONS_FILE" ] && [ ! -f "$DEFINITIONS_FILE" ]; then
    print_error "File not found: $DEFINITIONS_FILE"
    exit 1
fi

# Handle an already existing output file
if [ -f "$OUTPUT_FILE" ]; then
    if [ "$FORCE" = true ]; then
        print_info "Force mode: replacing existing file..."
    else
        print_warning "File $OUTPUT_FILE already exists"
        echo ""
        echo "Options:"
        echo "  [R] Replace existing file"
        echo "  [B] Create backup with timestamp"
        echo "  [C] Cancel operation"
        echo ""

        read -r -p "Choose an option (R/B/C): " choice

        case ${choice^^} in
            R)
                print_info "Replacing file..."
                ;;
            B)
                BACKUP_NAME="${OUTPUT_FILE}.$(date +%Y%m%d_%H%M%S).bak"
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
    fi
fi

# Build the schema in a temporary file so a failure never truncates the output
TEMP_FILE=$(mktemp "${OUTPUT_FILE}.XXXXXX.tmp")
cleanup() { rm -f "$TEMP_FILE"; }
trap cleanup EXIT

print_info "Generating schema from $VALUES_FILE..."
if ! yq -o=json "$VALUES_FILE" \
    | "$PYTHON_CMD" -m genson \
    | jq '. + {"$schema": "http://json-schema.org/draft-07/schema#"}' > "$TEMP_FILE"; then
    print_error "Error generating schema"
    exit 1
fi

if [ -n "$DEFINITIONS_FILE" ]; then
    print_info "Adding definitions from $DEFINITIONS_FILE..."
    DEFS_TEMP=$(mktemp "${OUTPUT_FILE}.XXXXXX.tmp")
    if ! jq --slurpfile defs "$DEFINITIONS_FILE" \
        'if $defs[0].definitions then .definitions = $defs[0].definitions else . end' \
        "$TEMP_FILE" > "$DEFS_TEMP"; then
        print_error "Error adding definitions"
        rm -f "$DEFS_TEMP"
        exit 1
    fi
    mv "$DEFS_TEMP" "$TEMP_FILE"
fi

mv "$TEMP_FILE" "$OUTPUT_FILE"
trap - EXIT

if [ -n "$DEFINITIONS_FILE" ]; then
    print_success "Schema generated in $OUTPUT_FILE with definitions from $DEFINITIONS_FILE"
else
    print_success "Schema generated in $OUTPUT_FILE"
fi
