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
 * Software I2C impementation.
 *
 * Based on pseudocode from:
 * https://en.wikipedia.org/wiki/I%C2%B2C#Example_of_bit-banging_the_I2C_protocol
 *
 * API: see description for functions i2c_write_byte and i2c_read_byte
 * 
 * It is needed to initialize the sda and scl gpio ports.
 *
 * TODO: update for generic RTC gpio port
 */

#include "soc/rtc_io_reg.h"
#include "soc/soc_ulp.h"

#include "stack.S"

/* RTC_GPIO_9 == GPIO_32 */
#define SCL_GPIO 9
/* RTC_GPIO_8 == GPIO_33 */
#define SDA_GPIO 8

.bss
i2c_started:
	.long 0

i2c_initialized:
	.long 0

.text

.global i2c_write_byte
.global i2c_read_byte

.macro I2C_delay
	/* 38 is around the minimal 4.7us */
	wait 50
.endm

/* Return current level of SCL line, 0 or 1 */
.macro read_SCL
	READ_RTC_REG(RTC_GPIO_IN_REG, RTC_GPIO_IN_NEXT_S + SCL_GPIO, 1)
.endm

/* Return current level of SDA line, 0 or 1 */
.macro read_SDA 
	READ_RTC_REG(RTC_GPIO_IN_REG, RTC_GPIO_IN_NEXT_S + SDA_GPIO, 1)
.endm
 
/* Do not drive SCL (set pin high-impedance) */
.macro set_SCL
	WRITE_RTC_REG(RTC_GPIO_ENABLE_W1TC_REG, RTC_GPIO_ENABLE_W1TC_S + SCL_GPIO, 1, 1)
.endm

 /* Actively drive SCL signal low */
.macro clear_SCL
	/* Output mode */
	WRITE_RTC_REG(RTC_GPIO_ENABLE_W1TS_REG, RTC_GPIO_ENABLE_W1TS_S + SCL_GPIO, 1, 1)
.endm

 /* Do not drive SDA (set pin high-impedance) */
.macro set_SDA
	WRITE_RTC_REG(RTC_GPIO_ENABLE_W1TC_REG, RTC_GPIO_ENABLE_W1TC_S + SDA_GPIO, 1, 1)
.endm

 /* Actively drive SDA signal low */
.macro clear_SDA
	/* Output mode */
	WRITE_RTC_REG(RTC_GPIO_ENABLE_W1TS_REG, RTC_GPIO_ENABLE_W1TS_S + SDA_GPIO, 1, 1)
.endm


i2c_start_cond:
	/* if(i2c_initialized) */
	move r1,i2c_initialized
	ld r0,r1,0
	jumpr initialized,1,ge

	/* i2c_initialzied = 1 */
	move r0,1
	st r0,r1,0

	/* set GPIO to pull low when activated */
	WRITE_RTC_REG(RTC_GPIO_OUT_REG, RTC_GPIO_OUT_DATA_S + SCL_GPIO, 1, 0)
	WRITE_RTC_REG(RTC_GPIO_OUT_REG, RTC_GPIO_OUT_DATA_S + SDA_GPIO, 1, 0)
initialized:
	/* if(i2c_started) */
	move r2,i2c_started
	ld r0,r2,0
	jumpr not_started,1,lt

	/* if started, do a restart condition */
	/* SDA = 1 */
	set_SDA
	I2C_delay
	/* SCL = 1 */
	set_SCL

	/* while(SCL != 1) */
clock_stretch_start:
	read_SCL
	jumpr clock_stretch_start,1,lt

	/* Repeated start setup time, minimum 4.7us */
	I2C_delay
not_started:
	/* SCL == 1, set SDA from 1 to 0 */
	clear_SDA

	I2C_delay
	/* SCL = 0 */
	clear_SCL

	/* i2c_started = 1 */
	move r0,1
	st r0,r2,0

	ret

i2c_stop_cond:
	/* SDA = 0 */
	clear_SDA

	I2C_delay

	/* SCL = 1 */
	set_SCL

	/* while(SCL != 1) */
clock_stretch_stop:
	read_SCL
	jumpr clock_stretch_stop,1,lt

	/* stop bit setup time, minimum 4us */
	I2C_delay

	/* SCL == 1, set SDA from 0 to 1 */
	set_SDA

	I2C_delay

	/* i2c_started = 0 */
 	move r2,i2c_started
 	move r0,0
 	st r0,r2,0

 	ret

/* 
 * Write a bit to I2C bus
 * arg0: (r0 & 0x1) bit
 */
i2c_write_bit:
	/* if( r0 == 1) */
	jumpr bit0,1,lt
	/* then SDA = 1*/
	set_SDA
	jump bit1
bit0:
	/* else SDA = 0 */
	clear_SDA
bit1:
	/* SDA change propagation delay */
	I2C_delay
	/* Set SCL high to indicate a new valid SDA value is available */
	set_SCL
	/* Wait for SDA value to be read by slave, minimum of 4us for standard mode */
	I2C_delay

	/* while(SCL != 1) */
clock_stretch_write:
	read_SCL
	jumpr clock_stretch_write,1,lt

	/* SCL is high, now data is valid */

 	/* Clear the SCL to low in preparation for next change */
 	clear_SCL

 	ret

/*
 * Read a bit from I2C bus
 * ret: (r0 & 0x1) bit
 */
i2c_read_bit:
	/* Let the slave drive data */
	set_SDA

	/* Wait for SDA value to be written by slave, minimum of 4us for standard mode */
	I2C_delay

	/* Set SCL high to indicate a new valid SDA value is available */
 	set_SCL

	/* while(SCL != 1) */
clock_stretch_read:
	read_SCL
	jumpr clock_stretch_read,1,lt

	/* Wait for SDA value to be written by slave, minimum of 4us for standard mode */
	I2C_delay
	/* SCL is high, read out bit */
	read_SDA
	/* Set SCL low in preparation for next operation */
	clear_SCL

	/* r0 = i2c_read_bit */
	ret

/*
 * Write a byte to I2C bus. Return 0 if ack by the slave.
 * arg0: (r0 & 0x1) send_start
 * arg1: (r0 & 0x2) send_stop
 * arg2: (r0 & 0xff00) byte
 * ret: (r0 & 0x1) nack
 */
i2c_write_byte:
	push r0
	/* if(send_start) { */
	and r0,r0,0x1
	jumpr write_no_start,1,lt
	
	call i2c_start_cond
	/* } */
write_no_start:
	/* for (bit = 0; bit < 8; bit++) { */
	top r1
	rsh r1,r1,8
	stage_rst
next_bit:
	and r0,r1,0x80

	/* write bit in r0 */
	call i2c_write_bit

	/* shift */
	lsh r1,r1,1

	/* bit++ */
	stage_inc 1
	jumps next_bit,8,lt
	/* } */

	call i2c_read_bit
	move r1,r0

	/* if(send_stop)*/
	pop r0
	and r0,r0,0x2
	jumpr write_no_stop,2,lt

	call i2c_stop_cond
	/* } */
write_no_stop:

	/* return nack */
	and r0,r1,1
	ret

/*
 * Read a byte from I2C bus
 * arg0: (r0 & 0x1) nack  
 * arg1: (r0 & 0x2) send_stop  
 * ret: (r0 & 0xff) byte
 */
i2c_read_byte:
	/* save args */
	push r0

	/* for (bit = 0; bit < 8; bit++) { */
	stage_rst
	move r1,0
next_bit_read:
	/* read bit to r0 */
	call i2c_read_bit

	/* shift r1 and save bit */
	lsh r1,r1,1
	or r1,r1,r0

	/* bit++ */
	stage_inc 1
	jumps next_bit_read,8,lt
	/* } */

	/* write_bit(nack) */
	top r2
	and r0,r2,0x1
	call i2c_write_bit

	/* if(send_stop) {*/
	pop r2
	and r0,r2,0x2
	jumpr read_no_stop,2,lt
	call i2c_stop_cond
	/* } */
read_no_stop:

	/* return(byte) */
	move r0,r1
	ret
