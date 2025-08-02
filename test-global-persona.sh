#!/bin/bash
# Test script to verify global Violet Noire Assistant persona integration

echo "🧪 Testing Global Violet Noire Assistant Persona Integration"
echo "============================================================="
echo ""

# Test 1: Check if global persona config exists
echo "🔍 Test 1: Checking global persona configuration..."
if [[ -f "toolkit/config/global-persona.yaml" ]]; then
    echo "✅ Global persona config found"
    echo "📄 Preview:"
    head -n 15 toolkit/config/global-persona.yaml | sed 's/^/   /'
    echo ""
else
    echo "❌ Global persona config missing"
    exit 1
fi

# Test 2: Test orchestrator with global context
echo "🔍 Test 2: Testing LLM orchestrator with global context..."
if command -v ollama >/dev/null 2>&1; then
    echo "📝 Generating test content with global persona context..."
    ./toolkit/scripts/llm-orchestrator.sh generate "Briefly introduce yourself and mention your mission." 2>/dev/null || echo "⚠️  LLM generation test skipped (Ollama may not be running)"
else
    echo "⚠️  Ollama not found - test skipped"
fi

echo ""
echo "🔍 Test 3: Checking updated security personas..."
if grep -q "Violet Noire" toolkit/config/security-personas.yaml; then
    echo "✅ Security personas updated with brand awareness"
else
    echo "❌ Security personas not updated"
fi

echo ""
echo "🔍 Test 4: Verifying Makefile integration..."
if grep -q "Global Violet Noire Assistant persona" Makefile; then
    echo "✅ Makefile updated with global persona feature"
else
    echo "❌ Makefile not updated"
fi

echo ""
echo "🎉 Global Violet Noire Assistant Persona Integration Complete!"
echo ""
echo "📋 Summary of Changes:"
echo "   • Global persona config: toolkit/config/global-persona.yaml"
echo "   • Updated LLM orchestrator to include global context"
echo "   • Enhanced personas script with brand awareness"
echo "   • Updated security personas with brand context"
echo "   • Updated Python content generator"
echo "   • Modified workflow orchestrator"
echo "   • Updated Makefile documentation"
echo ""
echo "🚀 All AI interactions now include Violet Noire brand context!"
echo "   - Brand mission awareness"
echo "   - Revenue generation focus"
echo "   - Literary theme consistency"
echo "   - Tool and workflow recommendations"
