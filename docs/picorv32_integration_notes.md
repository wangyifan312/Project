# PicoRV32 Integration Notes For u_core

## Scope

This note summarizes the first-pass study results for the upstream `picorv32` repository cloned into:

- `u_core_module_cpu/rtl`

Repository snapshot used for this note:

- upstream: `https://github.com/YosysHQ/picorv32.git`
- local commit: `87c89acc18994c8cf9a2311e871818e87d304568`

The focus here is the `picorv32_axi` variant that matches the current `u_core` architecture baseline.

## High-Level Conclusion

`picorv32_axi` is not a burst-capable data-plane master. It is a 32-bit AXI4-Lite master wrapper around the base `picorv32` core and is suitable for:

- boot ROM fetch
- local RAM access
- CSR configuration
- status polling
- light software-side result checking

It is not suitable as the main high-throughput path to external shared memory. This aligns with the current `u_core` architecture document, where:

- CPU owns the control plane
- DMA owns the AXI4 Full data plane

## Relevant Upstream Modules

The upstream source is concentrated in [`picorv32.v`](/root/Project/u_core_module_cpu/rtl/picorv32.v), which contains:

- `picorv32`: base core with native valid/ready memory interface
- `picorv32_axi`: AXI4-Lite master wrapped version
- `picorv32_axi_adapter`: native memory interface to AXI4-Lite adapter
- `picorv32_wb`: Wishbone version

Key references:

- [`README.md`](/root/Project/u_core_module_cpu/rtl/README.md)
- [`picorv32.v`](/root/Project/u_core_module_cpu/rtl/picorv32.v)
- [`picosoc/README.md`](/root/Project/u_core_module_cpu/rtl/picosoc/README.md)

## What `picorv32_axi` Really Is

In upstream RTL, `picorv32_axi` instantiates:

1. the base `picorv32` core
2. a `picorv32_axi_adapter`

The wrapper exports an AXI4-Lite master memory interface, not AXI4 Full. The interface is single-beat and maps one native memory transaction at a time into AXI-Lite transactions.

Important observations from the RTL:

- read and write data width is `32` bits
- there is no AXI burst support
- `mem_ready` is generated from `BVALID` or `RVALID`
- instruction fetches are tagged on `ARPROT` using `3'b100`
- data reads use `ARPROT = 3'b000`

This means the CPU path should be treated as a control-oriented bus master, even if it can also fetch instructions and access RAM through the same interface.

## Native Core Memory Model

The base `picorv32` core uses a simple native valid/ready memory interface:

- `mem_valid`
- `mem_ready`
- `mem_addr`
- `mem_wdata`
- `mem_wstrb`
- `mem_rdata`
- `mem_instr`

The core can only have one memory transfer in flight at a time. For `u_core`, this is another reason to avoid using CPU as a data mover for tensor traffic.

The upstream README also documents a look-ahead interface:

- `mem_la_read`
- `mem_la_write`
- `mem_la_addr`
- `mem_la_wdata`
- `mem_la_wstrb`

This is useful for timing or tightly-coupled memory systems, but it is combinational and should not be our first integration target unless timing analysis later proves it is needed.

## Configuration Parameters That Matter For u_core

The following parameters are the most relevant for our project:

- `PROGADDR_RESET`
  Controls reset vector address.
- `PROGADDR_IRQ`
  Controls IRQ handler entry address.
- `STACKADDR`
  Optional reset-time initialization of register `x2`.
- `COMPRESSED_ISA`
  Enables RVC support.
- `ENABLE_IRQ`
  Enables PicoRV32 custom IRQ mechanism.
- `ENABLE_IRQ_QREGS`
  Enables IRQ q-register support.
- `ENABLE_MUL`
  Enables iterative multiply support via internal PCPI block.
- `ENABLE_FAST_MUL`
  Enables faster multiply implementation.
- `ENABLE_DIV`
  Enables divide and remainder instructions.

For first integration, the safest baseline assumption is:

- do not modify CPU RTL
- choose parameters explicitly in top-level integration
- keep software-visible reset and stack addresses aligned with our SoC memory map

## Interrupt Caveat

Upstream PicoRV32 IRQ handling is not standard RISC-V privileged interrupt architecture. It uses a lightweight custom mechanism with custom instructions such as:

- `retirq`
- `maskirq`
- `waitirq`
- optional q-register access instructions

This has two implications for `u_core`:

1. polling is the cleanest first-version software model, which already matches our architecture document
2. if we later enable interrupts from DMA or NPU, firmware and verification must follow PicoRV32's custom IRQ model rather than assuming a standard machine-mode trap flow

## Integration Guidance For u_core

Based on the upstream design and our architecture baseline, the recommended integration model is:

- `picorv32_axi` as the CPU core instance in `cpu_subsys`
- CPU AXI4-Lite master connected to a control-plane interconnect
- boot ROM, local RAM wrapper, DMA CSR, NPU CSR, and SYS/PERF/ERROR registers exposed as AXI-Lite slaves
- DMA remains the only AXI4 Full master for external shared-memory bulk movement

This cleanly preserves the project boundary already frozen in the architecture document:

- CPU does configuration and polling
- DMA performs burst movement
- NPU computes
- SPM buffers local tiles

## Memory-Map Implications

The current architecture document proposes:

- `0x0000_0000 ~ 0x0000_3FFF`: boot ROM
- `0x0001_0000 ~ 0x0001_7FFF`: local RAM
- `0x1000_0000 ~ 0x1000_0FFF`: NPU CSR
- `0x1000_1000 ~ 0x1000_1FFF`: DMA CSR
- `0x1000_2000 ~ 0x1000_2FFF`: SYS/PERF/ERROR
- `0x2000_0000 ~ ...`: external shared storage

This fits PicoRV32 well because:

- `PROGADDR_RESET` can point into boot ROM
- `STACKADDR` can point into local RAM
- CPU instruction and data accesses remain on a uniform 32-bit AXI-Lite control-oriented path

The upstream `picosoc` example is useful as a reference for memory map composition and reset-vector placement, but it should not be copied directly because its flash-centric memory map is not our target architecture.

## Items Worth Reusing Later

Useful upstream assets for later work:

- firmware examples in [`firmware/`](/root/Project/u_core_module_cpu/rtl/firmware)
- simple SoC composition ideas in [`picosoc/`](/root/Project/u_core_module_cpu/rtl/picosoc)
- instruction tests in [`tests/`](/root/Project/u_core_module_cpu/rtl/tests)
- optional PCPI multiplier/divider implementations in [`picorv32.v`](/root/Project/u_core_module_cpu/rtl/picorv32.v)

## Recommended Next Step

The next concrete design task should be to define the `cpu_subsys` integration contract:

- CPU instance parameters
- AXI-Lite address map decode
- boot ROM interface shape
- local RAM wrapper interface shape
- DMA CSR slave interface
- NPU CSR slave interface
- reset vector and stack address constants

Once that is frozen, we can start the `cpu_subsys` top-level RTL skeleton without guessing.
