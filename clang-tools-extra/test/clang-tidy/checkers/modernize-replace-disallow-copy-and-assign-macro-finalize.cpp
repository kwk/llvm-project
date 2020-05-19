// RUN: %check_clang_tidy %s modernize-replace-disallow-copy-and-assign-macro %t -- -config="{CheckOptions: [{key: modernize-replace-disallow-copy-and-assign-macro.FinalizeWithSemicolon, value: 1}]}"

#define DISALLOW_COPY_AND_ASSIGN(TypeName)                                     \
  TypeName(const TypeName &) = delete;                                         \
  const TypeName &operator=(const TypeName &) = delete;

class Foo {
private:
  // Notice, that the macro allows to be used without a semicolon, hence our
  // replacement must contain a semicolon at the end.
  DISALLOW_COPY_AND_ASSIGN(Foo)
};
// CHECK-MESSAGES: :11:3: warning: using copy and assign macro 'DISALLOW_COPY_AND_ASSIGN' [modernize-replace-disallow-copy-and-assign-macro]
// CHECK-FIXES: {{^}}  Foo(const Foo &) = delete;const Foo &operator=(const Foo &) = delete;{{$}}
