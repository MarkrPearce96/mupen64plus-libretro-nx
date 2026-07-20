/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *   Mupen64plus - linkage_arm64.S                                         *
 *   Copyright (C) 2009-2018 Gillou68310                                   *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program; if not, write to the                         *
 *   Free Software Foundation, Inc.,                                       *
 *   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.          *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

#ifdef __MACH__
/* Mach-O port (macOS arm64). THREE constraints shape this block:
 * 1. Apple's arm64 assembler treats ';' as a COMMENT character (not a
 *    statement separator), so each macro may emit only ONE statement —
 *    visibility directives live in the explicit newline-separated list
 *    below instead of inside the label macros.
 * 2. C symbols carry a leading underscore: definitions paste it on
 *    (`_##name` — token-pasted args are not macro-expanded, so the
 *    reference renames below cannot corrupt definitions), references out
 *    to C functions and intra-file branch targets are renamed by #define.
 * 3. Conditional branches cannot target non-local (atom) symbols — the
 *    three such sites use inverted-condition trampolines further down.
 * No .hidden/.type/.size on Mach-O; .private_extern is the .hidden analog. */
#define GLOBAL_FUNCTION(name) _##name
#define LOCAL_FUNCTION(name)  _##name
#define GLOBAL_VARIABLE(name, size_) .globl _##name

/* Intra-file branch targets (the only two referenced by name). */
#define jump_vaddr    _jump_vaddr
#define new_dyna_stop _new_dyna_stop

/* C functions called from this file. */
#define get_addr_ht           _get_addr_ht
#define verify_dirty          _verify_dirty
#define get_addr              _get_addr
#define dynarec_gen_interrupt _dynarec_gen_interrupt
#define cop1_unusable         _cop1_unusable
#define SYSCALL_new           _SYSCALL_new
#define ERET_new              _ERET_new
#define dynamic_linker        _dynamic_linker
#define dynamic_linker_ds     _dynamic_linker_ds
#define new_recompile_block   _new_recompile_block

.globl _jump_vaddr_x0
.private_extern _jump_vaddr_x0
.globl _jump_vaddr_x1
.private_extern _jump_vaddr_x1
.globl _jump_vaddr_x2
.private_extern _jump_vaddr_x2
.globl _jump_vaddr_x3
.private_extern _jump_vaddr_x3
.globl _jump_vaddr_x4
.private_extern _jump_vaddr_x4
.globl _jump_vaddr_x5
.private_extern _jump_vaddr_x5
.globl _jump_vaddr_x6
.private_extern _jump_vaddr_x6
.globl _jump_vaddr_x7
.private_extern _jump_vaddr_x7
.globl _jump_vaddr_x8
.private_extern _jump_vaddr_x8
.globl _jump_vaddr_x9
.private_extern _jump_vaddr_x9
.globl _jump_vaddr_x10
.private_extern _jump_vaddr_x10
.globl _jump_vaddr_x11
.private_extern _jump_vaddr_x11
.globl _jump_vaddr_x12
.private_extern _jump_vaddr_x12
.globl _jump_vaddr_x13
.private_extern _jump_vaddr_x13
.globl _jump_vaddr_x14
.private_extern _jump_vaddr_x14
.globl _jump_vaddr_x15
.private_extern _jump_vaddr_x15
.globl _jump_vaddr_x16
.private_extern _jump_vaddr_x16
.globl _jump_vaddr_x17
.private_extern _jump_vaddr_x17
.globl _jump_vaddr_x19
.private_extern _jump_vaddr_x19
.globl _jump_vaddr_x21
.private_extern _jump_vaddr_x21
.globl _jump_vaddr_x22
.private_extern _jump_vaddr_x22
.globl _jump_vaddr_x23
.private_extern _jump_vaddr_x23
.globl _jump_vaddr_x24
.private_extern _jump_vaddr_x24
.globl _jump_vaddr_x25
.private_extern _jump_vaddr_x25
.globl _jump_vaddr_x26
.private_extern _jump_vaddr_x26
.globl _jump_vaddr_x27
.private_extern _jump_vaddr_x27
.globl _jump_vaddr_x28
.private_extern _jump_vaddr_x28
.globl _jump_vaddr
.private_extern _jump_vaddr
.globl _verify_code
.private_extern _verify_code
.globl _cc_interrupt
.private_extern _cc_interrupt
.globl _do_interrupt
.private_extern _do_interrupt
.globl _fp_exception
.private_extern _fp_exception
.globl _jump_syscall
.private_extern _jump_syscall
.globl _jump_eret
.private_extern _jump_eret
.globl _dyna_linker
.private_extern _dyna_linker
.globl _dyna_linker_ds
.private_extern _dyna_linker_ds
.globl _new_dyna_start
.private_extern _new_dyna_start
.globl _breakpoint
.private_extern _breakpoint

#else
#define GLOBAL_FUNCTION(name)  \
    .globl name;               \
    .hidden name;              \
    .type name, %function;     \
    name

#define LOCAL_FUNCTION(name)  \
    .hidden name;             \
    .type name, %function;    \
    name

#define GLOBAL_VARIABLE(name, size_) \
    .global name;                    \
    .hidden name;                    \
    .type   name, %object;           \
    .size   name, size_
#endif

.macro movl Wn, imm
    movz    \Wn, (\imm >> 16) & 0xFFFF, lsl 16
    movk    \Wn,  \imm & 0xFFFF
.endm

#define TEXT_SECTION .text
#define END_SECTION

#include "asm_defines_gas.h"

device_r4300_new_dynarec_hot_state_dynarec_local = (offsetof_struct_device_r4300 + offsetof_struct_r4300_core_new_dynarec_hot_state + offsetof_struct_new_dynarec_hot_state_dynarec_local)
saved_context = 160

/* Defines offsets for fp addressed variables */
fp_cycle_count         = offsetof_struct_new_dynarec_hot_state_cycle_count
fp_pending_exception   = offsetof_struct_new_dynarec_hot_state_pending_exception
fp_pcaddr              = offsetof_struct_new_dynarec_hot_state_pcaddr
fp_stop                = offsetof_struct_new_dynarec_hot_state_stop

TEXT_SECTION

GLOBAL_FUNCTION(jump_vaddr_x0):
    b      jump_vaddr

GLOBAL_FUNCTION(jump_vaddr_x1):
    mov    w0, w1
    b      jump_vaddr

GLOBAL_FUNCTION(jump_vaddr_x2):
    mov    w0, w2
    b      jump_vaddr

GLOBAL_FUNCTION(jump_vaddr_x3):
    mov    w0, w3
    b      jump_vaddr

GLOBAL_FUNCTION(jump_vaddr_x4):
    mov    w0, w4
    b      jump_vaddr

GLOBAL_FUNCTION(jump_vaddr_x5):
    mov    w0, w5
    b      jump_vaddr

GLOBAL_FUNCTION(jump_vaddr_x6):
    mov    w0, w6
    b      jump_vaddr

GLOBAL_FUNCTION(jump_vaddr_x8):
    mov    w0, w8
    b      jump_vaddr

GLOBAL_FUNCTION(jump_vaddr_x9):
    mov    w0, w9
    b      jump_vaddr

GLOBAL_FUNCTION(jump_vaddr_x10):
    mov    w0, w10
    b      jump_vaddr

GLOBAL_FUNCTION(jump_vaddr_x11):
    mov    w0, w11
    b      jump_vaddr

GLOBAL_FUNCTION(jump_vaddr_x12):
    mov    w0, w12
    b      jump_vaddr

GLOBAL_FUNCTION(jump_vaddr_x13):
    mov    w0, w13
    b      jump_vaddr

GLOBAL_FUNCTION(jump_vaddr_x14):
    mov    w0, w14
    b      jump_vaddr

GLOBAL_FUNCTION(jump_vaddr_x15):
    mov    w0, w15
    b      jump_vaddr

GLOBAL_FUNCTION(jump_vaddr_x16):
    mov    w0, w16
    b      jump_vaddr

GLOBAL_FUNCTION(jump_vaddr_x17):
    mov    w0, w17
    b      jump_vaddr

GLOBAL_FUNCTION(jump_vaddr_x19):
    mov    w0, w19
    b      jump_vaddr

GLOBAL_FUNCTION(jump_vaddr_x21):
    mov    w0, w21
    b      jump_vaddr

GLOBAL_FUNCTION(jump_vaddr_x22):
    mov    w0, w22
    b      jump_vaddr

GLOBAL_FUNCTION(jump_vaddr_x23):
    mov    w0, w23
    b      jump_vaddr

GLOBAL_FUNCTION(jump_vaddr_x24):
    mov    w0, w24
    b      jump_vaddr

GLOBAL_FUNCTION(jump_vaddr_x25):
    mov    w0, w25
    b      jump_vaddr

GLOBAL_FUNCTION(jump_vaddr_x26):
    mov    w0, w26
    b      jump_vaddr

GLOBAL_FUNCTION(jump_vaddr_x27):
    mov    w0, w27
    b      jump_vaddr

GLOBAL_FUNCTION(jump_vaddr_x28):
    mov    w0, w28
    b      jump_vaddr

GLOBAL_FUNCTION(jump_vaddr_x7):
    mov    w0, w7

GLOBAL_FUNCTION(jump_vaddr):
    bl     get_addr_ht
    br     x0

GLOBAL_FUNCTION(verify_code):
    /* x0 = head */
    mov    x21, x30 /* Save link register */
    bl     verify_dirty
    tst    x0, x0
    b.ne   .D1
    mov    x30, x21 /* Restore link register */
    ret
.D1:
    bl     get_addr
    br     x0

GLOBAL_FUNCTION(cc_interrupt):
    str    w20, [x29, #fp_cycle_count]
    str    wzr, [x29, #fp_pending_exception]
    mov    x20, x30 /* Save link register */
    bl     dynarec_gen_interrupt
    mov    x30, x20 /* Restore link register */
    ldr    w20, [x29, #fp_cycle_count]
    ldr    w1, [x29, #fp_pending_exception]
    ldr    w2, [x29, #fp_stop]
    tst    w2, w2
#ifdef __MACH__
    b.eq   1f
    b      new_dyna_stop
1:
#else
    b.ne   new_dyna_stop
#endif
    tst    w1, w1
    b.ne   .E1
    ret
.E1:
    ldr    w0, [x29, #fp_pcaddr]
    bl     get_addr_ht
    br     x0

LOCAL_FUNCTION(new_dyna_stop):
    add    x16, x29, #saved_context
    ldp    x19,x20,[x16,#0]
    ldp    x21,x22,[x16,#16]
    ldp    x23,x24,[x16,#32]
    ldp    x25,x26,[x16,#48]
    ldp    x27,x28,[x16,#64]
    ldp    x29,x30,[x16,#80]
    ret

GLOBAL_FUNCTION(do_interrupt):
    ldr    w2, [x29, #fp_stop]
    tst    w2, w2
#ifdef __MACH__
    b.eq   1f
    b      new_dyna_stop
1:
#else
    b.ne   new_dyna_stop
#endif
    ldr    w0, [x29, #fp_pcaddr]
    bl     get_addr_ht
    ldr    w20, [x29, #fp_cycle_count]
    br     x0

GLOBAL_FUNCTION(fp_exception):
    str    w0, [x29, #fp_pcaddr]
    bl     cop1_unusable
    br     x0

GLOBAL_FUNCTION(jump_syscall):
    str    w0, [x29, #fp_pcaddr]
    bl     SYSCALL_new
    br     x0

GLOBAL_FUNCTION(jump_eret):
    str    w20, [x29, #fp_cycle_count]
    bl     ERET_new
    ldr    w20, [x29, #fp_cycle_count]
    tst    w0, w0
#ifdef __MACH__
    b.ne   1f
    b      new_dyna_stop
1:
#else
    b.eq   new_dyna_stop
#endif
    br     x0

GLOBAL_FUNCTION(dyna_linker):
    bl     dynamic_linker
    br     x0

GLOBAL_FUNCTION(dyna_linker_ds):
    bl     dynamic_linker_ds
    br     x0

GLOBAL_FUNCTION(new_dyna_start):
#ifdef __MACH__
    /* Mach-O spells page-relative relocations @PAGE/@PAGEOFF (ELF: :lo12:),
     * and the C globals carry the leading underscore. */
    adrp   x16, _g_dev@PAGE
    add    x16, x16, _g_dev@PAGEOFF
#else
    adrp   x16, g_dev
    add    x16, x16, :lo12:g_dev
#endif
    movl   x1, (device_r4300_new_dynarec_hot_state_dynarec_local + saved_context)
    add    x16, x16, x1
#ifdef __MACH__
    adrp   x1, _base_addr_rx@PAGE
    add    x1, x1, _base_addr_rx@PAGEOFF
#else
    adrp   x1, base_addr_rx
    add    x1, x1, :lo12:base_addr_rx
#endif
    mov    w0, #0xa4000000
    stp    x19,x20,[x16,#0]
    stp    x21,x22,[x16,#16]
    stp    x23,x24,[x16,#32]
    stp    x25,x26,[x16,#48]
    stp    x27,x28,[x16,#64]
    stp    x29,x30,[x16,#80]
    sub    x29, x16, #saved_context
    ldr    x19, [x1]
    add    w0, w0, #0x40
    bl     new_recompile_block
    ldr    w20, [x29, #fp_cycle_count]
    br     x19

GLOBAL_FUNCTION(breakpoint):
    brk 0
    ret

END_SECTION