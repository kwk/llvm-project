// RUN: grep -Ev "// *[A-Z-]+:" %s \
// RUN:   | clang-format -style="{BasedOnStyle: LLVM, EmptyLineAfterFunctionDefinition: Always}" \
// RUN:   | FileCheck --dump-input=always -v --color -strict-whitespace %s

// CHECK: int one() { return 1; }
// CHECK-NEXT-EMPTY:
// CHECK-NEXT: int two() { return 2; }
// CHECK-NEXT-EMPTY:
int one() { return 1; }
int two() { return 2; }