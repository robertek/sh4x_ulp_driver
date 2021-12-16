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
 * r3 is reserved regiester = stack pointer
 *
 * Call conventions:
 * r0 is used as arg0
 * return value is stored in r0
 *
 * r1 is non-volatile regiester and is saved
 * r2 is volatile register and is not saved
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
