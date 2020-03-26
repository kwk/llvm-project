// clang-format off
// REQUIRES: debuginfod
// UNSUPPORTED: darwin, windows

//  Test that we can display the source of functions using debuginfod when the
//  original source file is no longer present.
//  
//  The debuginfod client requires a buildid in the binary, so we compile one in.
//  We can create the directory structure on disc that the client expects on a
//  webserver that serves source files. We then set DEBUGINFOD_URLS to the mock
//  directory using file://<path-to-mock-dir>. This avoids the need for a
//  debuginfod server to be run. 
//  
//  Go here to find more about debuginfod:
//  https://sourceware.org/elfutils/Debuginfod.html


//    We copy this file because we want to compile and later move it away

// RUN: mkdir -p %t.buildroot
// RUN: cp %s %t.buildroot/test.cpp

//    We use the prefix map in order to overwrite all DW_AT_decl_file paths
//    in the DWARF. We cd into the directory before compiling to get
//    DW_AT_comp_dir pickup %t.buildroot as well so it will be replaced by
//    /my/new/path.

// RUN: cd %t.buildroot
// RUN: %clang_host \
// RUN:   -g \
// RUN:   -Wl,--build-id="0xaaaaaaaaaabbbbbbbbbbccccccccccdddddddddd" \
// RUN:   -fdebug-prefix-map=%t.buildroot=/my/new/path \
// RUN:   -o %t \
// RUN:   %t.buildroot/test.cpp


//    We move the original source file to a directory that looks like a debuginfod
//    URL part.

// RUN: rm -rf %t.mock
// RUN: mkdir -p       %t.mock/buildid/aaaaaaaaaabbbbbbbbbbccccccccccdddddddddd/source/my/new/path
// RUN: mv    %t.buildroot/test.cpp %t.mock/buildid/aaaaaaaaaabbbbbbbbbbccccccccccdddddddddd/source/my/new/path


//    Adjust where debuginfod stores cache files:

// RUN: rm -rf %t.debuginfod_cache_path
// RUN: mkdir -p %t.debuginfod_cache_path
// RUN: export DEBUGINFOD_CACHE_PATH=%t.debuginfod_cache_path


//-- TEST 1 --  No debuginfod awareness ----------------------------------------


// RUN: DEBUGINFOD_URLS="" \
// RUN: %lldb -f %t -o 'source list -n main' | FileCheck --dump-input=fail %s --check-prefix=TEST-1

// TEST-1: (lldb) source list -n main
// TEST-1: File: /my/new/path/test.cpp
// TEST-1-EMPTY:


//-- TEST 2 -- debuginfod URL pointing in wrong place --------------------------


// RUN: DEBUGINFOD_URLS="http://example.com/debuginfod" \
// RUN: %lldb -f %t -o 'source list -n main' | FileCheck --dump-input=fail %s --check-prefix=TEST-2

// TEST-2: (lldb) source list -n main
// TEST-2: File: /my/new/path/test.cpp
// TEST-2-EMPTY:


//-- TEST 3 -- debuginfod URL pointing corectly --------------------------------


// RUN: DEBUGINFOD_URLS="file://%t.mock/" \
// RUN: %lldb -f %t -o 'source list -n main' | FileCheck --dump-input=fail %s --check-prefix=TEST-3

// TEST-3: (lldb) source list -n main
// TEST-3: File: /my/new/path/test.cpp
// TEST-3:         {{[0-9]+}}
// TEST-3-NEXT:    {{[0-9]+}}   // Some context lines before
// TEST-3-NEXT:    {{[0-9]+}}   // the function.
// TEST-3-NEXT:    {{[0-9]+}}
// TEST-3-NEXT:    {{[0-9]+}}
// TEST-3-NEXT:    {{[0-9]+}}   int main(int argc, char **argv) {
// TEST-3-NEXT:    {{[0-9]+}}     // Here are some comments.
// TEST-3-NEXT:    {{[0-9]+}}     // That we should print when listing source.
// TEST-3-NEXT:    {{[0-9]+}}     return 0;
// TEST-3-NEXT:    {{[0-9]+}}   }
// TEST-3-NEXT:    {{[0-9]+}}
// TEST-3-NEXT:    {{[0-9]+}}   // Some context lines after
// TEST-3-NEXT:    {{[0-9]+}}   // the function.
// TEST-3-EMPTY:

//    Validate that the server received the request from debuginfod client.

// RUN: cat %t.server.log | FileCheck --dump-input=fail %s --check-prefix=VALIDATION
// VALIDATION: 127.0.0.1 - - [{{.*}}] "GET /buildid/aaaaaaaaaabbbbbbbbbbccccccccccdddddddddd/source/my/new/path/test.cpp HTTP/1.1" 200 -


// Some context lines before
// the function.


int main(int argc, char **argv) {
  // Here are some comments.
  // That we should print when listing source.
  return 0;
}

// Some context lines after
// the function.
