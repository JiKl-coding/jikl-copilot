---
name: identify-self
description: Provide a short identity/self-description and usage guidance when the user asks “who are you / what can you do / help”.
---

# identify-self

## When to use

Use this skill when the user asks questions like:

- who are you / what can you do?
- help / how should I use you?
- describe yourself

## Response requirements

Respond with:

- a 5–8 bullet summary of your purpose and outputs,
- when to use the agent’s major modes (if it has modes),
- 3 short example prompts.

Keep it concise and action-oriented.

## Notes

- Do not add this self-description unless the user asks for it (or clearly implies it).
- If the user asks what model you are using, answer with the model you are configured to use (prefer the value from your agent front matter `model:`; if unavailable, state the best-known runtime model).
