ARCH ?= x86_64
TARGET ?= $(ARCH)-unknown-none
TOOL_PATH ?= /usr/local
GRUB_PATH ?= /usr/local
AS_PATH ?= /usr/local

rust_os = target/$(TARGET)/debug/libnewt.a
rust_os_release = target/$(TARGET)/release/libnewt.a

kernel = out/kernel-$(ARCH).bin
kernel-release = out/kernel-release-$(ARCH).bin

iso = out/newtOS-$(ARCH).iso
iso-release = out/newtOS-release-$(ARCH).iso

linker_script = src/arch/$(ARCH)/linker.ld
grub_cfg = src/arch/$(ARCH)/grub.cfg
asm_source_files = $(wildcard src/arch/$(ARCH)/*.asm)
asm_object_files = $(patsubst src/arch/$(ARCH)/%.asm, build/arch/$(ARCH)/%.o, $(asm_source_files))

out_dir := out
build_dir := build

qemu_args := -serial stdio -d int -no-shutdown -no-reboot  -m 512M


.PHONY: all release debug clean kernel kernel-release rust-debug rust-release

all: $(kernel) $(kernel-release)
release: $(kernel-release)
debug: $(kernel)
nasm_stage: $(asm_object_files)

clean:
	rm -rv $(out_dir)
	rm -rv $(build_dir)
	@RUST_TARGET_PATH=$(shell pwd) cargo clean --target ./$(target).json

kernel: $(kernel)
kernel-release: $(kernel-release)

rust-debug: $(rust_os)
rust-release: $(rust_os_release)

$(out_dir):
	mkdir -p $(out_dir)

$(build_dir):
	mkdir -p $(build_dir)

$(kernel): $(out_dir) $(build_dir) $(rust_os) $(asm_object_files) $(linker_script)
	$(TOOL_PATH)/bin/x86_64-elf-ld --nmagic --gc-sections -T $(linker_script) -o $(kernel) $(asm_object_files) $(rust_os)

$(kernel-release): $(out_dir) $(build_dir) $(rust_os_release) $(asm_object_files) $(linker_script)
	$(TOOL_PATH)/bin/x86_64-elf-ld --nmagic --gc-sections -T $(linker_script) -o $(kernel-release) $(asm_object_files) $(rust_os_release)

$(rust_os):
	@RUST_TARGET_PATH=$(shell pwd) cargo +nightly build -Z build-std --target x86_64-unknown-none --verbose
$(rust_os_release):
	@RUST_TARGET_PATH=$(shell pwd) cargo +nightly build -Z build-std --target x86_64-unknown-none --release

build/arch/$(ARCH)/%.o: src/arch/$(ARCH)/%.asm
	@mkdir -p $(shell dirname $@)
	$(AS_PATH)/bin/nasm -felf64 $< -o $@
