#!/bin/bash

echo "🔍 Continue Extension Debugging Script"
echo "======================================"
echo ""

echo "📋 1. Checking Ollama Status:"
if pgrep ollama > /dev/null; then
    echo "✅ Ollama is running"
    ollama ps | head -5
else
    echo "❌ Ollama is not running"
    echo "Run: ollama serve"
fi
echo ""

echo "📋 2. Testing Ollama API:"
curl -s -o /dev/null -w "%{http_code}" http://localhost:11434 && echo " ✅ Ollama API accessible" || echo " ❌ Ollama API not accessible"
echo ""

echo "📋 3. Available Models:"
ollama list | head -10
echo ""

echo "📋 4. Continue Configuration:"
if [ -f ".continue/config.json" ]; then
    echo "✅ Project config exists"
    echo "Models configured:"
    jq -r '.models[].title' .continue/config.json 2>/dev/null || echo "❌ Invalid JSON in config"
else
    echo "❌ No project config found"
fi
echo ""

echo "📋 5. Global Continue Configuration:"
if [ -f "$HOME/.continue/config.yaml" ]; then
    echo "✅ Global config exists"
    echo "Models configured:"
    grep -A1 "name:" ~/.continue/config.yaml | grep "name:" | head -5
else
    echo "❌ No global config found"
fi
echo ""

echo "📋 6. Testing Model Response:"
echo "Testing llama3:8b..."
curl -s -X POST http://localhost:11434/api/generate \
  -d '{"model": "llama3:8b", "prompt": "Hello! Test response.", "stream": false}' \
  | jq -r '.response' 2>/dev/null | head -3 || echo "❌ Model test failed"
echo ""

echo "🎯 Next Steps:"
echo "1. If all checks pass, restart VS Code"
echo "2. Open test-continue.md and try Continue (Cmd+I)"
echo "3. If issues persist, check VS Code Continue extension logs"
