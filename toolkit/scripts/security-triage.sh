#!/bin/bash
# Security Triage Multi-Agent Wrapper Script

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TRIAGE_SCRIPT="$SCRIPT_DIR/security-triage.py"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to check dependencies
check_deps() {
    print_status $BLUE "🔍 Checking dependencies..."

    if ! command -v ollama >/dev/null 2>&1; then
        print_status $RED "❌ Ollama not found. Install from: https://ollama.com"
        exit 1
    fi

    if ! [ -f "$SCRIPT_DIR/llm-meeting-enhanced.py" ]; then
        print_status $RED "❌ Enhanced meeting orchestrator not found"
        exit 1
    fi

    print_status $GREEN "✅ All dependencies available"
}

# Function to show usage
show_usage() {
    cat << EOF
🛡️  Security Triage Multi-Agent System

Usage: $0 [COMMAND] [OPTIONS]

Commands:
    check       - Check dependencies
    sarif       - Analyze SARIF vulnerability file
    markdown    - Analyze markdown vulnerability file
    interactive - Interactive vulnerability input
    help        - Show this help

Examples:
    $0 sarif /path/to/report.sarif
    $0 markdown /path/to/vulns.md --enhanced-meeting
    $0 interactive

Options:
    --model MODEL           LLM model to use (default: llama3.2:latest)
    --output PATH          Output file path
    --enhanced-meeting     Also run enhanced meeting orchestrator

Dependencies:
    - Ollama (https://ollama.com)
    - Enhanced Meeting Orchestrator (llm-meeting-enhanced.py)
    - Python 3.8+

EOF
}

# Function to run interactive mode
interactive_mode() {
    print_status $BLUE "🛡️  Interactive Security Triage"
    echo

    # Get vulnerability details interactively
    echo "Enter vulnerability details (press Ctrl+D when done):"
    echo "Format example:"
    echo "# Vulnerability 1"
    echo "- Severity: High"
    echo "- Component: Authentication"
    echo "- Description: SQL injection in login form"
    echo

    # Create temp file for input
    temp_input="/tmp/security_input_$(date +%s).md"
    cat > "$temp_input"

    if [ ! -s "$temp_input" ]; then
        print_status $RED "❌ No input provided"
        rm -f "$temp_input"
        exit 1
    fi

    print_status $GREEN "✅ Input received, starting analysis..."

    # Run analysis
    python3 "$TRIAGE_SCRIPT" --input "$temp_input" --format markdown "$@"

    # Cleanup
    rm -f "$temp_input"
}

# Main script logic
case "${1:-help}" in
    "check")
        check_deps
        python3 "$TRIAGE_SCRIPT" --check-deps
        ;;

    "sarif")
        if [ -z "$2" ]; then
            print_status $RED "❌ SARIF file path required"
            show_usage
            exit 1
        fi

        check_deps
        sarif_file="$2"
        shift 2
        python3 "$TRIAGE_SCRIPT" --input "$sarif_file" --format sarif "$@"
        ;;

    "markdown")
        if [ -z "$2" ]; then
            print_status $RED "❌ Markdown file path required"
            show_usage
            exit 1
        fi

        check_deps
        markdown_file="$2"
        shift 2
        python3 "$TRIAGE_SCRIPT" --input "$markdown_file" --format markdown "$@"
        ;;

    "interactive")
        check_deps
        shift
        interactive_mode "$@"
        ;;

    "help"|"--help"|"-h")
        show_usage
        ;;

    *)
        print_status $RED "❌ Unknown command: $1"
        show_usage
        exit 1
        ;;
esac
