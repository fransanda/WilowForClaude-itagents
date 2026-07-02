#!/bin/bash
# install.sh — Install WillowForClaude-itagents skills (companion to WillowForClaude-skills)
# Remote: curl -fsSL https://raw.githubusercontent.com/fransanda/WillowForClaude-itagents/main/install.sh | bash
# Local:  ./install.sh (from inside a cloned repo)

set -e

# Determine source: use the script's folder if it contains the skills,
# otherwise clone to a temp folder (needed for curl | bash install).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || true)"
TEMP_CLONE=""

if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/skills/itagentsreview/SKILL.md" ]; then
    SOURCE_ROOT="$SCRIPT_DIR"
else
    if ! command -v git >/dev/null 2>&1; then
        echo "Error: git is required to install. Install git first."
        exit 1
    fi
    TEMP_CLONE="$(mktemp -d)/WillowForClaude-itagents"
    trap '[ -n "$TEMP_CLONE" ] && rm -rf "$(dirname "$TEMP_CLONE")"' EXIT
    echo "Fetching itagents..."
    git clone --depth=1 --quiet https://github.com/fransanda/WillowForClaude-itagents.git "$TEMP_CLONE"
    SOURCE_ROOT="$TEMP_CLONE"
fi

echo ""
echo "Installing WillowForClaude-itagents skills..."
echo ""

# 1. Install the skills (/itagentsreview, /additagent, /mergeprs, /uitest) to both possible skill dirs
INSTALLED_SKILLS=0
for skill in itagentsreview additagent mergeprs uitest; do
    SRC="$SOURCE_ROOT/skills/$skill/SKILL.md"
    if [ ! -f "$SRC" ]; then
        echo "  ⚠️  Source not found for /$skill — skipping"
        continue
    fi
    for d in "$HOME/.claude/skills" "$HOME/.agents/skills"; do
        mkdir -p "$d/$skill"
        cp "$SRC" "$d/$skill/SKILL.md"
    done
    echo "  ✅ Installed /$skill"
    INSTALLED_SKILLS=$((INSTALLED_SKILLS+1))
done

# 2. Install the agent templates folder to both dirs (used by /kickoff and /autonomy when detected)
if [ -d "$SOURCE_ROOT/agents" ]; then
    for d in "$HOME/.claude/skills" "$HOME/.agents/skills"; do
        mkdir -p "$d/_itagents_templates/agents"
        cp -r "$SOURCE_ROOT/agents/." "$d/_itagents_templates/agents/"
    done
    echo "  ✅ Installed agent templates"
fi

echo ""
if [ $INSTALLED_SKILLS -eq 4 ]; then
    echo "Done! Restart Claude Code, then use:"
    echo "  /itagentsreview          — run the multi-agent QA pipeline"
    echo "  /itagentsreview --full   — full codebase audit (review-only)"
    echo "  /additagent              — add a custom agent to the project"
    echo "  /mergeprs                — review and merge open PRs autonomously"
    echo "  /uitest                  — deploy the live-browser UI testing army"
    echo ""
    echo "Note: requires WillowForClaude-skills installed first."
    echo "  curl -fsSL https://raw.githubusercontent.com/fransanda/WillowForClaude-skills/main/install.sh | bash"
    echo ""
else
    echo "⚠️  Installation incomplete: $INSTALLED_SKILLS of 4 skills installed"
fi
