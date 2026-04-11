# dma_top Register Table

DMA CSR base address:

- `0x1000_1000`

## Register Summary

| Register Name | Register Type | Address | Reset Value | Width |
| --- | --- | --- | --- | --- |
| `DMA_DESC_CFG0` | `RW` | `0x1000_1000` | `0x0000_0000` | `32` |
| `DMA_SRC_ADDR` | `RW` | `0x1000_1004` | `0x0000_0000` | `32` |
| `DMA_DST_ADDR` | `RW` | `0x1000_1008` | `0x0000_0000` | `32` |
| `DMA_DESC_CFG1` | `RW` | `0x1000_100C` | `0x0000_0000` | `32` |
| `DMA_DESC_RSVD0` | `RO` | `0x1000_1010` | `0x0000_0000` | `32` |
| `DMA_DESC_RSVD1` | `RO` | `0x1000_1014` | `0x0000_0000` | `32` |
| `DMA_CMD` | `W1P` | `0x1000_1018` | `0x0000_0000` | `32` |
| `DMA_STATUS` | `RO` | `0x1000_101C` | `0x0000_0000` | `32` |
| `DMA_FIFO_STATUS` | `RO` | `0x1000_1020` | `0x0000_0001` | `32` |
| `DMA_DONE_COUNT` | `RO` | `0x1000_1024` | `0x0000_0000` | `32` |
| `DMA_RD_BEAT_COUNT` | `RO` | `0x1000_1028` | `0x0000_0000` | `32` |
| `DMA_WR_BEAT_COUNT` | `RO` | `0x1000_102C` | `0x0000_0000` | `32` |
| `DMA_ERROR_CODE` | `RO` | `0x1000_1030` | `0x0000_0000` | `32` |

## Word Encoding

### `DMA_DESC_CFG0`

- `[1:0]`: `op_type`
- `[3:2]`: `buf_sel`
- `[6:4]`: `spm_row_base`
- `[13:7]`: `row_len`
- `[17:14]`: `row_cnt`
- `[31:18]`: reserved

### `DMA_DESC_CFG1`

- `[9:0]`: `ext_stride_units`
- unit: `64B`
- active meaning:
  - `LOAD_ACT / LOAD_WGT`: expands to `src_stride = ext_stride_units << 6`
  - `STORE_OUT`: expands to `dst_stride = ext_stride_units << 6`
- `[31:10]`: reserved

### `DMA_CMD`

- `[0]`: `submit`

### `DMA_STATUS`

- `[0]`: `dma_busy`
- `[1]`: `dma_done`
- `[2]`: `dma_error`

### `DMA_FIFO_STATUS`

- `[0]`: `dma_fifo_empty`
- `[1]`: `dma_fifo_full`
- `[4:2]`: `dma_fifo_level`

### `DMA_ERROR_CODE`

- `[7:0]`: `dma_error_code`

## First-Version Compact Descriptor Rule

- first-version staging descriptor uses `4` config writes plus `1` submit write
- all sub-`32b` fields are packed into `DMA_DESC_CFG0` / `DMA_DESC_CFG1`
- software no longer needs separate writes for `row_cfg` / `stride_cfg` / `local_cfg`

## First-Version Descriptor Constraint

- `row_len` must satisfy `1 <= row_len <= 64`
- `row_cnt` must be non-zero
- `row_cnt` is encoded in `4b`, current valid range remains within local row space
- `LOAD_ACT/LOAD_WGT`: `buf_sel` must be `0` or `1`
- `STORE_OUT`: `buf_sel` must be `0`
- `src_addr` / `dst_addr` must be `64B` aligned for the active direction
- `ext_stride_units` is interpreted in `64B` units
- `spm_row_base + row_cnt` must not exceed `8`

## Error Code Definition

| Value | Meaning |
| --- | --- |
| `0x01` | illegal `op_type` |
| `0x02` | illegal `buf_sel` |
| `0x03` | zero `row_len` |
| `0x04` | zero `row_cnt` |
| `0x05` | alignment error |
| `0x06` | submit while descriptor FIFO full |
| `0x07` | unsupported descriptor shape in first RTL |
| `0x08` | local row range overflow |
| `0x09` | AXI read response error |
| `0x0A` | AXI write response error |
