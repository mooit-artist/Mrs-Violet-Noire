#!/bin/bash
# LLM Personas for Mrs. Violet Noire Project
# Character-specific prompts and content generation

set -e

# Get the orchestrator path
SCRIPT_DIR="$(dirname "$0")"
ORCHESTRATOR="$SCRIPT_DIR/llm-orchestrator.sh"
GLOBAL_PERSONA_CONFIG="$SCRIPT_DIR/../config/global-persona.yaml"

# Colors
PURPLE='\033[0;35m'
BLUE='\033[0;34m'
GREEN='\033[0;32m'
NC='\033[0m'

# Enhanced Mrs. Violet Noire persona (supplements global context)
MRS_VIOLET_NOIRE_PERSONA="Building on your core Violet Noire identity, for this specific content generation you are:

- A sophisticated curator of dark literary mysteries
- Elegant and intellectually sophisticated in all communications
- Rich with gothic atmosphere in your descriptions
- Deeply analytical of psychological themes in literature
- Mysteriously alluring yet approachable to readers
- Well-versed in classic and contemporary mystery literature
- Focused on the darker aspects of human nature in fiction
- Maintaining an air of intrigue and sophistication

Your specialized expertise includes:
- Psychological thrillers and mystery novels
- Gothic literature and atmospheric writing
- Character development in dark fiction
- Plot structure analysis
- Literary criticism with a focus on suspense
- Understanding of mystery subgenres (cozy, noir, psychological, etc.)

Write in a voice that is both scholarly and engaging, as if speaking to fellow connoisseurs of fine mystery literature, while keeping your brand mission in mind."

# Content type functions
generate_book_review() {
    local title="$1"
    local author="$2"
    local genre="${3:-psychological thriller}"

    local prompt="$MRS_VIOLET_NOIRE_PERSONA

Write an elegant review of '$title' by $author, a $genre. Structure your review as follows:

1. Opening Hook: A compelling first sentence that draws readers in
2. Plot Overview: Brief, spoiler-free summary of the story
3. Character Analysis: Deep dive into character psychology and development
4. Atmospheric Assessment: How the author creates mood and tension
5. Literary Merit: Writing style, narrative techniques, themes
6. Genre Placement: How it fits within mystery/thriller literature
7. Recommendation: Who would enjoy this book and why

Maintain your sophisticated, gothic voice throughout. Aim for 400-500 words."

    echo -e "${PURPLE}Mrs. Violet Noire is crafting a review of '$title'...${NC}"
    "$ORCHESTRATOR" generate "$prompt"
}

generate_reading_list() {
    local theme="$1"
    local season="${2:-autumn}"

    local prompt="$MRS_VIOLET_NOIRE_PERSONA

Create a curated reading list of 5-7 mystery/thriller books centered around the theme of '$theme', perfect for $season reading. For each book, provide:

1. Title and Author
2. Brief description (2-3 sentences)
3. Why it fits the theme
4. Mood/atmosphere it creates
5. Your personal insight as Mrs. Violet Noire

Introduce the list with an elegant paragraph setting the mood for this themed collection. End with a thoughtful reflection on why these particular books work well together."

    echo -e "${PURPLE}Mrs. Violet Noire is curating a '$theme' reading list...${NC}"
    "$ORCHESTRATOR" generate "$prompt"
}

generate_author_profile() {
    local author="$1"
    local focus="${2:-mystery writing style}"

    local prompt="$MRS_VIOLET_NOIRE_PERSONA

Write an insightful profile of author $author, focusing on their $focus. Include:

1. Writing Style Analysis: What makes their voice distinctive
2. Recurring Themes: Common elements across their works
3. Character Development: How they create memorable characters
4. Atmospheric Techniques: Their approach to mood and setting
5. Evolution: How their writing has developed over time
6. Influence: Their impact on the mystery/thriller genre
7. Personal Recommendation: Which of their works to start with and why

Write in your sophisticated, analytical style, as if introducing this author to fellow mystery enthusiasts at an intimate literary salon."

    echo -e "${PURPLE}Mrs. Violet Noire is profiling author $author...${NC}"
    "$ORCHESTRATOR" generate "$prompt"
}

generate_mystery_analysis() {
    local topic="$1"
    local approach="${2:-psychological}"

    local prompt="$MRS_VIOLET_NOIRE_PERSONA

Write a sophisticated literary analysis on '$topic' from a $approach perspective. Structure your analysis as:

1. Opening Thesis: Your main argument or insight
2. Historical Context: How this topic has evolved in mystery literature
3. Psychological Depth: The human elements and motivations
4. Literary Techniques: How authors effectively explore this topic
5. Notable Examples: Specific books that exemplify excellence in this area
6. Contemporary Relevance: Why this topic resonates with modern readers
7. Conclusion: Your scholarly perspective on its significance

Write as if contributing to a prestigious literary journal, maintaining both academic rigor and elegant accessibility."

    echo -e "${PURPLE}Mrs. Violet Noire is analyzing '$topic'...${NC}"
    "$ORCHESTRATOR" generate "$prompt"
}

generate_website_copy() {
    local section="$1"
    local purpose="${2:-engaging visitors}"

    local prompt="$MRS_VIOLET_NOIRE_PERSONA

Write compelling website copy for the '$section' section of your mystery book review website. The purpose is $purpose.

Requirements:
- Maintain your sophisticated, gothic voice
- Create an atmosphere of literary intrigue
- Appeal to fellow mystery enthusiasts
- Be engaging yet scholarly
- Include subtle calls-to-action
- Reflect your expertise and passion

Write 2-3 paragraphs that would perfectly represent Mrs. Violet Noire's brand and draw visitors deeper into the world of dark literary mysteries."

    echo -e "${PURPLE}Mrs. Violet Noire is crafting copy for the '$section' section...${NC}"
    "$ORCHESTRATOR" generate "$prompt"
}

generate_social_media() {
    local platform="$1"
    local content_type="${2:-book recommendation}"

    local prompt="$MRS_VIOLET_NOIRE_PERSONA

Create $content_type content for $platform that maintains your sophisticated voice while being platform-appropriate.

For Twitter/X: Elegant, intriguing, under 280 characters
For Instagram: Atmospheric, visual-friendly, engaging caption
For Facebook: Thoughtful, discussion-sparking, community-building

Include relevant hashtags that mystery book lovers would follow. Make it shareable and likely to engage your audience of literary mystery enthusiasts."

    echo -e "${PURPLE}Mrs. Violet Noire is creating $platform content...${NC}"
    "$ORCHESTRATOR" generate "$prompt"
}

# Interactive persona menu
interactive_persona() {
    echo -e "${PURPLE}╔════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║     Mrs. Violet Noire Persona Suite    ║${NC}"
    echo -e "${PURPLE}╚════════════════════════════════════════╝${NC}"
    echo ""

    while true; do
        echo -e "${BLUE}Choose content type:${NC}"
        echo "  1) Book Review"
        echo "  2) Curated Reading List"
        echo "  3) Author Profile"
        echo "  4) Mystery Literary Analysis"
        echo "  5) Website Copy"
        echo "  6) Social Media Content"
        echo "  7) Custom Mrs. Violet Noire Content"
        echo "  8) Back to main menu"
        echo ""

        read -p "Choose an option (1-8): " choice

        case $choice in
            1)
                read -p "Book title: " title
                read -p "Author: " author
                read -p "Genre (default: psychological thriller): " genre
                echo ""
                generate_book_review "$title" "$author" "${genre:-psychological thriller}"
                ;;
            2)
                read -p "Theme (e.g., 'Victorian mysteries', 'locked room puzzles'): " theme
                read -p "Season (default: autumn): " season
                echo ""
                generate_reading_list "$theme" "${season:-autumn}"
                ;;
            3)
                read -p "Author name: " author
                read -p "Focus (default: mystery writing style): " focus
                echo ""
                generate_author_profile "$author" "${focus:-mystery writing style}"
                ;;
            4)
                read -p "Analysis topic (e.g., 'unreliable narrators', 'gothic settings'): " topic
                read -p "Approach (default: psychological): " approach
                echo ""
                generate_mystery_analysis "$topic" "${approach:-psychological}"
                ;;
            5)
                read -p "Website section (home, about, reviews, etc.): " section
                read -p "Purpose (default: engaging visitors): " purpose
                echo ""
                generate_website_copy "$section" "${purpose:-engaging visitors}"
                ;;
            6)
                read -p "Platform (Twitter, Instagram, Facebook): " platform
                read -p "Content type (default: book recommendation): " content_type
                echo ""
                generate_social_media "$platform" "${content_type:-book recommendation}"
                ;;
            7)
                read -p "Describe what you want Mrs. Violet Noire to write: " custom_request
                echo ""
                local custom_prompt="$MRS_VIOLET_NOIRE_PERSONA

$custom_request"
                "$ORCHESTRATOR" generate "$custom_prompt"
                ;;
            8)
                echo "Returning to main menu..."
                exit 0
                ;;
            *)
                echo "Invalid option. Please choose 1-8."
                ;;
        esac

        echo ""
        echo "─────────────────────────────────────────"
        echo ""
    done
}

# Main command handling
case "${1:-}" in
    "review")
        if [[ -z "$2" || -z "$3" ]]; then
            echo "Usage: $0 review <title> <author> [genre]"
            exit 1
        fi
        generate_book_review "$2" "$3" "$4"
        ;;
    "list")
        if [[ -z "$2" ]]; then
            echo "Usage: $0 list <theme> [season]"
            exit 1
        fi
        generate_reading_list "$2" "$3"
        ;;
    "profile")
        if [[ -z "$2" ]]; then
            echo "Usage: $0 profile <author> [focus]"
            exit 1
        fi
        generate_author_profile "$2" "$3"
        ;;
    "analysis")
        if [[ -z "$2" ]]; then
            echo "Usage: $0 analysis <topic> [approach]"
            exit 1
        fi
        generate_mystery_analysis "$2" "$3"
        ;;
    "copy")
        if [[ -z "$2" ]]; then
            echo "Usage: $0 copy <section> [purpose]"
            exit 1
        fi
        generate_website_copy "$2" "$3"
        ;;
    "social")
        if [[ -z "$2" ]]; then
            echo "Usage: $0 social <platform> [content_type]"
            exit 1
        fi
        generate_social_media "$2" "$3"
        ;;
    "interactive"|"")
        interactive_persona
        ;;
    *)
        echo "Mrs. Violet Noire Persona Content Generator"
        echo ""
        echo "Usage: $0 [command] [options]"
        echo ""
        echo "Commands:"
        echo "  review <title> <author> [genre]    - Generate book review"
        echo "  list <theme> [season]              - Create curated reading list"
        echo "  profile <author> [focus]           - Write author profile"
        echo "  analysis <topic> [approach]        - Literary analysis piece"
        echo "  copy <section> [purpose]           - Website copy"
        echo "  social <platform> [content_type]   - Social media content"
        echo "  interactive                        - Interactive mode"
        echo ""
        echo "Examples:"
        echo "  $0 review 'Gone Girl' 'Gillian Flynn'"
        echo "  $0 list 'Victorian mysteries' 'winter'"
        echo "  $0 profile 'Agatha Christie' 'puzzle construction'"
        echo "  $0 analysis 'unreliable narrators' 'psychological'"
        echo "  $0 copy 'about' 'establishing expertise'"
        echo "  $0 social 'Instagram' 'book recommendation'"
        ;;
esac
