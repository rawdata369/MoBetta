/*
 * MoBetta - end-to-end DEP check, run inside Wine as a 32-bit Windows exe
 *
 * Linked without NX_COMPAT, the worst case: stock Wine turns DEP off for any
 * such module. Built and run by scripts/test_dep.sh. Prints one line per check
 * and exits 0 only if DEP is on, permanent, cannot be turned off, and running
 * code from a PAGE_READWRITE page raises an execute access violation.
 */
#include <windows.h>
#include <setjmp.h>
#include <stdio.h>

static jmp_buf env;
static ULONG_PTR fault_kind = ~0u;

static LONG CALLBACK handler( EXCEPTION_POINTERS *ep )
{
    if (ep->ExceptionRecord->ExceptionCode != EXCEPTION_ACCESS_VIOLATION)
        return EXCEPTION_CONTINUE_SEARCH;
    fault_kind = ep->ExceptionRecord->ExceptionInformation[0];
    longjmp( env, 1 );
}

static int check( const char *name, int ok )
{
    printf( "%s: %s\n", ok ? "ok" : "FAIL", name );
    return !ok;
}

int main( void )
{
    BOOL (WINAPI *pGetProcessDEPPolicy)( HANDLE, DWORD *, BOOL * );
    BOOL (WINAPI *pSetProcessDEPPolicy)( DWORD );
    HMODULE k32 = GetModuleHandleA( "kernel32.dll" );
    IMAGE_NT_HEADERS *nt;
    DWORD flags = 0;
    BOOL permanent = FALSE;
    volatile int ran = 0;
    unsigned char *page;
    int failures = 0;

    pGetProcessDEPPolicy = (void *)GetProcAddress( k32, "GetProcessDEPPolicy" );
    pSetProcessDEPPolicy = (void *)GetProcAddress( k32, "SetProcessDEPPolicy" );

    nt = (IMAGE_NT_HEADERS *)((char *)GetModuleHandleA( NULL ) +
                              ((IMAGE_DOS_HEADER *)GetModuleHandleA( NULL ))->e_lfanew);
    failures += check( "exe lacks NX_COMPAT",
                       !(nt->OptionalHeader.DllCharacteristics & IMAGE_DLLCHARACTERISTICS_NX_COMPAT) );

    failures += check( "GetProcessDEPPolicy succeeds",
                       pGetProcessDEPPolicy( GetCurrentProcess(), &flags, &permanent ) );
    printf( "     flags=0x%lx permanent=%d\n", flags, permanent );
    failures += check( "DEP enabled", flags & PROCESS_DEP_ENABLE );
    failures += check( "DEP permanent", permanent );
    failures += check( "SetProcessDEPPolicy(0) refused", !pSetProcessDEPPolicy( 0 ) );

    page = VirtualAlloc( NULL, 4096, MEM_COMMIT | MEM_RESERVE, PAGE_READWRITE );
    page[0] = 0xc3;  /* ret */
    AddVectoredExceptionHandler( 1, handler );
    if (!setjmp( env ))
    {
        ((void (*)(void))page)();
        ran = 1;
    }
    failures += check( "code on a PAGE_READWRITE page faults", !ran );
    failures += check( "fault is an execute violation", fault_kind == EXCEPTION_EXECUTE_FAULT );

    printf( "%d failures\n", failures );
    return failures != 0;
}
