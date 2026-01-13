---
trigger: always_on
description: Rules for generating commit messages
---
# Commit Message Rules
When generating commit messages, STRICTLY follow this format:
`type/TICKET-ID: description`
## Format Breakdown
- **type**: One of `feature`, `fix`, `hotfix`, `release`, `docs`, `style`, `refactor`, `test`, `chore`.
- **slash (`/`)**: Separator between type and Ticket ID.
- **TICKET-ID**: The JIRA/Linear ticket ID (e.g., `TG-123`, `MEUP-544`). If available in branch name, USE IT.
- **colon (`:`)**: Separator after Ticket ID.
- **description**: Short summary in lowercase, imperative mood.
## Examples
- `feature/TG-123: add login button`
- `fix/MEUP-544: fix crash on startup`
- `style/TG-789: format code`
- `chore/TG-999: update dependencies`
## Rules
1. **Always include the Ticket ID** if one can be inferred from the context (branch name).
2. **Use lowercase** for the description.
3. **No period** at the end.
4. **Imperative mood** ("add" not "added").