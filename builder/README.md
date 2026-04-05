# Skill Writer Builder

Build tool for skill-writer - embeds core engine into platform-specific skills.

## Installation

```bash
npm install -g skill-writer-builder
```

Or use without installing:

```bash
npx skill-writer-builder <command>
```

## Usage

### Build

Build for a specific platform:

```bash
skill-writer-builder build --platform opencode
```

Build for all platforms:

```bash
skill-writer-builder build --all
```

Release build (optimized):

```bash
skill-writer-builder build --all --release
```

### Development Mode (Watch)

Watch files and auto-rebuild:

```bash
skill-writer-builder dev --platform opencode
```

### Validate

Validate project structure:

```bash
skill-writer-builder validate
```

### Inspect

Inspect built output:

```bash
skill-writer-builder inspect --platform opencode
```

## Supported Platforms

- **opencode** - OpenCode platform
- **openclaw** - OpenClaw platform (AgentSkills compatible)
- **claude** - Claude Code
- **cursor** - Cursor editor
- **openai** - OpenAI GPTs
- **gemini** - Google Gemini

## Project Structure

```
builder/
├── bin/                    # CLI entry point
├── src/
│   ├── commands/          # CLI commands
│   │   ├── build.js
│   │   ├── dev.js
│   │   ├── validate.js
│   │   └── inspect.js
│   ├── core/              # Core logic
│   │   ├── reader.js      # Read core files
│   │   └── embedder.js    # Embed into templates
│   ├── platforms/         # Platform adapters
│   │   ├── index.js
│   │   ├── opencode.js
│   │   └── openclaw.js
│   └── index.js           # Main entry
├── tests/                 # Test files
└── package.json
```

## How It Works

1. **Read** - Reads companion Markdown files from `refs/`, `templates/`, `eval/`, `optimize/`
2. **Parse** - Parses Markdown and JSON files
3. **Embed** - Embeds content into platform-specific templates
4. **Generate** - Generates complete skill files for each platform
5. **Output** - Writes to `../platforms/skill-writer-{platform}-dev.md`

## Development

```bash
cd builder
npm install
npm run dev
```

## License

MIT
