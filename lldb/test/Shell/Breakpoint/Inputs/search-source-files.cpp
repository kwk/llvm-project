#include "search-source-files.h"
#include "search-source-files2.h"

int main(int argc, char *argv[]) {
  int a = inlined_42();
  return return_zero() + a;
}
