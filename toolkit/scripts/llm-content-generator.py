#!/usr/bin/env python3
"""
LLM Content Generator for Mrs. Violet Noire Project
Python-based content generation with structured output
"""

import json
import subprocess
import sys
import argparse
from pathlib import Path
from typing import Dict, List, Optional, Any
import re
from datetime import datetime


class ContentGenerationError(Exception):
    """Custom exception for content generation errors."""


class OrchestratorError(ContentGenerationError):
    """Exception for orchestrator script errors."""


class GenerationTimeoutError(ContentGenerationError):
    """Exception for generation timeouts."""


class LLMContentGenerator:
    """Main class for generating structured content using local LLM."""

    def __init__(self, model: str = "llama3.2"):
        self.model = model
        self.script_dir = Path(__file__).parent
        self.orchestrator = self.script_dir / "llm-orchestrator.sh"

        # Enhanced Mrs. Violet Noire persona (supplements global context from orchestrator)
        self.persona = """Building on your core Violet Noire brand identity, for this structured content generation:

You are a sophisticated curator of dark literary mysteries with expertise in creating engaging, monetizable content.
Your writing style is elegant, intellectually sophisticated, rich with gothic atmosphere, and deeply analytical
of psychological themes. You are mysteriously alluring yet approachable, well-versed in classic and contemporary
mystery literature, and focused on the darker aspects of human nature in fiction.

Focus on creating content that serves both literary excellence and brand growth objectives."""

    def check_dependencies(self) -> bool:
        """Check if required dependencies are available."""
        try:
            # Check if Ollama is running
            result = subprocess.run(['ollama', 'list'],
                                  capture_output=True, text=True, timeout=10, check=False)
            if result.returncode != 0:
                print("❌ Ollama is not running. Please start Ollama first.")
                return False

            # Check if orchestrator exists
            if not self.orchestrator.exists():
                print(f"❌ Orchestrator script not found: {self.orchestrator}")
                return False

            return True

        except (subprocess.TimeoutExpired, FileNotFoundError):
            print("❌ Ollama not found. Please install and start Ollama.")
            return False

    def _generate_content(self, prompt: str) -> str:
        """Generate content using the orchestrator script."""
        try:
            result = subprocess.run([str(self.orchestrator), 'generate', prompt],
                                  capture_output=True, text=True, timeout=120, check=False)

            if result.returncode != 0:
                raise OrchestratorError(f"Orchestrator error: {result.stderr}")

            return result.stdout.strip()

        except subprocess.TimeoutExpired as exc:
            raise GenerationTimeoutError("Content generation timed out") from exc
        except Exception as e:
            raise ContentGenerationError(f"Failed to generate content: {str(e)}") from e

    def generate_book_review(self, title: str, author: str, genre: str = "mystery",
                             rating: Optional[int] = None) -> Dict[str, Any]:
        """Generate a structured book review."""

        rating_text = f"Rate this book {rating}/5 stars and explain your rating." if rating else ""

        prompt = f"""{self.persona}

Generate a comprehensive review of "{title}" by {author}, classified as {genre}.

Structure your response EXACTLY as follows:

TITLE: [Book title]
AUTHOR: [Author name]
GENRE: [Genre classification]
RATING: [Your rating out of 5 stars with brief explanation]

HOOK:
[Compelling opening paragraph that draws readers in]

PLOT_OVERVIEW:
[Spoiler-free summary of the story in 2-3 sentences]

CHARACTER_ANALYSIS:
[Deep dive into character psychology and development]

ATMOSPHERE:
[How the author creates mood and tension]

LITERARY_MERIT:
[Writing style, narrative techniques, themes]

RECOMMENDATION:
[Who would enjoy this book and why]

CLOSING_THOUGHT:
[Final sophisticated reflection on the work]

{rating_text}

Write in your elegant, gothic voice. Aim for literary sophistication while remaining accessible."""

        content = self._generate_content(prompt)
        return self._parse_structured_review(content, title, author, genre)

    def _parse_structured_review(
            self, content: str, title: str, author: str, genre: str) -> Dict[str, Any]:
        """Parse the structured review content."""
        review = {
            'title': title,
            'author': author,
            'genre': genre,
            'generated_at': datetime.now().isoformat(),
            'content': content,
            'sections': {}
        }

        # Parse sections
        sections = ['HOOK', 'PLOT_OVERVIEW', 'CHARACTER_ANALYSIS', 'ATMOSPHERE',
                    'LITERARY_MERIT', 'RECOMMENDATION', 'CLOSING_THOUGHT']

        for section in sections:
            pattern = rf'{section}:\s*(.*?)(?=\n[A-Z_]+:|$)'
            match = re.search(pattern, content, re.DOTALL)
            if match:
                review['sections'][section.lower()] = match.group(1).strip()

        # Extract rating
        rating_match = re.search(r'RATING:\s*(.*?)(?=\n[A-Z_]+:|$)', content, re.DOTALL)
        if rating_match:
            review['rating'] = rating_match.group(1).strip()

        return review

    def generate_reading_list(self, theme: str, count: int = 5,
                              season: str = "autumn") -> Dict[str, Any]:
        """Generate a curated reading list."""

        prompt = f"""{self.persona}

Create a curated reading list of {count} mystery/thriller books centered on the theme of "{theme}", perfect for {season} reading.

Structure your response EXACTLY as follows:

THEME: {theme}
SEASON: {season}
COUNT: {count}

INTRODUCTION:
[Elegant paragraph setting the mood for this themed collection]

BOOK_1:
Title: [Title]
Author: [Author]
Description: [2-3 sentence description]
Theme_Connection: [Why it fits the theme]
Atmosphere: [Mood it creates]

BOOK_2:
[Same structure as BOOK_1]

[Continue for all {count} books]

REFLECTION:
[Thoughtful reflection on why these books work well together]

Maintain your sophisticated, gothic voice throughout."""

        content = self._generate_content(prompt)
        return self._parse_reading_list(content, theme, season, count)

    def _parse_reading_list(self, content: str, theme: str,
                            season: str, count: int) -> Dict[str, Any]:
        """Parse the reading list content."""
        reading_list = {
            'theme': theme,
            'season': season,
            'count': count,
            'generated_at': datetime.now().isoformat(),
            'content': content,
            'books': [],
            'introduction': '',
            'reflection': ''
        }

        # Extract introduction
        intro_match = re.search(
            r'INTRODUCTION:\s*(.*?)(?=\nBOOK_1:|$)',
            content,
            re.DOTALL)
        if intro_match:
            reading_list['introduction'] = intro_match.group(1).strip()

        # Extract reflection
        reflection_match = re.search(r'REFLECTION:\s*(.*?)$', content, re.DOTALL)
        if reflection_match:
            reading_list['reflection'] = reflection_match.group(1).strip()

        # Extract books
        for i in range(1, count + 1):
            book_pattern = rf'BOOK_{i}:\s*(.*?)(?=\nBOOK_{i+1}:|\nREFLECTION:|$)'
            book_match = re.search(book_pattern, content, re.DOTALL)

            if book_match:
                book_content = book_match.group(1).strip()
                book = self._parse_book_entry(book_content)
                if book:
                    reading_list['books'].append(book)

        return reading_list

    def _parse_book_entry(self, book_content: str) -> Optional[Dict[str, str]]:
        """Parse individual book entry."""
        book = {}

        fields = ['Title', 'Author', 'Description', 'Theme_Connection', 'Atmosphere']
        for field in fields:
            pattern = rf'{field}:\s*(.*?)(?=\n[A-Z][a-z_]*:|$)'
            match = re.search(pattern, book_content, re.DOTALL)
            if match:
                book[field.lower()] = match.group(1).strip()

        return book if len(book) >= 2 else None

    def generate_meta_description(
            self,
            page_type: str,
            specific_content: str = "") -> str:
        """Generate SEO meta descriptions."""

        prompt = f"""{self.persona}

Create an SEO-optimized meta description for a {page_type} page on your mystery book review website.

{f"Specific content focus: {specific_content}" if specific_content else ""}

Requirements:
- 150-160 characters maximum
- Include relevant keywords for mystery book enthusiasts
- Compelling and click-worthy
- Reflects your sophisticated, gothic brand
- Encourages mystery lovers to visit

Generate ONLY the meta description text, no additional formatting."""

        return self._generate_content(prompt).strip()

    def generate_author_bio(self, word_count: int = 150) -> str:
        """Generate Mrs. Violet Noire's author bio."""

        prompt = f"""{self.persona}

Write your author bio for the website's About page. Write in third person about Mrs. Violet Noire.

Requirements:
- Approximately {word_count} words
- Establish credibility as a mystery literature expert
- Maintain air of sophisticated mystery
- Include passion for dark psychological themes
- Professional yet intriguing tone
- Suitable for About page or author profile

Write ONLY the bio text, no additional formatting."""

        return self._generate_content(prompt).strip()

    def generate_newsletter_content(self, topic: str, books: Optional[List[str]] = None) -> Dict[str, Any]:
        """Generate newsletter content."""

        books_text = f"Featured books: {', '.join(books)}" if books else ""

        prompt = f"""{self.persona}

Create newsletter content about "{topic}" for your mystery book enthusiasts.

{books_text}

Structure your response EXACTLY as follows:

SUBJECT_LINE: [Compelling email subject line]

OPENING: [Engaging opening paragraph]

MAIN_CONTENT: [2-3 paragraphs of valuable content about the topic]

BOOK_HIGHLIGHTS: [Brief mentions of relevant books or recommendations]

CLOSING: [Call-to-action and sign-off]

Maintain your sophisticated voice while being engaging for email format."""

        content = self._generate_content(prompt)
        return self._parse_newsletter(content, topic)

    def _parse_newsletter(self, content: str, topic: str) -> Dict[str, Any]:
        """Parse newsletter content."""
        newsletter = {
            'topic': topic,
            'generated_at': datetime.now().isoformat(),
            'content': content,
            'sections': {}
        }

        sections = [
            'SUBJECT_LINE',
            'OPENING',
            'MAIN_CONTENT',
            'BOOK_HIGHLIGHTS',
            'CLOSING']
        for section in sections:
            pattern = rf'{section}:\s*(.*?)(?=\n[A-Z_]+:|$)'
            match = re.search(pattern, content, re.DOTALL)
            if match:
                newsletter['sections'][section.lower()] = match.group(1).strip()

        return newsletter

    def save_content(self, content: Dict[str, Any], filename: str,
                     output_dir: str = "generated_content") -> Path:
        """Save generated content to JSON file."""

        output_path = Path(output_dir)
        output_path.mkdir(exist_ok=True)

        file_path = output_path / f"{filename}.json"

        with open(file_path, 'w', encoding='utf-8') as f:
            json.dump(content, f, indent=2, ensure_ascii=False)

        print(f"✅ Content saved to: {file_path}")
        return file_path

    def export_markdown(self, content: Dict[str, Any], filename: str,
                        output_dir: str = "generated_content") -> Path:
        """Export content as markdown file."""

        output_path = Path(output_dir)
        output_path.mkdir(exist_ok=True)

        file_path = output_path / f"{filename}.md"

        with open(file_path, 'w', encoding='utf-8') as f:
            if 'title' in content and 'author' in content:
                # Book review format
                f.write(f"# Review: {content['title']}\n\n")
                f.write(f"**Author:** {content['author']}\n")
                f.write(f"**Genre:** {content.get('genre', 'Mystery')}\n")
                if 'rating' in content:
                    f.write(f"**Rating:** {content['rating']}\n")
                f.write(f"**Generated:** {content.get('generated_at', 'Unknown')}\n\n")

                if 'sections' in content:
                    for section_name, section_content in content['sections'].items():
                        f.write(f"## {section_name.replace('_', ' ').title()}\n\n")
                        f.write(f"{section_content}\n\n")

            elif 'theme' in content and 'books' in content:
                # Reading list format
                f.write(f"# Reading List: {content['theme']}\n\n")
                f.write(f"**Season:** {content.get('season', 'Any')}\n")
                f.write(f"**Count:** {content.get('count', len(content['books']))}\n")
                f.write(f"**Generated:** {content.get('generated_at', 'Unknown')}\n\n")

                if content.get('introduction'):
                    f.write(f"## Introduction\n\n{content['introduction']}\n\n")

                f.write("## Books\n\n")
                for i, book in enumerate(content['books'], 1):
                    f.write(f"### {i}. {book.get('title', 'Unknown Title')}\n\n")
                    f.write(f"**Author:** {book.get('author', 'Unknown')}\n\n")
                    f.write(f"{book.get('description', '')}\n\n")
                    if book.get('theme_connection'):
                        f.write(f"**Theme Connection:** {book['theme_connection']}\n\n")
                    if book.get('atmosphere'):
                        f.write(f"**Atmosphere:** {book['atmosphere']}\n\n")

                if content.get('reflection'):
                    f.write(f"## Reflection\n\n{content['reflection']}\n\n")

            else:
                # Generic format
                f.write("# Generated Content\n\n")
                f.write(f"**Generated:** {content.get('generated_at', 'Unknown')}\n\n")
                f.write(content.get('content', str(content)))

        print(f"✅ Markdown exported to: {file_path}")
        return file_path


def main():
    parser = argparse.ArgumentParser(description="Mrs. Violet Noire Content Generator")
    parser.add_argument(
        'command',
        choices=[
            'review',
            'list',
            'meta',
            'bio',
            'newsletter'],
        help='Type of content to generate')

    # Common arguments
    parser.add_argument('--model', default='llama3.2', help='LLM model to use')
    parser.add_argument('--output', help='Output filename (without extension)')
    parser.add_argument('--save-json', action='store_true', help='Save as JSON')
    parser.add_argument('--save-md', action='store_true', help='Save as Markdown')

    # Review arguments
    parser.add_argument('--title', help='Book title for review')
    parser.add_argument('--author', help='Book author for review')
    parser.add_argument('--genre', default='mystery', help='Book genre')
    parser.add_argument(
        '--rating',
        type=int,
        choices=range(
            1,
            6),
        help='Book rating (1-5)')

    # Reading list arguments
    parser.add_argument('--theme', help='Reading list theme')
    parser.add_argument('--count', type=int, default=5, help='Number of books in list')
    parser.add_argument('--season', default='autumn', help='Season for reading list')

    # Meta description arguments
    parser.add_argument('--page-type', help='Type of page for meta description')
    parser.add_argument('--specific-content', help='Specific content focus')

    # Bio arguments
    parser.add_argument(
        '--word-count',
        type=int,
        default=150,
        help='Word count for bio')

    # Newsletter arguments
    parser.add_argument('--topic', help='Newsletter topic')
    parser.add_argument('--books', nargs='*', help='Featured books for newsletter')

    args = parser.parse_args()

    # Initialize generator
    generator = LLMContentGenerator(args.model)

    # Check dependencies
    if not generator.check_dependencies():
        sys.exit(1)

    print("🎭 Mrs. Violet Noire Content Generator")
    print(f"📝 Generating {args.command} content...\n")

    try:
        # Generate content based on command
        if args.command == 'review':
            if not args.title or not args.author:
                print("❌ Book title and author are required for review generation")
                sys.exit(1)

            content = generator.generate_book_review(
                args.title, args.author, args.genre, args.rating
            )
            output_name = args.output or f"review_{args.title.lower().replace(' ', '_')}"

        elif args.command == 'list':
            if not args.theme:
                print("❌ Theme is required for reading list generation")
                sys.exit(1)

            content = generator.generate_reading_list(
                args.theme, args.count, args.season
            )
            output_name = args.output or f"list_{args.theme.lower().replace(' ', '_')}"

        elif args.command == 'meta':
            if not args.page_type:
                print("❌ Page type is required for meta description generation")
                sys.exit(1)

            meta_desc = generator.generate_meta_description(
                args.page_type, args.specific_content or ""
            )
            print("📄 Generated Meta Description:")
            print(f"   {meta_desc}")
            print(f"   ({len(meta_desc)} characters)")
            return

        elif args.command == 'bio':
            bio = generator.generate_author_bio(args.word_count)
            print("👤 Generated Author Bio:")
            print(f"   {bio}")
            print(f"   ({len(bio.split())} words)")
            return

        elif args.command == 'newsletter':
            if not args.topic:
                print("❌ Topic is required for newsletter generation")
                sys.exit(1)

            content = generator.generate_newsletter_content(
                args.topic, args.books
            )
            output_name = args.output or f"newsletter_{args.topic.lower().replace(' ', '_')}"

        # Save content
        if args.save_json:
            generator.save_content(content, output_name)

        if args.save_md:
            generator.export_markdown(content, output_name)

        if not args.save_json and not args.save_md:
            # Print to console
            print("📖 Generated Content:")
            print("=" * 50)
            if isinstance(content, dict) and 'content' in content:
                print(content['content'])
            else:
                print(json.dumps(content, indent=2))

    except Exception as e:
        print(f"❌ Error generating content: {str(e)}")
        sys.exit(1)


if __name__ == "__main__":
    main()
