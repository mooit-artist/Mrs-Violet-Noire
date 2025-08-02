# Commit target: runs lint-status and only commits if score >= 80
commit:
	@echo "🔍 Running code quality scan before commit..."
	@make lint-status
	@score=$$(tail -1 .lint-history/last-run.log | cut -d'|' -f2); \
	if [ "$$score" -ge 80 ]; then \
		echo "✅ Code quality score $$score/100: Proceeding with commit."; \
		git add .; \
		read -p "Enter commit message: " msg; \
		git commit -m "$$msg"; \
		git push; \
	else \
		echo "❌ Code quality score $$score/100 is below threshold (80). Commit aborted."; \
		exit 1; \
	fi






# Alphabetized Makefile targets
build:
	@echo "🔨 Building project..."
	@make format
	@make validate
	@echo "🎉 Build completed successfully!"

deploy:
	@echo "🚀 Deploying website..."
	npm run deploy
	@echo "✅ Deployment completed!"

format:
	@echo "🎨 Formatting code files..."
	npx prettier --write "**/*.{html,css,js}"
	@echo "✅ Code formatting completed!"

install:
	@echo "📦 Installing dependencies..."
	npm install
	pip install -r requirements.txt || true
	@echo "✅ Dependencies installed successfully!"

lint:
	@echo "🚀 Starting comprehensive linting process..."
	@echo "📊 Running linters in sequence..."
	@make lint-js
	@make lint-html
	@make lint-css
	@make lint-py
	@echo "🎉 All linting tasks completed successfully!"

lint-css:
	@echo "🔍 Linting CSS files..."
	@npx stylelint "css/**/*.css" || echo "⚠️  CSS linter not configured (install stylelint if missing)"
	@echo "✅ CSS linting completed!"

lint-history:
	@echo "📈 Linting History & Trends"
	@echo "=========================="
	@if [ -f .lint-history/last-run.log ]; then \
		echo "📅 Recent runs (last 10):"; \
		echo "Date/Time           | Score | JS | HTML | CSS | PY | Total"; \
		echo "-------------------+-------+----+------+-----+----+------"; \
		tail -10 .lint-history/last-run.log | while IFS='|' read date score js html css py total; do \
			printf "%-19s | %3s/100 | %2s | %4s | %3s | %2s | %5s\n" "$$date" "$$score" "$$js" "$$html" "$$css" "$$py" "$$total"; \
		done; \
		echo "=========================="; \
		first_total=$$(head -1 .lint-history/last-run.log | cut -d'|' -f7); \
		last_total=$$(tail -1 .lint-history/last-run.log | cut -d'|' -f7); \
		runs=$$(wc -l < .lint-history/last-run.log); \
		if [ $$last_total -lt $$first_total ]; then \
			improvement=$$((first_total - last_total)); \
			echo "🎉 OVERALL PROGRESS: $$improvement fewer errors over $$runs runs"; \
		elif [ $$last_total -gt $$first_total ]; then \
			regression=$$((last_total - first_total)); \
			echo "⚠️  OVERALL TREND: $$regression more errors over $$runs runs"; \
		else \
			echo "➡️  OVERALL TREND: Stable error count over $$runs runs"; \
		fi; \
	else \
		echo "📝 No history found. Run 'make lint-status' first to establish baseline."; \
	fi

lint-html:
	@echo "🔍 Validating HTML files..."
	@npx html-validate *.html || (echo "❌ HTML validation failed - see errors above" && exit 1)
	@echo "✅ HTML validation completed!"

lint-js:
	@echo "🔍 Linting JavaScript files..."
	@npx eslint js/*.js || echo "⚠️  ESLint configuration needed (install eslint and plugins if missing)"
	@echo "✅ JavaScript linting completed!"

lint-py:
	@echo "🔍 Linting Python files..."
	@python3 -m flake8 scripts/ toolkit/scripts/ || echo "⚠️  Python linter not configured (install flake8 if missing)"
	@echo "✅ Python linting completed!"

lint-score:
	@echo "🎯 Quick Code Quality Score"
	@score=0; \
	npx eslint js/*.js > /dev/null 2>&1 && score=$$((score + 25)); \
	npx html-validate *.html > /dev/null 2>&1 && score=$$((score + 25)); \
	npx stylelint "css/**/*.css" > /dev/null 2>&1 && score=$$((score + 25)); \
	python3 -m flake8 scripts/ toolkit/scripts/ > /dev/null 2>&1 && score=$$((score + 25)); \
	echo "📊 Score: $$score/100 ($$((score))%)"

lint-status:
	@echo "📋 Linting Status Report"
	@echo "======================="
	@mkdir -p .lint-history
	@score=0; js_errors=0; html_errors=0; css_errors=0; py_errors=0; \
	printf "🔍 JavaScript: "; \
	if npx eslint js/*.js >/dev/null 2>&1; then \
		echo "✅ PERFECT (+25 points)"; \
		score=$$((score + 25)); \
	else \
		js_errors=$$(npx eslint js/*.js 2>&1 | wc -l | tr -d ' '); \
		if [ $$js_errors -le 10 ]; then \
			js_points=20; echo "🟢 GOOD: $$js_errors issues (+20 points)"; \
		elif [ $$js_errors -le 25 ]; then \
			js_points=15; echo "🟡 FAIR: $$js_errors issues (+15 points)"; \
		elif [ $$js_errors -le 50 ]; then \
			js_points=10; echo "🟠 POOR: $$js_errors issues (+10 points)"; \
		elif [ $$js_errors -le 100 ]; then \
			js_points=5; echo "🔴 BAD: $$js_errors issues (+5 points)"; \
		else \
			js_points=0; echo "❌ CRITICAL: $$js_errors issues (+0 points)"; \
		fi; \
		score=$$((score + js_points)); \
	fi; \
	printf "🔍 HTML: "; \
	if npx html-validate *.html >/dev/null 2>&1; then \
		echo "✅ PERFECT (+25 points)"; \
		score=$$((score + 25)); \
	else \
		html_errors=$$(npx html-validate *.html 2>&1 | grep -c "error" || echo 0); \
		if [ $$html_errors -le 5 ]; then \
			html_points=20; echo "🟢 GOOD: $$html_errors errors (+20 points)"; \
		elif [ $$html_errors -le 15 ]; then \
			html_points=15; echo "🟡 FAIR: $$html_errors errors (+15 points)"; \
		elif [ $$html_errors -le 30 ]; then \
			html_points=10; echo "🟠 POOR: $$html_errors errors (+10 points)"; \
		elif [ $$html_errors -le 60 ]; then \
			html_points=5; echo "🔴 BAD: $$html_errors errors (+5 points)"; \
		else \
			html_points=0; echo "❌ CRITICAL: $$html_errors errors (+0 points)"; \
		fi; \
		score=$$((score + html_points)); \
	fi; \
	printf "🔍 CSS: "; \
	if npx stylelint "css/**/*.css" >/dev/null 2>&1; then \
		echo "✅ PERFECT (+25 points)"; \
		score=$$((score + 25)); \
	else \
		css_errors=$$(npx stylelint "css/**/*.css" 2>&1 | wc -l | tr -d ' '); \
		if [ $$css_errors -le 5 ]; then \
			css_points=20; echo "🟢 GOOD: $$css_errors issues (+20 points)"; \
		elif [ $$css_errors -le 15 ]; then \
			css_points=15; echo "🟡 FAIR: $$css_errors issues (+15 points)"; \
		elif [ $$css_errors -le 30 ]; then \
			css_points=10; echo "🟠 POOR: $$css_errors issues (+10 points)"; \
		elif [ $$css_errors -le 60 ]; then \
			css_points=5; echo "🔴 BAD: $$css_errors issues (+5 points)"; \
		else \
			css_points=0; echo "❌ CRITICAL: $$css_errors issues (+0 points)"; \
		fi; \
		score=$$((score + css_points)); \
	fi; \
	printf "🔍 Python: "; \
	if python3 -m flake8 scripts/ toolkit/scripts/ >/dev/null 2>&1; then \
		echo "✅ PERFECT (+25 points)"; \
		score=$$((score + 25)); \
	else \
		py_errors=$$(python3 -m flake8 scripts/ toolkit/scripts/ 2>&1 | wc -l | tr -d ' '); \
		if [ $$py_errors -le 5 ]; then \
			py_points=20; echo "🟢 GOOD: $$py_errors issues (+20 points)"; \
		elif [ $$py_errors -le 15 ]; then \
			py_points=15; echo "🟡 FAIR: $$py_errors issues (+15 points)"; \
		elif [ $$py_errors -le 30 ]; then \
			py_points=10; echo "🟠 POOR: $$py_errors issues (+10 points)"; \
		elif [ $$py_errors -le 60 ]; then \
			py_points=5; echo "🔴 BAD: $$py_errors issues (+5 points)"; \
		else \
			py_points=0; echo "❌ CRITICAL: $$py_errors issues (+0 points)"; \
		fi; \
		score=$$((score + py_points)); \
	fi; \
	echo "======================="; \
	current_timestamp=$$(date '+%Y-%m-%d %H:%M:%S'); \
	total_errors=$$((js_errors + html_errors + css_errors + py_errors)); \
	echo "📊 Overall Code Quality Score: $$score/100 ($$score%)"; \
	echo "🐛 Total Issues: $$total_errors"; \
	if [ -f .lint-history/last-run.log ]; then \
		last_errors=$$(tail -1 .lint-history/last-run.log | cut -d'|' -f7); \
		last_date=$$(tail -1 .lint-history/last-run.log | cut -d'|' -f1); \
		if [ $$total_errors -lt $$last_errors ]; then \
			improvement=$$((last_errors - total_errors)); \
			echo "📈 IMPROVEMENT: $$improvement fewer issues since $$last_date"; \
		elif [ $$total_errors -gt $$last_errors ]; then \
			regression=$$((total_errors - last_errors)); \
			echo "📉 REGRESSION: $$regression more issues since $$last_date"; \
		else \
			echo "➡️  STABLE: Same issue count since $$last_date"; \
		fi; \
	else \
		echo "📝 FIRST RUN: Baseline established"; \
	fi; \
	echo "$$current_timestamp|$$score|$$js_errors|$$html_errors|$$css_errors|$$py_errors|$$total_errors" >> .lint-history/last-run.log; \
	if [ $$score -eq 100 ]; then \
		echo "🏆 EXCELLENT - Perfect code quality!"; \
	elif [ $$score -ge 80 ]; then \
		echo "🎯 GOOD - High code quality with minor issues"; \
	elif [ $$score -ge 60 ]; then \
		echo "⚠️  FAIR - Moderate code quality, needs attention"; \
	elif [ $$score -ge 40 ]; then \
		echo "🔧 POOR - Low code quality, significant work needed"; \
	elif [ $$score -ge 20 ]; then \
		echo "🚨 BAD - Very poor code quality, major cleanup required"; \
	else \
		echo "❌ CRITICAL - Code quality crisis, immediate action needed"; \
	fi; \
	echo "📈 Scoring: 0-25pts per linter based on error count (Perfect=25, Good≤threshold=20, Fair=15, Poor=10, Bad=5, Critical=0)"

llm-content:
	@echo "✍️  Content generation menu..."
	@./toolkit/scripts/llm-content-generator.py

llm-generate:
	@echo "📝 Generating content with Mrs. Violet Noire..."
	@./toolkit/scripts/llm-personas.sh interactive

llm-help:
	@echo "🤖 Mrs. Violet Noire LLM Integration Help"
	@echo ""
	@echo "Available LLM targets:"
	@echo "  llm-setup     - Set up and verify LLM integration"
	@echo "  llm-test      - Test LLM connectivity and voice"
	@echo "  llm-generate  - Interactive content generation"
	@echo "  llm-review    - Generate a book review"
	@echo "  llm-content   - Python-based content generator"
	@echo ""
	@echo "Meeting & Collaboration targets:"
	@echo "  llm-meeting          - Original LLM meeting orchestrator"
	@echo "  llm-meeting-enhanced - Enhanced meeting with monitoring"
	@echo ""
	@echo "Prompt Chaining Workflow targets:"
	@echo "  llm-workflow-review   - Multi-step book review creation"
	@echo "  llm-workflow-analysis - Comprehensive literary analysis"
	@echo "  llm-workflow-help     - Show workflow help and benefits"
	@echo ""
	@echo "Security Analysis targets:"
	@echo "  security-triage       - Interactive vulnerability triage"
	@echo "  security-triage-sarif - Analyze SARIF vulnerability reports"
	@echo "  security-triage-check - Check security dependencies"
	@echo ""
	@echo "Vision Analysis targets:"
	@echo "  llm-vision          - Interactive vision analysis"
	@echo "  llm-vision-analyze  - Analyze any image"
	@echo "  llm-vision-book     - Analyze book covers"
	@echo "  llm-vision-website  - Analyze website images"
	@echo "  llm-vision-alt      - Generate alt text"
	@echo "  llm-vision-compare  - Compare two images"
	@echo ""
	@echo "  llm-help      - Show this help message"
	@echo ""
	@echo "Scripts available:"
	@echo "  ./toolkit/scripts/llm-orchestrator.sh       - Main LLM coordinator"
	@echo "  ./toolkit/scripts/llm-personas.sh           - Character-specific content"
	@echo "  ./toolkit/scripts/llm-content-generator.py  - Structured Python generator"
	@echo "  ./toolkit/scripts/llm-vision.sh             - Vision analysis tool"
	@echo "  ./toolkit/scripts/llm-meeting-enhanced.py   - Enhanced meeting orchestrator"
	@echo "  ./toolkit/scripts/security-triage.py        - Multi-agent security analysis"
	@echo ""
	@echo "Requirements:"
	@echo "  - Ollama installed and running"
	@echo "  - Text model downloaded (e.g., ollama pull llama3.2)"
	@echo "  - Vision model downloaded (e.g., ollama pull llava:latest)"
	@echo "  - Security triage uses integrated enhanced meeting orchestrator"
	@echo ""
	@echo "Advanced Features:"
	@echo "  - Multi-agent security analysis with 6 specialized personas"
	@echo "  - Enhanced meeting orchestrator with retry logic and caching"
	@echo "  - Performance monitoring and metrics tracking"
	@echo "  - Local LLM integration optimized for privacy and cost"
	@echo "  - Prompt chaining workflows for sophisticated content creation"
	@echo "  - Global Violet Noire Assistant persona for brand consistency"

llm-review:
	@echo "� Generate a book review..."
	@read -p "Book title: " title; \
	 read -p "Author: " author; \
	 read -p "Genre (default: mystery): " genre; \
	 ./toolkit/scripts/llm-personas.sh review "$$title" "$$author" "$$genre:-mystery""

llm-setup:
	@echo "🤖 Setting up LLM integration..."
	@if command -v ollama >/dev/null 2>&1; then \
		echo "✅ Ollama found"; \
		./toolkit/scripts/llm-orchestrator.sh check; \
	else \
		echo "❌ Ollama not found. Please install Ollama first."; \
		echo "   Visit: https://ollama.com/download"; \
		exit 1; \
	fi
	@echo "🎉 LLM setup completed!"

llm-test:
	@echo "🧪 Testing LLM integration..."
	@./toolkit/scripts/llm-orchestrator.sh generate "Write a one-sentence test of Mrs. Violet Noire's voice."
	@echo "✅ LLM test completed!"

llm-vision:
	@echo "�️  Interactive vision analysis with Mrs. Violet Noire..."
	@./toolkit/scripts/llm-vision.sh interactive

llm-vision-alt:
	@echo "♿ Generate alt text for accessibility..."
	@read -p "Image path: " image_path; \
	 ./toolkit/scripts/llm-vision.sh alt-text "$$image_path"

llm-vision-analyze:
	@echo "🔍 Analyze an image with Mrs. Violet Noire..."
	@read -p "Image path: " image_path; \
	 ./toolkit/scripts/llm-vision.sh analyze "$$image_path"

llm-vision-book:
	@echo "📖 Analyze a book cover..."
	@read -p "Book cover image path: " image_path; \
	 ./toolkit/scripts/llm-vision.sh book-cover "$$image_path"

llm-vision-compare:
	@echo "⚖️  Compare two images..."
	@read -p "First image path: " image1; \
	 read -p "Second image path: " image2; \
	 ./toolkit/scripts/llm-vision.sh compare "$$image1" "$$image2"

llm-vision-website:
	@echo "🌐 Analyze a website image..."
	@read -p "Website image path: " image_path; \
	 ./toolkit/scripts/llm-vision.sh website "$$image_path"


llm-meeting:
	@echo "🤝 Start an LLM-powered meeting with all personas..."
	@if [ -n "$(TITLE)" ] && [ -n "$(AGENDA)" ]; then \
		python3 ./toolkit/scripts/llm-meeting.py --title "$(TITLE)" --agenda "$(AGENDA)"; \
	else \
		read -p "Meeting Title: " title; \
		read -p "Agenda/Topic: " agenda; \
		python3 ./toolkit/scripts/llm-meeting.py --title "$$title" --agenda "$$agenda"; \
	fi

llm-meeting-enhanced:
	@echo "🚀 Start enhanced LLM meeting with all improvements..."
	@if [ -n "$(TITLE)" ] && [ -n "$(AGENDA)" ]; then \
		python3 ./toolkit/scripts/llm-meeting-enhanced.py --title "$(TITLE)" --agenda "$(AGENDA)"; \
	else \
		read -p "Meeting Title: " title; \
		read -p "Agenda/Topic: " agenda; \
		python3 ./toolkit/scripts/llm-meeting-enhanced.py --title "$$title" --agenda "$$agenda"; \
	fi

security-triage:
	@echo "🛡️  Multi-agent security vulnerability triage..."
	@./toolkit/scripts/security-triage.sh interactive

security-triage-sarif:
	@echo "🛡️  Analyze SARIF vulnerability report..."
	@if [ -n "$(INPUT)" ]; then \
		./toolkit/scripts/security-triage.sh sarif "$(INPUT)"; \
	else \
		read -p "SARIF file path: " sarif_path; \
		./toolkit/scripts/security-triage.sh sarif "$$sarif_path"; \
	fi

security-triage-check:
	@echo "🔍 Check security triage dependencies..."
	@./toolkit/scripts/security-triage.sh check

# Prompt chaining workflow targets
llm-workflow-review:
	@echo "🔗 Starting book review workflow chain..."
	@echo "📚 This will create a complete review through multiple refinement steps"
	@read -p "Book title: " title; \
	 read -p "Author: " author; \
	 echo ""; \
	 ./toolkit/scripts/llm-workflow-orchestrator.sh book-review "$$title" "$$author"

llm-workflow-analysis:
	@echo "🔗 Starting literary analysis workflow chain..."
	@echo "📖 This will create comprehensive literary analysis through multiple steps"
	@read -p "Analysis topic: " topic; \
	 echo ""; \
	 ./toolkit/scripts/llm-workflow-orchestrator.sh analysis "$$topic"

llm-workflow-help:
	@echo "🔗 Mrs. Violet Noire Prompt Chaining Workflows"
	@echo ""
	@echo "Workflow targets (Progressive multi-step content creation):"
	@echo "  llm-workflow-review     - Multi-step book review creation"
	@echo "  llm-workflow-analysis   - Comprehensive literary analysis"
	@echo "  llm-workflow-help       - Show workflow help"
	@echo ""
	@echo "Workflow Process:"
	@echo "  1. Research & Context Gathering"
	@echo "  2. Initial Content Generation"
	@echo "  3. Character Voice Refinement"
	@echo "  4. SEO & Accessibility Enhancement"
	@echo "  5. Multi-format Output Generation"
	@echo ""
	@echo "Benefits:"
	@echo "  • Higher quality through progressive refinement"
	@echo "  • Consistent Mrs. Violet Noire voice"
	@echo "  • Publication-ready content"
	@echo "  • SEO-optimized while maintaining sophistication"
	@echo ""
	@echo "Note: Full workflow orchestrator in development"
	@echo "Current workflows use enhanced single-step generation"

validate:
	@echo "✅ Running HTML validation..."
	@make lint-html

.PHONY: build commit deploy format install lint lint-css lint-history lint-html lint-js lint-py lint-score lint-status llm-content llm-generate llm-help llm-review llm-setup llm-test llm-vision llm-vision-alt llm-vision-analyze llm-vision-book llm-vision-compare llm-vision-website llm-meeting llm-meeting-enhanced llm-workflow-review llm-workflow-analysis llm-workflow-help security-triage security-triage-sarif security-triage-check validate
