#include <pybind11/pybind11.h>
#include "simple_lib.h"

namespace py = pybind11;

PYBIND11_MODULE(py_simple, m) {
    m.doc() = "Simple test library for python-cmake-wheel";

    py::class_<simple::Calculator>(m, "Calculator")
        .def(py::init<>())
        .def("add", &simple::Calculator::add, "Add two numbers")
        .def("multiply", &simple::Calculator::multiply, "Multiply two numbers");
}
