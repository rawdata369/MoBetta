/* MoBetta - where x87 80-bit semantics differ from binary64 (Session #35).
 * Prints one line per probe: name, result bits, value. Compare stock Rosetta (exact x87) with x87sidecar (ROSETTA_X87_PATH set) or another emulator.
 * Build: i686-w64-mingw32-gcc -O0 -mno-sse -mfpmath=387 -o x87_precision_probe.exe x87_precision_probe.c */
#include <stdio.h>
#include <stdint.h>
#include <string.h>
static void pd(const char *n, double d) { uint64_t u; memcpy(&u, &d, 8); printf("%-22s %016llx %.17g\n", n, (unsigned long long)u, d); }
static void pc(unsigned short cw) { __asm__ volatile("fldcw %0" :: "m"(cw)); }
int main(void) {
    volatile double big = 1e308, ten = 10.0, one = 1.0, tiny = 0x1p-60, three = 3.0;
    volatile long long i64 = 0x7ffffffffffffff1LL; long long o64;
    double r;
    pc(0x037f); /* 64-bit precision, all masked */
    __asm__ volatile("fldl %1; fmull %2; fdivl %2; fstpl %0" : "=m"(r) : "m"(big), "m"(ten)); pd("range 1e308*10/10", r);
    __asm__ volatile("fldl %1; faddl %2; fsubl %1; fstpl %0" : "=m"(r) : "m"(one), "m"(tiny)); pd("pc64 1+2^-60-1", r);
    __asm__ volatile("fldl %1; fdivl %2; fmull %2; fstpl %0" : "=m"(r) : "m"(one), "m"(three)); pd("pc64 1/3*3", r);
    __asm__ volatile("fildll %1; fistpll %0" : "=m"(o64) : "m"(i64)); printf("%-22s %016llx\n", "int64 round trip", (unsigned long long)o64);
    __asm__ volatile("fldl %1; fsin; fstpl %0" : "=m"(r) : "m"(big)); pd("fsin 1e308", r);
    { volatile double x = 1e22; __asm__ volatile("fldl %1; fsin; fstpl %0" : "=m"(r) : "m"(x)); pd("fsin 1e22", r); }
    { volatile double x = 0.7; __asm__ volatile("fldl %1; fsin; fstpl %0" : "=m"(r) : "m"(x)); pd("fsin 0.7", r); }
    { volatile double x = 3.0; __asm__ volatile("fldl %1; fsqrt; fstpl %0" : "=m"(r) : "m"(x)); pd("fsqrt 3", r); }
    { volatile double x = 10.0; __asm__ volatile("fld1; fldl %1; fyl2x; fstpl %0" : "=m"(r) : "m"(x) : "st(1)"); pd("fyl2x log2 10", r); }
    { volatile double x = 0.3; __asm__ volatile("fldl %1; f2xm1; fstpl %0" : "=m"(r) : "m"(x)); pd("f2xm1 0.3", r); }
    { volatile double a = 1.0, b = 0x1p-30; double s = 0; /* accumulate in register */
      __asm__ volatile("fldz; mov $1000000,%%ecx; 1: fldl %1; fmull %2; faddp; dec %%ecx; jnz 1b; faddl %3; fstpl %0" : "=m"(s) : "m"(a), "m"(b), "m"(a) : "ecx"); pd("sum 1e6 * 2^-30 + 1", s); }
    pc(0x027f); /* 53-bit precision (MSVC CRT default) */
    __asm__ volatile("fldl %1; fmull %2; fdivl %2; fstpl %0" : "=m"(r) : "m"(big), "m"(ten)); pd("pc53 range 1e308*10/10", r);
    __asm__ volatile("fldl %1; faddl %2; fsubl %1; fstpl %0" : "=m"(r) : "m"(one), "m"(tiny)); pd("pc53 1+2^-60-1", r);
    pc(0x007f); /* 24-bit precision (D3D9 without FPU_PRESERVE) */
    { volatile double x = 0.1, y = 0.2; __asm__ volatile("fldl %1; faddl %2; fstpl %0" : "=m"(r) : "m"(x), "m"(y)); pd("pc24 0.1+0.2", r); }
    __asm__ volatile("fldl %1; fdivl %2; fstpl %0" : "=m"(r) : "m"(one), "m"(three)); pd("pc24 1/3", r);
    return 0;
}
