package("python")
    set_homepage("https://www.python.org/")
    set_description("The python programming language.")
    set_license("PSF")

    -- enable-FEATURE
    includes(path.join(os.scriptdir(), "constants.lua"))
    for _, feature in ipairs(constants.get_yn_features()) do
        -- if the user doesn't pass it (nil), we won't pass it either.
        add_configs(feature, {description = "Enable " .. feature .. ".", default = nil, type = "boolean"})
    end

    add_configs("framework", {description = "(macOS) Create a Python.framework rather than a traditional Unix install.", default = nil, type = "string"})
    add_configs("experimental_jit", {description = "Build the experimental just-in-time compiler.", default = nil, values = {true, false, "no", "yes", "yes-off", "interpreter"}})
    add_configs("big_digits", {description = "Use big digits for Python longs.", default = nil, type = "number", values = {15, 30}})

    -- with-PACKAGE
    add_configs("framework_name", {description = "(macOS) Specify the name for the python framework.", default = nil, type = "string"})
    add_configs("app_store_compliance", {description = "(macOS) Enable any patches required for compiliance with app stores.", default = nil, type = "boolean"}) -- 3.13
    add_configs("hash_algorithm", {description = "Select hash algorithm for use in Python/pyhash.c", default = nil, type = "string", values = {"fnv", "siphash13", "siphash24"}}) -- 3.4, 3.11
    add_configs("builtin_hashlib_hashes", {description = "Builtin hash modules. (md5, sha1, sha2, sha3, blake2)", default = nil, type = "string"}) -- 3.9
    add_configs("ssl_default_suites", {description = "Override default cipher suites string. (python, openssl)", default = nil, type = "string"}) -- 3.7, 3.10
    add_configs("lto", {description = "Enable Link-Time-Optimization in any build.", default = nil, values = {true, false, "full", "thin", "no", "yes"}})
    add_configs("ensurepip", {description = "'install' or 'upgrade' using bundled pip", default = nil, values = {true, false, "upgrade", "install", "no"}}) -- 3.6
    add_configs("emscripten_target", {description = "(wasm) Emscripten platform.", default = nil, type = "string", values = {"browser", "node"}})

    add_configs("openssl3", {description = "Use OpenSSL v3.", default = true, type = "boolean"})

    if is_plat("windows", "msys", "mingw", "cygwin") then
        if is_arch("x64", "x86_64") then
            add_urls("https://github.com/xmake-mirror/python-windows/releases/download/$(version)/python-$(version).win64.zip")
            add_versions("2.7.18", "6680835ed5b818e2c041c7033bea47ace17f6f3b73b0d6efb6ded8598a266754")
            add_versions("3.7.9", "d0d879c934b463d46161f933db53a676790d72f24e92143f629ee5629ae286bc")
            add_versions("3.8.10", "acf35048274404dd415e190bf5b928fae3b03d8bb5dfbfa504f9a183361468bd")
            add_versions("3.9.5", "3265059edac21bf4c46fac13553a5d78417e7aa209eceeffd0250aa1dd8d6fdf")
            add_versions("3.9.6", "57ccd1b1b5fbc62882bd2a6f47df6e830ba39af741acf0a1d2f161eef4e87f2e")
            add_versions("3.9.10", "4cee67e2a529fe363e34f0da57f8e5c3fc036913dc838b17389b2319ead0927e")
            add_versions("3.9.13", "6774fdd872fc55b028becc81b7d79bdcb96c5e0eb1483cfcd38224b921c94d7d")
        end
        if is_arch("x86", "i386") then
            add_urls("https://github.com/xmake-mirror/python-windows/releases/download/$(version)/python-$(version).win32.zip")
            add_versions("2.7.18", "95e21c87c9f38fa8068e014fc3683c3bc2c827f64875e620b9ecd3c75976a79c")
            add_versions("3.7.9", "55c8a408a11e598964f5d581589cf7f8c622e3cad048dce331ee5a61e5a6f57f")
            add_versions("3.8.10", "f520d2880578df076e3df53bf9e147b81b5328db02d8d873670a651fa076be50")
            add_versions("3.9.5", "ce0bfe8ced874d8d74a6cf6a98f13f5afee27cffbaf2d1ee0f09d3a027fab299")
            add_versions("3.9.6", "2918246384dfb233bd8f8c2bcf6aa3688e6834e84ab204f7c962147c468f8d12")
            add_versions("3.9.10", "e2c8e6b792748289ac27ef8462478022c96e24c99c4c3eb97d3afe510d9db646")
            add_versions("3.9.13", "c60ec0da0adf3a31623073d4fa085da62747085a9f23f4348fe43dfe94ea447b")
        end
    else
        add_urls("https://www.python.org/ftp/python/$(version)/Python-$(version).tgz")
        add_versions("2.7.18", "da3080e3b488f648a3d7a4560ddee895284c3380b11d6de75edb986526b9a814")
        add_versions("3.7.9", "39b018bc7d8a165e59aa827d9ae45c45901739b0bbb13721e4f973f3521c166a")
        add_versions("3.8.10", "b37ac74d2cbad2590e7cd0dd2b3826c29afe89a734090a87bf8c03c45066cb65")
        add_versions("3.9.5", "e0fbd5b6e1ee242524430dee3c91baf4cbbaba4a72dd1674b90fda87b713c7ab")
        add_versions("3.9.6", "d0a35182e19e416fc8eae25a3dcd4d02d4997333e4ad1f2eee6010aadc3fe866")
        add_versions("3.9.10", "1aa9c0702edbae8f6a2c95f70a49da8420aaa76b7889d3419c186bfc8c0e571e")
        add_versions("3.9.13", "829b0d26072a44689a6b0810f5b4a3933ee2a0b8a4bfc99d7c5893ffd4f97c44")
    end

    on_load("windows", "msys", "mingw", "cygwin", function (package)
        -- set includedirs
        package:add("includedirs", "include")

        -- set python environments
        local PYTHONPATH = package:installdir("Lib", "site-packages")
        package:addenv("PYTHONPATH", PYTHONPATH)
        package:addenv("PATH", "bin")
        package:addenv("PATH", "Scripts")
    end)

    on_load("macosx", "linux", "bsd", function (package)
        local pkgver = package:version()
        local pyver = ("python%d.%d"):format(pkgver:major(), pkgver:minor())

        -- add build dependencies
        package:add("deps", "bzip2") -- py module 'bz2'
        package:add("deps", "libb2") -- py module 'hashlib'
        package:add("deps", "libuuid") -- py module 'uuuid'
        package:add("deps", "zlib") -- py module 'gzip'
        package:add("deps", "ca-certificates") -- py module 'ssl'
        if is_plat("linux", "macosx", "bsd") then
            package:add("deps", "ncurses") -- py module 'curses'
            package:add("deps", "libedit") -- py module 'readline'
            package:add("deps", "libffi") -- py module 'ctypes'
            if pkgver:ge("3.10") then -- sqlite3, py module 'sqlite3'
                package:add("deps", "sqlite3 >=3.7.15")
            elseif pkgver:ge("3.13") then
                package:add("deps", "sqlite3 >=3.15.2")
            else
                package:add("deps", "sqlite3")
            end
        end
        if is_plat("linux", "macosx") then
            package:add("deps", "mpdecimal") -- py module 'decimal'
            package:add("deps", "lzma") -- py module 'lzma'
            package:add("deps", "readline") -- py module 'readline'
        end
        if is_plat("linux", "bsd") then
            package:add("syslinks", "util", "pthread", "dl")
        end
        
        if not is_plat("wasm") then
            if package:config("openssl3") then -- openssl, py module 'ssl', 'hashlib'
                package:add("deps", "openssl3")
            else
                if pkgver:ge("3.7") then
                    package:add("deps", "openssl >=1.0.2-a")
                elseif pkgver:ge("3.10") then
                    package:add("deps", "openssl >=1.1.1-a")
                else
                    package:add("deps", "openssl")
                end
            end
        end

        -- set includedirs
        if pkgver:ge("3.0") and pkgver:le("3.8") then
            package:add("includedirs", path.join("include", pyver .. "m"))
        else
            package:add("includedirs", path.join("include", pyver))
        end

        -- set python environments
        local PYTHONPATH = package:installdir("lib", pyver, "site-packages")
        package:addenv("PYTHONPATH", PYTHONPATH)
        package:addenv("PATH", "bin")
        package:addenv("PATH", "Scripts")
    end)

    on_fetch("fetch")

    on_install("windows|x86", "windows|x64", "msys", "mingw", "cygwin", function (package)
        if package:version():ge("3.0") then
            os.cp("python.exe", path.join(package:installdir("bin"), "python3.exe"))
        else
            os.cp("python.exe", path.join(package:installdir("bin"), "python2.exe"))
        end
        os.cp("*.exe", package:installdir("bin"))
        os.cp("*.dll", package:installdir("bin"))
        os.cp("Lib", package:installdir())
        os.cp("libs/*", package:installdir("lib"))
        os.cp("*", package:installdir())
        if package:config("pip") then
            local python = path.join(package:installdir("bin"), "python.exe")
            os.vrunv(python, {"-m", "pip", "install", "--upgrade", "--force-reinstall", "pip"})
            os.vrunv(python, {"-m", "pip", "install", "--upgrade", "setuptools"})
            os.vrunv(python, {"-m", "pip", "install", "wheel"})
        end
    end)

    --- android, iphoneos, wasm unsupported: dependencies not resolved.
    on_install("macosx", "linux", "bsd", function (package)
        local constants = import('constants')()
        function opt2cfg(cfg)
            if type(cfg) == "boolean" then
                return cfg and 'yes' or 'no'
            end
            return cfg
        end

        local pkgver = package:version()
        local pyver = ("python%d.%d"):format(pkgver:major(), pkgver:minor())

        -- init configs
        local configs = {}
        table.insert(configs, "--libdir=" .. package:installdir("lib"))
        table.insert(configs, "--datadir=" .. package:installdir("share"))
        table.insert(configs, "--datarootdir=" .. package:installdir("share"))
        for _, feature in ipairs(constants.get_all_features()) do
            if package:config(feature) ~= nil then
                table.insert(configs, ("--enable-%s=%s"):format(feature:gsub("_", "-"), opt2cfg(package:config(feature))))
            end
        end
        for _, pkg in ipairs(constants.get_supported_packages()) do
            if package:config(feature) ~= nil then
                table.insert(configs, ("--with-%s=%s"):format(pkg:gsub("_", "-"), opt2cfg(package:config(feature))))
            end
        end

        -- add openssl libs path
        local openssl = package:dep(package:config("openssl3") and "openssl3" or "openssl"):fetch()
        if openssl then
            local openssl_dir
            for _, linkdir in ipairs(openssl.linkdirs) do
                if path.filename(linkdir) == "lib" then
                    openssl_dir = path.directory(linkdir)
                else
                    -- try to find if linkdir is root (brew has linkdir as root and includedirs inside)
                    for _, includedir in ipairs(openssl.sysincludedirs or openssl.includedirs) do
                        if includedir:startswith(linkdir) then
                            openssl_dir = linkdir
                            break
                        end
                    end
                end
                if openssl_dir then
                    if pkgver:ge("3.0") then
                        table.insert(configs, "--with-openssl=" .. openssl_dir)
                    else
                        io.gsub("setup.py", "/usr/local/ssl", openssl_dir)
                    end
                    break
                end
            end
        end

        -- allow python modules to use ctypes.find_library to find xmake's stuff
        if package:is_plat("macosx") then
            io.gsub("Lib/ctypes/macholib/dyld.py", "DEFAULT_LIBRARY_FALLBACK = %[", format("DEFAULT_LIBRARY_FALLBACK = [ '%s/lib',", package:installdir()))
        end

        -- add flags for macOS
        local cppflags = {}
        local ldflags = {}
        if package:is_plat("macosx") then
            -- get xcode information
            import("core.tool.toolchain")
            local xcode_dir
            local xcode_sdkver
            local target_minver
            local xcode = toolchain.load("xcode", {plat = package:plat(), arch = package:arch()})
            if xcode and xcode.config and xcode:check() then
                xcode_dir = xcode:config("xcode")
                xcode_sdkver = xcode:config("xcode_sdkver")
                target_minver = xcode:config("target_minver")
            end
            xcode_dir = xcode_dir or get_config("xcode")
            xcode_sdkver = xcode_sdkver or get_config("xcode_sdkver")
            target_minver = target_minver or get_config("target_minver")

            if xcode_dir and xcode_sdkver then
                -- help Python's build system (setuptools/pip) to build things on SDK-based systems
                -- the setup.py looks at "-isysroot" to get the sysroot (and not at --sysroot)
                local xcode_sdkdir = xcode_dir .. "/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX" .. xcode_sdkver .. ".sdk"
                table.insert(cppflags, "-isysroot " .. xcode_sdkdir)
                table.insert(cppflags, "-I" .. path.join(xcode_sdkdir, "/usr/include"))
                table.insert(ldflags, "-isysroot " .. xcode_sdkdir)

                -- for the Xlib.h, Python needs this header dir with the system Tk
                -- yep, this needs the absolute path where zlib needed a path relative to the SDK.
                table.insert(cppflags, "-I" .. path.join(xcode_sdkdir, "/System/Library/Frameworks/Tk.framework/Versions/8.5/Headers"))
            end

            -- avoid linking to libgcc https://mail.python.org/pipermail/python-dev/2012-February/116205.html
            if target_minver then
                table.insert(configs, "MACOSX_DEPLOYMENT_TARGET=" .. target_minver)
            end
        end

        -- add pic
        if package:is_plat("linux", "bsd") and package:config("pic") ~= false then
            table.insert(cppflags, "-fPIC")
        end

        if #cppflags > 0 then
            table.insert(configs, "CPPFLAGS=" .. table.concat(cppflags, " "))
        end
        if #ldflags > 0 then
            table.insert(configs, "LDFLAGS=" .. table.concat(ldflags, " "))
        end

        -- https://github.com/python/cpython/issues/109796
        if pkgver:ge("3.12.0") then
            os.mkdir(package:installdir("lib", pyver))
        end

        -- fix ssl module detect, e.g. gcc conftest.c -ldl   -lcrypto >&5
        if package:is_plat("linux") then
            io.replace("./configure", "-lssl -lcrypto", "-lssl -lcrypto -ldl", {plain = true})
        end

        -- unset these so that installing pip and setuptools puts them where we want
        -- and not into some other Python the user has installed.
        import("package.tools.autoconf").configure(package, configs, {envs = {PYTHONHOME = "", PYTHONPATH = ""}})
        os.vrunv("make", {"-j4", "PYTHONAPPSDIR=" .. package:installdir()})
        os.vrunv("make", {"install", "-j4", "PYTHONAPPSDIR=" .. package:installdir()})
        if pkgver:ge("3.0") then
            os.cp(path.join(package:installdir("bin"), "python3"), path.join(package:installdir("bin"), "python"))
            os.cp(path.join(package:installdir("bin"), "python3-config"), path.join(package:installdir("bin"), "python-config"))
        end

        -- install wheel
        if package:config("ensurepip") then
            local python = path.join(package:installdir("bin"), "python")
            local envs = {
                PATH = package:installdir("bin"),
                PYTHONPATH = package:installdir("lib", pyver, "site-packages"),
                LD_LIBRARY_PATH = package:installdir("lib")
            }
            os.vrunv(python, {"-m", "pip", "install", "--upgrade", "--force-reinstall", "pip"}, {envs = envs})
            os.vrunv(python, {"-m", "pip", "install", "--upgrade", "setuptools"}, {envs = envs})
            os.vrunv(python, {"-m", "pip", "install", "wheel"}, {envs = envs})
        end
    end)

    on_test(function (package)
        if not package:is_cross() then
            os.vrun("python --version")
            if package:config("ensurepip") then
                os.vrun("python -c \"import pip\"")
                os.vrun("python -c \"import setuptools\"")
                os.vrun("python -c \"import wheel\"")
            end
        end
        assert(package:check_csnippets({test = [[
            #include <Python.h>
            void test() {
                Py_Initialize();
                Py_Finalize();
            }
        ]]}, {configs = {languages = 'c11'}}))
    end)
