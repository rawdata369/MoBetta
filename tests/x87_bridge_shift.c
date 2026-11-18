/*
 * MoBetta - x87 runs bridged across shl/shr/sar r32, imm (x87sidecar experiment, Session #18)
 *
 * 1. cull: Wow.exe 3.3.5a's box-vs-6-planes test at 0x9839e0, instruction for
 *    instruction (the loop at 0x9839fd is 18% of the game's x87 cost in the
 *    Shadowglen inn; `shr eax,31` between its x87 ops used to split the run).
 * 2. shiftmix: shl/sar/shr with counts 1..31 and 33 (masks to 1) and 32 (masks
 *    to 0, must stay with stock) in the gaps, flags dead.
 * 3. liveflag: shr's CF read by a jc after the x87 ops (must not be bridged).
 *
 * Prints "bits <hash>" over every result bit and "ms <time>" of the cull loop:
 * the same hash with and without the sidecar means bit-exact.
 *
 * Build: i686-w64-mingw32-gcc -O2 -mno-sse -mfpmath=387 -o x87_bridge_shift.exe x87_bridge_shift.c
 */
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <windows.h>

/* int __thiscall-like cull(planes in ecx, box on stack): 0 = outside, 3 = in */
int cull(const float *planes, const float *box);
__asm__(
    ".globl _cull\n"
    "_cull:\n"
    "    movl 4(%esp), %ecx\n"          /* planes */
    "    movl 8(%esp), %eax\n"          /* box: min xyz, max xyz */
    "    pushl %ebp\n"
    "    movl %esp, %ebp\n"
    "    subl $0x8, %esp\n"
    "    flds zero_c\n"
    "    leal 0xc(%eax), %edx\n"
    "    movl %edx, -0x8(%ebp)\n"
    "    xorl %edx, %edx\n"
    "    movl %eax, -0x4(%ebp)\n"
    "    addl $0x4, %ecx\n"
    "1:  movl 0x4(%ecx), %eax\n"
    "    shrl $0x1f, %eax\n"
    "    movl -0x8(%ebp,%eax,4), %eax\n"
    "    flds 0x8(%eax)\n"
    "    movl (%ecx), %eax\n"
    "    fmuls 0x4(%ecx)\n"
    "    shrl $0x1f, %eax\n"
    "    movl -0x8(%ebp,%eax,4), %eax\n"
    "    flds 0x4(%eax)\n"
    "    movl -0x4(%ecx), %eax\n"
    "    fmuls (%ecx)\n"
    "    shrl $0x1f, %eax\n"
    "    movl -0x8(%ebp,%eax,4), %eax\n"
    "    faddp %st, %st(1)\n"
    "    flds (%eax)\n"
    "    fmuls -0x4(%ecx)\n"
    "    faddp %st, %st(1)\n"
    "    fadds 0x8(%ecx)\n"
    "    fcomp %st(1)\n"
    "    fnstsw %ax\n"
    "    testb $0x5, %ah\n"
    "    jnp 2f\n"
    "    addl $0x1, %edx\n"
    "    addl $0x10, %ecx\n"
    "    cmpl $0x6, %edx\n"
    "    jl 1b\n"
    "    fstp %st(0)\n"
    "    movl $0x3, %eax\n"
    "    movl %ebp, %esp\n"
    "    popl %ebp\n"
    "    ret\n"
    "2:  fstp %st(0)\n"
    "    xorl %eax, %eax\n"
    "    movl %ebp, %esp\n"
    "    popl %ebp\n"
    "    ret\n"
    ".data\n"
    "zero_c: .float 0.0\n"
    ".text\n");

/* shiftmix(in[4], x, out[4]): x87 math with shifts of x in every gap */
void shiftmix(const float *in, uint32_t x, uint32_t *out);
__asm__(
    ".globl _shiftmix\n"
    "_shiftmix:\n"
    "    pushl %ebx\n"
    "    pushl %esi\n"
    "    movl 12(%esp), %esi\n"         /* in */
    "    movl 16(%esp), %eax\n"         /* x */
    "    movl 20(%esp), %ebx\n"         /* out */
    "    movl %eax, %ecx\n"
    "    movl %eax, %edx\n"
    "    flds (%esi)\n"
    "    shll $5, %eax\n"
    "    sarl $3, %ecx\n"
    "    fmuls 4(%esi)\n"
    "    shrl $1, %edx\n"
    "    sarl $31, %eax\n"
    "    flds 8(%esi)\n"
    "    shrl $33, %ecx\n"              /* masks to 1 */
    "    shll $31, %edx\n"
    "    fmuls 12(%esi)\n"
    "    shll $32, %eax\n"              /* masks to 0: unchanged */
    "    sarl $1, %edx\n"
    "    faddp %st, %st(1)\n"
    "    shrl $17, %ecx\n"
    "    fstps 12(%ebx)\n"
    "    movl %eax, (%ebx)\n"
    "    movl %ecx, 4(%ebx)\n"
    "    movl %edx, 8(%ebx)\n"
    "    testl %eax, %eax\n"            /* kills the shifts' flags */
    "    popl %esi\n"
    "    popl %ebx\n"
    "    ret\n");

/* liveflag(in[2], x): shr's CF is read by jc after the x87 ops */
uint32_t liveflag(const float *in, uint32_t x, float *outf);
__asm__(
    ".globl _liveflag\n"
    "_liveflag:\n"
    "    movl 4(%esp), %ecx\n"
    "    movl 8(%esp), %eax\n"
    "    movl 12(%esp), %edx\n"
    "    flds (%ecx)\n"
    "    shrl $3, %eax\n"               /* CF = bit 2 of x, read below */
    "    fmuls 4(%ecx)\n"
    "    fstps (%edx)\n"
    "    jc 1f\n"
    "    orl $0x80000000, %eax\n"
    "1:  ret\n");

static uint64_t h = 1469598103934665603ULL;
static void mix(const void *p, size_t n)
{
    const unsigned char *b = p;
    while (n--) { h ^= *b++; h *= 1099511628211ULL; }
}

static uint32_t rng = 12345;
static float frand(void)
{
    rng = rng * 1664525u + 1013904223u;
    return ((int32_t)rng >> 8) / 65536.0f;
}

int main(void)
{
    static float planes[64][24], boxes[256][6];
    LARGE_INTEGER f, t0, t1;
    int i, j, k, inside = 0;

    for (i = 0; i < 64; i++) for (j = 0; j < 24; j++) planes[i][j] = frand();
    for (i = 0; i < 256; i++)
        for (j = 0; j < 3; j++) {
            float a = frand(), b = frand();
            boxes[i][j] = a < b ? a : b;
            boxes[i][j + 3] = a < b ? b : a;
        }

    for (i = 0; i < 64; i++)
        for (k = 0; k < 256; k++) {
            int r = cull(planes[i], boxes[k]);
            mix(&r, sizeof(r));
            inside += r != 0;
        }

    for (i = 0; i < 4096; i++) {
        float in[4] = { frand(), frand(), frand(), frand() };
        uint32_t out[4], x = rng * 2654435761u;
        float lf;
        uint32_t lv;
        shiftmix(in, x, out);
        mix(out, sizeof(out));
        lv = liveflag(in, x, &lf);
        mix(&lv, sizeof(lv));
        mix(&lf, sizeof(lf));
    }

    QueryPerformanceFrequency(&f);
    QueryPerformanceCounter(&t0);
    for (j = 0; j < 400; j++)
        for (i = 0; i < 64; i++)
            for (k = 0; k < 256; k++) inside += cull(planes[i], boxes[k]) != 0;
    QueryPerformanceCounter(&t1);

    printf("inside %d\n", inside);
    printf("bits %016llx\n", (unsigned long long)h);
    printf("ms %d\n", (int)((t1.QuadPart - t0.QuadPart) * 1000 / f.QuadPart));
    return 0;
}
