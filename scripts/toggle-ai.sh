#!/bin/bash

# Toggle between GitHub Copilot and Local LLM with VS Code restart

SETTINGS_FILE=".vscode/settings.json"

echo "🤖 AI Model Switcher for Mrs. Violet Noire"
echo "=========================================="

# Function to restart VS Code
restart_vscode() {
    echo ""
    read -p "🔄 Restart VS Code to apply changes? (y/n): " restart_choice
    if [[ $restart_choice == "y" || $restart_choice == "Y" ]]; then
        echo "📴 Closing VS Code..."
        osascript -e 'tell application "Visual Studio Code" to quit'
        sleep 2
        echo "🚀 Restarting VS Code..."
        open -a "Visual Studio Code" .
        echo "✅ VS Code restarted!"
    else
        echo "💡 Remember to restart VS Code manually for changes to take full effect."
    fi
}

# Check current state
if grep -q '"github.copilot.editor.enableAutoCompletions": true' "$SETTINGS_FILE"; then
    CURRENT_MODE="GitHub Copilot"
else
    CURRENT_MODE="Local LLM"
fi

echo "Current mode: $CURRENT_MODE"
echo ""
echo "Choose your AI assistant:"
echo "1) 🏠 Local LLM (Dolphin Llama 3, Private)"
echo "2) ☁️  GitHub Copilot (Cloud-based)"
echo "3) 📊 Show current status"
echo "4) ❌ Cancel"
echo ""

read -p "Enter choice (1-4): " choice

case $choice in
    1)
        echo "🔄 Switching to Local LLM mode..."
        # Enable local, disable GitHub Copilot
        sed -i '' 's/"github.copilot.editor.enableAutoCompletions": true/"github.copilot.editor.enableAutoCompletions": false/' "$SETTINGS_FILE"
        sed -i '' 's/"github.copilot.enable": {/{/; s/"*": true/"*": false/' "$SETTINGS_FILE"
        sed -i '' 's/"yaml": true/"yaml": false/g' "$SETTINGS_FILE"
        sed -i '' 's/"plaintext": true/"plaintext": false/g' "$SETTINGS_FILE"
        sed -i '' 's/"markdown": true/"markdown": false/g' "$SETTINGS_FILE"
        sed -i '' 's/"javascript": true/"javascript": false/g' "$SETTINGS_FILE"
        sed -i '' 's/"python": true/"python": false/g' "$SETTINGS_FILE"
        sed -i '' 's/"html": true/"html": false/g' "$SETTINGS_FILE"
        sed -i '' 's/"css": true/"css": false/g' "$SETTINGS_FILE"
        sed -i '' 's/"json": true/"json": false/g' "$SETTINGS_FILE"
        echo "✅ Switched to Local LLM! Your Dolphin Llama 3 model is now active."
        restart_vscode
        ;;
    2)
        echo "🔄 Switching to GitHub Copilot mode..."
        # Enable GitHub Copilot, keep local available
        sed -i '' 's/"github.copilot.editor.enableAutoCompletions": false/"github.copilot.editor.enableAutoCompletions": true/' "$SETTINGS_FILE"
        sed -i '' 's/"*": false/"*": true/' "$SETTINGS_FILE"
        sed -i '' 's/"yaml": false/"yaml": true/g' "$SETTINGS_FILE"
        sed -i '' 's/"plaintext": false/"plaintext": true/g' "$SETTINGS_FILE"
        sed -i '' 's/"markdown": false/"markdown": true/g' "$SETTINGS_FILE"
        sed -i '' 's/"javascript": false/"javascript": true/g' "$SETTINGS_FILE"
        sed -i '' 's/"python": false/"python": true/g' "$SETTINGS_FILE"
        sed -i '' 's/"html": false/"html": true/g' "$SETTINGS_FILE"
        sed -i '' 's/"css": false/"css": true/g' "$SETTINGS_FILE"
        sed -i '' 's/"json": false/"json": true/g' "$SETTINGS_FILE"
        echo "✅ Switched to GitHub Copilot! Cloud-based suggestions are now active."
        restart_vscode
        ;;
    3)
        echo "📊 Current Configuration:"
        echo "========================"
        if grep -q '"github.copilot.editor.enableAutoCompletions": true' "$SETTINGS_FILE"; then
            echo "🟢 GitHub Copilot: ENABLED"
        else
            echo "🔴 GitHub Copilot: DISABLED"
        fi

        if grep -q '"localLLMCopilot.enabled": true' "$SETTINGS_FILE"; then
            echo "🟢 Local LLM: ENABLED"
            echo "   Model: $(grep 'localLLMCopilot.model' "$SETTINGS_FILE" | cut -d'"' -f4)"
        else
            echo "🔴 Local LLM: DISABLED"
        fi

        if grep -q '"continue.enableTabAutocomplete": true' "$SETTINGS_FILE"; then
            echo "🟢 Continue Tab Autocomplete: ENABLED"
            echo "   Default Model: $(grep 'continue.defaultModelTitle' "$SETTINGS_FILE" | cut -d'"' -f4)"
        else
            echo "🔴 Continue Tab Autocomplete: DISABLED"
        fi
        ;;
    4)
        echo "❌ Cancelled. No changes made."
        ;;
    *)
        echo "❌ Invalid choice. No changes made."
        ;;
esac

echo ""
echo "🔧 Available models in Continue:"
echo "   • Dolphin Llama 3 8B (Agent) - Default"
echo "   • Llama 3 8B - General purpose"
echo "   • CodeLlama 13B - Code completion"
echo "   • LLaVA Vision - Image analysis"
echo "   • DeepSeek V3 - Advanced reasoning"
