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
 * Simple implementation of SH4x temp/humi sensor read from I2C.
 * 
 * Based on the SH4x datasheet Sensor Operation section.
 *
 * TODO: checksum verification
 */

#include "stack.S"

#define SH4X_ADDR 0x44
#define SH4X_COM_RESET 0x94


.bss

	.global	humi_msb, humi_lsb, humi_csm, temp_msb, temp_lsb, temp_csm
humi_msb: 
	.long 0
humi_lsb:
	.long 0
humi_csm:
	.long 0
temp_msb: 
	.long 0
temp_lsb: 
	.long 0
temp_csm: 
	.long 0

	.global sh4x_meas
sh4x_meas:
	.long 0


.text
	.global read_sh4x

	/* return >0 if no ack */
write_no_ack:
	ret

read_sh4x:
	/* write addr+w,start,0 */
	move r0,SH4X_ADDR
	lsh r0,r0,9
	or r0,r0,1
	call i2c_write_byte
	jumpr write_no_ack,0,gt

	/* write reset,0,stop */
	move r0,SH4X_COM_RESET
	lsh r0,r0,8
	or r0,r0,2
	call i2c_write_byte
	jumpr write_no_ack,0,gt

	/* wait 2ms, softreset should be done in less than ms */
	move r0,2
	call wait_ms

	/* write addr+w,start,0 */
	move r0,SH4X_ADDR
	lsh r0,r0,9
	or r0,r0,1
	call i2c_write_byte
	jumpr write_no_ack,0,gt

	/* write com,0,stop */
	move r0,sh4x_meas
	ld r0,r0,0
	lsh r0,r0,8
	or r0,r0,2
	call i2c_write_byte
	jumpr write_no_ack,0,gt

	/* wait 10ms, this should be enough for any measurement type */
	move r0,10
	call wait_ms

	/* write addr+r,start,0 */
	move r0,SH4X_ADDR
	lsh r0,r0,1
	or r0,r0,1
	lsh r0,r0,8
	or r0,r0,1
	call i2c_write_byte
	jumpr write_no_ack,0,gt

	/* read temp_msb,ack,0 */
	move r0,0
	call i2c_read_byte
	move r2,temp_msb
	st r0,r2,0

	/* read temp_lsb,ack,0 */
	move r0,0
	call i2c_read_byte
	move r2,temp_lsb
	st r0,r2,0

	/* read temp_checksum,ack,0 */
	move r0,0
	call i2c_read_byte
	move r2,temp_csm
	st r0,r2,0

	/* read humi_msb,ack,0 */
	move r0,0
	call i2c_read_byte
	move r2,humi_msb
	st r0,r2,0

	/* read humi_lsb,ack,0 */
	move r0,0
	call i2c_read_byte
	move r2,humi_lsb
	st r0,r2,0

	/* read humi_checksum,nack,stop */
	move r0,3
	call i2c_read_byte
	move r2,humi_csm
	st r0,r2,0

	/* return 0 */
	move r0,0
	ret

/* 
 * Wait for r0 milliseconds
 */
wait_ms:
	wait 8000
	sub r0,r0,1
	jump done_wait_ms,eq
	jump wait_ms
done_wait_ms:
	ret
