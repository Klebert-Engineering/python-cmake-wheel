#include <pybind11/pybind11.h>
#include "lib_a.h"

namespace py = pybind11;

PYBIND11_MODULE(py_transitive, m) {
    m.doc() = "Test module with transitive library dependencies";

    m.def("process", &process_data, "Process data using lib_a (which uses lib_b)");

    m.def("test_transitive", []() {
        // This tests that lib_a can successfully call lib_b
        int result = process_data(5);
        return result == 25;  // (5 * 2 + 10) + 5 = 25
    }, "Test that transitive dependencies work correctly");
}
