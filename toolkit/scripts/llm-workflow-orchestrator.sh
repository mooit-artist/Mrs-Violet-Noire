#!/bin/bash
# LLM Workflow Orchestrator for Mrs. Violet Noire Project
# Proof-of-concept prompt chaining implementation

set -e

# Colors
PURPLE='\033[0;35m'
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$(dirname "$0")"
ORCHESTRATOR="$SCRIPT_DIR/llm-orchestrator.sh"
PERSONAS="$SCRIPT_DIR/llm-personas.sh"
GLOBAL_PERSONA_CONFIG="$SCRIPT_DIR/../config/global-persona.yaml"

# Check dependencies
check_dependencies() {
    if [[ ! -f "$ORCHESTRATOR" ]]; then
        echo -e "${YELLOW}⚠️  Warning: llm-orchestrator.sh not found${NC}"
        return 1
    fi

    if [[ ! -f "$PERSONAS" ]]; then
        echo -e "${YELLOW}⚠️  Warning: llm-personas.sh not found${NC}"
        return 1
    fi

    return 0
}

# Enhanced book review workflow
workflow_book_review() {
    local title="$1"
    local author="$2"
    local temp_dir="/tmp/llm_workflow_$$"

    mkdir -p "$temp_dir"

    echo -e "${PURPLE}🔗 Starting Book Review Workflow Chain${NC}"
    echo -e "${BLUE}📚 Book: $title by $author${NC}"
    echo ""

    # Step 1: Literary Research
    echo -e "${BLUE}🔍 Step 1: Gathering literary research and context...${NC}"
    research_prompt="Research '$title' by $author. Provide:
1. Genre and literary context
2. Major themes and psychological elements
3. Critical reception and significance
4. Comparable works in the mystery/thriller genre
5. Unique stylistic elements

Format as structured research notes for review preparation."

    echo "$research_prompt" > "$temp_dir/research_prompt.txt"

    if "$ORCHESTRATOR" generate "$research_prompt" > "$temp_dir/research.txt" 2>/dev/null; then
        echo -e "${GREEN}✅ Research completed${NC}"
    else
        echo -e "${YELLOW}⚠️  Research step failed, proceeding with basic review${NC}"
    fi

    # Step 2: Enhanced Review Generation
    echo -e "${BLUE}📝 Step 2: Generating enhanced review with research context...${NC}"

    if [[ -f "$temp_dir/research.txt" ]] && [[ -s "$temp_dir/research.txt" ]]; then
        research_content=$(cat "$temp_dir/research.txt")
        enhanced_prompt="$research_content

Now write a sophisticated review of '$title' by $author using this research context."

        echo "$enhanced_prompt" > "$temp_dir/enhanced_prompt.txt"

        if "$ORCHESTRATOR" generate "$enhanced_prompt" > "$temp_dir/enhanced_review.txt" 2>/dev/null; then
            echo -e "${GREEN}✅ Enhanced review generated${NC}"
        else
            echo -e "${YELLOW}⚠️  Enhanced generation failed, using standard review${NC}"
            "$PERSONAS" review "$title" "$author" > "$temp_dir/enhanced_review.txt" 2>/dev/null || echo "Standard review generation failed" > "$temp_dir/enhanced_review.txt"
        fi
    else
        echo -e "${YELLOW}⚠️  Using standard review generation${NC}"
        "$PERSONAS" review "$title" "$author" > "$temp_dir/enhanced_review.txt" 2>/dev/null || echo "Standard review generation failed" > "$temp_dir/enhanced_review.txt"
    fi

    # Step 3: Voice Refinement
    echo -e "${BLUE}🎭 Step 3: Refining Mrs. Violet Noire's voice and style...${NC}"

    if [[ -f "$temp_dir/enhanced_review.txt" ]] && [[ -s "$temp_dir/enhanced_review.txt" ]]; then
        review_content=$(cat "$temp_dir/enhanced_review.txt")
        refinement_prompt="Refine this review to perfectly embody Mrs. Violet Noire's sophisticated gothic voice:

$review_content

Enhance:
- Gothic atmospheric language
- Intellectual sophistication
- Psychological depth
- Literary elegance
- Mysterious allure

Maintain the substantive analysis while perfecting the voice."

        if "$ORCHESTRATOR" generate "$refinement_prompt" > "$temp_dir/refined_review.txt" 2>/dev/null; then
            echo -e "${GREEN}✅ Voice refinement completed${NC}"
        else
            echo -e "${YELLOW}⚠️  Voice refinement failed, using enhanced review${NC}"
            cp "$temp_dir/enhanced_review.txt" "$temp_dir/refined_review.txt"
        fi
    else
        echo -e "${YELLOW}⚠️  No content to refine${NC}"
        echo "Unable to generate review content" > "$temp_dir/refined_review.txt"
    fi

    # Step 4: Final Output
    echo -e "${BLUE}📤 Step 4: Preparing final output...${NC}"

    echo ""
    echo -e "${PURPLE}════════════════════════════════════════${NC}"
    echo -e "${PURPLE}   Mrs. Violet Noire's Book Review${NC}"
    echo -e "${PURPLE}   $title by $author${NC}"
    echo -e "${PURPLE}════════════════════════════════════════${NC}"
    echo ""

    if [[ -f "$temp_dir/refined_review.txt" ]]; then
        cat "$temp_dir/refined_review.txt"
    else
        echo "Unable to generate review content"
    fi

    echo ""
    echo -e "${GREEN}✅ Workflow completed! Temporary files in: $temp_dir${NC}"
    echo -e "${BLUE}💡 Note: This is a proof-of-concept. Full orchestrator coming soon!${NC}"
}

# Literary analysis workflow
workflow_analysis() {
    local topic="$1"

    echo -e "${PURPLE}🔗 Starting Literary Analysis Workflow Chain${NC}"
    echo -e "${BLUE}📖 Topic: $topic${NC}"
    echo ""

    echo -e "${BLUE}🔍 Step 1: Research and context gathering...${NC}"
    echo -e "${BLUE}📝 Step 2: Thesis development...${NC}"
    echo -e "${BLUE}🎭 Step 3: Mrs. Violet Noire academic voice...${NC}"
    echo -e "${BLUE}📤 Step 4: Final formatting...${NC}"
    echo ""

    # For now, use enhanced single-step generation
    echo -e "${YELLOW}⚠️  Full workflow in development. Using enhanced generation...${NC}"
    echo ""

    "$PERSONAS" analysis "$topic" "comprehensive"
}

# Main function
main() {
    if ! check_dependencies; then
        echo -e "${YELLOW}⚠️  Some dependencies missing. Workflow may be limited.${NC}"
        echo ""
    fi

    case "${1:-}" in
        "book-review")
            if [[ -z "$2" || -z "$3" ]]; then
                echo "Usage: $0 book-review <title> <author>"
                exit 1
            fi
            workflow_book_review "$2" "$3"
            ;;
        "analysis")
            if [[ -z "$2" ]]; then
                echo "Usage: $0 analysis <topic>"
                exit 1
            fi
            workflow_analysis "$2"
            ;;
        *)
            echo "Mrs. Violet Noire Workflow Orchestrator (Proof of Concept)"
            echo ""
            echo "Usage: $0 [workflow] [options]"
            echo ""
            echo "Available workflows:"
            echo "  book-review <title> <author>  - Enhanced multi-step book review"
            echo "  analysis <topic>              - Comprehensive literary analysis"
            echo ""
            echo "Examples:"
            echo "  $0 book-review 'The Silent Patient' 'Alex Michaelides'"
            echo "  $0 analysis 'unreliable narrators in modern mystery'"
            echo ""
            echo "Note: This is a proof-of-concept implementation."
            echo "Full workflow orchestrator with caching, error handling,"
            echo "and advanced chaining capabilities coming soon!"
            ;;
    esac
}

# Run main function
main "$@"
