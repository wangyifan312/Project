# u_core_top_soc FS

## 1. 模块定位

`u_core_top_soc` 是 `u_core` 首版 SoC 顶层集成模块，负责完成以下工作：

- 集成 `cpu_subsys`、`dma_top`、`spm_subsys`、`npu_top`
- 提供 DMA 对外的 `AXI4 Full` 数据面接口
- 提供 CPU 控制面的 `AXI4-Lite` 地址译码与路由
- 集成 `boot_rom`、`local_ram` 与 `sys_csr`

当前版本中，CPU 通过单一 `AXI4-Lite master` 接口访问以下地址窗口：

| 地址范围 | 从模块 | 说明 |
| --- | --- | --- |
| `0x0000_0000 ~ 0x0000_3FFF` | `boot_rom` | 复位入口与启动代码空间，首版为只读零初始化存储 |
| `0x0001_0000 ~ 0x0001_7FFF` | `local_ram` | 运行时数据、本地栈与全局变量空间 |
| `0x1000_0000 ~ 0x1000_0FFF` | `npu_csr` | NPU 配置与状态寄存器窗口 |
| `0x1000_1000 ~ 0x1000_1FFF` | `dma_csr` | DMA descriptor staging 与状态寄存器窗口 |
| `0x1000_2000 ~ 0x1000_2FFF` | `sys_csr` | 系统摘要状态、错误与性能计数窗口 |

## 2. 控制面结构

控制面由 `u_core_axil_xbar` 实现一主多从路由：

- 主设备：
  - `cpu_subsys`
- 从设备：
  - `u_boot_rom`
  - `u_local_ram`
  - `u_npu_top`
  - `u_dma_top`
  - `u_core_sys_csr`

该控制互连面向 PicoRV32 的首版使用场景，按单主机、低并发、寄存器访问优先的目标实现。当前版本支持：

- 依据地址窗口进行 `AW/W/AR` 路由
- 读写响应按目标从设备返回
- 对未映射地址返回默认错误响应，避免 CPU 永久挂死

## 3. 本地存储从设备

### 3.1 boot_rom

- 实现文件：`u_core_axil_mem.sv`
- 运行模式：`READ_ONLY=1`
- 位宽：`32-bit`
- 地址窗口：`16KB`
- 首版内容：零初始化

### 3.2 local_ram

- 实现文件：`u_core_axil_mem.sv`
- 运行模式：`READ_ONLY=0`
- 位宽：`32-bit`
- 地址窗口：`32KB`

## 4. SYS_CSR

`u_core_sys_csr` 用于聚合顶层摘要状态与错误码，向 CPU 暴露最小系统观测窗口。当前提供：

- CPU trap 状态
- DMA busy/done/error
- NPU armed/busy/done/error
- SPM DMA/NPU 侧错误标志
- DMA done/beat 性能计数
- NPU stall 计数
- DMA/NPU/SPM 错误码摘要

详细寄存器定义见 `u_core_top_soc_registers.md`。
