# u_core 接口说明评审稿

## 1. 文档定位

本文档用于对 `u_core` 当前版本的模块间接口定义进行评审。目标不是展开 RTL 级状态机设计，而是先把后续 RTL 拆解必须依赖的接口边界、字段语义、数据宽度和交互方向整理清楚。

当前评审范围包括：

- `cpu_subsys` 控制面接口
- `dma_top` 的 CSR 与状态接口
- `dma_top <-> 外部共享存储` 的 AXI4 Full 接口
- `dma_top <-> spm_subsys` 本地数据接口
- `npu_top <-> spm_subsys` 本地数据接口
- `npu_top` 的 CSR 与状态接口
- 系统级完成判定接口

参考文档：

- [`异构处理器总体规格与总体架构设计说明书_V1_5_整合增强版.docx`](/root/Project/docs/异构处理器总体规格与总体架构设计说明书_V1_5_整合增强版.docx)
- [`u_core_architecture_freeze.md`](/root/Project/docs/u_core_architecture_freeze.md)

## 2. 已冻结架构前提

本文档建立在以下已冻结前提之上：

- CPU 固定为 `picorv32_axi`，不修改 CPU 内核 RTL
- CPU 负责控制面，DMA 负责数据面
- 控制面统一采用 `AXI4-Lite`
- 数据面由 DMA 作为唯一 `AXI4 Full` master
- `spm_subsys` 是 DMA 与 NPU 的唯一数据交汇层
- DMA 首版仅支持 `LOAD_ACT`、`LOAD_WGT`、`STORE_OUT`
- NPU 首版采用 `CSR + START`
- NPU 首版不实现 descriptor 队列
- `act_spm` / `wgt_spm` 首版双缓冲
- `out_spm` 首版单缓冲
- `buf_sel[1:0]` 只表示 buffer 编号，不表示存储类型

## 3. 顶层控制面接口

### 3.1 角色定义

CPU 通过 `AXI4-Lite` 统一访问以下控制面目标：

- `boot_rom`
- `local_ram_wrapper`
- `dma_csr_if`
- `npu_csr`
- `sys_perf_error`

### 3.2 控制面地址图

| 地址范围 | 模块 | 用途 |
| --- | --- | --- |
| `0x0000_0000 ~ 0x0000_3FFF` | `boot_rom` | 启动代码与复位入口 |
| `0x0001_0000 ~ 0x0001_7FFF` | `local_ram_wrapper` | 栈、全局变量、运行时数据 |
| `0x1000_0000 ~ 0x1000_0FFF` | `npu_csr` | NPU 配置与状态 |
| `0x1000_1000 ~ 0x1000_1FFF` | `dma_csr_if` | DMA descriptor staging 与状态 |
| `0x1000_2000 ~ 0x1000_2FFF` | `sys_perf_error` | 系统摘要状态、错误与性能计数 |

### 3.3 CPU 复位相关常量

建议首版固定为：

- `PROGADDR_RESET = 32'h0000_0000`
- `PROGADDR_IRQ   = 32'h0000_0010`
- `STACKADDR      = 32'h0001_8000`

## 4. DMA CSR 与描述符接口

### 4.1 接口目标

DMA CSR 接口用于：

- 由 CPU 填写一条待执行 descriptor
- 将 descriptor 从 staging 区提交到 pending FIFO
- 由 CPU 查询 DMA 是否 busy、done、error
- 查询 FIFO 状态和基础性能计数

### 4.2 Descriptor 架构语义

一条 descriptor 只描述一种 DMA 操作：

- `LOAD_ACT`
- `LOAD_WGT`
- `STORE_OUT`

descriptor 先写入 staging 寄存器，再通过 `submit` 动作推进到待执行队列。

### 4.3 Descriptor 字段建议

| 字段名 | 位宽 | 含义 |
| --- | --- | --- |
| `op_type` | 2 | `00=LOAD_ACT`, `01=LOAD_WGT`, `10=STORE_OUT`, `11=保留` |
| `src_addr` | 32 | 外部共享存储源地址，单位为 byte |
| `dst_addr` | 32 | 外部共享存储目的地址，单位为 byte |
| `row_len` | 16 | 每行搬运字节数 |
| `row_cnt` | 16 | 行数 |
| `src_stride` | 16 | 源地址行跨度，单位为 byte |
| `dst_stride` | 16 | 目的地址行跨度，单位为 byte |
| `buf_sel` | 2 | 本地 buffer 编号 |
| `spm_row_base` | 16 | 本地 SPM 起始行号 |
| `tile_id` | 16 | 软件可见标签 |
| `flags` | 16 | 预留 |

### 4.4 Descriptor 使用规则

- 对 `LOAD_ACT` 与 `LOAD_WGT`，使用 `src_addr`，`dst_addr` 不参与首版语义
- 对 `STORE_OUT`，使用 `dst_addr`，`src_addr` 不参与首版语义
- `buf_sel` 不表示 `act/wgt/out`
- 目标存储类别由 `op_type` 唯一确定

### 4.5 `buf_sel` 规则

`buf_sel[1:0]` 冻结为：

- `LOAD_ACT`: `0/1` 合法
- `LOAD_WGT`: `0/1` 合法
- `STORE_OUT`: 仅 `0` 合法
- 其他取值保留，并应在配置或提交阶段报非法

### 4.6 DMA 状态接口建议

| 信号名 | 位宽 | 含义 |
| --- | --- | --- |
| `dma_busy` | 1 | DMA 正在执行至少一条 descriptor |
| `dma_done` | 1 | 最近完成的 descriptor 已结束 |
| `dma_error` | 1 | DMA 存在错误状态 |
| `dma_fifo_empty` | 1 | 待执行 FIFO 为空 |
| `dma_fifo_full` | 1 | 待执行 FIFO 已满 |
| `dma_fifo_level` | 3 | FIFO 占用深度 |
| `dma_done_count` | 32 | 已完成 descriptor 数 |
| `dma_rd_beat_count` | 32 | AXI 读 beat 计数 |
| `dma_wr_beat_count` | 32 | AXI 写 beat 计数 |
| `dma_error_code` | 8 | 错误类型编码 |

## 5. DMA <-> 外部共享存储接口

### 5.1 接口定位

这条接口是首版系统唯一的高带宽外部数据面接口，由 `dma_top` 独占使用。首版三类 DMA 操作与这条接口的关系如下：

- `LOAD_ACT`: AXI 读
- `LOAD_WGT`: AXI 读
- `STORE_OUT`: AXI 写

### 5.2 接口类型与位宽

首版冻结为：

- 接口类型：`AXI4 Full`
- 地址宽度：`32-bit`
- 数据宽度：`512-bit`
- 字节使能宽度：`64-bit`

### 5.3 AXI4 Full 通道集合

写地址通道：

- `m_axi_awvalid`
- `m_axi_awready`
- `m_axi_awaddr`
- `m_axi_awlen`
- `m_axi_awsize`
- `m_axi_awburst`
- `m_axi_awid`

写数据通道：

- `m_axi_wvalid`
- `m_axi_wready`
- `m_axi_wdata`
- `m_axi_wstrb`
- `m_axi_wlast`

写响应通道：

- `m_axi_bvalid`
- `m_axi_bready`
- `m_axi_bresp`
- `m_axi_bid`

读地址通道：

- `m_axi_arvalid`
- `m_axi_arready`
- `m_axi_araddr`
- `m_axi_arlen`
- `m_axi_arsize`
- `m_axi_arburst`
- `m_axi_arid`

读数据通道：

- `m_axi_rvalid`
- `m_axi_rready`
- `m_axi_rdata`
- `m_axi_rresp`
- `m_axi_rlast`
- `m_axi_rid`

### 5.4 架构使用规则

首版架构约束如下：

- DMA 是唯一 AXI4 Full master
- 首版默认只有一个 DMA 读引擎
- `LOAD_ACT` 与 `LOAD_WGT` 不要求并行搬运
- burst 类型采用 `INCR`
- burst 由 descriptor 中的地址、`row_len`、`row_cnt`、`stride` 派生

### 5.5 地址与对齐口径

建议首版统一以下口径：

- `src_addr/dst_addr` 以 byte 为单位
- `row_len` 以 byte 为单位
- `src_stride/dst_stride` 以 byte 为单位
- 外部地址尽量按 `512-bit` beat 对齐
- 对于非完整 beat 的首尾部分，允许支持
- 对于首版不支持的对齐模式，应通过 `dma_error` 暴露

### 5.6 外部存储错误可见性

以下情况应反映到 DMA 错误状态：

- `RRESP` 错误
- `BRESP` 错误
- 非法地址或不支持的对齐模式
- 无法构造合法 burst 的 descriptor

## 6. DMA <-> SPM 本地接口

### 6.1 接口定位

DMA 与 `spm_subsys` 之间不使用 AXI，而使用面向本地行搬运的接口。

首版架构假设：

- `LOAD_ACT` 将数据写入 `act_spm`
- `LOAD_WGT` 将数据写入 `wgt_spm`
- `STORE_OUT` 从 `out_spm` 取数
- 一次本地搬运粒度为一行
- 一行数据宽度与外部 `512-bit` 数据面一致

### 6.2 DMA 写入 SPM 的接口

| 信号名 | 方向 | 位宽 | 含义 |
| --- | --- | --- | --- |
| `dma_spm_wr_valid` | DMA->SPM | 1 | 本地写请求有效 |
| `dma_spm_wr_ready` | SPM->DMA | 1 | SPM 接受本地写请求 |
| `dma_spm_wr_type` | DMA->SPM | 2 | `00=act`, `01=wgt` |
| `dma_spm_wr_buf_sel` | DMA->SPM | 2 | 目标 buffer 编号 |
| `dma_spm_wr_row_idx` | DMA->SPM | 3 | 目标 buffer 内的 `64B` 本地行号 |
| `dma_spm_wr_data` | DMA->SPM | 512 | 本地行数据 |
| `dma_spm_wr_strb` | DMA->SPM | 64 | 本地行字节使能 |
| `dma_spm_wr_last` | DMA->SPM | 1 | 当前 descriptor 的最后一行 |

### 6.3 DMA 从 SPM 读取输出的接口

| 信号名 | 方向 | 位宽 | 含义 |
| --- | --- | --- | --- |
| `dma_spm_rd_req_valid` | DMA->SPM | 1 | 本地读请求有效 |
| `dma_spm_rd_req_ready` | SPM->DMA | 1 | SPM 接受本地读请求 |
| `dma_spm_rd_buf_sel` | DMA->SPM | 2 | 输出 buffer 编号 |
| `dma_spm_rd_row_idx` | DMA->SPM | 3 | 输出 buffer 内的 `64B` 本地行号 |
| `dma_spm_rd_data_valid` | SPM->DMA | 1 | 本地读返回有效 |
| `dma_spm_rd_data_ready` | DMA->SPM | 1 | DMA 接受返回数据 |
| `dma_spm_rd_data` | SPM->DMA | 512 | 返回的一行数据 |
| `dma_spm_rd_last` | SPM->DMA | 1 | 当前 descriptor 的最后一行 |

### 6.4 SPM 对 DMA 暴露的资源可用性

| 信号名 | 方向 | 位宽 | 含义 |
| --- | --- | --- | --- |
| `act_buf_writable[1:0]` | SPM->DMA | 2 | act buffer 是否可写 |
| `wgt_buf_writable[1:0]` | SPM->DMA | 2 | wgt buffer 是否可写 |
| `out_buf_readable[1:0]` | SPM->DMA | 2 | out buffer 是否可读 |
| `spm_dma_error` | SPM->DMA | 1 | 本地访问错误 |
| `spm_dma_error_code` | SPM->DMA | 8 | 本地访问错误编码 |

这里的“可写/可读”是架构级资源可用性信号，不在本文中展开内部 ownership 状态机。

## 7. NPU <-> SPM 本地接口

### 7.1 接口定位

`spm_subsys` 向 NPU 提供本地输入向量，NPU 将最终输出向量写回 `out_spm`。

首版假设：

- 每拍可提供一组 activation 向量与一组 weight 向量
- 向量宽度固定对应 `16 x INT8`
- 输出按逻辑“行”写回 `out_spm`

### 7.2 NPU 输入向量接口

| 信号名 | 方向 | 位宽 | 含义 |
| --- | --- | --- | --- |
| `spm_npu_vec_valid` | SPM->NPU | 1 | 输入向量对有效 |
| `spm_npu_vec_ready` | NPU->SPM | 1 | NPU 接受输入向量对 |
| `spm_npu_act_buf_sel` | NPU->SPM | 2 | activation buffer 选择 |
| `spm_npu_wgt_buf_sel` | NPU->SPM | 2 | weight buffer 选择 |
| `spm_npu_k_idx` | NPU->SPM | 6 | K 维步进索引，首版支持 `0..31` |
| `spm_npu_act_vec` | SPM->NPU | 128 | `16 x INT8` activation 向量 |
| `spm_npu_wgt_vec` | SPM->NPU | 128 | `16 x INT8` weight 向量 |

### 7.3 NPU 输出写回接口

| 信号名 | 方向 | 位宽 | 含义 |
| --- | --- | --- | --- |
| `npu_spm_out_valid` | NPU->SPM | 1 | 输出写请求有效 |
| `npu_spm_out_ready` | SPM->NPU | 1 | SPM 接受输出写请求 |
| `npu_spm_out_buf_sel` | NPU->SPM | 2 | 输出 buffer 选择 |
| `npu_spm_out_row_idx` | NPU->SPM | 4 | 输出 tile 内部行号 |
| `npu_spm_out_col_mask` | NPU->SPM | 16 | 按 lane 粒度定义的输出有效掩码 |
| `npu_spm_out_data` | NPU->SPM | 256 | `16 x OUT_ELEM_W` 输出向量 |
| `npu_spm_out_last` | NPU->SPM | 1 | 当前输出 tile 的最后一行 |

建议首版物理输出位宽固定为 `16 x 16-bit`。如果量化模式是 `INT8`，每个 lane 使用对应 `16-bit` 槽位的低 `8-bit`。
`npu_spm_out_col_mask[15:0]` 与这 `16` 个输出 lane 一一对应，而不是 byte mask。

### 7.4 SPM 对 NPU 暴露的资源信号

| 信号名 | 方向 | 位宽 | 含义 |
| --- | --- | --- | --- |
| `act_buf_ready[1:0]` | SPM->NPU | 2 | 对应 activation buffer 已就绪 |
| `wgt_buf_ready[1:0]` | SPM->NPU | 2 | 对应 weight buffer 已就绪 |
| `out_buf_free[1:0]` | SPM->NPU | 2 | 对应输出 buffer 可接收新结果 |
| `spm_npu_error` | SPM->NPU | 1 | 本地访问错误 |
| `spm_npu_error_code` | SPM->NPU | 8 | 本地访问错误编码 |

## 8. NPU CSR 与状态接口

### 8.1 接口目标

NPU CSR 接口用于：

- 选择 act/wgt/out buffer
- 配置 `Ktile`、模式和量化参数
- 由 CPU 发起 `START`
- 查询 NPU 当前执行状态

### 8.2 NPU CSR 字段建议

| 字段名 | 位宽 | 含义 |
| --- | --- | --- |
| `npu_mode` | 4 | 首版计算模式，面向 GEMM/FC |
| `ktile_cfg` | 8 | 首版推荐合法值为 `32` |
| `act_buf_sel` | 2 | activation buffer 编号 |
| `wgt_buf_sel` | 2 | weight buffer 编号 |
| `out_buf_sel` | 2 | 输出 buffer 编号，首版仅 `0` 合法 |
| `quant_shift` | 8 | 量化右移参数 |
| `quant_zero_point` | 16 | 输出零点 |
| `relu_en` | 1 | ReLU 使能 |
| `start_pulse` | 1 | 启动脉冲 |

### 8.3 NPU 状态接口建议

| 信号名 | 位宽 | 含义 |
| --- | --- | --- |
| `npu_armed` | 1 | `START` 已接受，等待资源 |
| `npu_busy` | 1 | NPU 正在计算 |
| `npu_done` | 1 | 当前 tile 计算和本地输出写入已完成 |
| `npu_error` | 1 | NPU 处于错误状态 |
| `npu_stall_cycles` | 32 | 等待本地资源的周期数 |
| `npu_busy_cycles` | 32 | 计算周期数 |
| `npu_error_code` | 8 | 错误类型编码 |

## 9. 系统级完成判定

首版系统中，一次 tile 任务完整完成的判定应满足：

- NPU 已完成当前 tile 的计算
- 对应输出 tile 已写入 `out_spm`
- DMA 已完成 `STORE_OUT`
- 没有待处理错误

建议在 `SYS/PERF/ERROR` 中暴露以下摘要信号：

| 信号名 | 位宽 | 含义 |
| --- | --- | --- |
| `sys_job_done` | 1 | 一次完整 tile 流程已完成 |
| `sys_job_error` | 1 | DMA 或 NPU 存在错误 |
| `sys_dma_busy` | 1 | DMA 忙摘要 |
| `sys_npu_busy` | 1 | NPU 忙摘要 |
| `sys_out_valid` | 1 | 输出 tile 已存在于本地输出缓冲 |
| `sys_out_committed` | 1 | 输出 tile 已写回外部共享存储 |

## 10. 本轮建议你重点 review 的内容

这一版建议你重点确认以下几项：

- 控制面地址图是否保持不变
- DMA descriptor 字段是否满足首版调度需求
- DMA 对外 AXI4 Full 接口的位宽与 burst 假设是否接受
- `row_len/stride` 统一按 byte 是否符合你的预期
- `spm_row_base` 作为本地起始行号是否合适
- DMA <-> SPM 采用“行级接口”是否符合你的系统抽象
- NPU 输入按 `16 x INT8 + K_idx` 组织是否符合阵列前端预期
- NPU 输出固定物理宽度 `16 x 16-bit` 是否接受
- 系统完成判定是否还需要增加其他摘要状态

## 11. 后续处理方式

如果你对本文内容 review 通过，我建议下一步按以下顺序推进：

1. 将确认后的内容同步回 Word 主文档
2. 细化 `CSR register map`
3. 按接口文档建立模块 RTL 骨架
