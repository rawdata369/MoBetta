/* MoBetta Session #36 - x87 fsin/fcos/fsincos/fptan across the argument range.
 * Real x87: |x| < 2^63 -> result, C2 = 0; finite |x| >= 2^63 -> ST(0) unchanged,
 * C2 = 1, and fsincos/fptan push nothing. Prints per case: op, input, C2,
 * TOP change (-1 = pushed), ST(0) bits, ST(1) bits if pushed.
 * Build: i686-w64-mingw32-gcc -O0 -mno-sse -mfpmath=387 -o x87_trig_probe.exe x87_trig_probe.c */
#include <stdio.h>
#include <stdint.h>
#include <string.h>
static uint64_t bits(double d) { uint64_t u; memcpy(&u, &d, 8); return u; }
static double dbl(uint64_t u) { double d; memcpy(&d, &u, 8); return d; }
enum { SIN, COS, SINCOS, TAN };
static const char *names[] = { "fsin", "fcos", "fsincos", "fptan" };
static void run(int op, double x) {
    volatile double in = x; double r0 = 0, r1 = 0; unsigned short sw0 = 0, sw1 = 0, sw2 = 0;
    unsigned short cw = 0x037f;
    __asm__ volatile("fldcw %0" :: "m"(cw));
    /* Load, record TOP, run the op, record status, then pop what is there. */
#define BODY(INSN) __asm__ volatile( \
        "fnclex; fldl %3; fnstsw %0; " INSN "; fnstsw %1; " \
        "fstpl %4; fnstsw %%ax; mov %%ax, %2; " \
        "movw %1, %%cx; andw $0x3800, %%cx; movw %0, %%dx; andw $0x3800, %%dx; cmpw %%cx, %%dx; je 1f; fstpl %5; 1: fninit" \
        : "=m"(sw0), "=m"(sw1), "=m"(sw2) : "m"(in), "m"(r0), "m"(r1) : "eax", "ecx", "edx", "memory")
    switch (op) {
    case SIN: BODY("fsin"); break;
    case COS: BODY("fcos"); break;
    case SINCOS: BODY("fsincos"); break;
    case TAN: BODY("fptan"); break;
    }
    int t0 = (sw0 >> 11) & 7, t1 = (sw1 >> 11) & 7;
    int dtop = ((t1 - t0) + 8) % 8; if (dtop > 4) dtop -= 8;
    printf("%-8s %-24.17g C2=%d dtop=%+d st0=%016llx", names[op], x, (sw1 >> 10) & 1, dtop,
           (unsigned long long)bits(r0));
    if (dtop) printf(" st1=%016llx", (unsigned long long)bits(r1));
    printf(" (%.17g)\n", r0);
}
int main(void) {
    const double xs[] = { 0.7, -2.5, 1e5, 0x1p23, 1e7 + 0.25, 1e10, 1e15, 1e18,
                          dbl(0x43dfffffffffffffULL) /* largest < 2^63 */, 0x1p63, -1e22, 1e22, 1e308,
                          dbl(0x7ff0000000000000ULL), dbl(0x7ff8000000000001ULL) };
    for (int op = SIN; op <= TAN; op++)
        for (unsigned i = 0; i < sizeof xs / sizeof xs[0]; i++) run(op, xs[i]);
    return 0;
}
