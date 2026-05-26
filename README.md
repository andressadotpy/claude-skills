# claude-skills

Personalized [Claude Code](https://docs.anthropic.com/en/docs/claude-code/overview) skills for software engineers. These are user-level skills, available across all repositories — not tied to any single project.

## Quick Start

```bash
git clone https://github.com/andressadotpy/claude-skills.git ~/claude-skills
cd ~/claude-skills
./setup.sh
```

`setup.sh` symlinks each skill directory from `skills/` into `~/.claude/skills/`, making them available as user-level skills in every Claude Code session.

## Skills

| Skill | Description |
|---|---|
| [`code-review`](./skills/code-review/SKILL.md) | Thorough code review covering correctness, security, performance, and best practices |

## How to Use a Skill

Once installed, invoke any skill from a Claude Code session using its name as a slash command:

```
/code-review
```

You can also pass arguments:

```
/code-review src/api/users.py
```

## Adding a New Skill

1. Create a directory under `skills/` with the skill name:

   ```bash
   mkdir skills/my-skill
   ```

2. Create a `SKILL.md` file inside it with front matter and instructions:

   ```markdown
   ---
   name: my-skill
   description: Brief description of what this skill does and when to invoke it.
   version: 1.0.0
   user-invocable: true
   argument-hint: "[optional argument hint]"
   ---

   # My Skill

   Instructions for Claude on how to execute this skill...
   ```

3. Re-run `./setup.sh` to link the new skill:

   ```bash
   ./setup.sh
   ```

### SKILL.md Front Matter Fields

| Field | Required | Description |
|---|---|---|
| `name` | ✅ | Unique skill identifier (used as the slash command name) |
| `description` | ✅ | One-sentence description; helps Claude decide when to suggest this skill |
| `version` | ❌ | Semantic version (e.g. `1.0.0`) |
| `user-invocable` | ❌ | Set to `true` to allow direct user invocation via `/skill-name` |
| `argument-hint` | ❌ | Hint shown to the user for optional arguments (e.g. `"[file or directory]"`) |

## Updating

Pull the latest changes and re-run setup:

```bash
cd ~/claude-skills
git pull
./setup.sh
```
