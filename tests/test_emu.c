/*
 * MoBetta - unit tests for the Rosetta instruction emulation in signal_x86_64.c
 *
 * Built as x86_64 and run under Rosetta by scripts/test_emu.sh, which extracts
 * the code between the MOBETTA markers into emu_extract.c.
 *
 * ARPL: emulate_arpl() is called on a fake 32-bit ucontext and fake 32-bit memory,
 *       and checked against hand-computed addresses, lengths and results.
 * x87:  each alias runs for real, faults, and is emulated from a SIGILL handler;
 *       the resulting fxsave state must match the documented instruction's.
 */
#define _XOPEN_SOURCE 700
#define _DARWIN_C_SOURCE
#include <setjmp.h>
#include <signal.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <ucontext.h>

/* Wine types and macros used by the extracted code */
typedef unsigned char BYTE;
typedef unsigned short WORD, USHORT;
typedef unsigned int DWORD;
typedef int BOOL;
typedef long long LONGLONG;
typedef unsigned long long ULONG64, DWORD64;
typedef unsigned long ULONG_PTR, SIZE_T;
typedef int NTSTATUS;
#define TRUE 1
#define FALSE 0
#define DECLSPEC_ALIGN(x) __attribute__((aligned(x)))

typedef struct { ULONG64 Low; LONGLONG High; } M128A;
typedef struct {
    WORD ControlWord; WORD StatusWord; BYTE TagWord; BYTE Reserved1; WORD ErrorOpcode;
    DWORD ErrorOffset; WORD ErrorSelector; WORD Reserved2; DWORD DataOffset; WORD DataSelector;
    WORD Reserved3; DWORD MxCsr; DWORD MxCsr_Mask; M128A FloatRegisters[8];
    M128A XmmRegisters[16]; BYTE Reserved4[96];
} XMM_SAVE_AREA32;
_Static_assert( sizeof(XMM_SAVE_AREA32) == 512, "fxsave layout" );
_Static_assert( offsetof(XMM_SAVE_AREA32, FloatRegisters) == 32, "fxsave layout" );

typedef struct { ULONG64 Rip; } CONTEXT;

#define RAX_sig(context)     ((context)->uc_mcontext->__ss.__rax)
#define RBX_sig(context)     ((context)->uc_mcontext->__ss.__rbx)
#define RCX_sig(context)     ((context)->uc_mcontext->__ss.__rcx)
#define RDX_sig(context)     ((context)->uc_mcontext->__ss.__rdx)
#define RSI_sig(context)     ((context)->uc_mcontext->__ss.__rsi)
#define RDI_sig(context)     ((context)->uc_mcontext->__ss.__rdi)
#define RBP_sig(context)     ((context)->uc_mcontext->__ss.__rbp)
#define RSP_sig(context)     ((context)->uc_mcontext->__ss.__rsp)
#define CS_sig(context)      ((context)->uc_mcontext->__ss.__cs)
#define EFL_sig(context)     ((context)->uc_mcontext->__ss.__rflags)
#define RIP_sig(context)     ((context)->uc_mcontext->__ss.__rip)

static inline void *FPU_sig( const ucontext_t *context )
{
    return &context->uc_mcontext->__fs.__fpu_fcw;
}

#define TRACE_(ch) trace_stub
static void trace_stub( const char *fmt, ... ) { (void)fmt; }

static USHORT cs32_sel = 0x107;
static BOOL is_rosetta2 = TRUE;

/* fake 32-bit address space for ARPL; anything above 4GB is real memory */
#define FAKE_ORG  0x00400000u
#define FAKE_SIZE 0x10000u
static BYTE fake_mem[FAKE_SIZE];

static BYTE *map_addr( const void *addr, SIZE_T size )
{
    ULONG_PTR a = (ULONG_PTR)addr;
    if (a >= 0x100000000ul) return (BYTE *)addr;
    if (a < FAKE_ORG || a + size > FAKE_ORG + FAKE_SIZE) return NULL;
    return fake_mem + (a - FAKE_ORG);
}

static SIZE_T virtual_uninterrupted_read_memory( const void *addr, void *buffer, SIZE_T size )
{
    ULONG_PTR a = (ULONG_PTR)addr;
    BYTE *p;
    /* like the real one, return what can be read up to the end of the mapping */
    if (a >= FAKE_ORG && a < FAKE_ORG + FAKE_SIZE && a + size > FAKE_ORG + FAKE_SIZE)
        size = FAKE_ORG + FAKE_SIZE - a;
    if (!(p = map_addr( addr, size ))) return 0;
    memcpy( buffer, p, size );
    return size;
}

static int write_fail;
static NTSTATUS virtual_uninterrupted_write_memory( void *addr, const void *buffer, SIZE_T size )
{
    BYTE *p = map_addr( addr, size );
    if (!p || write_fail) return 0xc0000005;
    memcpy( p, buffer, size );
    return 0;
}

#include "emu_extract.c"

static int failures, checks;

#define CHECK(cond, ...) do { checks++; if (!(cond)) { failures++; printf( "FAIL: " __VA_ARGS__ ); printf( "\n" ); } } while (0)

/*********************************************************************** ARPL */

enum { EAX, ECX, EDX, EBX, ESP, EBP, ESI, EDI };

struct arpl_case
{
    const char *name;
    BYTE bytes[16];
    unsigned int nbytes;
    unsigned int len;      /* expected instruction length, 0 = must be rejected */
    int dst_reg;           /* destination register, or -1 for memory */
    DWORD ea;              /* expected effective address for memory forms */
    int src_reg;
    DWORD regs[8];         /* low 32 bits; upper halves get garbage */
};

#define CODE (FAKE_ORG + 0x1000)
#define DATA (FAKE_ORG + 0x2000)

static const struct arpl_case arpl_cases[] =
{
    { "arpl ax,dx",           {0x63,0xd0}, 2, 2, EAX, 0, EDX },
    { "arpl ax,ax",           {0x63,0xc0}, 2, 2, EAX, 0, EAX },
    { "arpl bp,sp",           {0x63,0xe5}, 2, 2, EBP, 0, ESP },
    { "arpl di,si",           {0x63,0xf7}, 2, 2, EDI, 0, ESI },
    { "arpl [eax],dx",        {0x63,0x10}, 2, 2, -1, DATA, EDX, { [EAX] = DATA } },
    { "arpl [eax+8],dx",      {0x63,0x50,0x08}, 3, 3, -1, DATA + 8, EDX, { [EAX] = DATA } },
    { "arpl [ebp-0x10],cx",   {0x63,0x4d,0xf0}, 3, 3, -1, DATA + 0x30, ECX, { [EBP] = DATA + 0x40 } },
    { "arpl [eax+0x100],bx",  {0x63,0x98,0x00,0x01,0x00,0x00}, 6, 6, -1, DATA + 0x100, EBX, { [EAX] = DATA } },
    { "arpl [disp32],dx",     {0x63,0x15,0x10,0x20,0x40,0x00}, 6, 6, -1, DATA + 0x10, EDX },
    { "arpl [eax+ecx*4],dx",  {0x63,0x14,0x88}, 3, 3, -1, DATA + 0x14, EDX, { [EAX] = DATA, [ECX] = 5 } },
    { "arpl [disp32+none],dx",{0x63,0x14,0x25,0x20,0x20,0x40,0x00}, 7, 7, -1, DATA + 0x20, EDX },
    { "arpl [esp-4],dx",      {0x63,0x54,0x24,0xfc}, 4, 4, -1, DATA + 0x7c, EDX, { [ESP] = DATA + 0x80 } },
    { "arpl [ecx*8+disp32],ax",{0x63,0x04,0xcd,0x00,0x20,0x40,0x00}, 7, 7, -1, DATA + 0x18, EAX, { [ECX] = 3 } },
    { "arpl [ebp+esi*2+1],di",{0x63,0x7c,0x75,0x01}, 4, 4, -1, DATA + 0x45, EDI, { [EBP] = DATA + 0x40, [ESI] = 2 } },
    { "arpl [ebp+0],dx (mod1 rm5)", {0x63,0x55,0x00}, 3, 3, -1, DATA + 0x50, EDX, { [EBP] = DATA + 0x50 } },
    { "arpl [esp+eax*1],dx",  {0x63,0x14,0x04}, 3, 3, -1, DATA + 0x88, EDX, { [ESP] = DATA + 0x80, [EAX] = 8 } },
    { "32-bit wrap [eax+disp32]", {0x63,0x90,0x01,0x20,0x40,0x00}, 6, 6, -1, DATA, EDX, { [EAX] = 0xffffffff } },
    { "ds: prefix",           {0x3e,0x63,0x10}, 3, 3, -1, DATA, EDX, { [EAX] = DATA } },
    { "66 prefix",            {0x66,0x63,0xd0}, 3, 3, EAX, 0, EDX },
    { "ss: 66 prefixes",      {0x36,0x66,0x63,0x50,0x02}, 5, 5, -1, DATA + 2, EDX, { [EAX] = DATA } },
    { "fs: rejected",         {0x64,0x63,0x10}, 3, 0, -1, 0, EDX, { [EAX] = DATA } },
    { "gs: rejected",         {0x65,0x63,0x10}, 3, 0, -1, 0, EDX, { [EAX] = DATA } },
    { "addr16 rejected",      {0x67,0x63,0x10}, 3, 0, -1, 0, EDX, { [EAX] = DATA } },
    { "lock rejected",        {0xf0,0x63,0x10}, 3, 0, -1, 0, EDX, { [EAX] = DATA } },
    { "not arpl",             {0x62,0xd0}, 2, 0, -1, 0, EDX },
    { "unmapped memory",      {0x63,0x10}, 2, 0, -1, 0, EDX, { [EAX] = 0x1000 } },
};

static void init_uc( ucontext_t *uc, _STRUCT_MCONTEXT64 *mc )
{
    memset( uc, 0, sizeof(*uc) );
    memset( mc, 0, sizeof(*mc) );
    uc->uc_mcontext = mc;
}

static int run_arpl( const struct arpl_case *c, WORD dst_val, WORD src_val, ULONG64 cs,
                     ucontext_t *uc, BOOL *ret )
{
    static _STRUCT_MCONTEXT64 mc;
    CONTEXT context;
    int r;

    init_uc( uc, &mc );
    memset( fake_mem, 0xcc, sizeof(fake_mem) );
    memcpy( fake_mem + (CODE - FAKE_ORG), c->bytes, c->nbytes );
    for (r = 0; r < 8; r++)
        *get_gpr_sig( uc, r ) = 0xdead000000000000ull | ((ULONG64)r << 32) | c->regs[r];
    *(WORD *)get_gpr_sig( uc, c->src_reg ) = src_val;
    if (c->dst_reg >= 0) *(WORD *)get_gpr_sig( uc, c->dst_reg ) = dst_val;
    else if (c->len) memcpy( fake_mem + (c->ea - FAKE_ORG), &dst_val, 2 );
    CS_sig(uc) = cs;
    EFL_sig(uc) = 0x897;  /* CF PF AF SF OF set, ZF clear, plus bit 1 */
    RIP_sig(uc) = CODE;
    context.Rip = CODE;
    *ret = emulate_arpl( uc, &context );
    return 0;
}

static void test_arpl(void)
{
    static const WORD rpl_pairs[][2] = { {0,3}, {3,0}, {1,2}, {2,1}, {2,2}, {0,0}, {3,3}, {0,1} };
    unsigned int n, p;

    for (n = 0; n < sizeof(arpl_cases) / sizeof(arpl_cases[0]); n++)
    {
        const struct arpl_case *c = &arpl_cases[n];
        for (p = 0; p < sizeof(rpl_pairs) / sizeof(rpl_pairs[0]); p++)
        {
            WORD dst_val = 0xa5f0 | rpl_pairs[p][0], src_val = 0x5a0c | rpl_pairs[p][1];
            WORD expect = dst_val, got;
            BOOL ret, zf;
            ucontext_t uc;
            int same = c->dst_reg >= 0 && c->dst_reg == c->src_reg;
            ULONG64 before[8];
            int r;

            if (same) src_val = dst_val;
            zf = (dst_val & 3) < (src_val & 3);
            if (zf) expect = (dst_val & ~3) | (src_val & 3);

            run_arpl( c, dst_val, src_val, 0x107, &uc, &ret );
            if (!c->len)
            {
                CHECK( !ret, "%s: should be rejected", c->name );
                CHECK( RIP_sig(&uc) == CODE, "%s: rip moved on reject", c->name );
                CHECK( EFL_sig(&uc) == 0x897, "%s: flags changed on reject", c->name );
                continue;
            }
            CHECK( ret, "%s: not emulated", c->name );
            if (!ret) continue;
            CHECK( RIP_sig(&uc) == CODE + c->len, "%s: rip +%llu, want +%u", c->name,
                   RIP_sig(&uc) - CODE, c->len );
            CHECK( EFL_sig(&uc) == (zf ? 0x897 | 0x40 : 0x897), "%s: eflags %llx (zf %d)", c->name,
                   EFL_sig(&uc), zf );
            if (c->dst_reg >= 0)
            {
                got = *get_gpr_sig( &uc, c->dst_reg );
                CHECK( (*get_gpr_sig( &uc, c->dst_reg ) >> 16) ==
                       ((0xdead000000000000ull | ((ULONG64)c->dst_reg << 32) | c->regs[c->dst_reg]) >> 16),
                       "%s: upper register bits changed", c->name );
            }
            else memcpy( &got, fake_mem + (c->ea - FAKE_ORG), 2 );
            CHECK( got == expect, "%s rpl %d,%d: dst %04x, want %04x", c->name,
                   rpl_pairs[p][0], rpl_pairs[p][1], got, expect );

            /* nothing else written: other registers intact */
            for (r = 0; r < 8; r++) before[r] = 0xdead000000000000ull | ((ULONG64)r << 32) | c->regs[r];
            before[c->src_reg] = (before[c->src_reg] & ~0xffffull) | src_val;
            for (r = 0; r < 8; r++)
                if (r != c->dst_reg)
                    CHECK( *get_gpr_sig( &uc, r ) == before[r], "%s: register %d clobbered", c->name, r );
        }
    }

    /* 64-bit code: 63 is MOVSXD, never touched */
    {
        BOOL ret;
        ucontext_t uc;
        run_arpl( &arpl_cases[0], 0, 3, 0x33, &uc, &ret );
        CHECK( !ret, "64-bit cs: should be rejected" );
    }

    /* failed write leaves everything alone */
    {
        BOOL ret;
        ucontext_t uc;
        write_fail = 1;
        run_arpl( &arpl_cases[4], 0xa5f0, 0x0003, 0x107, &uc, &ret );
        write_fail = 0;
        CHECK( !ret && RIP_sig(&uc) == CODE && EFL_sig(&uc) == 0x897, "write failure not rejected cleanly" );
    }

    /* instruction cut off by the end of mapped memory */
    {
        static _STRUCT_MCONTEXT64 mc;
        ucontext_t uc;
        CONTEXT context;
        init_uc( &uc, &mc );
        fake_mem[FAKE_SIZE - 2] = 0x63;
        fake_mem[FAKE_SIZE - 1] = 0x50;  /* needs a disp8 that isn't there */
        CS_sig(&uc) = 0x107;
        RAX_sig(&uc) = DATA;
        context.Rip = RIP_sig(&uc) = FAKE_ORG + FAKE_SIZE - 2;
        CHECK( !emulate_arpl( &uc, &context ), "truncated instruction accepted" );
    }
}

/*********************************************************************** x87 */

typedef void (*fx_func)( XMM_SAVE_AREA32 *in, XMM_SAVE_AREA32 *out );

static BYTE *jit;
static volatile int sigill_count, emulate_failed;

static void sigill_handler( int sig, siginfo_t *info, void *ptr )
{
    ucontext_t *uc = ptr;
    CONTEXT context;

    sigill_count++;
    context.Rip = RIP_sig(uc);
    if (!emulate_x87_alias( uc, &context ))
    {
        emulate_failed = 1;
        RIP_sig(uc) += 2;  /* skip it so the test can report */
    }
}

/* fxrstor (%rdi); <op>; fxsave (%rsi); ret */
static fx_func make_fx( BYTE *where, BYTE b0, BYTE b1 )
{
    BYTE code[] = { 0x0f,0xae,0x0f, b0,b1, 0x0f,0xae,0x06, 0xc3 };
    memcpy( where, code, sizeof(code) );
    return (fx_func)where;
}

struct x87_alias { BYTE op, modrm, doc_op, doc_modrm; const char *name; };

static const struct x87_alias aliases[] =
{
    { 0xdc, 0xd0, 0xd8, 0xd0, "FCOM2" },
    { 0xdc, 0xd8, 0xd8, 0xd8, "FCOMP3" },
    { 0xde, 0xd0, 0xd8, 0xd8, "FCOMP5" },
    { 0xdd, 0xc8, 0xd9, 0xc8, "FXCH4" },
    { 0xdf, 0xc8, 0xd9, 0xc8, "FXCH7" },
    { 0xd9, 0xd8, 0xdd, 0xd8, "FSTP1" },
    { 0xdf, 0xd0, 0xdd, 0xd8, "FSTP8" },
    { 0xdf, 0xd8, 0xdd, 0xd8, "FSTP9" },
};

static void set_st( XMM_SAVE_AREA32 *fx, int i, long double v )
{
    memset( &fx->FloatRegisters[i], 0, 16 );
    memcpy( &fx->FloatRegisters[i], &v, 10 );
}

static void set_raw( XMM_SAVE_AREA32 *fx, int i, ULONG64 mant, WORD exp )
{
    memset( &fx->FloatRegisters[i], 0, 16 );
    memcpy( &fx->FloatRegisters[i], &mant, 8 );
    memcpy( (BYTE *)&fx->FloatRegisters[i] + 8, &exp, 2 );
}

/* x87 input states: top of stack, tag bits (by ST index), values */
static void make_state( XMM_SAVE_AREA32 *fx, int scenario )
{
    int i, top = 0, valid = 0xff;

    memset( fx, 0, sizeof(*fx) );
    fx->ControlWord = 0x037f;
    __asm__ volatile( "stmxcsr %0" : "=m" (fx->MxCsr) );
    for (i = 0; i < 16; i++) { fx->XmmRegisters[i].Low = 0x1111111111111111ull * i; fx->XmmRegisters[i].High = ~i; }
    for (i = 0; i < 8; i++) set_st( fx, i, 1.5L * (i + 1) );

    switch (scenario)
    {
    case 0: break;                                    /* full stack, distinct values */
    case 1: top = 6; valid = 0x03; break;             /* two values */
    case 2: set_raw( fx, 0, 0xc000000000000000ull, 0x7fff ); break;  /* ST0 = QNaN */
    case 3: set_raw( fx, 0, 0xa000000000000000ull, 0x7fff ); break;  /* ST0 = SNaN */
    case 4: for (i = 0; i < 8; i++) set_st( fx, i, -2.25L ); break;  /* all equal */
    case 5: top = 3; valid = 0x00; break;             /* empty stack: underflow */
    case 6: top = 5; valid = 0x01; break;             /* only ST0 valid */
    case 7: fx->ControlWord = 0x037e;                 /* IM unmasked, QNaN */
            set_raw( fx, 0, 0xc000000000000000ull, 0x7fff ); break;
    case 8: set_st( fx, 0, 0.0L ); set_st( fx, 1, -0.0L ); top = 7; break;  /* +0 vs -0 */
    case 9: set_raw( fx, 2, 1, 0 ); fx->ControlWord = 0x037d; break;  /* denormal ST2, DM unmasked */
    }
    fx->StatusWord = top << 11;
    /* abridged tag is indexed by physical register */
    for (i = 0; i < 8; i++) if (valid & (1 << i)) fx->TagWord |= 1 << ((top + i) & 7);
}
#define NB_SCENARIOS 10

static int compare_fx( const XMM_SAVE_AREA32 *a, const XMM_SAVE_AREA32 *b, char *why )
{
    int i;
    if (a->ControlWord != b->ControlWord) return sprintf( why, "fcw %04x/%04x", a->ControlWord, b->ControlWord );
    if (a->StatusWord != b->StatusWord) return sprintf( why, "fsw %04x/%04x", a->StatusWord, b->StatusWord );
    if (a->TagWord != b->TagWord) return sprintf( why, "ftw %02x/%02x", a->TagWord, b->TagWord );
    if (a->ErrorOpcode != b->ErrorOpcode) return sprintf( why, "fop %03x/%03x", a->ErrorOpcode, b->ErrorOpcode );
    if (a->MxCsr != b->MxCsr) return sprintf( why, "mxcsr %08x/%08x", a->MxCsr, b->MxCsr );
    for (i = 0; i < 8; i++)
        if (memcmp( &a->FloatRegisters[i], &b->FloatRegisters[i], 10 )) return sprintf( why, "st(%d)", i );
    if (memcmp( a->XmmRegisters, b->XmmRegisters, sizeof(a->XmmRegisters) )) return sprintf( why, "xmm" );
    return 0;
}

static void test_x87(void)
{
    struct sigaction sa;
    XMM_SAVE_AREA32 DECLSPEC_ALIGN(16) in, out_doc, out_alias;
    unsigned int a, i, s;
    char why[64];

    jit = mmap( NULL, 4096, PROT_READ | PROT_WRITE | PROT_EXEC, MAP_PRIVATE | MAP_ANON | MAP_JIT, -1, 0 );
    if (jit == MAP_FAILED) { perror( "mmap" ); exit( 2 ); }

    memset( &sa, 0, sizeof(sa) );
    sa.sa_sigaction = sigill_handler;
    sa.sa_flags = SA_SIGINFO;
    sigaction( SIGILL, &sa, NULL );

    for (a = 0; a <= sizeof(aliases) / sizeof(aliases[0]); a++)
        for (i = 0; i < 8; i++)
            for (s = 0; s < NB_SCENARIOS; s++)
            {
                BOOL ffreep = a == sizeof(aliases) / sizeof(aliases[0]);
                const char *name = ffreep ? "FFREEP" : aliases[a].name;
                int count;

                make_state( &in, s );
                memset( &out_doc, 0, sizeof(out_doc) );
                memset( &out_alias, 0, sizeof(out_alias) );

                if (ffreep)
                {
                    /* no documented twin: ffree st(i); ffree st(0); fincstp */
                    BYTE code[] = { 0x0f,0xae,0x0f, 0xdd,0xc0 + i, 0xdd,0xc0, 0xd9,0xf7, 0x0f,0xae,0x06, 0xc3 };
                    memcpy( jit + 64, code, sizeof(code) );
                    ((fx_func)(jit + 64))( &in, &out_doc );
                    make_fx( jit, 0xdf, 0xc0 + i )( &in, &out_alias );
                }
                else
                {
                    make_fx( jit + 64, aliases[a].doc_op, aliases[a].doc_modrm + i )( &in, &out_doc );
                    count = sigill_count;
                    make_fx( jit, aliases[a].op, aliases[a].modrm + i )( &in, &out_alias );
                    CHECK( sigill_count == count + 1, "%s st(%u): alias didn't fault (Rosetta changed?)", name, i );
                }
                CHECK( !emulate_failed, "%s st(%u) scenario %u: not emulated", name, i, s );
                emulate_failed = 0;
                CHECK( !compare_fx( &out_doc, &out_alias, why ), "%s st(%u) scenario %u: %s",
                       name, i, s, why );
            }

    /* documented forms and memory forms are left to Rosetta */
    {
        static _STRUCT_MCONTEXT64 mc;
        static const BYTE others[][2] = { {0xd8,0xd8}, {0xdc,0x18}, {0xde,0xd9}, {0xdf,0xe0}, {0xd9,0xc8}, {0x0f,0x0b} };
        ucontext_t uc;
        CONTEXT context;
        unsigned int n;

        for (n = 0; n < sizeof(others) / sizeof(others[0]); n++)
        {
            init_uc( &uc, &mc );
            memcpy( jit + 128, others[n], 2 );
            context.Rip = RIP_sig(&uc) = (ULONG_PTR)(jit + 128);
            CHECK( !emulate_x87_alias( &uc, &context ), "%02x %02x should not be emulated", others[n][0], others[n][1] );
        }
    }
}

int main(void)
{
    test_arpl();
    test_x87();
    printf( "%d checks, %d failures\n", checks, failures );
    return failures != 0;
}
