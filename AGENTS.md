# Project Agents Guide

## Active Program

- Active project codename: `u_core`
- Active architecture baseline: `docs/异构处理器总体规格与总体架构设计说明书_V1_5_整合增强版.docx`
- Effective spec rule: treat the V1.5 architecture document as the single active top-level spec baseline for current design work.
- Legacy context rule: previous `axi4`-centric project context is obsolete unless the user explicitly asks to reuse or reference it.

## Scope

This repository is used for the `u_core` digital IC front-end project, including:

- RTL design, primarily in Verilog/SystemVerilog
- Verification, primarily in SystemVerilog and UVM
- Documentation and specification refinement
- Git-based version management

The current project target is a heterogeneous processor prototype built around a 32-bit CPU, DMA engine, independent SPM subsystem, and a 16x16 systolic-array NPU.

All implementation and verification work must stay aligned with the chip spec. If the current spec is incomplete, inconsistent, or outdated, update the related documentation as part of the same task when appropriate.

## Working Rules

1. Treat the spec as the first source of truth before changing RTL or verification code.
2. Review both design code and related documents before making functional changes.
3. When behavior is unclear, identify the spec gap explicitly instead of guessing silently.
4. Keep docs and code synchronized. If code behavior changes, update the relevant spec note or design note in the same round when feasible.
5. Prefer small, reviewable changes with a clear purpose and verification story.
6. For `u_core`, prioritize the V1.5 architecture document over older notes, drafts, or legacy module assumptions.
7. Do not carry forward old `axi4_master` module assumptions, interfaces, or terminology unless they are explicitly reintroduced by the current spec.
8. Place RTL code only under the owned module `rtl/` directory.
9. Place module FS and register-table documents only under the owned module `doc/` directory, unless the document is project-wide and belongs in `docs/`.
10. Place UVM verification code only under the owned `u_core_dv_*` directory.
11. CPU currently does not use a standalone top-level DV directory unless the user explicitly asks for one.
12. Lightweight module-local non-UVM smoke tests may be placed under the owned module `tb/` directory.

## Environment Assumption

1. The user's primary development environment is a MacBook running macOS.
2. For system-related errors, shell behavior, path conventions, tool installation guidance, and local workflow assumptions, default to macOS standards unless the user explicitly says otherwise.
3. If the current execution environment differs from macOS, treat it only as a temporary execution host and do not generalize its Linux-specific behavior to the user's normal workflow.

## Primary Spec Baseline

Current first-source specification document:

- `docs/异构处理器总体规格与总体架构设计说明书_V1_5_整合增强版.docx`

When extracting implementation requirements from the document, use these project-level frozen points unless the spec is updated:

- CPU is fixed to `picorv32_axi` and CPU core RTL must not be modified.
- Control plane uses AXI-Lite.
- Data plane uses AXI4 Full.
- `spm_subsys` is an independent subsystem between DMA and NPU.
- DMA follows `descriptor staging + pending FIFO + scheduler`.
- NPU follows `CSR + START`, then waits for buffer-ready conditions before compute.
- Compute baseline is a `16x16` systolic array with `INT8` multiply, `INT32` psum, and `Ktile=32` as the preferred starting point.

## Code Areas

- `docs/`: project-wide specification notes, architecture notes, interface notes, and workflow documents
- `u_core_module_cpu/rtl/`: CPU RTL and imported CPU source
- `u_core_module_cpu/doc/`: CPU FS documents and register tables only
- `u_core_module_cpu/tb/`: lightweight module-local non-UVM tests when needed
- `u_core_module_dma/rtl/`: DMA RTL only
- `u_core_module_dma/doc/`: DMA FS documents and register tables only
- `u_core_module_dma/tb/`: lightweight module-local non-UVM tests
- `u_core_module_npu/rtl/`: NPU RTL only
- `u_core_module_npu/doc/`: NPU FS documents and register tables only
- `u_core_module_npu/tb/`: lightweight module-local non-UVM tests
- `u_core_module_spm/rtl/`: SPM RTL only
- `u_core_module_spm/doc/`: SPM FS documents and register tables only
- `u_core_module_spm/tb/`: lightweight module-local non-UVM tests when needed
- `u_core_top_soc/rtl/`: top-level integration RTL only
- `u_core_top_soc/doc/`: top-level FS documents and register tables only
- `u_core_top_soc/tb/`: lightweight top-level directed tests when needed
- `u_core_dv_dma/`: DMA UVM verification only
- `u_core_dv_npu/`: NPU UVM verification only
- `u_core_dv_spm/`: SPM UVM verification only
- `u_core_dv_top_soc/`: top-level SoC UVM verification only

As the repository grows, keep code and documentation inside the owning module directory. Do not place RTL outside `rtl/`, and do not place module FS or register-list documents outside `doc/`.
For verification work, do not place UVM source outside the owning `u_core_dv_*` directory.
Keep module `tb/` focused on simple directed tests and smoke-test content, not full UVM environments.

## Design Workflow

For RTL design tasks:

1. Read the relevant spec or design note first.
2. Confirm module responsibility boundaries before coding, especially across `cpu_subsys`, `dma_top`, `spm_subsys`, and `npu_top`.
3. Confirm interface intent, legal transactions, boundary conditions, reset behavior, and backpressure assumptions.
4. Implement the RTL change with readable state machines, explicit signal intent, and maintainable naming.
5. Check whether the change also requires documentation updates in `docs/`.
6. Summarize what changed, why, and what still needs verification.

## Verification Workflow

For verification tasks:

1. Derive the test plan from the spec and current RTL behavior.
2. Prefer self-checking testbenches.
3. Use SystemVerilog and UVM patterns when the environment calls for them.
4. Cover legal flows, protocol violations, corner cases, and backpressure scenarios.
5. For `u_core`, ensure verification plans cover DMA/SPM/NPU coordination, ready/free/valid ownership transitions, and system-level tile completion conditions.
6. When a bug is found, document the failure mode, root cause, and verification coverage added for the fix.

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
5. If a request conflicts with the active V1.5 architecture document, call out the conflict explicitly before implementing.
6. When the document is high-level and signal definitions are still open, prefer documenting the unresolved signal-level contract instead of silently inventing one.

## Current Project Context

- Current architecture spec: `docs/异构处理器总体规格与总体架构设计说明书_V1_5_整合增强版.docx`
- Current project focus: heterogeneous `CPU + DMA + spm_subsys + NPU` design for `u_core`
- Current frozen architecture boundaries include the following:
- CPU: `picorv32_axi`, no CPU core RTL modifications
- DMA: AXI-Lite CSR front end plus AXI4 Full data mover
- SPM: independent local buffer subsystem
- NPU: CSR-configured compute engine with START-driven execution
- Current normalized architecture note: `docs/u_core_architecture_freeze.md`
- Current interface definition note: `docs/u_core_interface_definition.md`
- Current project structure note: `docs/project_structure.md`
- Current module layout:
- `u_core_module_cpu/{rtl,doc}`
- `u_core_module_dma/{rtl,doc}`
- `u_core_module_npu/{rtl,doc}`
- `u_core_module_spm/{rtl,doc}`
- `u_core_top_soc/{rtl,doc}`
- Current DV layout:
- `u_core_dv_dma/{tb,env,agent,seq,test,sim,doc}`
- `u_core_dv_npu/{tb,env,agent,seq,test,sim,doc}`
- `u_core_dv_spm/{tb,env,agent,seq,test,sim,doc}`
- `u_core_dv_top_soc/{tb,env,agent,seq,test,sim,doc}`
- CPU currently has no standalone `u_core_dv_cpu/` root.
- Git flow reference: `docs/git_workflow.md`
- Legacy `axi4_master` project references are no longer the default working context.
- The current workflow and conventions are expected to evolve; update this file as new team norms are established.
