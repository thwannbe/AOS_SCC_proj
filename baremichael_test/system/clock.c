/* BareMichael SCC baremetal framework.
 * Copyright (C) 2012.  All rights reserved. */

#include <interrupt.h>
#include <apic.h>
#include <scc.h>
#include <clock.h>

#if RTCLOCK
ulong clkticks;      /** ticks per second downcounter */
ulong clktime;       /** current time in seconds */

void init_clock()
{
	ulong value;
	interrupt clockIRQ(void);

	clkticks = 0;
	clktime = 0;

	set_trap_gate(IRQBASE + LOCAL_TIMER_IRQ, clockIRQ);
	
	/* make timer periodic */
	value = APIC_LVT_TIMER_PERIODIC | (IRQBASE + LOCAL_TIMER_IRQ);
	lapic->lvtt = value;

	/* set timer divisor to 1 */
	value = APIC_TDR_DIV_1;
	lapic->tdcr = value;

	/* This write starts the timer */
	lapic->tmict = get_tile_freq(get_my_tileid()) / CLKTICKS_PER_SEC;
}

interrupt clkhandler()
{
	/* another clock tick passes */
	clkticks++;

	/* update global second counter */
	if (CLKTICKS_PER_SEC == clkticks)
	{
		clktime++;
		clkticks = 0;
	}
}
#endif /* RTCLOCK */
