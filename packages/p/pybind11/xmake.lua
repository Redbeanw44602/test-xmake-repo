package("pybind11")
    set_kind("library", {headeronly = true})

    set_homepage("https://github.com/pybind/pybind11")
    set_description("Seamless operability between C++11 and Python.")
    set_license("BSD-3-Clause")

    add_urls("https://github.com/pybind/pybind11/archive/refs/tags/$(version).zip",
             "https://github.com/pybind/pybind11.git")
    add_versions("v2.13.6", "d0a116e91f64a4a2d8fb7590c34242df92258a61ec644b79127951e821b47be6")

    add_deps("cmake")
    add_deps("python 3.x", {system = false})
    on_install(function (package)
        local configs = {
            "-DPYBIND11_TEST=OFF"
        }

        table.insert(configs, "-DPython_ROOT_DIR=" .. package:dep("python"):installdir())
        import("package.tools.cmake").install(package, configs)
    end)

    on_test(function (package)
        assert(package:check_cxxsnippets({test = [[
            #include <pybind11/pybind11.h>
            int add(int i, int j) {
                return i + j;
            }
            PYBIND11_MODULE(example, m) {
                m.def("add", &add, "A function which adds two numbers");
            }
        ]]}, {configs = {languages = "c++11"}}))
    end)
