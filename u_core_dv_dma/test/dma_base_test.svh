class dma_base_test extends uvm_test;
  `uvm_component_utils(dma_base_test)

  dma_env     env;
  dma_env_cfg cfg;

  function new(string name = "dma_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    cfg = dma_env_cfg::type_id::create("cfg");
    if (!uvm_config_db#(virtual dma_axil_if)::get(this, "", "axil_vif", cfg.axil_vif)) begin
      `uvm_fatal(get_type_name(), "axil_vif is not set")
    end
    if (!uvm_config_db#(virtual dma_axi_mem_if)::get(this, "", "axi_mem_vif", cfg.axi_mem_vif)) begin
      `uvm_fatal(get_type_name(), "axi_mem_vif is not set")
    end
    if (!uvm_config_db#(virtual dma_spm_if)::get(this, "", "spm_vif", cfg.spm_vif)) begin
      `uvm_fatal(get_type_name(), "spm_vif is not set")
    end
    if (!uvm_config_db#(virtual dma_status_if)::get(this, "", "status_vif", cfg.status_vif)) begin
      `uvm_fatal(get_type_name(), "status_vif is not set")
    end
    configure_env();
    uvm_config_db#(dma_env_cfg)::set(this, "env", "cfg", cfg);
    env = dma_env::type_id::create("env", this);
  endfunction

  virtual function void configure_env();
    dma_mem_init_item mem_init;
    dma_spm_init_item spm_init;

    repeat (8) begin
      mem_init = dma_mem_init_item::type_id::create("mem_init");
      mem_init.addr = 32'h2000_0000 + (cfg.mem_init_q.size() * 32'h40);
      mem_init.data = {$random, $random, $random, $random, $random, $random, $random, $random,
                       $random, $random, $random, $random, $random, $random, $random, $random};
      cfg.mem_init_q.push_back(mem_init);
    end

    repeat (8) begin
      spm_init = dma_spm_init_item::type_id::create("spm_init");
      spm_init.row_idx = cfg.spm_out_init_q.size()[2:0];
      spm_init.data = {$random, $random, $random, $random, $random, $random, $random, $random,
                       $random, $random, $random, $random, $random, $random, $random, $random};
      cfg.spm_out_init_q.push_back(spm_init);
    end
  endfunction
endclass
