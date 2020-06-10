#include "search-support-files.h"
#include "search-support-files-func.cpp"

int main(int argc, char *argv[]) {
  int a = func() - function_in_header();
  return a;
}
