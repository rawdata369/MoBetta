/*
 * MoBetta - x87 runs bridged across push/pop r32 and mov [m],imm (x87sidecar patch 0002, Session #30)
 *
 * 1. segbox: Wow.exe 3.3.5a's segment-vs-box test at 0x7f9480, instruction for
 *    instruction (5.8% of the game thread at the Dalaran fountain, Session #29;
 *    `push ebx; push esi`, `push edi` and `movl $1,-0x4(%ebp)` in its gaps
 *    split it into single-op runs).  Only the two constants it reads by
 *    absolute address (-1.0f at 0x9e2ef4, 1e-5f at 0x9ea558) are relabelled.
 * 2. stackmix: push/pop r32 and mov m32,imm between x87 ops on a 32-bit stack,
 *    with the pushed slot read by fildl and the stored immediates read back.
 *
 * Prints "bits <hash>" over every result bit and "ms <time>" of the segbox
 * loop: the same hash with and without the sidecar means bit-exact.
 *
 * Build: i686-w64-mingw32-gcc -O2 -mno-sse -mfpmath=387 -o x87_bridge_stack.exe x87_bridge_stack.c
 */
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <windows.h>

/* int segbox(const float box[6] (min xyz, max xyz), const float a[3], const float b[3]) */
int segbox(const float *box, const float *a, const float *b);
__asm__(
    ".section .rdata\n"
    "    .p2align 2\n"
    "c_m1:  .long 0xbf800000\n"     /* -1.0f, Wow.exe 0x9e2ef4 */
    "c_eps: .long 0x3727c5ac\n"     /* 1e-5f, Wow.exe 0x9ea558 */
    ".text\n"
    ".globl _segbox\n"
    "_segbox:\n"
    "          push   %ebp\n"   /* 7f9480 */
    "          mov    %esp,%ebp\n"   /* 7f9481 */
    "          sub    $0x34,%esp\n"   /* 7f9483 */
    "          mov    0x10(%ebp),%eax\n"   /* 7f9486 */
    "          flds   (%eax)\n"   /* 7f9489 */
    "          mov    0x8(%ebp),%edx\n"   /* 7f948b */
    "          push   %ebx\n"   /* 7f948e */
    "          push   %esi\n"   /* 7f948f */
    "          mov    0xc(%ebp),%esi\n"   /* 7f9490 */
    "          fsubs  (%esi)\n"   /* 7f9493 */
    "          push   %edi\n"   /* 7f9495 */
    "          lea    0xc(%edx),%ebx\n"   /* 7f9496 */
    "          lea    -0x28(%ebp),%edi\n"   /* 7f9499 */
    "          fstps  -0x28(%ebp)\n"   /* 7f949c */
    "          mov    %ebx,-0x10(%ebp)\n"   /* 7f949f */
    "          flds   0x4(%eax)\n"   /* 7f94a2 */
    "          sub    %edx,%ebx\n"   /* 7f94a5 */
    "          fsubs  0x4(%esi)\n"   /* 7f94a7 */
    "          sub    %edx,%edi\n"   /* 7f94aa */
    "          movl   $0x1,-0x4(%ebp)\n"   /* 7f94ac */
    "          movl   $0x0,-0xc(%ebp)\n"   /* 7f94b3 */
    "          fstps  -0x24(%ebp)\n"   /* 7f94ba */
    "          mov    %edx,%ecx\n"   /* 7f94bd */
    "          flds   0x8(%eax)\n"   /* 7f94bf */
    "          sub    %edx,%eax\n"   /* 7f94c2 */
    "          fsubs  0x8(%esi)\n"   /* 7f94c4 */
    "          mov    %eax,0xc(%ebp)\n"   /* 7f94c7 */
    "          lea    -0x34(%ebp),%eax\n"   /* 7f94ca */
    "          sub    %edx,%eax\n"   /* 7f94cd */
    "          mov    %eax,0x8(%ebp)\n"   /* 7f94cf */
    "          fstps  -0x20(%ebp)\n"   /* 7f94d2 */
    "          flds   c_m1\n"   /* 7f94d5 */
    "          mov    %esi,%eax\n"   /* 7f94db */
    "          sub    %edx,%eax\n"   /* 7f94dd */
    "          fsts   -0x1c(%ebp)\n"   /* 7f94df */
    "          mov    %eax,0x10(%ebp)\n"   /* 7f94e2 */
    "          fsts   -0x18(%ebp)\n"   /* 7f94e5 */
    "          lea    -0x1c(%ebp),%eax\n"   /* 7f94e8 */
    "          fstps  -0x14(%ebp)\n"   /* 7f94eb */
    "          sub    %edx,%eax\n"   /* 7f94ee */
    "          mov    %eax,-0x8(%ebp)\n"   /* 7f94f0 */
    "L7f94f3:  mov    0x10(%ebp),%eax\n"   /* 7f94f3 */
    "          flds   (%ecx)\n"   /* 7f94f6 */
    "          fcomps (%eax,%ecx,1)\n"   /* 7f94f8 */
    "          fnstsw %ax\n"   /* 7f94fb */
    "          test   $0x41,%ah\n"   /* 7f94fd */
    "          jne L7f952e\n"   /* 7f9500 */
    "          mov    0xc(%ebp),%eax\n"   /* 7f9502 */
    "          flds   (%ecx)\n"   /* 7f9505 */
    "          fcomps (%eax,%ecx,1)\n"   /* 7f9507 */
    "          fnstsw %ax\n"   /* 7f950a */
    "          test   $0x41,%ah\n"   /* 7f950c */
    "          je L7f9647\n"   /* 7f950f */
    "          cmpl   $0x0,(%edi,%ecx,1)\n"   /* 7f9515 */
    "          flds   (%ecx)\n"   /* 7f9519 */
    "          mov    0x8(%ebp),%eax\n"   /* 7f951b */
    "          fstps  (%eax,%ecx,1)\n"   /* 7f951e */
    "          movl   $0x0,-0x4(%ebp)\n"   /* 7f9521 */
    "          je L7f957a\n"   /* 7f9528 */
    "          flds   (%ecx)\n"   /* 7f952a */
    "          jmp L7f956b\n"   /* 7f952c */
    "L7f952e:  mov    0x10(%ebp),%eax\n"   /* 7f952e */
    "          flds   (%ebx,%ecx,1)\n"   /* 7f9531 */
    "          fcomps (%eax,%ecx,1)\n"   /* 7f9534 */
    "          fnstsw %ax\n"   /* 7f9537 */
    "          test   $0x5,%ah\n"   /* 7f9539 */
    "          jp L7f957a\n"   /* 7f953c */
    "          mov    0xc(%ebp),%eax\n"   /* 7f953e */
    "          flds   (%ebx,%ecx,1)\n"   /* 7f9541 */
    "          fcomps (%eax,%ecx,1)\n"   /* 7f9544 */
    "          fnstsw %ax\n"   /* 7f9547 */
    "          test   $0x5,%ah\n"   /* 7f9549 */
    "          jnp L7f9647\n"   /* 7f954c */
    "          cmpl   $0x0,(%edi,%ecx,1)\n"   /* 7f9552 */
    "          flds   (%ebx,%ecx,1)\n"   /* 7f9556 */
    "          mov    0x8(%ebp),%eax\n"   /* 7f9559 */
    "          fstps  (%eax,%ecx,1)\n"   /* 7f955c */
    "          movl   $0x0,-0x4(%ebp)\n"   /* 7f955f */
    "          je L7f957a\n"   /* 7f9566 */
    "          flds   (%ebx,%ecx,1)\n"   /* 7f9568 */
    "L7f956b:  mov    0x10(%ebp),%eax\n"   /* 7f956b */
    "          fsubs  (%eax,%ecx,1)\n"   /* 7f956e */
    "          mov    -0x8(%ebp),%eax\n"   /* 7f9571 */
    "          fdivs  (%edi,%ecx,1)\n"   /* 7f9574 */
    "          fstps  (%eax,%ecx,1)\n"   /* 7f9577 */
    "L7f957a:  mov    -0xc(%ebp),%eax\n"   /* 7f957a */
    "          add    $0x1,%eax\n"   /* 7f957d */
    "          add    $0x4,%ecx\n"   /* 7f9580 */
    "          cmp    $0x3,%eax\n"   /* 7f9583 */
    "          mov    %eax,-0xc(%ebp)\n"   /* 7f9586 */
    "          jb L7f94f3\n"   /* 7f9589 */
    "          xor    %edi,%edi\n"   /* 7f958f */
    "          cmp    %edi,-0x4(%ebp)\n"   /* 7f9591 */
    "          jne L7f9637\n"   /* 7f9594 */
    "          flds   -0x1c(%ebp)\n"   /* 7f959a */
    "          mov    %edi,0x10(%ebp)\n"   /* 7f959d */
    "          fcomps -0x18(%ebp)\n"   /* 7f95a0 */
    "          fnstsw %ax\n"   /* 7f95a3 */
    "          test   $0x5,%ah\n"   /* 7f95a5 */
    "          jp L7f95b1\n"   /* 7f95a8 */
    "          movl   $0x1,0x10(%ebp)\n"   /* 7f95aa */
    "L7f95b1:  mov    0x10(%ebp),%ecx\n"   /* 7f95b1 */
    "          flds   -0x1c(%ebp,%ecx,4)\n"   /* 7f95b4 */
    "          fcomps -0x14(%ebp)\n"   /* 7f95b8 */
    "          fnstsw %ax\n"   /* 7f95bb */
    "          test   $0x5,%ah\n"   /* 7f95bd */
    "          jp L7f95c9\n"   /* 7f95c0 */
    "          movl   $0x2,0x10(%ebp)\n"   /* 7f95c2 */
    "L7f95c9:  mov    0x10(%ebp),%eax\n"   /* 7f95c9 */
    "          testl  $0x80000000,-0x1c(%ebp,%eax,4)\n"   /* 7f95cc */
    "          jne L7f9647\n"   /* 7f95d4 */
    "          flds   c_eps\n"   /* 7f95d6 */
    "          sub    %esi,%edx\n"   /* 7f95dc */
    "          lea    -0x34(%ebp),%eax\n"   /* 7f95de */
    "          mov    %edx,0xc(%ebp)\n"   /* 7f95e1 */
    "          mov    -0x10(%ebp),%edx\n"   /* 7f95e4 */
    "          lea    -0x28(%ebp),%ebx\n"   /* 7f95e7 */
    "          sub    %esi,%eax\n"   /* 7f95ea */
    "          sub    %esi,%ebx\n"   /* 7f95ec */
    "          mov    %esi,%ecx\n"   /* 7f95ee */
    "          mov    %eax,0x8(%ebp)\n"   /* 7f95f0 */
    "          sub    %esi,%edx\n"   /* 7f95f3 */
    "L7f95f5:  mov    0x10(%ebp),%esi\n"   /* 7f95f5 */
    "          cmp    %esi,%edi\n"   /* 7f95f8 */
    "          je L7f962a\n"   /* 7f95fa */
    "          flds   (%ebx,%ecx,1)\n"   /* 7f95fc */
    "          fmuls  -0x1c(%ebp,%esi,4)\n"   /* 7f95ff */
    "          fadds  (%ecx)\n"   /* 7f9603 */
    "          fsts   (%eax,%ecx,1)\n"   /* 7f9605 */
    "          mov    0xc(%ebp),%eax\n"   /* 7f9608 */
    "          flds   (%eax,%ecx,1)\n"   /* 7f960b */
    "          fsub   %st(2),%st\n"   /* 7f960e */
    "          fcomp  %st(1)\n"   /* 7f9610 */
    "          fnstsw %ax\n"   /* 7f9612 */
    "          test   $0x41,%ah\n"   /* 7f9614 */
    "          je L7f9643\n"   /* 7f9617 */
    "          flds   (%edx,%ecx,1)\n"   /* 7f9619 */
    "          fadd   %st(2),%st\n"   /* 7f961c */
    "          fcompp\n"   /* 7f961e */
    "          fnstsw %ax\n"   /* 7f9620 */
    "          test   $0x5,%ah\n"   /* 7f9622 */
    "          jnp L7f9645\n"   /* 7f9625 */
    "          mov    0x8(%ebp),%eax\n"   /* 7f9627 */
    "L7f962a:  add    $0x1,%edi\n"   /* 7f962a */
    "          add    $0x4,%ecx\n"   /* 7f962d */
    "          cmp    $0x3,%edi\n"   /* 7f9630 */
    "          jb L7f95f5\n"   /* 7f9633 */
    "          fstp   %st(0)\n"   /* 7f9635 */
    "L7f9637:  pop    %edi\n"   /* 7f9637 */
    "          pop    %esi\n"   /* 7f9638 */
    "          mov    $0x1,%eax\n"   /* 7f9639 */
    "          pop    %ebx\n"   /* 7f963e */
    "          mov    %ebp,%esp\n"   /* 7f963f */
    "          pop    %ebp\n"   /* 7f9641 */
    "          ret\n"   /* 7f9642 */
    "L7f9643:  fstp   %st(0)\n"   /* 7f9643 */
    "L7f9645:  fstp   %st(0)\n"   /* 7f9645 */
    "L7f9647:  pop    %edi\n"   /* 7f9647 */
    "          pop    %esi\n"   /* 7f9648 */
    "          xor    %eax,%eax\n"   /* 7f9649 */
    "          pop    %ebx\n"   /* 7f964b */
    "          mov    %ebp,%esp\n"   /* 7f964c */
    "          pop    %ebp\n"   /* 7f964e */
    "          ret\n"   /* 7f964f */
);

/* stackmix(in[2], x, out[4]) */
void stackmix(const float *in, uint32_t x, uint32_t *out);
__asm__(
    ".globl _stackmix\n"
    "_stackmix:\n"
    "    pushl %ebp\n"
    "    movl %esp, %ebp\n"
    "    pushl %ebx\n"
    "    pushl %esi\n"
    "    pushl %edi\n"
    "    movl 8(%ebp), %eax\n"          /* in */
    "    movl 12(%ebp), %ebx\n"         /* x */
    "    movl 16(%ebp), %ecx\n"         /* out */
    "    xorl %esi, %esi\n"
    "    flds (%eax)\n"
    "    fmuls 4(%eax)\n"
    "    pushl %ebx\n"                  /* bridge: push r32 */
    "    fildl (%esp)\n"                /* reads the pushed slot */
    "    popl %esi\n"                   /* bridge: pop r32 */
    "    fmulp\n"
    "    movl $0x40490fdb, 8(%ecx)\n"   /* bridge: mov m32,imm (pi) */
    "    fadds 8(%ecx)\n"
    "    movl $-3, 12(%ecx)\n"          /* bridge: mov m32,imm (negative) */
    "    fildl 12(%ecx)\n"
    "    faddp\n"
    "    fstps (%ecx)\n"
    "    movl %esi, 4(%ecx)\n"
    "    popl %edi\n"
    "    popl %esi\n"
    "    popl %ebx\n"
    "    popl %ebp\n"
    "    ret\n"
);

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
    static float boxes[256][6], segs[256][6];
    LARGE_INTEGER f, t0, t1;
    int i, j, k, hits = 0;

    for (i = 0; i < 256; i++)
        for (j = 0; j < 3; j++) {
            float a = frand(), b = frand();
            boxes[i][j] = a < b ? a : b;
            boxes[i][j + 3] = a < b ? b : a;
        }
    /* Segments: half start inside the unit cube's range, so both of segbox's
     * paths (start inside, start outside) run. */
    for (i = 0; i < 256; i++)
        for (j = 0; j < 6; j++) segs[i][j] = (i & 1) ? frand() * 0.5f : frand() * 3.0f;

    for (i = 0; i < 256; i++)
        for (k = 0; k < 256; k++) {
            int r = segbox(boxes[i], segs[k], segs[k] + 3);
            mix(&r, sizeof(r));
            hits += r != 0;
        }

    for (i = 0; i < 4096; i++) {
        float in[2] = { frand(), frand() };
        uint32_t out[4], x = rng * 2654435761u;
        stackmix(in, x, out);
        mix(out, sizeof(out));
    }

    QueryPerformanceFrequency(&f);
    QueryPerformanceCounter(&t0);
    for (j = 0; j < 100; j++)
        for (i = 0; i < 256; i++)
            for (k = 0; k < 256; k++) hits += segbox(boxes[i], segs[k], segs[k] + 3) != 0;
    QueryPerformanceCounter(&t1);

    printf("hits %d\n", hits);
    printf("bits %016llx\n", (unsigned long long)h);
    printf("ms %d\n", (int)((t1.QuadPart - t0.QuadPart) * 1000 / f.QuadPart));
    return 0;
}
