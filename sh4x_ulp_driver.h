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

/* measurement types*/
#define SH4X_COM_MEAS_HR 0xFD
#define SH4X_COM_MEAS_MR 0xF6
#define SH4X_COM_MEAS_LR 0xE0

/* default values */
#define DEFAULT_MEAS SH4X_COM_MEAS_HR
#define DEFAULT_T_DIFF 0x20
#define DEFAULT_H_DIFF 0x40
#define DEFAULT_PERIOD 5


typedef struct sh4x_ulp_config {
	int meas;
	int t_diff;
	int h_diff;
	int period;
} sh4x_ulp_config_t;

int sh4x_ulp_setup(sh4x_ulp_config_t *);
float sh4x_ulp_get_temp();
float sh4x_ulp_get_humi();
void sh4x_ulp_enable();
