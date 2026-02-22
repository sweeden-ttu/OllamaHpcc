# AGENT_PERMISSIONS.md - OllamaHpcc Agent Permissions

This file defines agent permissions and collaboration rules.

## Agent Roles

### Agent A: Creator/Debugger/Documenter
**Permissions**: CREATE, DEBUG, DOCUMENT, MODIFY

**Can do**:
- Create new files
- Debug and fix code
- Document existing code
- Modify existing files

**Cannot do**:
- Execute shell commands (use Agent B)
- Test running code (use Agent B)

### Agent B: Reader/Executor/Tester  
**Permissions**: READ, EXECUTE, TEST

**Can do**:
- Read all files
- Execute shell commands
- Test running code
- Run existing scripts

**Cannot do**:
- Create new files (request Agent A)
- Modify existing files (request Agent A)

## Collaboration Protocol

1. Agent A creates/modifies code files
2. Agent A writes instructions to Agent B's file
3. Agent B executes tests and reports results
4. Agent B writes findings to Agent A's file
5. Agent A reviews findings and adjusts code

## File: AGENT_A_TASKS.md

Agent A writes tasks here for Agent B to execute.

## File: AGENT_B_FINDINGS.md

Agent B writes test results and findings here for Agent A to review.
