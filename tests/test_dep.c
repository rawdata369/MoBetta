/*
 * MoBetta - unit test for get_execute_flags() in the patched unix/process.c
 *
 * Built by scripts/test_dep.sh, which extracts get_execute_flags() into
 * dep_extract.c. The result is cached per process, so each case is one run:
 *   test_dep <expect_permanent 0|1>
 * with WINE_FORCE_NX set or unset by the script.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/sysctl.h>

typedef unsigned int ULONG;
#define MEM_EXECUTE_OPTION_DISABLE   0x01
#define MEM_EXECUTE_OPTION_PERMANENT 0x08
#define TRACE(...) do { } while (0)

static ULONG execute_flags = MEM_EXECUTE_OPTION_DISABLE;

#include "dep_extract.c"

int main( int argc, char **argv )
{
    int expect = argc > 1 && atoi( argv[1] );
    ULONG flags = get_execute_flags();
    int permanent = !!(flags & MEM_EXECUTE_OPTION_PERMANENT);
    int ok = permanent == expect && (flags & MEM_EXECUTE_OPTION_DISABLE) &&
             get_execute_flags() == flags;

    printf( "%s: WINE_FORCE_NX=%s flags=0x%x, expected permanent=%d\n", ok ? "ok" : "FAIL",
            getenv( "WINE_FORCE_NX" ) ? getenv( "WINE_FORCE_NX" ) : "(unset)", flags, expect );
    return !ok;
}
