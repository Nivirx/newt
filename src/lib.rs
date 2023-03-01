#![no_std]
#![no_main]

#![feature(lang_items)]
#![feature(ptr_internals)]
//#![feature(allocator_api)]
#![feature(integer_atomics)]
#![feature(panic_info_message)]
#![feature(asm)]
#![feature(abi_x86_interrupt)]



#[macro_use]
extern crate alloc;

extern crate spin;
extern crate volatile;
extern crate bit_field;

#[allow(unused_imports)]
#[macro_use]
extern crate bitflags;

extern crate raw_cpuid;
extern crate lazy_static;
extern crate x86_64;

extern crate uefi;
extern crate uefi_services;
extern crate goblin;

use uefi::prelude::*;
use uefi::{table::Runtime};


#[repr(C)]
pub struct EBootTable {
    sys_table: Option<SystemTable<Runtime>>,
    mmap_buf: Option<*mut u8>,
    mmap_len: Option<usize>,
    mmap_cap: Option<usize>,
}

#[no_mangle]
pub extern "C" fn kmain(mut eboot: EBootTable) {
    let st = eboot.sys_table.expect("No sys table present from bootloader passed eboot table");
    let rts = unsafe { st.runtime_services() };

    loop {
        unsafe { asm!("hlt") }
    }
    /*
    let cpuid = CpuId::new();
    match cpuid.get_vendor_info() {
        Some(vf) => println!("CPU Vendor: {}", vf.as_str()),
        None => println!("<CPU Vendor: <Unable to retreive CPU vendor>"),
    };
    match cpuid.get_processor_brand_string() {
        Some(pbs) => println!("CPU: {}", pbs.as_str() ),
        None => println!("CPU: <Unable to retreive CPU brand string>"),
    }
    */
}


