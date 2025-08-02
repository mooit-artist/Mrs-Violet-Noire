# Local LLM Configuration Guide 🤖

## Overview
Your Mrs. Violet Noire project is now configured to use local LLMs through both **Continue.dev** extension and custom toolkit scripts, giving you complete control over AI assistance while keeping your code private.

## Configuration Complete ✅

### 1. Continue Extension Setup
- **Extension:** Continue.dev (already installed)
- **Config Location:** `.continue/config.json`
- **Local Models Configured:**
  - Llama 3.2 (main chat model)
  - Llama 3.2 3B (lightweight option)
  - CodeLlama (code completion)
  - Mistral (alternative model)
  - DeepSeek Coder (coding specialist)

### 2. VS Code Settings
- **Location:** `.vscode/settings.json`
- **Features Enabled:**
  - Continue tab autocomplete
  - Local model integration
  - Mrs. Violet Noire context

### 3. Custom Mrs. Violet Noire Commands
Added to Continue configuration:
- `/review` - Generate book reviews in Mrs. Violet Noire's voice
- `/gothic` - Apply gothic styling and atmosphere
- `/mystery` - Analyze mystery/thriller elements

## Quick Start Commands

### Check Ollama Status
```bash
npm run llm:check        # List installed models
ollama list              # Direct command
```

### Install Required Models
```bash
npm run llm:pull         # Install recommended models
# OR manually:
ollama pull llama3.2
ollama pull codellama
ollama pull nomic-embed-text
```

### Start Ollama Server
```bash
npm run llm:start        # Start Ollama service
ollama serve             # Direct command
```

### Test Integration
```bash
npm run llm:test         # Test Mrs. Violet Noire voice
make llm-setup           # Full setup verification
```

## Using Continue Extension

### 1. **Chat Interface** (Cmd/Ctrl + Shift + M)
- Open Continue chat panel
- Select your preferred local model
- Ask questions or generate content
- Models automatically use Mrs. Violet Noire context

### 2. **Code Completion**
- **Tab Autocomplete:** Automatic as you type
- **Model:** CodeLlama 7B optimized for code
- **Privacy:** 100% local, no data sent externally

### 3. **Custom Commands**
- **Highlight code** → Right-click → "Continue: Edit"
- Use custom prompts like:
  - `@mrs-violet-noire-review` - Generate book review
  - `@mystery-analysis` - Analyze literary elements
  - `@gothic-refactor` - Refactor with gothic style

### 4. **Slash Commands in Chat**
- `/review` - Book review generation
- `/gothic` - Gothic styling assistance
- `/mystery` - Mystery/thriller analysis
- `/edit` - Inline code editing
- `/comment` - Add elegant comments

## Using Custom Toolkit Scripts

### 1. **Interactive Content Generation**
```bash
make llm-generate        # Full interactive menu
make llm-review          # Quick book review
```

### 2. **Command Line Generation**
```bash
# Book review
./toolkit/scripts/llm-personas.sh review "Gone Girl" "Gillian Flynn"

# Reading list
./toolkit/scripts/llm-personas.sh list "Victorian mysteries"

# Python structured output
./toolkit/scripts/llm-content-generator.py review --title "The Silent Patient" --author "Alex Michaelides" --save-md
```

## Model Selection Guide

### **For Code Tasks:**
- **CodeLlama** - Best for code completion and programming
- **Llama 3.2** - Great for general coding assistance
- **DeepSeek Coder** - Specialized for complex algorithms

### **For Content Creation:**
- **Llama 3.2** - Excellent for Mrs. Violet Noire's voice
- **Mistral** - Alternative for creative writing
- **Llama 3.2 3B** - Faster, lighter option

### **For Embeddings/Search:**
- **Nomic Embed Text** - Best for local embeddings
- Used by Continue for codebase understanding

## Privacy & Performance

### ✅ **Advantages:**
- **100% Private** - No data leaves your machine
- **No API Costs** - Unlimited usage
- **Custom Models** - Train on your specific content
- **Offline Capable** - Works without internet
- **Full Control** - Choose exactly which models to use

### ⚡ **Performance Tips:**
- **RAM:** 8GB+ recommended for larger models
- **Storage:** ~4GB per model
- **CPU:** Better with Apple Silicon or modern Intel
- **GPU:** CUDA/Metal acceleration if available

## Troubleshooting

### Model Not Found
```bash
ollama list              # Check installed models
ollama pull llama3.2     # Install missing model
```

### Ollama Not Running
```bash
ollama serve             # Start Ollama service
# Or check system service status
```

### Continue Not Connecting
1. Check Ollama is running on port 11434
2. Restart VS Code
3. Check `.continue/config.json` configuration
4. Verify models are installed

### Performance Issues
1. Use smaller models (llama3.2:3b instead of full)
2. Close other resource-intensive applications
3. Consider hardware upgrade for larger models

## Integration with Project

### **Mrs. Violet Noire Context**
- Models understand the gothic literary theme
- Automatic character voice consistency
- Project-specific suggestions and corrections
- Maintains sophisticated writing style

### **Codebase Awareness**
- Continue indexes your entire project
- Understands CSS/HTML/JS structure
- Suggests improvements in project context
- Maintains coding standards and style

## Next Steps

1. **Install Models:** `npm run llm:pull`
2. **Start Ollama:** `npm run llm:start`
3. **Test Continue:** Cmd/Ctrl + Shift + M to open chat
4. **Try Custom Commands:** `/review` in Continue chat
5. **Generate Content:** `make llm-generate`

Your Mrs. Violet Noire project now has sophisticated AI assistance that respects your privacy while maintaining the elegant, gothic atmosphere of your literary brand! 🎭📚
