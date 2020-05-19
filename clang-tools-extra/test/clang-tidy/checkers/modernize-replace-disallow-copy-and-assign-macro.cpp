// RUN: %check_clang_tidy %s modernize-replace-disallow-copy-and-assign-macro %t

#define DISALLOW_COPY_AND_ASSIGN(TypeName)                                     \
  TypeName(const TypeName &) = delete;                                         \
  const TypeName &operator=(const TypeName &) = delete

class Foo {
private:
  DISALLOW_COPY_AND_ASSIGN(Foo);
};
// CHECK-MESSAGES: :9:3: warning: using copy and assign macro 'DISALLOW_COPY_AND_ASSIGN' [modernize-replace-disallow-copy-and-assign-macro]
// CHECK-FIXES: {{^}}  Foo(const Foo &) = delete;const Foo &operator=(const Foo &) = delete;{{$}}
