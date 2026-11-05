#include <iostream>
#include <omp.h>
#include "calc.h"
int main() { int s = 0;
#pragma omp parallel for reduction(+ : s)
  for (int i = 0; i < 100; ++i) s += add(i, 1);
  std::cout << "hello from cmake " << s << std::endl; return 0; }
