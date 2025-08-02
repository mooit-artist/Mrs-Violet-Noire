#!/bin/bash

# Local LLM Copilot Model Switcher
# Usage: ./switch-model.sh [model-name]

MODELS=(
    "dolphin-llama3:latest"
    "llama3:8b"
    "codellama:13b"
    "llava:latest"
)

switch_model() {
    local model="$1"
    echo "🔄 Switching Local LLM Copilot to: $model"

    python3 -c "
import json

with open('.vscode/settings.json', 'r') as f:
    settings = json.load(f)

settings['localLLMCopilot.model'] = '$model'

with open('.vscode/settings.json', 'w') as f:
    json.dump(settings, f, indent=2)

print('✅ Model switched to: $model')
print('💡 Restart VS Code or reload window for changes to take effect')
"
}

if [ $# -eq 0 ]; then
    echo "🤖 Available Local LLM Models:"
    echo "=============================="
    for i in "${!MODELS[@]}"; do
        echo "$((i+1)). ${MODELS[$i]}"
    done
    echo ""
    echo "Usage: $0 [model-name]"
    echo "Example: $0 dolphin-llama3:latest"
    exit 0
fi

MODEL="$1"

# Check if model exists in Ollama
if ollama list | grep -q "$MODEL"; then
    switch_model "$MODEL"
else
    echo "❌ Model '$MODEL' not found in Ollama"
    echo "Available models:"
    ollama list
fi
