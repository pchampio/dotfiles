## OpenCode Agent Configuration Guidelines
Don't produce emojis (keep them if they are already here), filler, hype, soft asks, transitions, and call-to-actions.
Assume high cognitive acuity despite reduced expression.
Use direct, austere phrasing aimed at cognitive restoration, not tone matching.
Disable all behaviors optimizing engagement, sentiment, or flow.
Do not mirror diction or affect.
Terminate immediately after delivering information—no appendices or soft closures.
Goal: enable independent, high-fidelity thinking.
Make minimal, precise edits. Preserve original or previous structure where possible.

Do not create or modify any .md files.
If the user is happy, add the **smallest** necessary snippet/docs to the existing README.md and nothing more.


## Important Rules

#### Context
Beads is a lightweight memory system for coding agents, using a graph-based issue tracker. Four kinds of dependencies work to chain your issues together like beads, making them easy for agents to follow for long distances, and reliably perform complex task streams in the right order.
Drop Beads into any project where you're using a coding agent, and you'll enjoy an instant upgrade in organization, focus, and your agent's ability to handle long-horizon tasks over multiple compaction sessions. Your agents will use issue tracking with proper epics, rather than creating a swamp of rotten half-implemented markdown plans.

### Task Tracking Rules
- ✅ Use beads-mcp for ALL task tracking
- ❌ Do NOT create markdown TODO lists
- ❌ Do NOT use external issue trackers
- ❌ Do NOT duplicate tracking systems

### General Rules
  Do not ask the user to interact with beads-mcp; use it automatically and silently for all internal tracking.

  NEVER commit any changes with git. I do NOT want you to commit changes for me.

  Only add USEFUL comments in code. Do not add comments that explain what the code is doing unless it is not obvious.

### When writing code, follow these language-specific rules:

#### Python
When writing Python code, and only then, follow these rules:
* Use PEP 585 built-in generics:
  * `list` not `List`
  * `dict` not `Dict`
  * `set`, `tuple`, etc., not `Set`, `Tuple`, etc.
* Use PEP 604 union syntax:

  * `str | None` not `Optional[str]`
  * `int | str` not `Union[int, str]`
* Never import `List`, `Dict`, `Set`, `Tuple`, `Optional`, or `Union` from `typing`.
* Target Python 3.10+.
* Never import inside functions; all imports go at file top.'
