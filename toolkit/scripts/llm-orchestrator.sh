#!/bin/bash
# LLM Orchestrator for Mrs. Violet Noire Project
# Coordinates local Ollama models for content generation and code analysis

set -e

# Configuration
OLLAMA_HOST="${OLLAMA_HOST:-http://localhost:11434}"
DEFAULT_MODEL="${OLLAMA_MODEL:-llama3.1}"
TOOLKIT_DIR="$(dirname "$0")"
PROJECT_ROOT="$(dirname "$(dirname "$TOOLKIT_DIR")")"
GLOBAL_PERSONA_CONFIG="$TOOLKIT_DIR/../config/global-persona.yaml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Load global Violet Noire Assistant persona
load_global_persona() {
    if [[ -f "$GLOBAL_PERSONA_CONFIG" ]]; then
        # Extract the system prompt from YAML (basic parsing)
        local global_prompt=$(grep -A 20 "system_prompt:" "$GLOBAL_PERSONA_CONFIG" | sed '1d' | sed 's/^      //' | sed '/^[[:space:]]*$/d' | head -n -1)
        echo "$global_prompt"
    else
        # Fallback if config file doesn't exist
        echo "You are Violet Noire, the AI voice behind a murder mystery book review brand. Your tone is intelligent, witty, and slightly mysterious. You're passionate about murder mysteries, psychological thrillers, and classic whodunits. Always maintain brand consistency and literary sophistication."
    fi
}

# Global persona context
GLOBAL_PERSONA_CONTEXT=$(load_global_persona)

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if Ollama is running
check_ollama() {
    log "Checking Ollama connectivity..."
    if curl -s "$OLLAMA_HOST/api/tags" > /dev/null 2>&1; then
        success "Ollama is running at $OLLAMA_HOST"
        return 0
    else
        error "Ollama is not running at $OLLAMA_HOST"
        error "Please start Ollama: ollama serve"
        return 1
    fi
}

# List available models
list_models() {
    log "Fetching available models..."
    curl -s "$OLLAMA_HOST/api/tags" | jq -r '.models[]?.name // empty' 2>/dev/null || {
        error "Failed to fetch models. Is Ollama running?"
        return 1
    }
}

# Pull a model if not available
ensure_model() {
    local model="$1"
    log "Checking if model '$model' is available..."

    if curl -s "$OLLAMA_HOST/api/tags" | jq -r '.models[]?.name' | grep -q "^$model$"; then
        success "Model '$model' is available"
        return 0
    else
        warning "Model '$model' not found. Attempting to pull..."
        ollama pull "$model" || {
            error "Failed to pull model '$model'"
            return 1
        }
        success "Model '$model' pulled successfully"
    fi
}

# Generate content using Ollama with global persona context
generate_content() {
    local model="${1:-$DEFAULT_MODEL}"
    local prompt="$2"
    local temperature="${3:-0.7}"
    local max_tokens="${4:-2048}"

    if [[ -z "$prompt" ]]; then
        error "Prompt is required"
        return 1
    fi

    # Prepend global persona context to all prompts
    local enhanced_prompt="$GLOBAL_PERSONA_CONTEXT

$prompt"

    log "Generating content with model: $model (with global Violet Noire context)"

    local payload=$(jq -n \
        --arg model "$model" \
        --arg prompt "$enhanced_prompt" \
        --argjson temperature "$temperature" \
        --argjson max_tokens "$max_tokens" \
        '{
            model: $model,
            prompt: $prompt,
            stream: false,
            options: {
                temperature: $temperature,
                num_predict: $max_tokens
            }
        }')

    curl -s -X POST "$OLLAMA_HOST/api/generate" \
        -H "Content-Type: application/json" \
        -d "$payload" | jq -r '.response // empty' || {
        error "Failed to generate content"
        return 1
    }
}

# Mrs. Violet Noire specific content generation
generate_mystery_review() {
    local book_title="$1"
    local author="$2"
    local model="${3:-$DEFAULT_MODEL}"

    local prompt="As Mrs. Violet Noire, a sophisticated curator of dark literary mysteries, write an elegant and insightful review of '$book_title' by $author.

Your writing style should be:
- Gothic and atmospheric
- Intellectually sophisticated
- Rich in literary analysis
- Focused on psychological depth
- Maintaining an air of mystery

Include analysis of:
- Plot structure and pacing
- Character development
- Atmospheric elements
- Psychological themes
- How it fits within the mystery genre

Write approximately 300-400 words in Mrs. Violet Noire's distinctive voice."

    log "Generating mystery review for '$book_title' by $author"
    generate_content "$model" "$prompt" "0.8" "1000"
}

# Generate meta description for SEO
generate_meta_description() {
    local page_type="$1"
    local content_focus="$2"
    local model="${3:-$DEFAULT_MODEL}"

    local prompt="Generate an SEO-optimized meta description for the Mrs. Violet Noire mystery book review website.

Page type: $page_type
Content focus: $content_focus

Requirements:
- 150-160 characters maximum
- Include relevant mystery/thriller keywords
- Compelling and clickable
- Reflects the gothic, sophisticated brand
- Avoid keyword stuffing

Generate only the meta description text, no explanations."

    log "Generating meta description for $page_type page"
    generate_content "$model" "$prompt" "0.5" "200"
}

# Code analysis and suggestions
analyze_code() {
    local file_path="$1"
    local model="${2:-codellama}"

    if [[ ! -f "$file_path" ]]; then
        error "File not found: $file_path"
        return 1
    fi

    local file_content=$(cat "$file_path")
    local file_extension="${file_path##*.}"

    local prompt="Analyze this $file_extension code for the Mrs. Violet Noire mystery book review website and provide suggestions for improvement:

\`\`\`$file_extension
$file_content
\`\`\`

Focus on:
- Code quality and best practices
- Performance optimizations
- Accessibility improvements
- Security considerations
- Maintainability
- Gothic/mystery theme integration opportunities

Provide specific, actionable suggestions."

    log "Analyzing code in $file_path"
    generate_content "$model" "$prompt" "0.3" "2048"
}

# Interactive mode
interactive_mode() {
    echo -e "${PURPLE}╔════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║    Mrs. Violet Noire LLM Assistant     ║${NC}"
    echo -e "${PURPLE}╚════════════════════════════════════════╝${NC}"
    echo ""

    while true; do
        echo -e "${BLUE}Available commands:${NC}"
        echo "  1) Generate mystery book review"
        echo "  2) Generate meta description"
        echo "  3) Analyze code file"
        echo "  4) Custom prompt"
        echo "  5) List available models"
        echo "  6) Exit"
        echo ""

        read -p "Choose an option (1-6): " choice

        case $choice in
            1)
                read -p "Book title: " book_title
                read -p "Author: " author
                echo ""
                generate_mystery_review "$book_title" "$author"
                ;;
            2)
                read -p "Page type (home/review/author): " page_type
                read -p "Content focus: " content_focus
                echo ""
                generate_meta_description "$page_type" "$content_focus"
                ;;
            3)
                read -p "File path: " file_path
                echo ""
                analyze_code "$file_path"
                ;;
            4)
                read -p "Enter your prompt: " custom_prompt
                echo ""
                generate_content "$DEFAULT_MODEL" "$custom_prompt"
                ;;
            5)
                list_models
                ;;
            6)
                echo "Goodbye!"
                exit 0
                ;;
            *)
                warning "Invalid option. Please choose 1-6."
                ;;
        esac

        echo ""
        echo "─────────────────────────────────────────"
        echo ""
    done
}

# Main command handling
case "${1:-}" in
    "check")
        check_ollama
        ;;
    "models")
        list_models
        ;;
    "pull")
        if [[ -z "$2" ]]; then
            error "Model name required: $0 pull <model_name>"
            exit 1
        fi
        ensure_model "$2"
        ;;
    "review")
        if [[ -z "$2" || -z "$3" ]]; then
            error "Usage: $0 review <book_title> <author> [model]"
            exit 1
        fi
        generate_mystery_review "$2" "$3" "$4"
        ;;
    "meta")
        if [[ -z "$2" || -z "$3" ]]; then
            error "Usage: $0 meta <page_type> <content_focus> [model]"
            exit 1
        fi
        generate_meta_description "$2" "$3" "$4"
        ;;
    "analyze")
        if [[ -z "$2" ]]; then
            error "Usage: $0 analyze <file_path> [model]"
            exit 1
        fi
        analyze_code "$2" "$3"
        ;;
    "generate")
        if [[ -z "$2" ]]; then
            error "Usage: $0 generate <prompt> [model] [temperature] [max_tokens]"
            exit 1
        fi
        generate_content "$3" "$2" "$4" "$5"
        ;;
    "meeting")
        # LLM Meeting: consult all personas and summarize
        title="$2"
        agenda="$3"
        if [[ -z "$title" || -z "$agenda" ]]; then
            error "Usage: $0 meeting <title> <agenda>"
            exit 1
        fi
        check_ollama || exit 1
        PERSONA_DIR="$PROJECT_ROOT/toolkit/prompts"
        SUMMARY_FILE="/tmp/llm_meeting_summary_$$.txt"
        > "$SUMMARY_FILE"
        echo -e "🧑‍💼 LLM Meeting: $title\n📝 Agenda: $agenda\n----------------------------------------" | tee -a "$SUMMARY_FILE"
        for persona in "$PERSONA_DIR"/*.md; do
            persona_name=$(basename "$persona" .md)
            prompt="You are the persona described below. Participate in a meeting with the user and other personas. The meeting agenda is: '$agenda'. Provide your input, suggestions, and concerns.\n\nPersona Description:\n$(cat "$persona")\n\nMeeting Title: $title\nAgenda: $agenda\n"
            echo "--- $persona_name ---" | tee -a "$SUMMARY_FILE"
            generate_content "$DEFAULT_MODEL" "$prompt" | tee -a "$SUMMARY_FILE"
            echo "" | tee -a "$SUMMARY_FILE"
        done
        echo "----------------------------------------" | tee -a "$SUMMARY_FILE"
        echo "🔎 Compiling summary and next steps..." | tee -a "$SUMMARY_FILE"
        summary_prompt="You are an expert meeting facilitator. Given the following meeting transcript, produce a concise summary and a list of actionable next steps.\n\nMeeting Title: $title\nAgenda: $agenda\n\nTranscript:\n$(cat "$SUMMARY_FILE")"
        echo "" | tee -a "$SUMMARY_FILE"
        generate_content "$DEFAULT_MODEL" "$summary_prompt"
        echo ""
        rm -f "$SUMMARY_FILE"
        ;;
    "interactive"|"")
        check_ollama || exit 1
        interactive_mode
        ;;
    *)
        echo "Mrs. Violet Noire LLM Orchestrator"
        echo ""
        echo "Usage: $0 [command] [options]"
        echo ""
        echo "Commands:"
        echo "  check                           - Check Ollama connectivity"
        echo "  models                          - List available models"
        echo "  pull <model>                    - Pull a model from Ollama"
        echo "  review <title> <author> [model] - Generate book review"
        echo "  meta <page> <focus> [model]     - Generate meta description"
        echo "  analyze <file> [model]          - Analyze code file"
        echo "  generate <prompt> [model]       - Generate content from prompt"
        echo "  meeting <title> <agenda>        - Run a meeting with all personas"
        echo "  interactive                     - Start interactive mode"
        echo ""
        echo "Examples:"
        echo "  $0 check"
        echo "  $0 review 'The Silent Patient' 'Alex Michaelides'"
        echo "  $0 meta home 'mystery book reviews'"
        echo "  $0 analyze js/script.js"
        echo "  $0 meeting 'Issue Backlog' 'Prioritize repo issues'"
        echo "  $0 interactive"
        ;;
esac
