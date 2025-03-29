package("llvm")
    set_kind("toolchain") -- also supports "kind = library" 
    set_homepage("https://llvm.org/")
    set_description("The LLVM Compiler Infrastructure.")

    -- The LLVM shared library cannot be built under windows.
    add_configs("shared", {description = "Build shared library.", default = false, type = "boolean", readonly = is_plat("windows")})

    add_configs("exception", {description = "Enable C++ exception support for LLVM.", default = true, type = "boolean"})
    add_configs("rtti",      {description = "Enable C++ RTTI support for LLVM.", default = true, type = "boolean"})

    add_configs("use_dia",     {description = "Enable DIA SDK to support non-native PDB parsing. (msvc only)", default = true, type = "boolean"})
    add_configs("use_libffi",  {description = "Enable libffi to support the LLVM interpreter to call external functions.", default = false, type = "boolean"})
    add_configs("use_httplib", {description = "Enable cpp-httplib to support llvm-debuginfod serve debug information over HTTP.", default = false, type = "boolean"})
    add_configs("use_libcxx",  {description = "Use libc++ as C++ standard library instead of libstdc++, ", default = false, type = "boolean"})
    add_configs("use_zlib",    {description = "Indicates whether to use zlib, by default it is only used if available.", default = nil, type = "boolean"})
    add_configs("use_zstd",    {description = "Indicates whether to use zstd, by default it is only used if available.", default = nil, type = "boolean"})

    includes(path.join(os.scriptdir(), "constants.lua"))
    for _, project in ipairs(constants.get_llvm_known_projects()) do
        add_configs(project, {description = "Build " .. project .. " project.", default = (project == "clang"), type = "boolean"})
    end
    add_configs("all", {description = "Build all projects.", default = false, type = "boolean"})

    set_urls("https://github.com/llvm/llvm-project/releases/download/llvmorg-$(version)/llvm-project-$(version).src.tar.xz")
    add_versions("16.0.6", "ce5e71081d17ce9e86d7cbcfa28c4b04b9300f8fb7e78422b1feb6bc52c3028e")
    add_versions("17.0.6", "58a8818c60e6627064f312dbf46c02d9949956558340938b71cf731ad8bc0813")
    add_versions("18.1.8", "0b58557a6d32ceee97c8d533a59b9212d87e0fc4d2833924eb6c611247db2f2a")
    add_versions("19.1.7", "82401fea7b79d0078043f7598b835284d6650a75b93e64b6f761ea7b63097501")

    add_deps("cmake")
    on_load(function (package)
        -- add deps.
        if package:config("use_libffi") then
            package:add("deps", "libffi")
        end
        if package:config("use_httplib") then
            package:add("deps", "cpp-httplib")
        end
        if package:config("use_libcxx") then
            package:add("deps", "libc++", {host = true})
        end
        if package:config("use_zlib") then
            package:add("deps", "zlib", {host = true})
        end
        if package:config("use_zstd") then
            package:add("deps", "zstd", {host = true})
        end

        -- add components
        if package:is_library() then
            local components = {"flang", "clang", "mlir", "libunwind"}
            for _, name in ipairs(components) do
                if package:config(name) or package:config("all") then
                    package:add("components", name, {deps = "base"})
                end
            end
            package:add("components", "base", {default = true})
        end
    end)

    on_fetch("fetch")

    on_install(function (package)
        local constants = import('constants')()
        
        local projects_enabled = {}
        if package:config("all") then
            table.insert(projects_enabled, "all")
        else
            for _, project in ipairs(constants.get_llvm_known_projects()) do
                if package:config(project) then
                    table.insert(projects_enabled, project)
                end
            end
        end

        local configs = {
            "-DCMAKE_BUILD_TYPE=Release",
            "-DLLVM_INCLUDE_BENCHMARKS=OFF",
            "-DLLVM_INCLUDE_EXAMPLES=OFF",
            "-DLLVM_INCLUDE_TESTS=OFF",
            "-DLLVM_OPTIMIZED_TABLEGEN=ON",
            "-DLLVM_ENABLE_PROJECTS=" .. table.concat(projects_enabled, ";")
        }
        table.insert(configs, "-DLLVM_BUILD_LLVM_DYLIB=" .. (package:config("shared") and "ON" or "OFF"))
        table.insert(configs, "-DLLVM_BUILD_TOOLS="  .. (package:is_toolchain() and "ON" or "OFF"))
        table.insert(configs, "-DLLVM_INCLUDE_TOOLS=" .. (package:is_toolchain() and "ON" or "OFF"))
        table.insert(configs, "-DLLVM_ENABLE_EH=" .. (package:config("exception") and "ON" or "OFF"))
        table.insert(configs, "-DLLVM_ENABLE_RTTI=" .. (package:config("rtti") and "ON" or "OFF"))
        table.insert(configs, "-DLLVM_ENABLE_DIA_SDK=" .. (package:config("use_dia") and "ON" or "OFF"))
        table.insert(configs, "-DLLVM_ENABLE_LIBPFM=" .. (package:config("use_libpfm") and "ON" or "OFF"))
        table.insert(configs, "-DLLVM_ENABLE_LIBCXX=" .. (package:config("use_libcxx") and "ON" or "OFF"))
        if package:config("use_libffi") then
            table.insert(configs, "-DLLVM_ENABLE_FFI=ON")
            table.insert(configs, "-DFFI_INCLUDE_DIR=" .. package:dep("libffi"):installdir("include"))
            table.insert(configs, "-DFFI_LIBRARY_DIR=" .. package:dep("libffi"):installdir("lib"))
        else
            table.insert(configs, "-DLLVM_ENABLE_FFI=OFF")
        end
        if package:config("use_httplib") then
            table.insert(configs, "-DLLVM_ENABLE_HTTPLIB=ON")
            table.insert(configs, "-Dhttplib_ROOT=" .. package:dep("cpp-httplib"):installdir())
        else
            table.insert(configs, "-DLLVM_ENABLE_HTTPLIB=OFF")
        end
        if package:config("use_zlib") == nil then
            table.insert(configs, "-DLLVM_ENABLE_ZLIB=ON")
        else
            table.insert(configs, "-DLLVM_ENABLE_ZLIB=" .. (package:config("use_zlib") and "FORCE_ON" or "OFF"))
        end
        if package:config("use_zstd") == nil then
            table.insert(configs, "-DLLVM_ENABLE_ZSTD=ON")
        else
            table.insert(configs, "-DLLVM_ENABLE_ZSTD=" .. (package:config("use_zstd") and "FORCE_ON" or "OFF"))
        end

        os.cd("llvm")
        import("package.tools.cmake").install(package, configs)
    end)

    on_component("flang", function (package, component)
        local constants = import('constants')()
        component:add("links", package:config("shared") and constants.get_flang_shared_libraries() or constants.get_flang_static_libraries())
    end)

    on_component("clang", function (package, component)
        local constants = import('constants')()
        component:add("links", package:config("shared") and constants.get_clang_shared_libraries() or constants.get_clang_static_libraries())
    end)

    on_component("mlir", function (package, component)
        local constants = import('constants')()
        component:add("links", package:config("shared") and constants.get_llvm_shared_libraries() or constants.get_llvm_static_libraries())
    end)

    on_component("libunwind", function (package, component)
        component:add("links", {
            "unwind"
        })
    end)

    on_component("base", function (package, component)
        local constants = import('constants')()
        component:add("links", package:config("shared") and constants.get_llvm_shared_libraries() or constants.get_llvm_static_libraries())
    end)

    on_test(function (package)
        if package:is_toolchain() and not package:is_cross() then
            os.vrun(package:installdir() .. "/bin/llvm-config --version")
            if package:config("clang") then
                os.vrun(package:installdir() .. "/bin/clang --version")
            end
        elseif package:is_library() and package:config("clang") then
            assert(package:check_cxxsnippets({test = [[
                #include <clang/Frontend/CompilerInstance.h>
                int main(int argc, char** argv) {
                    clang::CompilerInstance instance;
                    return 0;
                }
            ]]}, {configs = {languages = 'c++17'}}))
        end
    end)
