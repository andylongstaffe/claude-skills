echo "Refreshing skills from ~/.claude/skills to the current directory..."
cp -R ~/.claude/skills/* ./skills/
echo "Refreshing agents from ~/.claude/agents to the current directory..."
cp -R ~/.claude/agents/* ./agents/
echo "Refreshing CLAUDE.md from ~/.claude/CLAUDE.md to the current directory..."
cp ~/.claude/CLAUDE.md ./md/claude.global.md
echo "Refresh complete!"