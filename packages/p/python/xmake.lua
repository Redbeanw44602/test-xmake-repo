package("python")
    set_homepage("https://www.python.org/")
    set_description("The python programming language.")
    set_license("PSF")

    if is_host("windows") then
        if is_arch("x86", "i386") or os.arch() == "x86" then
            add_urls("https://github.com/xmake-mirror/python-windows/releases/download/$(version)/python-$(version).win32.zip")
            add_versions("3.13.1", "f89b297ca94ced2fbdad7919518ebf05005f39637f8ec5b01e42f2c71d53a673")
        else
            add_urls("https://github.com/xmake-mirror/python-windows/releases/download/$(version)/python-$(version).win64.zip")
            add_versions("3.13.1", "104d1de9eb6ff7c345c3415a57880dc0b2c51695515f2a87097512e6d77e977d")
        end
    else
        add_urls("https://www.python.org/ftp/python/$(version)/Python-$(version).tgz")
        add_versions("3.13.1", "1513925a9f255ef0793dbf2f78bb4533c9f184bdd0ad19763fd7f47a400a7c55")
    end

    if is_host("linux", "bsd") then
        add_deps("libffi", "zlib", {host = true, private = true})
        add_syslinks("util", "pthread", "dl")
    end

    on_load("windows", "msys", "cygwin", function (package)
        -- set includedirs
        package:add("includedirs", "include")

        -- set python environments
        local PYTHONPATH = package:installdir("Lib", "site-packages")
        package:addenv("PYTHONPATH", PYTHONPATH)
        package:addenv("PATH", "bin")
        package:addenv("PATH", "Scripts")
    end)

    on_load("macosx", "linux", "bsd", function (package)
        local version = package:version()

        -- set openssl dep
        if version:ge("3.10") then
            -- starting with Python 3.10, Python requires OpenSSL 1.1.1 or newer
            -- see https://peps.python.org/pep-0644/
            package:add("deps", "openssl >=1.1.1-a", "ca-certificates", {host = true})
        else
            package:add("deps", "openssl", "ca-certificates", {host = true})
        end

        -- set includedirs
        local pyver = ("python%d.%d"):format(version:major(), version:minor())
        if version:ge("3.0") and version:le("3.8") then
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

    on_install("windows|x86", "windows|x64", "msys", "cygwin", function (package)
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
        local python = path.join(package:installdir("bin"), "python.exe")
        os.vrunv(python, {"-m", "pip", "install", "--upgrade", "--force-reinstall", "pip"})
        os.vrunv(python, {"-m", "pip", "install", "--upgrade", "setuptools"})
        os.vrunv(python, {"-m", "pip", "install", "wheel"})
    end)

    on_install("macosx", "bsd", "linux", function (package)
        local version = package:version()

        -- init configs
        local configs = {"--enable-ipv6", "--with-ensurepip", "--enable-optimizations"}
        table.insert(configs, "--libdir=" .. package:installdir("lib"))
        table.insert(configs, "--with-platlibdir=lib")
        table.insert(configs, "--datadir=" .. package:installdir("share"))
        table.insert(configs, "--datarootdir=" .. package:installdir("share"))
        table.insert(configs, "--enable-shared=" .. (package:config("shared") and "yes" or "no"))

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
                    if version:ge("3.0") then
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

        -- add external path for zlib and libffi
        for _, libname in ipairs({"zlib", "libffi"}) do
            local lib = package:dep(libname)
            if lib and not lib:is_system() then
                local fetchinfo = lib:fetch({external = false})
                if fetchinfo then
                    for _, includedir in ipairs(fetchinfo.includedirs or fetchinfo.sysincludedirs) do
                        table.insert(cppflags, "-I" .. includedir)
                    end
                    for _, linkdir in ipairs(fetchinfo.linkdirs) do
                        table.insert(ldflags, "-L" .. linkdir)
                    end
                end
            end
        end
        if #cppflags > 0 then
            table.insert(configs, "CPPFLAGS=" .. table.concat(cppflags, " "))
        end
        if #ldflags > 0 then
            table.insert(configs, "LDFLAGS=" .. table.concat(ldflags, " "))
        end

        local pyver = ("python%d.%d"):format(version:major(), version:minor())
        -- https://github.com/python/cpython/issues/109796
        if version:ge("3.12.0") then
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
        if version:ge("3.0") then
            os.cp(path.join(package:installdir("bin"), "python3"), path.join(package:installdir("bin"), "python"))
            os.cp(path.join(package:installdir("bin"), "python3-config"), path.join(package:installdir("bin"), "python-config"))
        end

        -- install wheel
        local python = path.join(package:installdir("bin"), "python")
        local envs = {
            PATH = package:installdir("bin"),
            PYTHONPATH = package:installdir("lib", pyver, "site-packages"),
            LD_LIBRARY_PATH = package:installdir("lib")
        }
        os.vrunv(python, {"-m", "pip", "install", "--upgrade", "--force-reinstall", "pip"}, {envs = envs})
        os.vrunv(python, {"-m", "pip", "install", "--upgrade", "setuptools"}, {envs = envs})
        os.vrunv(python, {"-m", "pip", "install", "wheel"}, {envs = envs})
    end)

    on_test(function (package)
        if not package:is_cross() then
            os.vrun("python --version")
            os.vrun("python -c \"import pip\"")
            os.vrun("python -c \"import setuptools\"")
            os.vrun("python -c \"import wheel\"")
        end
        assert(package:has_cfuncs("PyModule_New", {includes = "Python.h"}))
    end)
