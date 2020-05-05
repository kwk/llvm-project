.. title:: clang-tidy - modernize-replace-disallow-copy-and-assign-macro

modernize-replace-disallow-copy-and-assign-macro
================================================

This check finds macro expansions of ``DISALLOW_COPY_AND_ASSIGN(Type)`` and
replaces them with a deleted copy constructor and a deleted assignment operator.

Before the ``delete`` keyword was introduced in C++11 it was common practice to
declare a copy constructor and an assignment operator as a private members. This
effectively makes them unusable to the public API of a class.

With the advent of the ``delete`` keyword in C++11 we can abandon the
``private`` access of the copy constructor and the assignment operator and
delete the methods entirely.

Migration example:

.. code-block:: c++

  class Foo {
  private:
  -  DISALLOW_COPY_AND_ASSIGN(Foo);
  +  Foo(const & Foo) = delete;
  +  Foo & operator=(const & other) = delete;
  }

Known Limitations
-----------------
* Notice that the migration example above leaves the ``private`` access
  specification untouched. This opens room for improvement, yes I know.

Options
-------

.. option:: MacroName

   A string specifying the macro name whose expansion will be replaced.
   Default is `DISALLOW_COPY_AND_ASSIGN`.

See: https://en.cppreference.com/w/cpp/language/function#Deleted_functions

./bin/clang-tidy --checks=modernize-replace-disallow-copy-and-assign-macro test.cpp -dump-config --config="{Checks: 'modernize-replace-disallow-copy-and-assign-macro', CheckOptions: [{key: 'modernize-replace-disallow-copy-and-assign-macro.MacroName', value: 'FooBar'}]}"
