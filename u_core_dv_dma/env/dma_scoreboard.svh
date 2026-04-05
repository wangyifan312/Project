class dma_scoreboard extends uvm_component;
  `uvm_component_utils(dma_scoreboard)

  uvm_analysis_imp_axil   #(dma_axil_item,   dma_scoreboard) axil_imp;
  uvm_analysis_imp_axi_mem#(dma_axi_mem_item,dma_scoreboard) axi_mem_imp;
  uvm_analysis_imp_spm    #(dma_spm_item,    dma_scoreboard) spm_imp;
  uvm_analysis_imp_status #(dma_status_item, dma_scoreboard) status_imp;

  dma_desc_cfg exp_desc_q[$];
  dma_desc_cfg active_desc;
  bit [31:0] csr_shadow [bit [31:0]];
  int unsigned active_row_idx;
  bit [511:0] load_data_q[$];
  bit [511:0] store_data_q[$];

  function new(string name = "dma_scoreboard", uvm_component parent = null);
    super.new(name, parent);
    axil_imp   = new("axil_imp", this);
    axi_mem_imp = new("axi_mem_imp", this);
    spm_imp    = new("spm_imp", this);
    status_imp = new("status_imp", this);
  endfunction

  function void write_axil(dma_axil_item t);
    if (t.kind == dma_axil_item::DMA_AXIL_WRITE) begin
      csr_shadow[t.addr] = t.data;
      if (t.addr[7:0] == 8'h18 && t.data[0]) begin
        dma_desc_cfg desc = dma_desc_cfg::type_id::create("desc");
        desc.op_type      = csr_shadow[32'h1000_1000][1:0];
        desc.buf_sel      = csr_shadow[32'h1000_1000][3:2];
        desc.flags        = csr_shadow[32'h1000_1000][19:4];
        desc.src_addr     = csr_shadow[32'h1000_1004];
        desc.dst_addr     = csr_shadow[32'h1000_1008];
        desc.row_len      = csr_shadow[32'h1000_100c][15:0];
        desc.row_cnt      = csr_shadow[32'h1000_100c][31:16];
        desc.src_stride   = csr_shadow[32'h1000_1010][15:0];
        desc.dst_stride   = csr_shadow[32'h1000_1010][31:16];
        desc.spm_row_base = csr_shadow[32'h1000_1014][15:0];
        desc.tile_id      = csr_shadow[32'h1000_1014][31:16];
        exp_desc_q.push_back(desc);
        if (active_desc == null) begin
          active_desc = exp_desc_q.pop_front();
          active_row_idx = 0;
        end
      end
    end
  endfunction

  function void write_axi_mem(dma_axi_mem_item t);
    if (active_desc == null) return;
    case (t.kind)
      dma_axi_mem_item::DMA_AXI_MEM_AR: begin
        `uvm_info(get_type_name(), $sformatf("Observe AR addr=0x%08x", t.addr), UVM_LOW)
      end
      dma_axi_mem_item::DMA_AXI_MEM_R: begin
        load_data_q.push_back(t.data);
      end
      dma_axi_mem_item::DMA_AXI_MEM_W: begin
        if (store_data_q.size() == 0) begin
          `uvm_error(get_type_name(), "AXI write data observed before SPM read data")
        end else begin
          bit [511:0] exp_data = store_data_q.pop_front();
          if (t.data !== exp_data) begin
            `uvm_error(get_type_name(), "AXI write data mismatch against SPM return data")
          end
        end
      end
      default: begin end
    endcase
  endfunction

  function void write_spm(dma_spm_item t);
    if (active_desc == null) return;
    case (t.kind)
      dma_spm_item::DMA_SPM_WR: begin
        if ((active_desc.op_type != u_core_pkg::DMA_OP_LOAD_ACT) &&
            (active_desc.op_type != u_core_pkg::DMA_OP_LOAD_WGT)) begin
          `uvm_error(get_type_name(), "Unexpected SPM write for non-load descriptor")
        end
        if (load_data_q.size() == 0) begin
          `uvm_error(get_type_name(), "SPM write observed before AXI read data")
        end else begin
          bit [511:0] exp_data = load_data_q.pop_front();
          if (t.data !== exp_data) begin
            `uvm_error(get_type_name(), "SPM write data mismatch against AXI read data")
          end
        end
        active_row_idx++;
      end
      dma_spm_item::DMA_SPM_RD_DATA: begin
        store_data_q.push_back(t.data);
      end
      default: begin end
    endcase
  endfunction

  function void write_status(dma_status_item t);
    if (t.dma_done && active_desc != null) begin
      active_desc = (exp_desc_q.size() != 0) ? exp_desc_q.pop_front() : null;
      active_row_idx = 0;
      load_data_q.delete();
      store_data_q.delete();
    end
  endfunction
endclass
