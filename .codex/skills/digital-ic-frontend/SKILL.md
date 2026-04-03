---
name: digital-ic-frontend
description: Use this skill for digital IC front-end tasks in this repository, especially RTL design in Verilog/SystemVerilog, verification in SystemVerilog/UVM, spec-driven implementation, documentation updates, and VCS/Verdi-based compile, simulation, and debug workflows.
---

# Digital IC Front-End Workflow

Use this skill when the task involves digital IC front-end development or verification in this repository.

## Primary Rules

1. Start from the chip spec or the closest available design note before changing code.
2. Treat `docs/` and implementation as a linked pair. If behavior changes, check whether the docs should change too.
3. Prefer explicit protocol handling, readable control logic, and verification that traces back to the spec.
4. Use Git as the default change-management layer and keep updates review-friendly.

## Environment Default

- Assume the user's normal development machine is a MacBook.
- For system-related troubleshooting, shell usage, install steps, filesystem conventions, and tool invocation guidance, prefer macOS-compatible instructions by default.
- If the current runtime environment is Linux, do not let Linux-specific behavior override macOS guidance unless the user explicitly asks for Linux handling.

## Repository Focus

- RTL is primarily written in Verilog/SystemVerilog.
- Verification is primarily written in SystemVerilog and UVM.
- Main simulation flow uses `vcs`.
- Main debug flow uses `verdi`.
- `main` is the stable branch.
- `develop` is the default integration base for ongoing work.

## Task Flow

For any design or verification task:

1. Read the relevant module file and matching document in `docs/`.
2. Extract the intended behavior, assumptions, legal/illegal cases, and open questions.
3. Make the smallest coherent code change that satisfies the spec intent.
4. Update related documentation when the implementation meaning, assumptions, or interface contract changes.
5. Report verification status clearly:
   - not run
   - compile checked
   - simulated
   - debugged in waveform

## RTL Guidance

When editing RTL:

- preserve synthesizability
- make reset behavior explicit
- keep handshake behavior clear
- avoid hidden protocol assumptions
- call out unsupported cases rather than masking them

Pay special attention to:

- burst legality
- boundary conditions such as 4 KB crossing
- backpressure behavior
- single-outstanding vs multi-outstanding assumptions
- local error generation paths

## Verification Guidance

When adding or planning verification:

- derive the test intent from the spec first
- prefer self-checking behavior
- include legal traffic, illegal traffic, boundary cases, and backpressure
- if using UVM, keep sequence, monitor, scoreboard, and coverage intent aligned with the feature under change

## VCS And Verdi

If compile, simulation, or debug work is requested:

1. Prefer existing repo scripts and command conventions if present.
2. If commands are created ad hoc, record the exact command used.
3. Distinguish between compile success and functional verification.
4. Use `verdi` or waveform analysis when explaining root cause for failures.

## Git And Review Requirements

- Git is the source of version history.
- Start new work from `develop` unless the user requests a different base.
- Use focused task branches and merge them back through PRs.
- If asked to prepare a PR summary, always include:
  - changed files or modules
  - functional impact
  - verification performed
  - version name or change name

## Current Repository Anchors

- Read `docs/axi4_master_notes.md` for current AXI4 master behavior and assumptions.
- Read `docs/git_workflow.md` for the project Git flow.
- Read `rtl/axi4_master.sv` before modifying AXI4 master logic.

## When To Escalate

Pause and surface the issue clearly if:

- the spec is missing or contradictory
- RTL behavior and docs disagree
- verification intent is underspecified
- a requested change may alter interface contract or architectural assumptions
