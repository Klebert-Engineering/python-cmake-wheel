#include "lib_a.h"
#include "lib_b.h"

int process_data(int x) {
    // lib_a uses lib_b internally
    return compute_value(x) + 5;
}
