/*
 * MoBetta - end-to-end x87 check, run inside Wine as a 32-bit Windows exe
 *
 * Built with x87 math only (no SSE) and run at the 53-bit precision control
 * Windows (and MSVC-built WoW) uses. Runs a fixed x87 loop and prints:
 *   bits <hex>   the loop's result, which must match bit for bit with and
 *                without the x87sidecar (add, mul, div, sqrt are exact at 53 bits)
 *   ms <n>       how long the loop took
 * Built and run by scripts/test_x87.sh.
 */
#include <windows.h>
#include <float.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main( int argc, char **argv )
{
    LARGE_INTEGER freq, t0, t1;
    volatile double seed = 1.0000001;
    double x = 0.5, y = 0.0;
    unsigned long long bits;
    int i, n = argc > 1 ? atoi( argv[1] ) : 20000000;

    _controlfp( _PC_53, _MCW_PC );
    QueryPerformanceFrequency( &freq );
    QueryPerformanceCounter( &t0 );
    for (i = 0; i < n; i++)
    {
        x = x * seed + 0.25;
        y = y + sqrt( x ) / (x + 1.0);
        if (x > 1e6) x = 0.5;
    }
    QueryPerformanceCounter( &t1 );

    memcpy( &bits, &y, sizeof(bits) );
    printf( "bits %016llx\n", bits );
    printf( "ms %lld\n", (t1.QuadPart - t0.QuadPart) * 1000 / freq.QuadPart );
    return 0;
}
