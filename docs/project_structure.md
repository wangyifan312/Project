# Project Structure Standard

## Scope

This document defines the preferred repository layout for the `u_core` project.
It is intended to keep architecture, RTL, verification, and third-party content
organized as the project grows.

## Standard Top-Level Layout

Recommended repository layout:

```text
Project/
├── AGENTS.md
├── docs/
├── u_core_dv_dma/
├── u_core_dv_npu/
├── u_core_dv_spm/
├── u_core_dv_top_soc/
├── u_core_module_cpu/
├── u_core_module_dma/
├── u_core_module_npu/
├── u_core_module_spm/
└── u_core_top_soc/
```

## Directory Rules

### `docs/`

Use `docs/` for all project-authored specifications and design notes, including:

- architecture specifications
- interface definitions
- module notes
- verification plans
- project workflow notes

Recommended contents:

- original architecture documents, including `.docx` artifacts when needed
- normalized Markdown freeze notes
- interface-definition notes
- block-level design notes

### Module Directories

The project uses module-owned directories for implementation work:

- `u_core_module_cpu/`
- `u_core_module_dma/`
- `u_core_module_npu/`
- `u_core_module_spm/`
- `u_core_top_soc/`

Each module directory must contain:

- `rtl/`
- `doc/`

### `rtl/`

Use each module's `rtl/` directory for synthesizable design code only.

Allowed contents:

```text
u_core_module_xxx/rtl/
└── RTL source, include files, and related synthesizable code
```

Constraints:

- all new RTL code must be added only under the corresponding module `rtl/`
- do not place FS documents, register tables, review notes, or other documentation in `rtl/`

### `doc/`

Use each module's `doc/` directory for module-owned documentation only.

Allowed contents:

```text
u_core_module_xxx/doc/
├── module FS documents
└── module register list / register table documents
```

Constraints:

- module `doc/` directories are reserved for:
  - FS documents
  - register list / register table documents
- do not place RTL source files in `doc/`
- do not use module `doc/` as a general scratch-note directory

### `u_core_top_soc/`

`u_core_top_soc/` is reserved for top-level integration work.

Its subdirectory rules are the same:

```text
u_core_top_soc/
├── rtl/
└── doc/
```

Use `u_core_top_soc/rtl/` for:

- top-level integration RTL
- top-level wiring between CPU, DMA, SPM, and NPU
- top-level interconnect and address decode logic

Use `u_core_top_soc/doc/` for:

- top-level FS
- top-level register map
- top-level integration documents directly tied to the SoC top

### DV Directories

The project uses dedicated DV-owned directories for UVM verification work:

- `u_core_dv_dma/`
- `u_core_dv_npu/`
- `u_core_dv_spm/`
- `u_core_dv_top_soc/`

Current rule:

- CPU does not use a standalone top-level DV directory in the current phase

Each DV directory should use the following structure:

```text
u_core_dv_xxx/
├── tb/
├── env/
├── agent/
├── seq/
├── test/
├── sim/
└── doc/
```

Use guidance:

- `tb/`: top-level testbench files and harness code
- `env/`: UVM environment, scoreboard, coverage, configuration objects
- `agent/`: protocol agents, drivers, monitors, sequencers
- `seq/`: sequences and sequence items
- `test/`: test classes and test-list content
- `sim/`: simulation scripts, filelists, run recipes, and tool config
- `doc/`: DV plan, checklist, and verification notes

Constraints:

- keep UVM verification code only inside the owning `u_core_dv_*` directory
- do not place DUT RTL inside DV directories
- do not place ad-hoc scratch files directly under the DV root
- use `doc/` under each DV root for module-owned verification documentation only

### Imported CPU Source

The imported PicoRV32 CPU source is currently located under:

- [`u_core_module_cpu/rtl`](/root/Project/u_core_module_cpu/rtl)

Preserve the imported CPU code carefully and avoid mixing unrelated non-CPU material into that directory.

## Naming Guidance

Use the following fixed directory names:

- `u_core_module_cpu`
- `u_core_module_dma`
- `u_core_module_npu`
- `u_core_module_spm`
- `u_core_top_soc`
- `u_core_dv_dma`
- `u_core_dv_npu`
- `u_core_dv_spm`
- `u_core_dv_top_soc`

For documentation, prefer names that clearly indicate intent:

- `*_fs.*`
- `*_registers.*`
- `*_reg_table.*`

## Immediate Standardization Status

The repository is currently in an early setup phase. The following are already standardized:

- architecture and interface documents live under [`docs/`](/root/Project/docs)
- CPU source is placed under [`u_core_module_cpu/rtl`](/root/Project/u_core_module_cpu/rtl)
- module directories exist for CPU, DMA, NPU, SPM, and top-level integration
- each module directory contains `rtl/` and `doc/`
- dedicated DV directories exist for DMA, NPU, SPM, and top-level SoC verification
- each DV directory contains `tb/`, `env/`, `agent/`, `seq/`, `test/`, `sim/`, and `doc/`
