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
            add_versions("3.13.2", "baee66e4d1b16a220bf61d64a210676f6d6fef69c65959ffd9828264c7fe8ef5")
        end
        if is_arch("x86", "i386") then
            add_urls("https://github.com/xmake-mirror/python-windows/releases/download/$(version)/python-$(version).win32.zip")
            add_versions("3.13.2", "67ccaa5e8fb05e8e15a46f9262368fcfef190b1cfab3e2511acada7d68cf6464")
        end
    else
        add_urls("https://www.python.org/ftp/python/$(version)/Python-$(version).tgz")
        add_versions("3.13.2", "b8d79530e3b7c96a5cb2d40d431ddb512af4a563e863728d8713039aa50203f9")
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

    on_load("macosx", "linux", "bsd", "android", "iphoneos", "wasm", function (package)
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

    on_install("macosx", "linux", "bsd", "android", "iphoneos", "wasm", function (package)
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
        local openssl = package:dep("openssl"):fetch()
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
