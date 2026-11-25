#include <Python.h>

static struct PyModuleDef module = {PyModuleDef_HEAD_INIT, "example", NULL, -1, NULL};
PyMODINIT_FUNC PyInit_example(void) { return PyModule_Create(&module); }
