---
name: user-story
description: Use when asked to write a user story, JIRA ticket, or describe work for a ticket tracker. Also use when brainstorming produces a design that needs capturing as a story.
---

# Write User Story

Generate a concise JIRA user story from conversation context or a design/spec.

## Format

Output must follow this exact structure:

```
**User Story:**

As a <role>, I want <goal>, so that <benefit>.

**Acceptance Criteria:**

1. <criterion>
2. <criterion>
...

**Notes:**
- <implementation note or background info>
- <link to spec/plan if applicable>
```

## Rules

- **Title:** Always suggest a short title separately before the story (under 70 characters, no ticket prefix)
- **Role:** Use the most specific end-user role that benefits (e.g. "policy author" not "platform engineer", "API consumer" not "developer"). Ask if unsure.
- **As/I want/So that:** One sentence each, concrete, no jargon
- **Acceptance criteria:** Numbered, testable, terse — one short line each. Sacrifice grammar for brevity. Cover observable behaviour, not implementation steps.
- **Notes:** Optional section. Only include if there are implementation references (spec paths, plan paths), scope exclusions worth calling out, or brief background that isn't obvious from the story. Keep to 2-5 bullet points max.
- **Tone:** Write for the person picking up the ticket, not the person who designed it. Assume they have access to linked specs but no other context.
- **Length:** The whole story should fit on one screen. Sacrifice grammar for concision. No filler.
- **No implementation detail in acceptance criteria.** "Input is validated against a JSON schema" is good. "A `Registry` struct with `Register` and `Get` methods is implemented" is not — that belongs in the plan.
