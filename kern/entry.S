#if LAB >= 1
/* See COPYRIGHT for copyright information. */

#include <inc/asm.h>
#include <inc/mmu.h>
#include <inc/pmap.h>


###################################################################
# The kernel (this code) is linked at address ~(KERNBASE + 1 Meg), 
# but the bootloader load it at address	~1 Meg.
#	
# RELOC(x) maps a symbol x from its link address to its actual
# location in physical memory (its load address).	 
###################################################################

#define	RELOC(x) ((x) - KERNBASE)


.set CODE_SEL,0x8		# index of code seg within mygdt
.set DATA_SEL,0x10		# index of data seg within mygdt


###################################################################
# entry point
###################################################################

.text
.globl		_start
_start:
	movw	$0x1234,0x472			# warm boot

	# Establish our own GDT in place of the boot loader's temporary GDT.
	lgdt	RELOC(mygdtdesc)		# load descriptor

	# Immediately reload all segment registers (including CS!)
	# with segment selectors from the new GDT.
	movl	$DATA_SEL, %eax			# Data segment selector
	movw	%ax,%ds				# -> DS: Data Segment
	movw	%ax,%es				# -> ES: Extra Segment
	movw	%ax,%ss				# -> SS: Stack Segment
	ljmp	$CODE_SEL,$relocated		# reload CS by jumping
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer

        # Leave a few words on the stack for the user trap frame UTF
	# XXX use sizeof(.)
	movl	$(_bootstacktop-0x40),%esp	# set the stack pointer 

	# now to C code
	call	_i386_init

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin


###################################################################	
# See mmu.h for a complete description of these two symbols.
###################################################################
.data
	.globl	_vpt
	.set	_vpt, VPT
	.globl	_vpd
	.set	_vpd, (VPT + SRL(VPT, 10))


###################################################################
# boot stack
###################################################################
	.p2align	PGSHIFT		# force page alignment
	.globl		_bootstack
_bootstack:
	.space		KSTKSIZE
	.globl		_bootstacktop   
_bootstacktop:

###################################################################
# setup the GDT	
###################################################################
.p2align	2				# force 4 byte alignment
mygdt:
	SEG_NULL				# null seg
	SEG(STA_X|STA_R, -KERNBASE, 0xffffffff)	# code seg
	SEG(STA_W, -KERNBASE, 0xffffffff)	# data seg
mygdtdesc:
	.word	0x17			# sizeof(mygdt) - 1
	.long	RELOC(mygdt)		# address mygdt

#endif // LAB >= 1