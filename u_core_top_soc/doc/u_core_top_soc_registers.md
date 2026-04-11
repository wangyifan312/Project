# u_core_top_soc Register List

## SYS_CSR Window

Base address: `0x1000_2000`

| 寄存器名 | 寄存器类型 | 地址 | reset值 | 位宽 | 说明 |
| --- | --- | --- | --- | --- | --- |
| `SYS_STATUS` | `RO` | `0x1000_2000` | `0x0000_0000` | `32` | `bit[0]=cpu_trap`, `bit[1]=dma_busy`, `bit[2]=dma_done`, `bit[3]=dma_error`, `bit[4]=npu_armed`, `bit[5]=npu_busy`, `bit[6]=npu_done`, `bit[7]=npu_error`, `bit[8]=spm_dma_error`, `bit[9]=spm_npu_error` |
| `SYS_DMA_DONE_COUNT` | `RO` | `0x1000_2004` | `0x0000_0000` | `32` | DMA 完成次数计数 |
| `SYS_DMA_RD_BEAT_COUNT` | `RO` | `0x1000_2008` | `0x0000_0000` | `32` | DMA AXI 读 beat 计数 |
| `SYS_DMA_WR_BEAT_COUNT` | `RO` | `0x1000_200C` | `0x0000_0000` | `32` | DMA AXI 写 beat 计数 |
| `SYS_NPU_STALL_CYCLES` | `RO` | `0x1000_2010` | `0x0000_0000` | `32` | NPU stall 周期计数 |
| `SYS_ERROR_CODE_SUMMARY` | `RO` | `0x1000_2014` | `0x0000_0000` | `32` | `{spm_npu_error_code[31:24], spm_dma_error_code[23:16], npu_error_code[15:8], dma_error_code[7:0]}` |
