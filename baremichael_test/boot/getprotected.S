 /*
 * This is intended to get the processor into 32-bit protected mode.
 * Based off of Embedded X86 Programming: Protected Mode by Jean Gareau
 * with help from Mike Schultz's startup.S from Embedded Xinu for x86.
 */

/* BareMichael SCC baremetal framework.
 * Copyright (C) 2012.  All rights reserved. */

/* Modification version of get protect mode for AOS (Active Oberon System).
 * modified by suwon, oh.
 * Computer System And Platform Lab., SNU, Korea
 * 29. Sep. 2014.
 */

.code16
.text
	.globl _start

.org 0x0000
_start:
	jmp getprotected
	
	/* OBERON signature */
	.byte 	'O'
	.byte	'B'
	.byte	'E'
	.byte 	'R'
	.byte	'O'
	.byte	'N'
	.align	8	/* Intel likes 8-byte alignment for the GDT */
gdt:
/* GDT[0]: Null entry, never used. */
	.word	0, 0, 0, 0

/* GDT[1]: Executable, read-only code, base address of 0, limit of FFFFFh,
 * granularity bit (G) set (making the limit 4GB) */
	.word	0xffff		/* Limit[15..0] */
	.word	0x0000		/* Base[15..0] */
	.byte	0x00		/* Base[23..16] */
	.byte	0b10011010	/* P(1) DPL(00) S(1) 1 C(0) R(1) A(0) */
	.byte	0b11001111	/* G(1) D(1) 0 0 Limit[19..16] */
	.byte	0x00		/* Base[31..24] */

/* GDT[2]: Writable data segment, covering the same address space as GDT[1]. */
	.word	0xffff		/* Limit[15..0] */
	.word	0x0000		/* Base[15..0] */
	.byte	0x00		/* Base[23..16] */
	.byte	0b10010010	/* P(1) DPL(00) S(1) 0 E(0) W(1) A(0) */
	.byte	0b11001111	/* G(1) B(1) 0 0 Limit[19..16] */
	.byte	0x00		/* Base[31..24] */
gdt_end:

	.align	4
gdt_desc:
	.word	gdt_end - gdt - 1	/* gdt limit */
	.long	gdt					/* gdt base */

	.align	8	/* Intel likes 8-byte alignment for the IDT */
idt:
	.space	NID * 8, 0			/* must equal NID*8 */
idt_desc:
	.word	idt_desc - idt - 1	/* size of idt - 1 (in bytes) */
	.long	idt

getprotected:
	/* hard code an initial boot table */
	movw	$0x1800, %si	/* boot table locates 4 sectors after getprotected.S */
	movl	$0x7, (%si)		/* fragmented kernel info flag = 0000_0007H */
	add		$4, %si
	movl	$0x1c, (%si)	/* entry length = 28 bytes */
	add		$4, %si
	movl	$0x2000, (%si)	/* kernel address */
	add		$4, %si
	movb	$1, (%si)		/* checksum */
	add		$1, %si
	movb	$0x0, (%si)		/* void */
	add		$1, %si
	movw	$0xd2, (%si)	/* number of fragments */
	add		$2, %si
	movl	$0x2000, (%si)	/* kernel entry point */
	add		$4, %si
	movl	$0x0, (%si)	/* padding 0 for packing 8 bytes */
	add		$4, %si
	movl	$0x3a2, (%si)	/* unknown */
	add		$4, %si

	movl	$0x8, (%si)		/* environment info */
	add		$4, %si
	movl	$0x4c, (%si)	/* entry length = 76 bytes */
	add		$4, %si
	/* environment variables start from here */
	movl	$0x746f6f42, (%si)
	add		$4, %si
	movl	$0x316c6f56, (%si)
	add		$4, %si
	movl	$0x534f4100, (%si)
	add		$4, %si
	movl	$0x736f4120, (%si)
	add		$4, %si
	movl	$0x49205346, (%si)
	add		$4, %si
	movl	$0x23304544, (%si)
	add		$4, %si
	movl	$0x6f410031, (%si)
	add		$4, %si
	movl	$0x00534673, (%si)
	add		$4, %si
	movl	$0x6b736944, (%si)
	add		$4, %si
	movl	$0x756c6f56, (%si)
	add		$4, %si
	movl	$0x2e73656d, (%si)
	add		$4, %si
	movl	$0x2077654e, (%si)
	add		$4, %si
	movl	$0x6b736944, (%si)
	add		$4, %si
	movl	$0x4e2e5346, (%si)
	add		$4, %si
	movl	$0x53467765, (%si)
	add		$4, %si
	movl	$0x6f6f4200, (%si)
	add		$4, %si
	movl	$0x74, (%si)
	add		$4, %si

	movl	$0x3, (%si)		/* boot area type */
	add		$4, %si
	movl	$0x10, (%si)	/* entry length = 16 bytes */
	add		$4, %si
	movl	$0x1000, (%si)	/* boot area start address */
	add		$4, %si
	movl	$0x2000, (%si)	/* 2 pages */
	add		$4, %si

	movl	$0x4, (%si)		/* free area type */
	add		$4, %si
	movl	$0x10, (%si)	/* entry length = 16 bytes */
	add		$4, %si
	movl	$0x100000, (%si) /* free area (extended memory) */
	add		$4, %si
	movl	$0x1f00000, (%si)
	add		$4, %si

	/* add boot table end marker */
	movl	$0xffffffff, (%si)
	movl	$0x0, 4(%si)
	
	/* hard code an LGDT */
	.byte	0x66		/* 32-bit operand override */
	.byte	0x8d		/* lea (e)bx,Addr */
	.byte	0x1e
	.long	gdt_desc
	.byte	0x0f		/* lgdt fword ptr [bx] */
	.byte	0x01
	.byte	0x17

	movw	$1, %ax		/* Protected mode bit */
	lmsw	%ax			/* Protected mode is go! (but not 32-bit yet!) */
	movw	$0x10, %ax	/* Load data seg regs with index to GDT[2] entry! */
	movw	%ax, %ds
	movw	%ax, %es
	movw	%ax, %ss
	movw	%ax, %fs
	movw	%ax, %gs

	/* hard code an LJMP */
	.byte	0x66		/* 32-bit operand override */
	.byte	0xea		/* far jump */
	.long	prot_world	/* 32-bit offset */
	.word	0x8			/* 16-bit selector ([index into GDT] * 8) */
						/* NOTE: that ljmp implicitly sets %cs to 0x8 */

.code32
prot_world:
	lgdt	gdt_desc
	lidt	idt_desc
	
	ljmp	$0x8, $IMG_ADDR /* Jump to kernel */

