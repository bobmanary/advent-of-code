#include <iostream>
#include <fstream>
#include <vector>
#include <string>
#include <iterator>
#include <numeric>
#include <set>

int part1(std::vector<int> changes) {
  auto add = [](int a, int b) { return a + b; };
  return std::accumulate(changes.begin(), changes.end(), 0, add);
}

int part2(std::vector<int> changes) {
  std::set<int> previousFreqs;
  int freq = 0;
  while(true) {
    for(std::vector<int>::iterator it = changes.begin(); it != changes.end(); ++it) {
      freq += *it;
      if (previousFreqs.end() != previousFreqs.find(freq)) return freq;
      previousFreqs.insert(freq);
    }
  }
}

int main() {
  std::ifstream file("inputs/1.txt");

  std::vector<int> values(
    (std::istream_iterator<int>(file)),
    (std::istream_iterator<int>())
  );

  std::cout << part1(values) << std::endl
            << part2(values) << std::endl;
}
