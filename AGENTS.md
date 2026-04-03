# Project Agents Guide

## Scope

This repository is used for digital IC front-end work, including:

- RTL design, primarily in Verilog/SystemVerilog
- Verification, primarily in SystemVerilog and UVM
- Documentation and specification refinement
- Git-based version management

All implementation and verification work must stay aligned with the chip spec. If the current spec is incomplete, inconsistent, or outdated, update the related documentation as part of the same task when appropriate.

## Working Rules

1. Treat the spec as the first source of truth before changing RTL or verification code.
2. Review both design code and related documents before making functional changes.
3. When behavior is unclear, identify the spec gap explicitly instead of guessing silently.
4. Keep docs and code synchronized. If code behavior changes, update the relevant spec note or design note in the same round when feasible.
5. Prefer small, reviewable changes with a clear purpose and verification story.

## Environment Assumption

1. The user's primary development environment is a MacBook running macOS.
2. For system-related errors, shell behavior, path conventions, tool installation guidance, and local workflow assumptions, default to macOS standards unless the user explicitly says otherwise.
3. If the current execution environment differs from macOS, treat it only as a temporary execution host and do not generalize its Linux-specific behavior to the user's normal workflow.

## Code Areas

- `rtl/`: synthesizable design code
- `docs/`: specification notes, design notes, verification notes, and change context

As the repository grows, keep design, verification, and documentation organized by module or IP block.

## Design Workflow

For RTL design tasks:

1. Read the relevant spec or design note first.
2. Confirm interface intent, legal transactions, boundary conditions, reset behavior, and backpressure assumptions.
3. Implement the RTL change with readable state machines, explicit signal intent, and maintainable naming.
4. Check whether the change also requires documentation updates in `docs/`.
5. Summarize what changed, why, and what still needs verification.

## Verification Workflow

For verification tasks:

1. Derive the test plan from the spec and current RTL behavior.
2. Prefer self-checking testbenches.
3. Use SystemVerilog and UVM patterns when the environment calls for them.
4. Cover legal flows, protocol violations, corner cases, and backpressure scenarios.
5. When a bug is found, document the failure mode, root cause, and verification coverage added for the fix.

## Simulation And Debug

Primary tools:

- `vcs` for compile and simulation
- `verdi` for waveform and debug analysis

When working on simulation-related tasks:

1. Use `vcs` and `verdi` conventions if the repo already contains scripts or established commands.
2. Report the exact compile, simulation, or debug command when it matters for reproducibility.
3. Call out whether a result is compile-only, smoke-tested, or fully verified.
4. Preserve useful debug artifacts and notes when they materially help future analysis.

## Git Workflow

1. Use Git for all version management.
2. `main` is the stable branch.
3. `develop` is the integration branch for ongoing work.
4. Create task branches from `develop` using clear names such as `feature/<topic>`, `fix/<topic>`, or `verify/<topic>`.
5. Merge task branches back to `develop` through PRs.
6. Merge `develop` to `main` only when the change set is ready for a stable milestone or release point.
7. Never rewrite or discard user changes unless explicitly requested.
8. See `docs/git_workflow.md` for the project Git flow.

## PR And Commit Expectations

Every PR should clearly state:

- what changed
- why it changed
- what was verified
- the version name or change name for that update

When preparing commit or PR text, include module-level impact and any related spec/doc updates.

## Communication Defaults

When assisting in this repository:

1. Start from the spec and current code, not assumptions.
2. Flag unclear requirements, missing documentation, and verification gaps.
3. After code changes, explain the modified behavior and expected verification scope.
4. If a task touches both design and verification, address both sides or state what remains open.

## Current Project Context

- Current design note: `docs/axi4_master_notes.md`
- Current RTL module: `rtl/axi4_master.sv`
- Git flow reference: `docs/git_workflow.md`
- The current workflow and conventions are expected to evolve; update this file as new team norms are established.
