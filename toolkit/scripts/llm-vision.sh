#!/bin/bash
# LLM Vision Analysis for Mrs. Violet Noire Project
# Analyze images using local LLaVA vision model

set -e

# Colors
PURPLE='\033[0;35m'
BLUE='\033[0;34m'
GREEN='\033[0;32m'
NC='\033[0m'

# Mrs. Violet Noire vision persona
MRS_VIOLET_NOIRE_VISION_PERSONA="You are Mrs. Violet Noire, a sophisticated curator of dark literary mysteries. When analyzing images, focus on:

- Gothic and atmospheric elements
- Mystery and thriller book covers
- Dark literary aesthetics
- Psychological depth in visual storytelling
- Elegant and sophisticated design elements
- Atmospheric lighting and mood
- Typography that conveys mystery
- Color palettes that evoke intrigue

Describe images with your characteristic elegant, intellectually sophisticated voice, rich with gothic atmosphere."

# Functions
check_llava() {
    echo -e "${BLUE}Checking LLaVA model availability...${NC}"

    if ollama list | grep -q "llava:latest"; then
        echo -e "${GREEN}✅ LLaVA model found${NC}"
        return 0
    else
        echo -e "${PURPLE}📥 LLaVA model not found. Install with: ollama pull llava:latest${NC}"
        return 1
    fi
}

analyze_image() {
    local image_path="$1"
    local custom_prompt="${2:-}"

    if [[ ! -f "$image_path" ]]; then
        echo "❌ Image file not found: $image_path"
        return 1
    fi

    if ! check_llava; then
        return 1
    fi

    local full_prompt="$MRS_VIOLET_NOIRE_VISION_PERSONA

Analyze this image in detail. ${custom_prompt:-Describe what you see, focusing on gothic, mysterious, or literary elements that would appeal to mystery book enthusiasts.}"

    echo -e "${PURPLE}Mrs. Violet Noire is analyzing the image...${NC}"
    echo ""

    # Use Ollama's vision API with correct syntax
    ollama run llava:latest "$full_prompt" < "$image_path"
}

analyze_book_cover() {
    local image_path="$1"

    local prompt="Analyze this book cover as Mrs. Violet Noire. Focus on:
1. Genre indicators (mystery, thriller, gothic, etc.)
2. Atmospheric elements and mood
3. Typography and design choices
4. Color palette and its psychological impact
5. Visual storytelling elements
6. Target audience appeal
7. How well it represents the mystery genre

Provide a sophisticated literary analysis of the visual design."

    analyze_image "$image_path" "$prompt"
}

analyze_website_image() {
    local image_path="$1"

    local prompt="As Mrs. Violet Noire, analyze this website image for its effectiveness in creating a gothic, literary atmosphere. Consider:
1. Visual hierarchy and composition
2. Atmospheric mood creation
3. Brand consistency with mystery literature
4. Color harmony and gothic aesthetics
5. Typography and readability
6. Overall sophistication and elegance
7. Appeal to mystery book enthusiasts

Suggest improvements to enhance the gothic literary atmosphere."

    analyze_image "$image_path" "$prompt"
}

generate_alt_text() {
    local image_path="$1"

    local prompt="Generate sophisticated, accessible alt text for this image that would be appropriate for the Mrs. Violet Noire website. The alt text should:
1. Be descriptive but concise
2. Capture the gothic/literary atmosphere
3. Be accessible for screen readers
4. Maintain the elegant, mysterious tone
5. Include relevant literary or atmospheric details

Provide ONLY the alt text, nothing else."

    analyze_image "$image_path" "$prompt"
}

compare_images() {
    local image1="$1"
    local image2="$2"

    if [[ ! -f "$image1" || ! -f "$image2" ]]; then
        echo "❌ One or both image files not found"
        return 1
    fi

    echo -e "${PURPLE}Mrs. Violet Noire is comparing images...${NC}"
    echo ""

    echo "=== First Image Analysis ==="
    analyze_image "$image1" "Describe this image focusing on its gothic and literary elements."

    echo ""
    echo "=== Second Image Analysis ==="
    analyze_image "$image2" "Describe this image focusing on its gothic and literary elements."

    echo ""
    echo "=== Comparison ==="
    local comparison_prompt="Compare these two images you just analyzed. Which one better captures the gothic, literary atmosphere suitable for Mrs. Violet Noire's brand? Explain your reasoning with sophisticated literary analysis."

    echo -e "${PURPLE}$comparison_prompt${NC}"
}

interactive_vision() {
    echo -e "${PURPLE}╔════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║    Mrs. Violet Noire Vision Analysis   ║${NC}"
    echo -e "${PURPLE}╚════════════════════════════════════════╝${NC}"
    echo ""

    if ! check_llava; then
        echo "Please install LLaVA first: ollama pull llava:latest"
        return 1
    fi

    while true; do
        echo -e "${BLUE}Choose analysis type:${NC}"
        echo "  1) General image analysis"
        echo "  2) Book cover analysis"
        echo "  3) Website image analysis"
        echo "  4) Generate alt text"
        echo "  5) Compare two images"
        echo "  6) Exit"
        echo ""

        read -p "Choose an option (1-6): " choice

        case $choice in
            1)
                read -p "Image path: " image_path
                read -p "Custom prompt (optional): " custom_prompt
                echo ""
                analyze_image "$image_path" "$custom_prompt"
                ;;
            2)
                read -p "Book cover image path: " image_path
                echo ""
                analyze_book_cover "$image_path"
                ;;
            3)
                read -p "Website image path: " image_path
                echo ""
                analyze_website_image "$image_path"
                ;;
            4)
                read -p "Image path: " image_path
                echo ""
                generate_alt_text "$image_path"
                ;;
            5)
                read -p "First image path: " image1
                read -p "Second image path: " image2
                echo ""
                compare_images "$image1" "$image2"
                ;;
            6)
                echo "Farewell from Mrs. Violet Noire's vision analysis..."
                exit 0
                ;;
            *)
                echo "Invalid option. Please choose 1-6."
                ;;
        esac

        echo ""
        echo "─────────────────────────────────────────"
        echo ""
    done
}

# Main command handling
case "${1:-}" in
    "analyze")
        if [[ -z "$2" ]]; then
            echo "Usage: $0 analyze <image_path> [custom_prompt]"
            exit 1
        fi
        analyze_image "$2" "$3"
        ;;
    "book-cover")
        if [[ -z "$2" ]]; then
            echo "Usage: $0 book-cover <image_path>"
            exit 1
        fi
        analyze_book_cover "$2"
        ;;
    "website")
        if [[ -z "$2" ]]; then
            echo "Usage: $0 website <image_path>"
            exit 1
        fi
        analyze_website_image "$2"
        ;;
    "alt-text")
        if [[ -z "$2" ]]; then
            echo "Usage: $0 alt-text <image_path>"
            exit 1
        fi
        generate_alt_text "$2"
        ;;
    "compare")
        if [[ -z "$2" || -z "$3" ]]; then
            echo "Usage: $0 compare <image1_path> <image2_path>"
            exit 1
        fi
        compare_images "$2" "$3"
        ;;
    "check")
        check_llava
        ;;
    "interactive"|"")
        interactive_vision
        ;;
    *)
        echo "Mrs. Violet Noire Vision Analysis Tool"
        echo ""
        echo "Usage: $0 [command] [options]"
        echo ""
        echo "Commands:"
        echo "  analyze <image> [prompt]     - General image analysis"
        echo "  book-cover <image>           - Analyze book cover design"
        echo "  website <image>              - Analyze website imagery"
        echo "  alt-text <image>             - Generate accessibility alt text"
        echo "  compare <image1> <image2>    - Compare two images"
        echo "  check                        - Check LLaVA availability"
        echo "  interactive                  - Interactive mode"
        echo ""
        echo "Examples:"
        echo "  $0 analyze cover.jpg"
        echo "  $0 book-cover mystery-novel.png"
        echo "  $0 website MrsVioletNoire.png"
        echo "  $0 alt-text gothic-background.jpg"
        echo "  $0 compare old-logo.png new-logo.png"
        ;;
esac
