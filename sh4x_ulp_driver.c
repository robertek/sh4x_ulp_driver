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

#include <stdio.h>
#include "esp_sleep.h"
#include "driver/gpio.h"
#include "driver/rtc_io.h"
#include "esp32/ulp.h"

#include "ulp_sh4x_ulp_driver.h"
#include "sh4x_ulp_driver.h"


extern const uint8_t ulp_bin_start[]
    asm("_binary_ulp_sh4x_ulp_driver_bin_start");
extern const uint8_t ulp_bin_end[]
    asm("_binary_ulp_sh4x_ulp_driver_bin_end");


#define temp_msb ((uint8_t) ulp_temp_msb)
#define temp_lsb ((uint8_t) ulp_temp_lsb)
#define humi_msb ((uint8_t) ulp_humi_msb)
#define humi_lsb ((uint8_t) ulp_humi_lsb)

int sh4x_ulp_setup( sh4x_ulp_config_t * config )
{
	gpio_num_t gpio_scl, gpio_sda;

	/* setup the GPIOs */
	gpio_scl = GPIO_NUM_32;
	rtc_gpio_init(gpio_scl);
	rtc_gpio_set_direction(gpio_scl, RTC_GPIO_MODE_INPUT_ONLY);

	gpio_sda = GPIO_NUM_33;
	rtc_gpio_init(gpio_sda);
	rtc_gpio_set_direction(gpio_sda, RTC_GPIO_MODE_INPUT_ONLY);

	/* Load the ulp code */
	ESP_ERROR_CHECK(ulp_load_binary(0, ulp_bin_start, 
	    (ulp_bin_end - ulp_bin_start) / sizeof(uint32_t)));

	/* Set the temp and humi thresholds */
	if (config && config->t_diff) {
		ulp_t_diff = config->t_diff;
	} else {
		ulp_t_diff = DEFAULT_T_DIFF;
	}

	if (config && config->h_diff) {
		ulp_h_diff = config->h_diff;
	} else {
		ulp_h_diff = DEFAULT_H_DIFF;
	}

	/* Set ulp wakeup period to 1s and set the read period */
	ulp_set_wakeup_period(0, 1000*1000);

	if (config && config->period) {
		ulp_period = config->period;
	} else {
		ulp_period = DEFAULT_PERIOD;
	}

	/* Set measurement type */
	if (config && config->meas) {
		if (config->meas == SH4X_COM_MEAS_LR ||
		    config->meas == SH4X_COM_MEAS_MR ||
		    config->meas == SH4X_COM_MEAS_HR) {
			ulp_sh4x_meas = config->meas;
		} else {
			printf("Unknwon SH4x measurement type\n");
		}

	} else {
		ulp_sh4x_meas = DEFAULT_MEAS;
	}

	return(0);
}

float sh4x_ulp_get_temp()
{
	uint32_t raw_t = (uint32_t)((temp_msb << 8) | temp_lsb);
	float temp = 175*((float)raw_t/0xffff) - 45; 
	
	/*
	printf("raw_t = 0x%x\n", raw_t);	
	*/

	return(temp);
}


float sh4x_ulp_get_humi()
{
	uint32_t raw_h = (uint32_t)((humi_msb << 8) | humi_lsb);
	float humi = 125*((float)raw_h/0xffff) - 6;

	/*
	printf("raw_h = 0x%x\n", raw_h);	
	*/

	if (humi < 0) {
		humi = 0;
	}

	if (humi > 100) {
		humi = 100;
	}

	return(humi);
}

void sh4x_ulp_enable()
{
	ESP_ERROR_CHECK( esp_sleep_enable_ulp_wakeup() );
	ESP_ERROR_CHECK(
	    ulp_run((&ulp_entry - RTC_SLOW_MEM) / sizeof(uint32_t)) );
}
