# npu_top Register Table

NPU CSR base address:

- `0x1000_0000`

## Register Summary

| Register Name | Register Type | Address | Reset Value | Width |
| --- | --- | --- | --- | --- |
| `NPU_CFG0` | `RW` | `0x1000_0000` | `0x0000_0000` | `32` |
| `NPU_BUF_CFG` | `RW` | `0x1000_0004` | `0x0000_0000` | `32` |
| `NPU_KTILE_CFG` | `RW` | `0x1000_0008` | `0x0000_0020` | `32` |
| `NPU_QUANT_CFG` | `RW` | `0x1000_000C` | `0x0000_0000` | `32` |
| `NPU_CMD` | `W1P` | `0x1000_0010` | `0x0000_0000` | `32` |
| `NPU_STATUS` | `RO` | `0x1000_0014` | `0x0000_0000` | `32` |
| `NPU_STALL_CYCLES` | `RO` | `0x1000_0018` | `0x0000_0000` | `32` |
| `NPU_BUSY_CYCLES` | `RO` | `0x1000_001C` | `0x0000_0000` | `32` |
| `NPU_ERROR_CODE` | `RO` | `0x1000_0020` | `0x0000_0000` | `32` |

## Word Encoding

### `NPU_CFG0`

- `[3:0]`: `npu_mode`
- `[4]`: `relu_en`

### `NPU_BUF_CFG`

- `[1:0]`: `act_buf_sel`
- `[3:2]`: `wgt_buf_sel`
- `[5:4]`: `out_buf_sel`

### `NPU_KTILE_CFG`

- `[7:0]`: `ktile_cfg`

### `NPU_QUANT_CFG`

- `[7:0]`: `quant_shift`
- `[23:8]`: `quant_zero_point`

### `NPU_CMD`

- `[0]`: `start`

### `NPU_STATUS`

- `[0]`: `npu_armed`
- `[1]`: `npu_busy`
- `[2]`: `npu_done`
- `[3]`: `npu_error`

### `NPU_ERROR_CODE`

- `[7:0]`: `npu_error_code`

## First-Version Configuration Constraint

- `act_buf_sel` must be `0` or `1`
- `wgt_buf_sel` must be `0` or `1`
- `out_buf_sel` must be `0`
- `ktile_cfg` must satisfy `1 <= ktile_cfg <= 32`

## Error Code Definition

| Value | Meaning |
| --- | --- |
| `0x01` | `START` issued while NPU is already armed or busy |
| `0x02` | illegal `act_buf_sel` |
| `0x03` | illegal `wgt_buf_sel` |
| `0x04` | illegal `out_buf_sel` |
| `0x05` | illegal `ktile_cfg` |
| `0x06` | propagated `spm_npu_error` |
