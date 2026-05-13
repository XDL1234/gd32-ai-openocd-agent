# GD32F4xx 标准外设库 API 速查手册

> 来源：GD32F4xx_Firmware_Library V3.x
> 适用芯片：GD32F450xx / GD32F470xx 系列
> 离线缓存，RESEARCH/EXECUTE 阶段优先查本文件，无需联网。

---

## 外设总线速查表

| 外设 | 总线 | RCU 时钟常量 |
|---|---|---|
| GPIOA/B/C/D/E/F/G/H/I | AHB1 | RCU_GPIOx |
| DMA0 / DMA1 | AHB1 | RCU_DMA0 / RCU_DMA1 |
| CRC | AHB1 | RCU_CRC |
| ENET（以太网） | AHB1 | RCU_ENET / RCU_ENETTX / RCU_ENETRX |
| DCMI | AHB2 | RCU_DCMI |
| TRNG | AHB2 | RCU_TRNG |
| USBFS | AHB2 | RCU_USBFS |
| USART0 | APB2 | RCU_USART0 |
| USART5 | APB2 | RCU_USART5 |
| SPI0 / SPI4 / SPI5 | APB2 | RCU_SPI0 / RCU_SPI4 / RCU_SPI5 |
| TIMER0 | APB2 | RCU_TIMER0 |
| TIMER7 / TIMER8 / TIMER9 / TIMER10 | APB2 | RCU_TIMERx |
| ADC0 / ADC1 / ADC2 | APB2 | RCU_ADCx |
| SYSCFG | APB2 | RCU_SYSCFG |
| USART1 / USART2 | APB1 | RCU_USART1 / RCU_USART2 |
| UART3 / UART4 | APB1 | RCU_UART3 / RCU_UART4 |
| SPI1 / SPI2 | APB1 | RCU_SPI1 / RCU_SPI2 |
| I2C0 / I2C1 / I2C2 | APB1 | RCU_I2C0 / RCU_I2C1 / RCU_I2C2 |
| TIMER1 / TIMER2 / TIMER3 / TIMER4 / TIMER5 / TIMER6 | APB1 | RCU_TIMERx |
| TIMER11 / TIMER12 / TIMER13 | APB1 | RCU_TIMERx |
| CAN0 / CAN1 | APB1 | RCU_CAN0 / RCU_CAN1 |
| DAC | APB1 | RCU_DAC |

> **总线频率**（SYSCLK = 200MHz）：AHB = 200MHz, APB2 = 100MHz, APB1 = 50MHz
> **定时器时钟**：APB2 定时器 = 200MHz（×2），APB1 定时器 = 100MHz（×2）

> **GD32 vs STM32 编号对照**：GD32 外设从 0 开始编号。USART0 = STM32 USART1，TIMER0 = STM32 TIM1，SPI0 = STM32 SPI1，I2C0 = STM32 I2C1，以此类推。

---

## RCU 时钟控制

### 常用函数

```c
void rcu_periph_clock_enable(rcu_periph_enum periph);
void rcu_periph_clock_disable(rcu_periph_enum periph);
void rcu_periph_reset_enable(rcu_periph_enum periph);
void rcu_periph_reset_disable(rcu_periph_enum periph);
void rcu_pll_config(uint32_t pll_src, uint32_t pll_psc, uint32_t pll_n,
                    uint32_t pll_p, uint32_t pll_q);
void rcu_system_clock_source_config(uint32_t ck_sys);
uint32_t rcu_system_clock_source_get(void);
void rcu_ahb_clock_config(uint32_t ck_ahb);
void rcu_apb1_clock_config(uint32_t ck_apb1);
void rcu_apb2_clock_config(uint32_t ck_apb2);
void rcu_osci_on(rcu_osci_type_enum osci);
void rcu_osci_stab_wait(rcu_osci_type_enum osci);
FlagStatus rcu_flag_get(rcu_flag_enum flag);
```

### 200MHz 时钟配置（HXTAL 25MHz，GD32F470）

```c
/* system_gd32f4xx.c 中已实现，此处为原理说明 */
rcu_deinit();
rcu_osci_on(RCU_HXTAL);
rcu_osci_stab_wait(RCU_HXTAL);

rcu_pll_config(RCU_PLLSRC_HXTAL, 25, 400, 2, 9);
/* HXTAL=25MHz, /25=1MHz VCO_in, *400=400MHz VCO_out, /2=200MHz SYSCLK */
/* PLLQ: 400/9≈44.4MHz (USB 需 48MHz，另需配置) */

rcu_system_clock_source_config(RCU_CKSYSSRC_PLL);
while(rcu_system_clock_source_get() != RCU_SCSS_PLL);

rcu_ahb_clock_config(RCU_AHB_CKSYS_DIV1);    /* AHB  = 200MHz */
rcu_apb2_clock_config(RCU_APB2_CKAHB_DIV2);   /* APB2 = 100MHz */
rcu_apb1_clock_config(RCU_APB1_CKAHB_DIV4);   /* APB1 = 50MHz  */
```

### 8MHz HXTAL 配置（兼容 STM32 晶振）

```c
rcu_pll_config(RCU_PLLSRC_HXTAL, 8, 400, 2, 9);
/* 8MHz /8=1MHz *400=400MHz /2=200MHz */
```

---

## GPIO 通用输入输出

### 配置函数（无初始化结构体，直接调用）

```c
void gpio_mode_set(uint32_t gpio_periph, uint32_t mode,
                   uint32_t pull_up_down, uint32_t pin);
void gpio_output_options_set(uint32_t gpio_periph, uint8_t otype,
                             uint32_t speed, uint32_t pin);
void gpio_af_set(uint32_t gpio_periph, uint32_t alt_func_num, uint32_t pin);
```

### GPIO 模式速查

| mode 常量 | 含义 | 典型场景 |
|-----------|------|---------|
| GPIO_MODE_INPUT | 输入 | 按键、外部信号 |
| GPIO_MODE_OUTPUT | 通用输出 | LED、继电器 |
| GPIO_MODE_AF | 复用功能 | USART TX/RX、SPI、I2C |
| GPIO_MODE_ANALOG | 模拟 | ADC 输入、DAC 输出 |

| pull_up_down 常量 | 含义 |
|-------------------|------|
| GPIO_PUPD_NONE | 无上下拉（浮空） |
| GPIO_PUPD_PULLUP | 上拉 |
| GPIO_PUPD_PULLDOWN | 下拉 |

| otype 常量 | 含义 |
|------------|------|
| GPIO_OTYPE_PP | 推挽输出 |
| GPIO_OTYPE_OD | 开漏输出 |

| speed 常量 | 速度 |
|------------|------|
| GPIO_OSPEED_2MHZ | 2MHz |
| GPIO_OSPEED_25MHZ | 25MHz |
| GPIO_OSPEED_50MHZ | 50MHz |
| GPIO_OSPEED_200MHZ | 200MHz |

### 读写函数

```c
void gpio_bit_set(uint32_t gpio_periph, uint32_t pin);
void gpio_bit_reset(uint32_t gpio_periph, uint32_t pin);
void gpio_bit_write(uint32_t gpio_periph, uint32_t pin, bit_status bit_value);
void gpio_port_write(uint32_t gpio_periph, uint16_t data);
FlagStatus gpio_input_bit_get(uint32_t gpio_periph, uint32_t pin);
FlagStatus gpio_output_bit_get(uint32_t gpio_periph, uint32_t pin);
uint16_t gpio_input_port_get(uint32_t gpio_periph);
uint16_t gpio_output_port_get(uint32_t gpio_periph);
```

### GPIO AF 映射表

| AF编号 | 功能 | 常量 |
|--------|------|------|
| AF0 | SYS（MCO、SWD、TRACE） | GPIO_AF_0 |
| AF1 | TIMER0、TIMER1 | GPIO_AF_1 |
| AF2 | TIMER2、TIMER3、TIMER4 | GPIO_AF_2 |
| AF3 | TIMER7、TIMER8、TIMER9、TIMER10 | GPIO_AF_3 |
| AF4 | I2C0、I2C1、I2C2 | GPIO_AF_4 |
| AF5 | SPI0、SPI1、SPI2、SPI3、SPI4、SPI5 | GPIO_AF_5 |
| AF6 | SPI2、SPI3（备选映射） | GPIO_AF_6 |
| AF7 | USART0、USART1、USART2 | GPIO_AF_7 |
| AF8 | UART3、UART4、USART5 | GPIO_AF_8 |
| AF9 | CAN0、CAN1、TIMER11、TIMER12、TIMER13 | GPIO_AF_9 |
| AF10 | USBFS、USBHS | GPIO_AF_10 |
| AF11 | ENET（以太网） | GPIO_AF_11 |
| AF12 | EXMC、SDIO | GPIO_AF_12 |
| AF13 | DCMI | GPIO_AF_13 |
| AF14 | TLI（LCD 控制器） | GPIO_AF_14 |
| AF15 | EVENTOUT | GPIO_AF_15 |

### GPIO 典型配置示例

```c
/* LED 推挽输出 (PB2) */
rcu_periph_clock_enable(RCU_GPIOB);
gpio_mode_set(GPIOB, GPIO_MODE_OUTPUT, GPIO_PUPD_NONE, GPIO_PIN_2);
gpio_output_options_set(GPIOB, GPIO_OTYPE_PP, GPIO_OSPEED_50MHZ, GPIO_PIN_2);

/* USART0 TX(PA9) + RX(PA10) 复用功能 */
rcu_periph_clock_enable(RCU_GPIOA);
gpio_af_set(GPIOA, GPIO_AF_7, GPIO_PIN_9);
gpio_af_set(GPIOA, GPIO_AF_7, GPIO_PIN_10);
gpio_mode_set(GPIOA, GPIO_MODE_AF, GPIO_PUPD_PULLUP, GPIO_PIN_9 | GPIO_PIN_10);
gpio_output_options_set(GPIOA, GPIO_OTYPE_PP, GPIO_OSPEED_50MHZ, GPIO_PIN_9);

/* 按键输入，内部上拉 (PA0) */
gpio_mode_set(GPIOA, GPIO_MODE_INPUT, GPIO_PUPD_PULLUP, GPIO_PIN_0);

/* ADC 模拟输入 (PC0) */
gpio_mode_set(GPIOC, GPIO_MODE_ANALOG, GPIO_PUPD_NONE, GPIO_PIN_0);
```

> **与 STM32F1 的关键差异**：GD32F4xx 不使用 GPIO_Init 结构体，而是直接调用 `gpio_mode_set()` + `gpio_output_options_set()`。复用功能必须用 `gpio_af_set()` 显式指定 AF 编号，不再依赖 AFIO 重映射。

---

## USART 串口通信

### 配置函数（无初始化结构体，逐项设置）

```c
void usart_deinit(uint32_t usart_periph);
void usart_baudrate_set(uint32_t usart_periph, uint32_t baudval);
void usart_word_length_set(uint32_t usart_periph, uint32_t wlen);
void usart_stop_bit_set(uint32_t usart_periph, uint32_t stblen);
void usart_parity_config(uint32_t usart_periph, uint32_t paession);
void usart_receive_config(uint32_t usart_periph, uint32_t rxconfig);
void usart_transmit_config(uint32_t usart_periph, uint32_t txconfig);
void usart_enable(uint32_t usart_periph);
void usart_disable(uint32_t usart_periph);
```

### 数据收发

```c
void usart_data_transmit(uint32_t usart_periph, uint32_t data);
uint16_t usart_data_receive(uint32_t usart_periph);
FlagStatus usart_flag_get(uint32_t usart_periph, usart_flag_enum flag);
void usart_flag_clear(uint32_t usart_periph, usart_flag_enum flag);
void usart_interrupt_enable(uint32_t usart_periph, usart_interrupt_enum interrupt);
void usart_interrupt_disable(uint32_t usart_periph, usart_interrupt_enum interrupt);
FlagStatus usart_interrupt_flag_get(uint32_t usart_periph, usart_interrupt_flag_enum int_flag);
void usart_interrupt_flag_clear(uint32_t usart_periph, usart_interrupt_flag_enum int_flag);
void usart_dma_receive_config(uint32_t usart_periph, uint32_t dmacmd);
void usart_dma_transmit_config(uint32_t usart_periph, uint32_t dmacmd);
```

### 常用标志/中断

| 标志 | 含义 |
|------|------|
| USART_FLAG_TBE | 发送数据寄存器空（Transmit Buffer Empty） |
| USART_FLAG_TC | 发送完成（Transmission Complete） |
| USART_FLAG_RBNE | 接收数据寄存器非空（Read Buffer Not Empty） |
| USART_FLAG_IDLE | 空闲帧检测 |
| USART_FLAG_ORERR | 溢出错误 |
| USART_INT_RBNE | 接收中断 |
| USART_INT_TBE | 发送缓冲区空中断 |
| USART_INT_TC | 发送完成中断 |
| USART_INT_IDLE | 空闲中断 |

> **注意**：GD32 用 `USART_FLAG_TBE`/`USART_FLAG_RBNE`，STM32 用 `USART_FLAG_TXE`/`USART_FLAG_RXNE`，名称不同但功能相同。

### 默认引脚分配

| 外设 | TX | RX | AF | 总线 |
|------|----|----|-----|------|
| USART0 | PA9 | PA10 | AF7 | APB2 |
| USART1 | PA2 | PA3 | AF7 | APB1 |
| USART2 | PB10 | PB11 | AF7 | APB1 |
| UART3 | PC10 | PC11 | AF8 | APB1 |
| UART4 | PC12 | PD2 | AF8 | APB1 |
| USART5 | PC6 | PC7 | AF8 | APB2 |

### USART0 115200 典型初始化

```c
rcu_periph_clock_enable(RCU_GPIOA);
rcu_periph_clock_enable(RCU_USART0);

gpio_af_set(GPIOA, GPIO_AF_7, GPIO_PIN_9 | GPIO_PIN_10);
gpio_mode_set(GPIOA, GPIO_MODE_AF, GPIO_PUPD_PULLUP, GPIO_PIN_9 | GPIO_PIN_10);
gpio_output_options_set(GPIOA, GPIO_OTYPE_PP, GPIO_OSPEED_50MHZ, GPIO_PIN_9);

usart_deinit(USART0);
usart_baudrate_set(USART0, 115200U);
usart_word_length_set(USART0, USART_WL_8BIT);
usart_stop_bit_set(USART0, USART_STB_1BIT);
usart_parity_config(USART0, USART_PM_NONE);
usart_receive_config(USART0, USART_RECEIVE_ENABLE);
usart_transmit_config(USART0, USART_TRANSMIT_ENABLE);
usart_enable(USART0);
```

### printf 重定向

```c
int fputc(int ch, FILE *f) {
    usart_data_transmit(USART0, (uint8_t)ch);
    while(RESET == usart_flag_get(USART0, USART_FLAG_TBE));
    return ch;
}
```

---

## SPI 串行外设接口

### 初始化结构体

```c
typedef struct {
    uint32_t device_mode;          /* SPI_MASTER / SPI_SLAVE */
    uint32_t trans_mode;           /* SPI_TRANSMODE_FULLDUPLEX / _RECEIVEONLY / _BDRECEIVE / _BDTRANSMIT */
    uint32_t frame_size;           /* SPI_FRAMESIZE_8BIT / SPI_FRAMESIZE_16BIT */
    uint32_t nss;                  /* SPI_NSS_SOFT / SPI_NSS_HARD */
    uint32_t clock_polarity_phase; /* SPI_CK_PL_LOW_PH_1EDGE (Mode0) / _PH_2EDGE (Mode1)
                                      SPI_CK_PL_HIGH_PH_1EDGE (Mode2) / _PH_2EDGE (Mode3) */
    uint32_t prescale;             /* SPI_PSC_2/4/8/16/32/64/128/256 */
    uint32_t endian;               /* SPI_ENDIAN_MSB / SPI_ENDIAN_LSB */
} spi_parameter_struct;
```

### 常用函数

```c
void spi_init(uint32_t spi_periph, spi_parameter_struct *spi_struct);
void spi_enable(uint32_t spi_periph);
void spi_disable(uint32_t spi_periph);
void spi_i2s_data_transmit(uint32_t spi_periph, uint16_t data);
uint16_t spi_i2s_data_receive(uint32_t spi_periph);
FlagStatus spi_i2s_flag_get(uint32_t spi_periph, uint32_t flag);
void spi_i2s_interrupt_enable(uint32_t spi_periph, uint8_t interrupt);
void spi_i2s_interrupt_disable(uint32_t spi_periph, uint8_t interrupt);
void spi_nss_output_enable(uint32_t spi_periph);
void spi_nss_internal_high(uint32_t spi_periph);
void spi_dma_enable(uint32_t spi_periph, uint8_t dma);
```

### SPI 模式速查

| 模式 | 常量 | CPOL | CPHA | 说明 |
|------|------|------|------|------|
| Mode 0 | SPI_CK_PL_LOW_PH_1EDGE | Low | 1Edge | 最常用 |
| Mode 1 | SPI_CK_PL_LOW_PH_2EDGE | Low | 2Edge | |
| Mode 2 | SPI_CK_PL_HIGH_PH_1EDGE | High | 1Edge | |
| Mode 3 | SPI_CK_PL_HIGH_PH_2EDGE | High | 2Edge | W25Qxx Flash |

### 常用标志

| 标志 | 含义 |
|------|------|
| SPI_FLAG_TBE | 发送缓冲区空 |
| SPI_FLAG_RBNE | 接收缓冲区非空 |
| SPI_FLAG_TRANS | 传输进行中 |
| SPI_FLAG_CONFERR | 配置错误 |

### 默认引脚分配

| 外设 | SCK | MISO | MOSI | NSS | AF | 总线 |
|------|-----|------|------|-----|-----|------|
| SPI0 | PA5 | PA6 | PA7 | PA4 | AF5 | APB2 |
| SPI1 | PB13 | PB14 | PB15 | PB12 | AF5 | APB1 |
| SPI2 | PC10 | PC11 | PC12 | PA15 | AF6 | APB1 |

---

## I2C 总线

### 配置函数

```c
void i2c_clock_config(uint32_t i2c_periph, uint32_t clkspeed, uint32_t dutycyc);
void i2c_mode_addr_config(uint32_t i2c_periph, uint32_t mode,
                          uint32_t addformat, uint32_t addr);
void i2c_enable(uint32_t i2c_periph);
void i2c_disable(uint32_t i2c_periph);
void i2c_ack_config(uint32_t i2c_periph, uint32_t ack);
```

### 数据传输

```c
void i2c_start_on_bus(uint32_t i2c_periph);
void i2c_stop_on_bus(uint32_t i2c_periph);
void i2c_data_transmit(uint32_t i2c_periph, uint8_t data);
uint8_t i2c_data_receive(uint32_t i2c_periph);
FlagStatus i2c_flag_get(uint32_t i2c_periph, i2c_flag_enum flag);
void i2c_flag_clear(uint32_t i2c_periph, i2c_flag_enum flag);
void i2c_interrupt_enable(uint32_t i2c_periph, uint32_t interrupt);
void i2c_dma_enable(uint32_t i2c_periph, uint32_t dmastate);
```

### 常用标志

| 标志 | 含义 |
|------|------|
| I2C_FLAG_SBSEND | 起始条件已发送 |
| I2C_FLAG_ADDSEND | 地址已发送/匹配 |
| I2C_FLAG_BTC | 字节传输完成 |
| I2C_FLAG_TBE | 发送缓冲区空 |
| I2C_FLAG_RBNE | 接收缓冲区非空 |
| I2C_FLAG_I2CBSY | 总线忙 |

### I2C 主机发送典型流程

```c
/* 等待总线空闲 */
while(i2c_flag_get(I2C0, I2C_FLAG_I2CBSY));
/* 发送起始条件 */
i2c_start_on_bus(I2C0);
while(!i2c_flag_get(I2C0, I2C_FLAG_SBSEND));
/* 发送从机地址（写） */
i2c_master_addressing(I2C0, slave_addr, I2C_TRANSMITTER);
while(!i2c_flag_get(I2C0, I2C_FLAG_ADDSEND));
i2c_flag_clear(I2C0, I2C_FLAG_ADDSEND);
/* 发送数据 */
i2c_data_transmit(I2C0, data);
while(!i2c_flag_get(I2C0, I2C_FLAG_TBE));
/* 发送停止条件 */
i2c_stop_on_bus(I2C0);
```

### 默认引脚分配

| 外设 | SCL | SDA | AF |
|------|-----|-----|-----|
| I2C0 | PB6 | PB7 | AF4 |
| I2C1 | PB10 | PB11 | AF4 |
| I2C2 | PA8 | PC9 | AF4 |

> **dutycyc 参数**：标准模式(≤100kHz)用 `I2C_DTCY_2`，快速模式(≤400kHz)用 `I2C_DTCY_2` 或 `I2C_DTCY_16_9`

---

## DMA 直接内存访问

> GD32F4xx 使用基于通道+子外设的 DMA 架构（类似 STM32F4 的 stream+channel），共 DMA0(8通道) + DMA1(8通道)。

### 单数据模式初始化结构体

```c
typedef struct {
    uint32_t periph_addr;         /* 外设地址，如 (uint32_t)&USART_DATA(USART0) */
    uint32_t periph_inc;          /* DMA_PERIPH_INCREASE_ENABLE / _DISABLE */
    uint32_t memory0_addr;        /* 内存缓冲区地址 */
    uint32_t memory_inc;          /* DMA_MEMORY_INCREASE_ENABLE / _DISABLE */
    uint32_t periph_memory_width; /* DMA_PERIPH_WIDTH_8BIT / _16BIT / _32BIT */
    uint32_t circular_mode;       /* DMA_CIRCULAR_MODE_ENABLE / _DISABLE */
    uint32_t direction;           /* DMA_PERIPH_TO_MEMORY / DMA_MEMORY_TO_PERIPH / DMA_MEMORY_TO_MEMORY */
    uint32_t number;              /* 传输数据量 */
    uint32_t priority;            /* DMA_PRIORITY_LOW / _MEDIUM / _HIGH / _ULTRA_HIGH */
} dma_single_data_parameter_struct;
```

### 常用函数

```c
void dma_deinit(uint32_t dma_periph, dma_channel_enum channelx);
void dma_single_data_mode_init(uint32_t dma_periph, dma_channel_enum channelx,
                               dma_single_data_parameter_struct *init_struct);
void dma_channel_enable(uint32_t dma_periph, dma_channel_enum channelx);
void dma_channel_disable(uint32_t dma_periph, dma_channel_enum channelx);
void dma_channel_subperipheral_select(uint32_t dma_periph, dma_channel_enum channelx,
                                      dma_subperipheral_enum sub_periph);
void dma_transfer_number_config(uint32_t dma_periph, dma_channel_enum channelx, uint32_t number);
uint32_t dma_transfer_number_get(uint32_t dma_periph, dma_channel_enum channelx);
FlagStatus dma_flag_get(uint32_t dma_periph, dma_channel_enum channelx, uint32_t flag);
void dma_flag_clear(uint32_t dma_periph, dma_channel_enum channelx, uint32_t flag);
void dma_interrupt_enable(uint32_t dma_periph, dma_channel_enum channelx, uint32_t source);
void dma_interrupt_disable(uint32_t dma_periph, dma_channel_enum channelx, uint32_t source);
```

### DMA 常用通道-子外设映射（节选）

| DMA | 通道 | 子外设 | 外设请求 |
|-----|------|--------|---------|
| DMA0 | CH0 | SUB_PERIPH_0 | SPI2_RX |
| DMA0 | CH2 | SUB_PERIPH_3 | SPI0_RX |
| DMA0 | CH3 | SUB_PERIPH_3 | SPI0_TX |
| DMA0 | CH3 | SUB_PERIPH_4 | USART2_TX |
| DMA0 | CH5 | SUB_PERIPH_3 | SPI0_TX |
| DMA0 | CH1 | SUB_PERIPH_4 | USART2_RX |
| DMA1 | CH2 | SUB_PERIPH_4 | USART0_RX |
| DMA1 | CH5 | SUB_PERIPH_4 | USART0_RX |
| DMA1 | CH6 | SUB_PERIPH_4 | USART0_TX |
| DMA1 | CH7 | SUB_PERIPH_4 | USART0_TX |
| DMA0 | CH0 | SUB_PERIPH_0 | SPI2_RX |
| DMA1 | CH0 | SUB_PERIPH_0 | ADC0 |
| DMA1 | CH2 | SUB_PERIPH_1 | ADC1 |
| DMA1 | CH0 | SUB_PERIPH_2 | ADC2 |

> **关键**：必须用 `dma_channel_subperipheral_select()` 选择正确的子外设编号，否则 DMA 请求无法路由。查阅数据手册 DMA 请求映射表确认具体通道。

---

## TIMER 定时器

### 时基初始化结构体

```c
typedef struct {
    uint16_t prescaler;         /* 预分频器 PSC，0~65535 */
    uint16_t alignedmode;       /* TIMER_COUNTER_EDGE / _CENTER_DOWN / _CENTER_UP / _CENTER_BOTH */
    uint16_t counterdirection;  /* TIMER_COUNTER_UP / TIMER_COUNTER_DOWN */
    uint32_t period;            /* 自动重载值 ARR，0~65535（32位定时器可达 0xFFFFFFFF） */
    uint16_t clockdivision;     /* TIMER_CKDIV_DIV1 / _DIV2 / _DIV4 */
    uint8_t  repetitioncounter; /* 仅 TIMER0/TIMER7 有效 */
} timer_parameter_struct;
```

### 输出比较（PWM）结构体

```c
typedef struct {
    uint16_t outputstate;      /* TIMER_CCX_ENABLE / _DISABLE */
    uint16_t outputnstate;     /* TIMER_CCXN_ENABLE / _DISABLE（互补输出，仅高级定时器） */
    uint32_t ocpolarity;       /* TIMER_OC_POLARITY_HIGH / _LOW */
    uint32_t ocnpolarity;      /* TIMER_OCN_POLARITY_HIGH / _LOW */
    uint32_t ocidlestate;      /* TIMER_OC_IDLE_STATE_HIGH / _LOW */
    uint32_t ocnidlestate;     /* TIMER_OCN_IDLE_STATE_HIGH / _LOW */
} timer_oc_parameter_struct;
```

### 常用函数

```c
/* 时基 */
void timer_deinit(uint32_t timer_periph);
void timer_init(uint32_t timer_periph, timer_parameter_struct *initpara);
void timer_enable(uint32_t timer_periph);
void timer_disable(uint32_t timer_periph);
void timer_auto_reload_shadow_enable(uint32_t timer_periph);

/* PWM 输出 */
void timer_channel_output_config(uint32_t timer_periph, uint16_t channel,
                                 timer_oc_parameter_struct *ocpara);
void timer_channel_output_pulse_value_config(uint32_t timer_periph,
                                             uint16_t channel, uint32_t pulse);
void timer_channel_output_mode_config(uint32_t timer_periph,
                                      uint16_t channel, uint16_t ocmode);
void timer_channel_output_shadow_config(uint32_t timer_periph,
                                        uint16_t channel, uint16_t ocshadow);
void timer_primary_output_config(uint32_t timer_periph, ControlStatus newvalue);

/* 输入捕获 */
void timer_input_capture_config(uint32_t timer_periph, uint16_t channel,
                                timer_ic_parameter_struct *icpara);
uint32_t timer_channel_capture_value_register_read(uint32_t timer_periph, uint16_t channel);

/* 中断 */
void timer_interrupt_enable(uint32_t timer_periph, uint32_t interrupt);
void timer_interrupt_disable(uint32_t timer_periph, uint32_t interrupt);
FlagStatus timer_interrupt_flag_get(uint32_t timer_periph, uint32_t interrupt);
void timer_interrupt_flag_clear(uint32_t timer_periph, uint32_t interrupt);
FlagStatus timer_flag_get(uint32_t timer_periph, uint32_t flag);
void timer_flag_clear(uint32_t timer_periph, uint32_t flag);
```

### 定时器频率计算

```
更新频率 = TIMERxCLK / (prescaler + 1) / (period + 1)

示例：1ms 中断（TIMER1，APB1 定时器时钟 = 100MHz）
  prescaler = 9999, period = 9  →  100MHz / 10000 / 10 = 1000Hz = 1ms

示例：50Hz PWM（20ms 周期，用于舵机，TIMER0，APB2 定时器时钟 = 200MHz）
  prescaler = 199, period = 19999  →  200MHz / 200 / 20000 = 50Hz
  占空比 = pulse / (period + 1)
```

### 常用中断标志

| 标志 | 含义 |
|------|------|
| TIMER_INT_UP | 更新中断（计数溢出） |
| TIMER_INT_CH0 ~ CH3 | 捕获/比较通道 0~3 中断 |
| TIMER_INT_TRG | 触发中断 |

### TIMER PWM 默认引脚

| 定时器 | CH0 | CH1 | CH2 | CH3 | AF |
|--------|-----|-----|-----|-----|-----|
| TIMER0 | PA8 | PA9 | PA10 | PA11 | AF1 |
| TIMER1 | PA0 | PA1 | PA2 | PA3 | AF1 |
| TIMER2 | PA6 | PA7 | PB0 | PB1 | AF2 |
| TIMER3 | PB6 | PB7 | PB8 | PB9 | AF2 |
| TIMER4 | PA0 | PA1 | PA2 | PA3 | AF2 |

> **注意**：TIMER0/TIMER7 是高级定时器，PWM 输出必须调用 `timer_primary_output_config(TIMERx, ENABLE)`。通道编号从 CH0 开始（STM32 从 CH1 开始）。

---

## ADC 模数转换

### 配置函数

```c
void adc_deinit(void);
void adc_mode_config(uint32_t mode);
void adc_special_function_config(uint32_t adc_periph, uint32_t function, ControlStatus newvalue);
void adc_data_alignment_config(uint32_t adc_periph, uint32_t data_alignment);
void adc_channel_length_config(uint32_t adc_periph, uint8_t adc_channel_group, uint32_t length);
void adc_regular_channel_config(uint32_t adc_periph, uint8_t rank,
                                uint8_t adc_channel, uint32_t sample_time);
void adc_external_trigger_config(uint32_t adc_periph, uint8_t adc_channel_group, uint32_t newvalue);
void adc_external_trigger_source_config(uint32_t adc_periph, uint8_t adc_channel_group,
                                        uint32_t external_trigger_source);
void adc_enable(uint32_t adc_periph);
void adc_disable(uint32_t adc_periph);
void adc_calibration_enable(uint32_t adc_periph);
void adc_software_trigger_enable(uint32_t adc_periph, uint8_t adc_channel_group);
uint16_t adc_regular_data_read(uint32_t adc_periph);
FlagStatus adc_flag_get(uint32_t adc_periph, uint32_t flag);
void adc_flag_clear(uint32_t adc_periph, uint32_t flag);
void adc_interrupt_enable(uint32_t adc_periph, uint32_t interrupt);
void adc_dma_mode_enable(uint32_t adc_periph);
void adc_tempsensor_vrefint_enable(void);
```

### special_function 参数

| 常量 | 功能 |
|------|------|
| ADC_SCAN_MODE | 多通道扫描模式 |
| ADC_CONTINUOUS_MODE | 连续转换模式 |
| ADC_INSERTED_CHANNEL_AUTO | 注入通道自动转换 |

### ADC 通道对应引脚

| 通道 | 引脚 | 通道 | 引脚 |
|------|------|------|------|
| ADC_CHANNEL_0 | PA0 | ADC_CHANNEL_8 | PB0 |
| ADC_CHANNEL_1 | PA1 | ADC_CHANNEL_9 | PB1 |
| ADC_CHANNEL_2 | PA2 | ADC_CHANNEL_10 | PC0 |
| ADC_CHANNEL_3 | PA3 | ADC_CHANNEL_11 | PC1 |
| ADC_CHANNEL_4 | PA4 | ADC_CHANNEL_12 | PC2 |
| ADC_CHANNEL_5 | PA5 | ADC_CHANNEL_13 | PC3 |
| ADC_CHANNEL_6 | PA6 | ADC_CHANNEL_14 | PC4 |
| ADC_CHANNEL_7 | PA7 | ADC_CHANNEL_15 | PC5 |
| ADC_CHANNEL_16 | 内部温度传感器 | ADC_CHANNEL_17 | VREFINT |

### 采样时间常量

`ADC_SAMPLETIME_3` / `_15` / `_28` / `_56` / `_84` / `_112` / `_144` / `_480`（单位：cycle）

### ADC 单通道轮询典型代码

```c
rcu_periph_clock_enable(RCU_ADC0);
adc_deinit();
adc_mode_config(ADC_MODE_FREE);
adc_special_function_config(ADC0, ADC_CONTINUOUS_MODE, DISABLE);
adc_special_function_config(ADC0, ADC_SCAN_MODE, DISABLE);
adc_data_alignment_config(ADC0, ADC_DATAALIGN_RIGHT);
adc_channel_length_config(ADC0, ADC_REGULAR_CHANNEL, 1);
adc_regular_channel_config(ADC0, 0, ADC_CHANNEL_10, ADC_SAMPLETIME_56);
adc_external_trigger_config(ADC0, ADC_REGULAR_CHANNEL, ENABLE);
adc_external_trigger_source_config(ADC0, ADC_REGULAR_CHANNEL, ADC_EXTTRIG_REGULAR_NONE);
adc_enable(ADC0);
adc_calibration_enable(ADC0);

/* 读取一次 */
adc_software_trigger_enable(ADC0, ADC_REGULAR_CHANNEL);
while(!adc_flag_get(ADC0, ADC_FLAG_EOC));
uint16_t value = adc_regular_data_read(ADC0);
adc_flag_clear(ADC0, ADC_FLAG_EOC);
```

---

## NVIC 中断控制

### 常用函数

```c
void nvic_irq_enable(uint8_t nvic_irq, uint8_t nvic_irq_pre_priority,
                     uint8_t nvic_irq_sub_priority);
void nvic_irq_disable(uint8_t nvic_irq);
void nvic_priority_group_set(uint32_t nvic_prigroup);
```

### 优先级分组

```c
nvic_priority_group_set(NVIC_PRIGROUP_PRE2_SUB2); /* 2位抢占 + 2位子优先级，最常用 */
/* 可选：NVIC_PRIGROUP_PRE0_SUB4 / PRE1_SUB3 / PRE2_SUB2 / PRE3_SUB1 / PRE4_SUB0 */
```

### 常用 IRQn

| IRQn 常量 | 对应中断 |
|-----------|---------|
| USART0_IRQn | USART0 全局中断 |
| USART1_IRQn | USART1 全局中断 |
| USART2_IRQn | USART2 全局中断 |
| TIMER1_IRQn | TIMER1 全局中断 |
| TIMER2_IRQn | TIMER2 全局中断 |
| TIMER3_IRQn | TIMER3 全局中断 |
| DMA0_Channel0_IRQn | DMA0 通道 0 |
| DMA0_Channel1_IRQn | DMA0 通道 1 |
| DMA1_Channel0_IRQn | DMA1 通道 0 |
| EXTI0_IRQn | 外部中断线 0 |
| EXTI1_IRQn | 外部中断线 1 |
| EXTI2_IRQn | 外部中断线 2 |
| EXTI3_IRQn | 外部中断线 3 |
| EXTI4_IRQn | 外部中断线 4 |
| EXTI5_9_IRQn | 外部中断线 5~9 |
| EXTI10_15_IRQn | 外部中断线 10~15 |
| ADC_IRQn | ADC0/1/2 全局中断 |
| SPI0_IRQn | SPI0 全局中断 |
| I2C0_EV_IRQn | I2C0 事件中断 |
| I2C0_ER_IRQn | I2C0 错误中断 |

---

## EXTI 外部中断

### 配置函数

```c
void exti_init(exti_line_enum linex, exti_mode_enum mode, exti_trig_type_enum trig_type);
void exti_deinit(void);
FlagStatus exti_flag_get(exti_line_enum linex);
void exti_flag_clear(exti_line_enum linex);
FlagStatus exti_interrupt_flag_get(exti_line_enum linex);
void exti_interrupt_flag_clear(exti_line_enum linex);
```

### 配置步骤

```c
/* 1. 开启 SYSCFG 时钟（GD32F4xx 用 SYSCFG 替代 AFIO） */
rcu_periph_clock_enable(RCU_SYSCFG);
/* 2. GPIO 配置为输入模式 */
gpio_mode_set(GPIOA, GPIO_MODE_INPUT, GPIO_PUPD_PULLUP, GPIO_PIN_0);
/* 3. 映射 GPIO 到 EXTI 线 */
syscfg_exti_line_config(EXTI_SOURCE_GPIOA, EXTI_SOURCE_PIN0);
/* 4. 配置 EXTI */
exti_init(EXTI_0, EXTI_INTERRUPT, EXTI_TRIG_FALLING);
/* 5. 配置 NVIC */
nvic_irq_enable(EXTI0_IRQn, 2, 0);
```

### 中断服务函数

```c
void EXTI0_IRQHandler(void) {
    if(exti_interrupt_flag_get(EXTI_0) != RESET) {
        /* 处理中断 */
        exti_interrupt_flag_clear(EXTI_0);
    }
}
```

> **与 STM32F1 的关键差异**：GD32F4xx 使用 `syscfg_exti_line_config()` 替代 `GPIO_EXTILineConfig()`，需要开启 `RCU_SYSCFG` 时钟而非 `RCC_APB2Periph_AFIO`。

---

## GD32F4xx vs STM32F1xx API 对照速查

| 功能 | STM32F1 StdPeriph | GD32F4xx StdPeriph |
|------|-------------------|---------------------|
| 开时钟 | `RCC_APB2PeriphClockCmd(x, ENABLE)` | `rcu_periph_clock_enable(x)` |
| GPIO 初始化 | `GPIO_Init(&struct)` | `gpio_mode_set()` + `gpio_output_options_set()` |
| GPIO 复用 | AFIO 重映射 | `gpio_af_set(GPIOx, AFn, pin)` |
| GPIO 置位 | `GPIO_SetBits(GPIOx, pin)` | `gpio_bit_set(GPIOx, pin)` |
| GPIO 复位 | `GPIO_ResetBits(GPIOx, pin)` | `gpio_bit_reset(GPIOx, pin)` |
| GPIO 读取 | `GPIO_ReadInputDataBit()` | `gpio_input_bit_get()` |
| USART 初始化 | `USART_Init(&struct)` | 逐项 `usart_baudrate_set()` 等 |
| USART 发送 | `USART_SendData(USARTx, data)` | `usart_data_transmit(USARTx, data)` |
| USART 接收 | `USART_ReceiveData(USARTx)` | `usart_data_receive(USARTx)` |
| 发送空标志 | `USART_FLAG_TXE` | `USART_FLAG_TBE` |
| 接收非空标志 | `USART_FLAG_RXNE` | `USART_FLAG_RBNE` |
| NVIC 配置 | `NVIC_Init(&struct)` | `nvic_irq_enable(irq, pre, sub)` |
| EXTI GPIO映射 | `GPIO_EXTILineConfig()` + AFIO | `syscfg_exti_line_config()` + SYSCFG |
| DMA 架构 | 通道制（DMA1_Channel1） | 通道+子外设（DMA0_CH0 + SUB_PERIPH） |
| 外设编号 | 从 1 开始（USART1, TIM1） | 从 0 开始（USART0, TIMER0） |
