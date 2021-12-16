/*
 * BSD 2-Clause License
 *
 * Copyright (c) 2021, Robert David <robert.david@posteo.net>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/*
 * ULP stack and subroutine implementation.
 *
 * ABI reference:
 *
 * r3 is reserved register = stack pointer
 *
 * Call conventions:
 * r0 is used as arg0
 * return value is stored in r0
 *
 * r1 is non-volatile register and is saved
 * r2 is volatile register and is not saved
 */

/*
 * For debugging purposes, you may define DEBUG and then all the regs will be
 * saved on stack.
 * To display the stack put this snippet to your code:
 *
 * printf("    addr   pc r  val\n");
 * for(uint32_t* addr = &ulp_stack_begin ; addr<=&ulp_stack_end ; addr++) {
 * 	printf("%x ", (uint32_t)addr);
 * 	printf("%4x ", (uint32_t)*addr>>21);
 * 	printf("%1x ", ((uint32_t)*addr>>16) & 0x3);
 * 	printf("%4x\n", ((uint32_t)*addr) & 0xffff);
 * }
 *
 * It is highly useful if your code crash/hang in some code path.
 * You may also implement simple panic call, which will wake up the ESP32
 * and stop the ULP (the same as when ULP ends).
 * Than place call it on the place you want to examine.
 *
 */
/*
#define DEBUG
*/

#ifdef DEBUG
#define STACK_SIZE 128
#else
#define STACK_SIZE 64
#endif


.macro stack_space
	.global stack_begin
	.global stack_end
stack_begin: 
	.skip STACK_SIZE
stack_end: 
	.long 0
.endm

/*
 * Initialzie r3 with stack pointer
 */
.macro stack_init
	move r3,stack_end
.endm

/*
 * push the reg rx to the stack
 */
.macro push rx
	st \rx,r3,0
	sub r3,r3,1
.endm

/*
 * pop to the reg rx from the stack
 */
.macro pop rx
	add r3,r3,1
	ld \rx,r3,0
.endm

/*
 * top to the reg rx from the stack
 */
.macro top rx
	ld \rx,r3,4
.endm

#ifdef DEBUG

/*
 * Call subroutine with all registers saved on stack
 */
.macro call func
	sub r3,r3,5
	st r0,r3,4
	st r1,r3,8
	st r2,r3,12
	st r3,r3,16
	.set addr,(.+12)
	move r2,addr
	st r2,r3,20
	jump \func
.endm

/* 
 *  Return from subroutine
 */
.macro ret
	ld r2,r3,20
	ld r1,r3,8
	add r3,r3,5
	jump r2
.endm

#else

/*
 * Call subroutine
 */
.macro call func
	sub r3,r3,2
	st r1,r3,4
	.set addr,(.+12)
	move r2,addr
	st r2,r3,8
	jump \func
.endm

/* 
 *  Return from subroutine
 */
.macro ret
	ld r2,r3,8
	ld r1,r3,4
	add r3,r3,2
	jump r2
.endm

#endif
