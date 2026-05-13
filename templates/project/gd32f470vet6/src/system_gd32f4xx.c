#include "gd32f4xx.h"

#define __SYSTEM_CLOCK_200M_PLL_25M_HXTAL  (uint32_t)(200000000)

uint32_t SystemCoreClock = __SYSTEM_CLOCK_200M_PLL_25M_HXTAL;

static void system_clock_200m_25m_hxtal(void);

void SystemInit(void)
{
    RCU_CTL |= RCU_CTL_IRC16MEN;
    while (0U == (RCU_CTL & RCU_CTL_IRC16MSTB)) {
    }

    RCU_CFG0 &= ~RCU_CFG0_SCS;

    RCU_CTL &= ~(RCU_CTL_HXTALEN | RCU_CTL_CKMEN | RCU_CTL_PLLEN);
    RCU_CTL &= ~RCU_CTL_HXTALBPS;
    RCU_CFG0 &= ~(RCU_CFG0_SCS | RCU_CFG0_AHBPSC | RCU_CFG0_APB1PSC | RCU_CFG0_APB2PSC |
                   RCU_CFG0_RTCDIV | RCU_CFG0_CKOUT0SEL | RCU_CFG0_CKOUT0DIV);
    RCU_CFG1 &= ~(RCU_CFG1_CKOUT1SEL | RCU_CFG1_CKOUT1DIV | RCU_CFG1_PLLPRESEL);

    RCU_PLL = 0x24003010U;
    RCU_INT = 0x00000000U;

    system_clock_200m_25m_hxtal();
}

static void system_clock_200m_25m_hxtal(void)
{
    uint32_t timeout = 0U;
    uint32_t stab_flag = 0U;

    RCU_CTL |= RCU_CTL_HXTALEN;

    while ((0U == (RCU_CTL & RCU_CTL_HXTALSTB)) && (0xFFFFU != timeout)) {
        timeout++;
    }

    if (0U != (RCU_CTL & RCU_CTL_HXTALSTB)) {
        stab_flag = 1U;
    }

    if (stab_flag) {
        RCU_APB1EN |= RCU_APB1EN_PMUEN;
        PMU_CTL |= PMU_CTL_LDOVS;

        RCU_CFG0 |= RCU_AHB_CKSYS_DIV1;
        RCU_CFG0 |= RCU_APB2_CKAHB_DIV2;
        RCU_CFG0 |= RCU_APB1_CKAHB_DIV4;

        /* PLL: HXTAL=25MHz, /25*400/2 = 200MHz */
        RCU_PLL = (25U | (400U << 6U) | (((2U >> 1U) - 1U) << 16U) |
                   (RCU_PLLSRC_HXTAL) | (9U << 24U));

        RCU_CTL |= RCU_CTL_PLLEN;
        while (0U == (RCU_CTL & RCU_CTL_PLLSTB)) {
        }

        FMC_WS &= ~FMC_WS_WSCNT;
        FMC_WS |= WS_WSCNT(7);

        RCU_CFG0 &= ~RCU_CFG0_SCS;
        RCU_CFG0 |= RCU_CKSYSSRC_PLL;
        while (RCU_SCSS_PLL != (RCU_CFG0 & RCU_CFG0_SCSS)) {
        }
    }
}

void SystemCoreClockUpdate(void)
{
    SystemCoreClock = __SYSTEM_CLOCK_200M_PLL_25M_HXTAL;
}
