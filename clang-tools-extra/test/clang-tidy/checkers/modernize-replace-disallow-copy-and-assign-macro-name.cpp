// RUN: %check_clang_tidy %s modernize-replace-disallow-copy-and-assign-macro %t -- -config="{CheckOptions: [{key: modernize-replace-disallow-copy-and-assign-macro.MacroName, value: MY_MACRO_NAME}]}"

#define MY_MACRO_NAME(TypeName)                                     \
  TypeName(const TypeName &) = delete;                                         \
  const TypeName &operator=(const TypeName &) = delete

class Foo {
private:
  MY_MACRO_NAME(Foo);
};
// CHECK-MESSAGES: :9:3: warning: using copy and assign macro 'MY_MACRO_NAME' [modernize-replace-disallow-copy-and-assign-macro]
// CHECK-FIXES: {{^}}  Foo(const Foo &) = delete;const Foo &operator=(const Foo &) = delete;{{$}}
