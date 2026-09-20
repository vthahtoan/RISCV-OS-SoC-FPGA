/* link.ld - Linker script cho RISC-V CPU tren FPGA */

OUTPUT_ARCH("riscv")
ENTRY(_start)

MEMORY
{
    /* BRAM: 8KB cho ca instruction va data */
    BRAM (rwx) : ORIGIN = 0x00000000, LENGTH = 8K
}

SECTIONS
{
    /* Code section - bat dau tu dia chi 0 */
    .text 0x00000000 : {
        /* QUAN TRONG: crt0.o phai nam DAU TIEN (tai dia chi 0) */
        *(.text.init)
        *(.text.startup)
        *(.text)
        *(.text.*)
    } > BRAM

    /* Read-only data */
    .rodata : {
        *(.rodata)
        *(.rodata.*)
    } > BRAM

    /* Initialized data */
    .data : {
        *(.data)
        *(.data.*)
        *(.sdata)
        *(.sdata.*)
    } > BRAM

    /* BSS (zero-initialized) */
    .bss : {
        __bss_start = .;
        *(.bss)
        *(.bss.*)
        *(.sbss)
        *(.sbss.*)
        *(COMMON)
        __bss_end = .;
    } > BRAM

    /* Stack: tu 0x800 tro len (0x1000 la dinh stack) */
    /* Vung 0x800 - 0x804 danh cho result/status output */

    /DISCARD/ : {
        *(.comment)
        *(.note.*)
        *(.eh_frame)
    }
}
