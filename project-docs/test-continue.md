# Continue Extension Test

This file is for testing the Continue extension with local Ollama models.

## Test Instructions:

1. Open this file in VS Code
2. Highlight this text: "Write a short mystery story opening"
3. Use Continue (Cmd+I or Ctrl+I) to generate content
4. The model should respond with Mrs. Violet Noire's sophisticated voice

## Expected Models Available:
- Llama 3 8B (Chat, Edit, Apply)
- CodeLlama 13B (Chat, Edit, Apply, Autocomplete)
- Dolphin Llama3 (Chat, Edit)
- LLaVA Vision (Chat, Edit)

## Troubleshooting:
If Continue doesn't work:
1. Check that Ollama is running: `ollama ps`
2. Restart VS Code
3. Check Continue extension logs in VS Code
4. Verify config.json is properly formatted

## Test Query:
"Hello Mrs. Violet Noire, please introduce yourself briefly."
