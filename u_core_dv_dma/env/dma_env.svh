class dma_env extends uvm_env;
  `uvm_component_utils(dma_env)

  dma_env_cfg          cfg;
  dma_axil_agent       axil_agent;
  dma_axi_mem_agent    axi_mem_agent;
  dma_spm_agent        spm_agent;
  dma_status_monitor   status_mon;
  dma_virtual_sequencer vseqr;
  dma_scoreboard       scb;
  dma_coverage         cov;

  function new(string name = "dma_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(dma_env_cfg)::get(this, "", "cfg", cfg)) begin
      `uvm_fatal(get_type_name(), "dma_env_cfg is not set")
    end

    uvm_config_db#(virtual dma_axil_if)::set(this, "axil_agent.*", "vif", cfg.axil_vif);
    uvm_config_db#(virtual dma_axi_mem_if)::set(this, "axi_mem_agent.*", "vif", cfg.axi_mem_vif);
    uvm_config_db#(virtual dma_spm_if)::set(this, "spm_agent.*", "vif", cfg.spm_vif);
    uvm_config_db#(virtual dma_status_if)::set(this, "status_mon", "vif", cfg.status_vif);
    uvm_config_db#(dma_env_cfg)::set(this, "axi_mem_agent.*", "cfg", cfg);
    uvm_config_db#(dma_env_cfg)::set(this, "spm_agent.*", "cfg", cfg);

    axil_agent = dma_axil_agent::type_id::create("axil_agent", this);
    axi_mem_agent = dma_axi_mem_agent::type_id::create("axi_mem_agent", this);
    spm_agent = dma_spm_agent::type_id::create("spm_agent", this);
    status_mon = dma_status_monitor::type_id::create("status_mon", this);
    vseqr = dma_virtual_sequencer::type_id::create("vseqr", this);

    if (cfg.enable_scoreboard) begin
      scb = dma_scoreboard::type_id::create("scb", this);
    end
    if (cfg.enable_coverage) begin
      cov = dma_coverage::type_id::create("cov", this);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    vseqr.axil_sqr = axil_agent.sqr;

    if (scb != null) begin
      axil_agent.mon.ap.connect(scb.axil_imp);
      axi_mem_agent.mon.ap.connect(scb.axi_mem_imp);
      spm_agent.mon.ap.connect(scb.spm_imp);
      status_mon.ap.connect(scb.status_imp);
    end

    if (cov != null) begin
      axil_agent.mon.ap.connect(cov.axil_imp);
      status_mon.ap.connect(cov.status_imp);
    end
  endfunction
endclass
