package("llvm")
    set_kind("toolchain") -- also supports "kind = library" 
    set_homepage("https://llvm.org/")
    set_description("The LLVM Compiler Infrastructure.")

    -- The LLVM shared library cannot be built under windows.
    add_configs("shared", {description = "Build shared library.", default = false, type = "boolean", readonly = is_plat("windows")})

    add_configs("exception", {description = "Enable C++ exception support for LLVM.", default = true, type = "boolean"})
    add_configs("rtti",      {description = "Enable C++ RTTI support for LLVM.", default = true, type = "boolean"})
    add_configs("lto",       {description = "Enable link-time optimizations for LLVM builds.", default = "on", type = "string", values = {"on", "off", "thin", "full"}})

    add_configs("ms_dia",  {description = "Enable DIA SDK to support non-native PDB parsing. (msvc only)", default = true, type = "boolean"})
    add_configs("libffi",  {description = "Enable libffi to support the LLVM interpreter to call external functions.", default = false, type = "boolean"})
    add_configs("httplib", {description = "Enable cpp-httplib to support llvm-debuginfod serve debug information over HTTP.", default = false, type = "boolean"})
    add_configs("libcxx",  {description = "Use libc++ as C++ standard library instead of libstdc++, ", default = false, type = "boolean"})
    add_configs("zlib",    {description = "Indicates whether to use zlib, by default it is only used if available.", default = nil, type = "boolean"})
    add_configs("zstd",    {description = "Indicates whether to use zstd, by default it is only used if available.", default = nil, type = "boolean"})

    includes(path.join(os.scriptdir(), "constants.lua"))
    for _, project in ipairs(constants.get_llvm_known_projects()) do
        add_configs(project, {description = "Build " .. project .. " project.", default = (project == "clang"), type = "boolean"})
    end
    add_configs("all", {description = "Build all projects.", default = false, type = "boolean"})

    on_source(function (package)
        if package:is_plat("windows") then
            if package:is_arch("x86") then
                package:set("urls", "https://github.com/xmake-mirror/llvm-windows/releases/download/$(version)/clang+llvm-$(version)-win32.zip")
                package:add("versions", "16.0.6", "5e1f560f75e7a4c7a6509cf7d9a28b4543e7afcb4bcf4f747e9f208f0efa6818")
                package:add("versions", "17.0.6", "ce78b510603cb3b347788d2f52978e971cf5f55559151ca13a73fd400ad80c41")
                package:add("versions", "18.1.1", "9f59dd99d45f64a5c00b00d27da8fe8b5f162905026f5c9ef0ade6e73ae18df3")
            else
                package:set("urls", "https://github.com/xmake-mirror/llvm-windows/releases/download/$(version)/clang+llvm-$(version)-win64.zip")
                package:add("versions", "16.0.6", "7adb1a630b6cc676a4b983aca9b01e67f770556c6e960e9ee9aa7752c8beb8a3")
                package:add("versions", "17.0.6", "c480a4c280234b91f7796a1b73b18134ae62fe7c88d2d0c33312d33cb2999187")
                package:add("versions", "18.1.1", "28a9fbcd18f1e7e736ece6d663726bc15649f025343c3004dcbfc2d367b9924c")
            end
        else
            package:set("urls", "https://github.com/llvm/llvm-project/releases/download/llvmorg-$(version)/llvm-project-$(version).src.tar.xz")
            package:add("versions", "16.0.6", "ce5e71081d17ce9e86d7cbcfa28c4b04b9300f8fb7e78422b1feb6bc52c3028e")
            package:add("versions", "17.0.6", "58a8818c60e6627064f312dbf46c02d9949956558340938b71cf731ad8bc0813")
            package:add("versions", "18.1.1", "8f34c6206be84b186b4b31f47e1b52758fa38348565953fad453d177ef34c0ad")
        end
    end)

    add_deps("cmake")
    on_load(function (package)
        -- add deps.
        if package:config("libffi") then
            package:add("deps", "libffi")
        end
        if package:config("httplib") then
            package:add("deps", "cpp-httplib")
        end
        if package:config("libcxx") then
            package:add("deps", "libc++")
        end
        if package:config("zlib") then
            package:add("deps", "zlib")
        end
        if package:config("zstd") then
            package:add("deps", "zstd")
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

    on_install("windows", "msys", "cygwin", function (package)
        os.cp("*", package:installdir())
    end)

    on_install("linux", "macosx", "bsd", "android", "iphoneos", "wasm", function (package)
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
        table.insert(configs, "-DLLVM_ENABLE_DIA_SDK=" .. (package:config("ms_dia") and "ON" or "OFF"))
        table.insert(configs, "-DLLVM_ENABLE_LIBPFM=" .. (package:config("use_libpfm") and "ON" or "OFF"))
        table.insert(configs, "-DLLVM_ENABLE_LIBCXX=" .. (package:config("libcxx") and "ON" or "OFF"))
        table.insert(configs, "-DLLVM_ENABLE_LTO=" .. package:config("lto"))
        if package:config("libffi") then
            table.insert(configs, "-DLLVM_ENABLE_FFI=ON")
            table.insert(configs, "-DFFI_INCLUDE_DIR=" .. package:dep("libffi"):installdir("include"))
            table.insert(configs, "-DFFI_LIBRARY_DIR=" .. package:dep("libffi"):installdir("lib"))
        else
            table.insert(configs, "-DLLVM_ENABLE_FFI=OFF")
        end
        if package:config("httplib") then
            table.insert(configs, "-DLLVM_ENABLE_HTTPLIB=ON")
            table.insert(configs, "-Dhttplib_ROOT=" .. package:dep("cpp-httplib"):installdir())
        else
            table.insert(configs, "-DLLVM_ENABLE_HTTPLIB=OFF")
        end
        if package:config("zlib") == nil then
            table.insert(configs, "-DLLVM_ENABLE_ZLIB=ON")
        else
            table.insert(configs, "-DLLVM_ENABLE_ZLIB=" .. (package:config("zlib") and "FORCE_ON" or "OFF"))
        end
        if package:config("zstd") == nil then
            table.insert(configs, "-DLLVM_ENABLE_ZSTD=ON")
        else
            table.insert(configs, "-DLLVM_ENABLE_ZSTD=" .. (package:config("zstd") and "FORCE_ON" or "OFF"))
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
        elseif package:is_library() then
            if package:config("clang") then
                assert(package:check_cxxsnippets({test = [[
                    #include <clang/Frontend/CompilerInstance.h>
                    void test() {
                        clang::CompilerInstance instance;
                    }
                ]]}, {configs = {languages = 'c++17'}}))
            end
            if package:config("mlir") then
                assert(package:check_cxxsnippets({test = [[
                    #include <mlir/IR/MLIRContext.h>
                    void test() {
                        mlir::MLIRContext context;
                    }   
                ]]}, {configs = {languages = 'c++17'}}))
            end
            assert(package:check_cxxsnippets({test = [[
                #include <llvm/IR/LLVMContext.h>
                #include <llvm/IR/Module.h>
                void test() {
                    llvm::LLVMContext context;
                    llvm::Module module("test", context);
                }
            ]]}, {configs = {languages = 'c++17'}}))
        end
    end)
