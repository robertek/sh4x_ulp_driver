# sh4x_ulp_driver

ESP32 ULP driver for SH4x sensor.
It is plain ulp code and c api for inclusion in other project requiring to
collect SH4x through ULP coprocessor.
Targeted mainly for battery powered sensors.

## api

## sample code

Include the driver in your code:

    $ cd path/to/my/project
    $ git clone https://github.com/robertek/sh4x_ulp_driver
    $ ls
    sh4x_ulp_driver CMakeLists.txt  main  sdkconfig

Update the CMakeLists to include the driver

    $ cat main/CMakeLists.txt
    idf_component_register(SRCS "sh4x_ulp_example"
                    INCLUDE_DIRS "." "../sh4x_ulp_driver/"
                    REQUIRES soc)
    $ cat CMakeLists.txt
    cmake_minimum_required(VERSION 3.5)
    
    set(EXTRA_COMPONENT_DIRS ./sh4x_ulp_driver)
    
    include($ENV{IDF_PATH}/tools/cmake/project.cmake)
    project(sh4x_ulp_example)

You may test it with this example code

    $ cat main/sh4x_ulp_example.c
    #include <stdio.h>
    #include "esp_sleep.h"
    #include "freertos/FreeRTOS.h"
    #include "freertos/task.h"
    
    #include "sh4x_ulp_driver.h"
    
    void app_main()
    {
          if (esp_sleep_get_wakeup_cause() != ESP_SLEEP_WAKEUP_ULP) {
                  sh4x_ulp_setup( NULL );
          } else {
                  printf("Temp: %.2f C\n", sh4x_ulp_get_temp());
                  printf("Humidity: %.2f %\n", sh4x_ulp_get_humi());
          }

          sh4x_ulp_enable();
          vTaskDelay(20);
          esp_deep_sleep_start();
    }



## Credits

Most credits went to Tom Vijlbrief and his i2c implementation I have based on (and fine tuned that from the wiki source).
https://github.com/tomtor/ulp-i2c
