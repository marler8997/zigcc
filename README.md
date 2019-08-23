# zigcc

Wrappers for the Zig compiler to emulator C compiler command-line interfaces

### Build
```
zig build
```

### Usage
```
./zig-cache/bin/zigcc <cc-command-line-options>...
```

# Status

Currently testing this by trying to build SDL with zig.  SDL uses autotools so it performs a bunch of tests on the C compiler which provides a free "test-suite" for zigcc.

Currently able to compile executables and object files with simple options.  SDL is now failing because it can't invoke the C Preprocessor with the `-E` option.  Trying to figure out the best way to implment that with zigcc.
