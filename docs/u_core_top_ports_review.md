# u_core Top-Level Ports Review

## 1. 目标

本文档用于统一 review `u_core` 首版真正需要关注的顶层接口。文档分两层来看：

- CPU 核 `picorv32_axi` 的原生顶层接口
- `cpu_subsys`、`dma_top`、`npu_top`、`spm_subsys` 之间的系统级顶层端口组

本文档不展开内部状态机，不讨论寄存器位定义，只从控制路径和数据路径出发整理顶层需要存在的端口。

当前关注路径：

- CPU 写 DMA 控制，配置 descriptor
- CPU 写 NPU 控制，配置并启动 NPU
- DMA 读外部存储，写 SPM
- DMA 读 SPM，写外部存储
- NPU 读 SPM 数据
- NPU 写 SPM 数据

## 2. CPU 核原生接口 Review

这一节只看开源 CPU 核 `picorv32_axi` 本身，不混入外层 `cpu_subsys` 的封装。

### 2.1 `picorv32_axi` 原生顶层端口分类

`picorv32_axi` 原生顶层接口可以分成 5 类：

- 时钟与复位
- 运行状态
- AXI4-Lite master 存储器接口
- 可选 PCPI 接口
- 可选 IRQ 接口

### 2.2 时钟与复位

| 端口名 | 方向 | 位宽 | 说明 |
| --- | --- | --- | --- |
| `clk` | input | 1 | CPU 时钟 |
| `resetn` | input | 1 | 低有效复位 |

### 2.3 运行状态

| 端口名 | 方向 | 位宽 | 说明 |
| --- | --- | --- | --- |
| `trap` | output | 1 | CPU 进入 trap 状态 |

### 2.4 AXI4-Lite Master 接口

这是 `picorv32_axi` 对外最核心的接口组。

写地址通道：

- `mem_axi_awvalid`
- `mem_axi_awready`
- `mem_axi_awaddr[31:0]`
- `mem_axi_awprot[2:0]`

写数据通道：

- `mem_axi_wvalid`
- `mem_axi_wready`
- `mem_axi_wdata[31:0]`
- `mem_axi_wstrb[3:0]`

写响应通道：

- `mem_axi_bvalid`
- `mem_axi_bready`

读地址通道：

- `mem_axi_arvalid`
- `mem_axi_arready`
- `mem_axi_araddr[31:0]`
- `mem_axi_arprot[2:0]`

读数据通道：

- `mem_axi_rvalid`
- `mem_axi_rready`
- `mem_axi_rdata[31:0]`

### 2.5 可选 PCPI 接口

- `pcpi_valid`
- `pcpi_insn[31:0]`
- `pcpi_rs1[31:0]`
- `pcpi_rs2[31:0]`
- `pcpi_wr`
- `pcpi_rd[31:0]`
- `pcpi_wait`
- `pcpi_ready`

首版建议：

- 不使用 PCPI 将 NPU 接入 CPU
- NPU 仍作为独立模块通过 CSR 控制

### 2.6 可选 IRQ 接口

- `irq[31:0]`
- `eoi[31:0]`

首版建议：

- 保留 IRQ 能力
- 但系统主控制路径先采用 polling

### 2.7 首版我们真正关心的 CPU 核端口

从 `u_core` 首版集成角度，真正要优先 review 的 CPU 核端口只有：

- `clk`
- `resetn`
- `trap`
- 全部 `mem_axi_*`

也就是说，当前可以先把 `picorv32_axi` 理解成：

- 一个 `32-bit AXI4-Lite master CPU`
- 外加一个 `trap` 观察输出

## 3. 总体原则

- CPU 只走控制面
- DMA 负责外部存储与 SPM 之间的数据搬运
- NPU 只和 SPM 交换计算相关数据
- SPM 是 DMA 与 NPU 的唯一数据交汇层
- 顶层接口按“端口组”定义，不在本轮展开寄存器位定义和总线时序细节

## 4. 模块顶层端口总览

### 4.1 `cpu_subsys`

`cpu_subsys` 顶层只需要对外暴露一组控制面主接口：

- `cpu_axil_awvalid`
- `cpu_axil_awready`
- `cpu_axil_awaddr[31:0]`
- `cpu_axil_awprot[2:0]`
- `cpu_axil_wvalid`
- `cpu_axil_wready`
- `cpu_axil_wdata[31:0]`
- `cpu_axil_wstrb[3:0]`
- `cpu_axil_bvalid`
- `cpu_axil_bready`
- `cpu_axil_bresp[1:0]`
- `cpu_axil_arvalid`
- `cpu_axil_arready`
- `cpu_axil_araddr[31:0]`
- `cpu_axil_arprot[2:0]`
- `cpu_axil_rvalid`
- `cpu_axil_rready`
- `cpu_axil_rdata[31:0]`
- `cpu_axil_rresp[1:0]`

说明：

- CPU 配 DMA descriptor，本质上就是对 `dma_csr_if` 做 AXI-Lite 写
- CPU 配 NPU，本质上就是对 `npu_csr` 做 AXI-Lite 写
- CPU 轮询 DMA/NPU 状态，本质上就是对相应 CSR 做 AXI-Lite 读

### 4.2 `dma_top`

`dma_top` 顶层需要三组接口：

- CPU 可见的 DMA CSR 接口
- 面向外部共享存储的数据接口
- 面向 SPM 的本地数据接口

#### `dma_top` 的控制面端口组

- `dma_axil_awvalid`
- `dma_axil_awready`
- `dma_axil_awaddr[31:0]`
- `dma_axil_awprot[2:0]`
- `dma_axil_wvalid`
- `dma_axil_wready`
- `dma_axil_wdata[31:0]`
- `dma_axil_wstrb[3:0]`
- `dma_axil_bvalid`
- `dma_axil_bready`
- `dma_axil_bresp[1:0]`
- `dma_axil_arvalid`
- `dma_axil_arready`
- `dma_axil_araddr[31:0]`
- `dma_axil_arprot[2:0]`
- `dma_axil_rvalid`
- `dma_axil_rready`
- `dma_axil_rdata[31:0]`
- `dma_axil_rresp[1:0]`

#### `dma_top` 的外部存储端口组

- `dma_m_axi_awvalid`
- `dma_m_axi_awready`
- `dma_m_axi_awaddr[31:0]`
- `dma_m_axi_awlen[7:0]`
- `dma_m_axi_awsize[2:0]`
- `dma_m_axi_awburst[1:0]`
- `dma_m_axi_wvalid`
- `dma_m_axi_wready`
- `dma_m_axi_wdata[511:0]`
- `dma_m_axi_wstrb[63:0]`
- `dma_m_axi_wlast`
- `dma_m_axi_bvalid`
- `dma_m_axi_bready`
- `dma_m_axi_bresp[1:0]`
- `dma_m_axi_arvalid`
- `dma_m_axi_arready`
- `dma_m_axi_araddr[31:0]`
- `dma_m_axi_arlen[7:0]`
- `dma_m_axi_arsize[2:0]`
- `dma_m_axi_arburst[1:0]`
- `dma_m_axi_rvalid`
- `dma_m_axi_rready`
- `dma_m_axi_rdata[511:0]`
- `dma_m_axi_rresp[1:0]`
- `dma_m_axi_rlast`

#### `dma_top` 的 SPM 写端口组

这组端口对应路径：

- DMA 读外部存储
- DMA 写 `act_spm` / `wgt_spm`

端口建议：

- `dma_spm_wr_valid`
- `dma_spm_wr_ready`
- `dma_spm_wr_type[1:0]`
- `dma_spm_wr_buf_sel[1:0]`
- `dma_spm_wr_row_idx[2:0]`
- `dma_spm_wr_data[511:0]`
- `dma_spm_wr_strb[63:0]`
- `dma_spm_wr_last`

其中：

- `dma_spm_wr_type=00` 表示写 `act_spm`
- `dma_spm_wr_type=01` 表示写 `wgt_spm`
- `dma_spm_wr_buf_sel` 表示目标 local SRAM tile buffer 编号
- `dma_spm_wr_row_idx[2:0]` 表示所选 buffer 内的 `64B` 本地行号

#### `dma_top` 的 SPM 读端口组

这组端口对应路径：

- DMA 读 `out_spm`
- DMA 写外部存储

端口建议：

- `dma_spm_rd_req_valid`
- `dma_spm_rd_req_ready`
- `dma_spm_rd_buf_sel[1:0]`
- `dma_spm_rd_row_idx[2:0]`
- `dma_spm_rd_data_valid`
- `dma_spm_rd_data_ready`
- `dma_spm_rd_data[511:0]`
- `dma_spm_rd_last`

其中：

- `dma_spm_rd_buf_sel` 首版只允许 `0`
- `dma_spm_rd_row_idx[2:0]` 表示 `out_spm` buffer 内的 `64B` 本地行号

### 4.3 `npu_top`

`npu_top` 顶层需要两组接口：

- CPU 可见的 NPU CSR 接口
- 面向 SPM 的本地数据接口

#### `npu_top` 的控制面端口组

- `npu_axil_awvalid`
- `npu_axil_awready`
- `npu_axil_awaddr[31:0]`
- `npu_axil_awprot[2:0]`
- `npu_axil_wvalid`
- `npu_axil_wready`
- `npu_axil_wdata[31:0]`
- `npu_axil_wstrb[3:0]`
- `npu_axil_bvalid`
- `npu_axil_bready`
- `npu_axil_bresp[1:0]`
- `npu_axil_arvalid`
- `npu_axil_arready`
- `npu_axil_araddr[31:0]`
- `npu_axil_arprot[2:0]`
- `npu_axil_rvalid`
- `npu_axil_rready`
- `npu_axil_rdata[31:0]`
- `npu_axil_rresp[1:0]`

#### `npu_top` 的 SPM 读端口组

这组端口对应路径：

- NPU 读 `act_spm`
- NPU 读 `wgt_spm`

端口建议：

- `spm_npu_vec_valid`
- `spm_npu_vec_ready`
- `spm_npu_act_buf_sel[1:0]`
- `spm_npu_wgt_buf_sel[1:0]`
- `spm_npu_k_idx[5:0]`
- `spm_npu_act_vec[127:0]`
- `spm_npu_wgt_vec[127:0]`

#### `npu_top` 的 SPM 写端口组

这组端口对应路径：

- NPU 写 `out_spm`

端口建议：

- `npu_spm_out_valid`
- `npu_spm_out_ready`
- `npu_spm_out_buf_sel[1:0]`
- `npu_spm_out_row_idx[3:0]`
- `npu_spm_out_col_mask[15:0]`
- `npu_spm_out_data[255:0]`
- `npu_spm_out_last`

说明：

- `npu_spm_out_data[255:0]` 表示 `16` 个输出 lane
- 每个 lane 的物理槽位宽度为 `16 bit`
- `npu_spm_out_col_mask[15:0]` 按 lane 粒度定义
- `col_mask[i]` 对应第 `i` 个 `16-bit` 输出 lane 是否有效

### 4.4 `spm_subsys`

`spm_subsys` 顶层本质上是两个接口面的汇合：

- 接 DMA 的本地行级接口
- 接 NPU 的本地向量/输出接口

#### `spm_subsys` 面向 DMA 的端口组

写入口：

- `dma_spm_wr_valid`
- `dma_spm_wr_ready`
- `dma_spm_wr_type[1:0]`
- `dma_spm_wr_buf_sel[1:0]`
- `dma_spm_wr_row_idx[2:0]`
- `dma_spm_wr_data[511:0]`
- `dma_spm_wr_strb[63:0]`
- `dma_spm_wr_last`

读出口：

- `dma_spm_rd_req_valid`
- `dma_spm_rd_req_ready`
- `dma_spm_rd_buf_sel[1:0]`
- `dma_spm_rd_row_idx[2:0]`
- `dma_spm_rd_data_valid`
- `dma_spm_rd_data_ready`
- `dma_spm_rd_data[511:0]`
- `dma_spm_rd_last`

#### `spm_subsys` 面向 NPU 的端口组

输入向量输出：

- `spm_npu_vec_valid`
- `spm_npu_vec_ready`
- `spm_npu_act_buf_sel[1:0]`
- `spm_npu_wgt_buf_sel[1:0]`
- `spm_npu_k_idx[5:0]`
- `spm_npu_act_vec[127:0]`
- `spm_npu_wgt_vec[127:0]`

输出结果写入口：

- `npu_spm_out_valid`
- `npu_spm_out_ready`
- `npu_spm_out_buf_sel[1:0]`
- `npu_spm_out_row_idx[3:0]`
- `npu_spm_out_col_mask[15:0]`
- `npu_spm_out_data[255:0]`
- `npu_spm_out_last`

## 5. 按路径重新理解这些端口

### 5.1 CPU 写 DMA 控制

路径：

- `cpu_subsys -> dma_top`

对应端口组：

- `cpu_axil_*`
- `dma_axil_*`

本质动作：

- CPU 写 DMA descriptor staging
- CPU 写 submit
- CPU 读 DMA busy/done/error/FIFO 状态

### 5.2 CPU 写 NPU 控制

路径：

- `cpu_subsys -> npu_top`

对应端口组：

- `cpu_axil_*`
- `npu_axil_*`

本质动作：

- CPU 写 NPU buffer 选择
- CPU 写 `Ktile`、模式、量化参数
- CPU 写 `START`
- CPU 读 NPU `ARMED/BUSY/DONE/ERROR`

### 5.3 DMA 读外部存储，写 SPM

路径：

- `dma_top -> external memory`
- `dma_top -> spm_subsys`

对应端口组：

- `dma_m_axi_ar*`
- `dma_m_axi_r*`
- `dma_spm_wr_*`

本质动作：

- `LOAD_ACT`
- `LOAD_WGT`

### 5.4 DMA 读 SPM，写外部存储

路径：

- `spm_subsys -> dma_top`
- `dma_top -> external memory`

对应端口组：

- `dma_spm_rd_*`
- `dma_m_axi_aw*`
- `dma_m_axi_w*`
- `dma_m_axi_b*`

本质动作：

- `STORE_OUT`

### 5.5 NPU 读 SPM

路径：

- `spm_subsys -> npu_top`

对应端口组：

- `spm_npu_vec_*`

本质动作：

- NPU 按 `act_buf_sel/wgt_buf_sel/k_idx` 读取一对输入向量

### 5.6 NPU 写 SPM

路径：

- `npu_top -> spm_subsys`

对应端口组：

- `npu_spm_out_*`

本质动作：

- NPU 将当前 tile 的输出结果写入 `out_spm`

## 6. 当前建议先 review 的问题

这一轮建议你先确认下面这些：

- `picorv32_axi` 是否就按一个 `AXI4-Lite master CPU` 来看
- `trap` 是否作为首版 CPU 异常观察信号
- PCPI 是否明确不作为首版 NPU 接入方式
- IRQ 是否保留但不作为首版主控制路径
- 四个 top 模块的端口组划分是否合理
- DMA 是否确实只需要“一组外部存储接口 + 两组 SPM 接口”
- NPU 是否确实只需要“一组 CSR 接口 + 一组 SPM 读接口 + 一组 SPM 写接口”
- SPM 是否确实只需要把 DMA 和 NPU 两侧端口完整接住即可
- `512-bit` 的 DMA<->SPM 行数据宽度是否接受
- `128-bit` 的 NPU 输入向量宽度是否接受
- `256-bit` 的 NPU 输出向量宽度是否接受

## 7. 当前已通过结论

截至当前轮 review，以下内容已经通过：

- `picorv32_axi` 按 `32-bit AXI4-Lite master CPU` 理解
- `trap` 保留为首版 CPU 异常观察信号
- `PCPI` 不作为首版 NPU 接入方式
- `IRQ` 保留能力，但首版主控制路径采用 polling
- `cpu_subsys` 对外只暴露一组 `AXI-Lite` 主接口
- `dma_top` 对外包含：
  - 一组 `AXI-Lite` CSR 接口
  - 一组外部共享存储 `AXI4 Full` 接口
  - 一组 `dma_spm_wr_*`
  - 一组 `dma_spm_rd_*`
- `npu_top` 对外包含：
  - 一组 `AXI-Lite` CSR 接口
  - 一组 `spm_npu_vec_*`
  - 一组 `npu_spm_out_*`
- `spm_subsys` 只接 DMA 侧和 NPU 侧本地接口，不对 CPU 直接暴露专用数据接口
- `act_spm` 双缓冲，每个 buffer `512B`
- `wgt_spm` 双缓冲，每个 buffer `512B`
- `out_spm` 单缓冲，每个 buffer `512B`
- 首版 `spm_subsys` 总有效本地存储容量为 `2.5KB`
- `dma_spm_wr_type[1:0]` 冻结为：
  - `00=act`
  - `01=wgt`
  - `10/11=保留`
- `dma_spm_wr_buf_sel[1:0]` 表示目标 local SRAM tile buffer 编号
- `dma_spm_rd_buf_sel[1:0]` 首版保留 `2 bit`，但只允许 `0`
- `dma_spm_wr_row_idx[2:0]` 与 `dma_spm_rd_row_idx[2:0]` 表示 `64B` 本地行号
- `spm_npu_k_idx[5:0]` 保留 `6 bit`，为后续更大 `Ktile` 留扩展余量
- `spm_npu_vec_valid/ready` 一次握手表示 NPU 接收一组完整输入向量对
- `npu_spm_out_data[255:0]` 表示 `16` 个输出 lane，每 lane `16 bit`
- `npu_spm_out_col_mask[15:0]` 按 lane 粒度定义，与这 `16` 个输出 lane 一一对应
- `npu_spm_out_last` 表示当前 output tile 的最后一个本地输出写事务

## 8. 下一步

如果这份 top 端口草案方向正确，下一步再做两件事就比较自然：

1. 把每组端口的字段语义再收紧一点
2. 再落到 `rtl/` 里的模块顶层端口声明
