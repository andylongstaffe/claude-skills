---
name: review
allowed-tools: Bash(git *:*)
description: Review code using code-reviewer with optional commit and push
argument-hint: [jira-ticket-number]
disable-model-invocation: true
---

# Code Review Workflow

Reviews code changes using the code-reviewer subagent and optionally commits/pushes if no critical issues are found.

## Workflow

1. Review pending changes using the code-reviewer subagent
2. Report all findings to the user
3. Ask the user if they want to commit and push
4. If yes and no critical issues:
   - Get JIRA ticket number (from $ARGUMENTS or ask user)
   - Create branch from main if needed (format: cbp-XXXXX-short-description)
   - Commit with proper format: `fix(cbp-XXXXX): description`
   - Push to remote
5. If no or if critical issues found:
   - Stop without committing

## Instructions

### Step 1: Review Code

Use the code-reviewer subagent to review all pending changes. Focus on:
- Security issues
- Code quality problems
- Potential bugs
- Performance concerns
- Principles:
  - KISS (Keep It Simple, Stupid)
  - YAGNI (You Aren't Gonna Need It)
  - SOLID Principles
  - DRY (Don't Repeat Yourself)

### Step 2: Report Findings

Show the user a summary of the review:
- List any critical or high-priority issues
- List any medium/low priority suggestions
- Overall assessment

### Step 3: Ask User if They Want to Commit

Use AskUserQuestion to ask:
- Question: "Would you like to proceed with committing and pushing these changes?"
- Options:
  - "Yes, commit and push" (only if no critical issues)
  - "No, I'll review the findings first"

**IF user says NO or IF critical/high-priority issues exist:**
- Stop here
- Do not proceed with commit

**IF user says YES and no critical issues:**
- Proceed to Step 4

### Step 4: Prepare for Commit (only if user approved)

**CRITICAL: Check current branch first**
- Run `git branch --show-current`
- **IF on main or master branch:**
  - STOP immediately
  - Tell user: "Cannot commit directly to main branch. Please create a feature branch first."
  - Do NOT proceed with commit
  - Exit

**IF on a feature branch:**
- Check if JIRA ticket number was provided in $ARGUMENTS
- If not provided, ask the user for the JIRA ticket number
- Continue to Step 5

### Step 5: Commit and Push (only if user approved and NOT on main)

- Stage all changes: `git add .`
- Ask user for commit message (provide suggestion based on changes)
- Create commit with message format:
  ```
  fix(cbp-XXXXX): concise description of why changes were made

  Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
  ```
- Push to remote: `git push -u origin <branch-name>`
- Display the PR creation URL

## Important Notes

- **NEVER commit or push directly to main or master branch**
- Always create a feature branch first (cbp-XXXXX-description)
- Follow commit message conventions: `fix(cbp-XXXXX):` or `feat(cbp-XXXXX):` or `chore(cbp-XXXXX):`
- Description should explain WHY changes were made, not WHAT changed
- Always use heredoc format for multi-line commit messages
- Never commit if critical issues are found
- Always ask user before committing
