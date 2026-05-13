######################################
# GD32F470VET6 Makefile
# ARM GCC 工程模板
######################################

# 工程名称
TARGET = app

# 编译器
PREFIX = arm-none-eabi-
CC  = $(PREFIX)gcc
AS  = $(PREFIX)gcc -x assembler-with-cpp
CP  = $(PREFIX)objcopy
SZ  = $(PREFIX)size

# 芯片参数
CPU = -mcpu=cortex-m4
FPU = -mfpu=fpv4-sp-d16
FLOAT-ABI = -mfloat-abi=hard
MCU = $(CPU) -mthumb $(FPU) $(FLOAT-ABI)

######################################
# 路径配置
# 请根据实际 GD32 标准库路径修改
######################################

# GD32 标准库根目录（需要用户修改）
GD32_LIB_DIR = ../GD32F4xx_Firmware_Library

# 标准库子目录
GD32_CMSIS    = $(GD32_LIB_DIR)/CMSIS
GD32_STD_PERIPH = $(GD32_LIB_DIR)/GD32F4xx_standard_peripheral

######################################
# 源文件
######################################

# 启动文件
ASM_SOURCES = $(GD32_CMSIS)/GD32F4xx/Source/ARM/startup_gd32f470.s

# C 源文件
C_SOURCES =  \
src/main.c \
src/system_gd32f4xx.c \
src/gd32f4xx_it.c \
src/retarget.c \
src/systick.c

# 标准库源文件（按需添加，此处列出常用外设）
C_SOURCES += \
$(GD32_STD_PERIPH)/Source/gd32f4xx_gpio.c \
$(GD32_STD_PERIPH)/Source/gd32f4xx_rcu.c \
$(GD32_STD_PERIPH)/Source/gd32f4xx_usart.c \
$(GD32_STD_PERIPH)/Source/gd32f4xx_misc.c
# 按需添加更多外设源文件：
# $(GD32_STD_PERIPH)/Source/gd32f4xx_timer.c
# $(GD32_STD_PERIPH)/Source/gd32f4xx_spi.c
# $(GD32_STD_PERIPH)/Source/gd32f4xx_i2c.c
# $(GD32_STD_PERIPH)/Source/gd32f4xx_adc.c
# $(GD32_STD_PERIPH)/Source/gd32f4xx_dma.c
# $(GD32_STD_PERIPH)/Source/gd32f4xx_exti.c
# $(GD32_STD_PERIPH)/Source/gd32f4xx_syscfg.c

######################################
# 头文件路径
######################################

C_INCLUDES =  \
-Iinc \
-I$(GD32_CMSIS)/GD32F4xx/Include \
-I$(GD32_CMSIS) \
-I$(GD32_STD_PERIPH)/Include

######################################
# 编译选项
######################################

# 宏定义
C_DEFS = -DGD32F470 -DUSE_STDPERIPH_DRIVER

# 编译标志
CFLAGS = $(MCU) $(C_DEFS) $(C_INCLUDES) -Wall -fdata-sections -ffunction-sections -Os -g
ASFLAGS = $(MCU) -Wall -fdata-sections -ffunction-sections

# 链接脚本
LDSCRIPT = gd32f470vet6_flash.ld

# 链接标志
LIBS = -lc -lm -lnosys
LDFLAGS = $(MCU) -specs=nano.specs -T$(LDSCRIPT) $(LIBS) -Wl,-Map=$(BUILD_DIR)/$(TARGET).map,--cref -Wl,--gc-sections

######################################
# 构建
######################################

BUILD_DIR = build

OBJECTS = $(addprefix $(BUILD_DIR)/,$(notdir $(C_SOURCES:.c=.o)))
vpath %.c $(sort $(dir $(C_SOURCES)))

OBJECTS += $(addprefix $(BUILD_DIR)/,$(notdir $(ASM_SOURCES:.s=.o)))
vpath %.s $(sort $(dir $(ASM_SOURCES)))

all: $(BUILD_DIR)/$(TARGET).elf $(BUILD_DIR)/$(TARGET).hex $(BUILD_DIR)/$(TARGET).bin
	$(SZ) $(BUILD_DIR)/$(TARGET).elf

$(BUILD_DIR)/%.o: %.c Makefile | $(BUILD_DIR)
	$(CC) -c $(CFLAGS) $< -o $@

$(BUILD_DIR)/%.o: %.s Makefile | $(BUILD_DIR)
	$(AS) -c $(ASFLAGS) $< -o $@

$(BUILD_DIR)/$(TARGET).elf: $(OBJECTS) Makefile
	$(CC) $(OBJECTS) $(LDFLAGS) -o $@

$(BUILD_DIR)/%.hex: $(BUILD_DIR)/%.elf | $(BUILD_DIR)
	$(CP) -O ihex $< $@

$(BUILD_DIR)/%.bin: $(BUILD_DIR)/%.elf | $(BUILD_DIR)
	$(CP) -O binary -S $< $@

$(BUILD_DIR):
	mkdir -p $@

clean:
	rm -rf $(BUILD_DIR)

.PHONY: all clean
