ROOT_DIR           =$(PWD)
BUILD              =build
BUILD_DIR          =$(ROOT_DIR)/$(BUILD)
SRC_DIR            =$(ROOT_DIR)/src
SIM_DIR            =$(ROOT_DIR)/sim
SYN_DIR            =$(ROOT_DIR)/syn
SCRIPT_DIR         =$(ROOT_DIR)/script
REPORT_DIR         =$(ROOT_DIR)/report
SV_DIR             =$(ROOT_DIR)/conf/simvision_conf
NC_DIR             =$(ROOT_DIR)/conf/nWave_conf

TB_TOP             =testfixture3
TOP                =ISE

SRC=$(shell ls $(SRC_DIR)/*.v)

TB_SRC=$(SIM_DIR)/in_pattern3.dat $(SIM_DIR)/out_golden3.dat

.PHONY: default init check rtl nw sv syn autosyn post post_sv clean gen_def

# Show available all command
default:
	@echo "clean   => Clean previous build"
	@echo "init    => Create necessary directory"
	@echo "rtl     => Run RTL simulation"
	@echo "nw      => Run nWave"
	@echo "sv      => Run Simvision"
	@echo "syn     => Run synthesize in interactive mode"
	@echo "autosyn => Run synthesize in background"
	@echo "post    => Run gate-level simulation"
	@echo "post_sv => Run Simvision with post sim"
	@echo "gen_def => Generate Verilog define macro"

$(BUILD):
	mkdir -p $(BUILD)

# Create folders
init: clean
	mkdir -p $(BUILD_DIR) $(SYN_DIR) $(REPORT_DIR)

# Generate header
gen_def:
	sh $(SRC_DIR)/gen_def.sh > $(SRC_DIR)/def.v

cp_tb_src:
	cd $(BUILD_DIR); \
	cp $(TB_SRC) .;

# Check HDL syntax
check:
	jg -superlint $(SCRIPT_DIR)/superlint.tcl &

# Run RTL simulation
rtl: $(BUILD) gen_def cp_tb_src
	cd $(BUILD_DIR); \
	ncverilog  $(SIM_DIR)/$(TB_TOP).v $(SRC) \
	+incdir+$(SRC_DIR) \
	+nc64bit \
	+access+r \
	+define+SHM_FILE=\"$(TOP).shm\" \
	+define+FSDB_FILE=\"$(TOP).fsdb\"

# View waveform using nWave
nw: $(BUILD)
	cp $(NC_DIR)/signal.rc $(BUILD_DIR); \
	cd $(BUILD_DIR); \
	nWave -f $(TOP).fsdb -sswr $(NC_DIR)/signal.rc +access+r +nc64bit &

# View waveform using simvision
sv: $(BUILD)
	cd $(BUILD_DIR); \
	simvision -64bit -waves -input $(SV_DIR)/rtl.sv &

# Run synthesize with Design Compiler
syn: $(BUILD)
	cd $(BUILD_DIR); \
	cp $(SCRIPT_DIR)/synopsys_dc.setup $(BUILD_DIR)/.synopsys_dc.setup; \
	dcnxt_shell -f $(SCRIPT_DIR)/synthesize.tcl;

# Auto run synthesize with Design Compiler
autosyn: $(BUILD)
	cd $(BUILD_DIR); \
	cp $(SCRIPT_DIR)/synopsys_dc.setup $(BUILD_DIR)/.synopsys_dc.setup; \
	nohup dcnxt_shell -f $(SCRIPT_DIR)/synthesize.tcl &> $(ROOT_DIR)/nohup.log &

# Run gate-level simulation (nWave)
post: $(BUILD) cp_tb_src
	cd $(BUILD_DIR); \
	cp $(SYN_DIR)/$(TOP)_syn.sdf $(BUILD_DIR); \
	ncverilog +ncmaxdelays $(SIM_DIR)/$(TB_TOP).v $(SYN_DIR)/$(TOP)_syn.v -v $(SIM_DIR)/tsmc13_neg.v \
	+nc64bit \
	+access+r \
	+define+SHM_FILE=\"$(TOP).shm\" \
	+define+FSDB_FILE=\"$(TOP).fsdb\" \
	+define+SDF \
	+define+SDFFILE=\"$(SYN_DIR)/$(TOP)_syn.sdf\"

# View waveform using simvision
post_sv: $(BUILD)
	cd $(BUILD_DIR); \
	simvision -64bit -waves -input $(SV_DIR)/post.sv &

# Remove all files
clean:
	rm -rf $(BUILD_DIR) $(SYN_DIR) $(REPORT_DIR) *.log

