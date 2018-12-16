#include <cstdint>
#include <iostream>
#include <fstream>
#include <optional>
#include <iterator>
#include <vector>
#include <cassert>
#include <sstream>

typedef std::vector<std::uint16_t> IntVec;

struct Node {
  IntVec metadata;
  std::vector<Node> children;
};

IntVec readData(std::istream &ifs) {
  // using uint16 because uint8 appears to cause the stream iterator
  // to parse individual chars into 0-9 instead of splitting into a
  // multi-char string and parsing that (eg '2 11' -> '2 1 1')
  return IntVec (
    std::istream_iterator<std::uint16_t>(ifs),
    std::istream_iterator<std::uint16_t>()
  );
}

std::istringstream testInput(R"(2 3 0 3 10 11 12 1 1 0 1 99 2 1 1 2)");
// 0 3 10 11 12 1 1 0 1 99 2
// 1 1 0 1 99 2
// 
std::vector<Node> getNodes(const IntVec &input, std::uint16_t childCount, std::uint16_t metadataCount) {
  IntVec body(input.begin(), input.end());
  IntVec metadata(input.begin() + input.size() - metadataCount, input.end());
  std::vector<Node> nodes;

  

  if (childCount == 0) {
    return std::vector<Node>();
  }

  std::uint32_t offset = 0;
  while (offset < input.size()) {
    
  }

  for (std::uint16_t i = 0; i<childCount; i++) {
    getEndPos(IntVec())
  }
}

std::uint32_t part1(const IntVec &input) {
  auto childCount = input.at(0);
  auto metadataCount = input.at(1);
  Node node {
    .metadata = IntVec(input.begin() + (input.size() - metadataCount), input.end())
  };
  node.children = getNodes(IntVec(input.begin() + 2, input.end() - metadataCount), childCount, metadataCount);


}

int main(int argc, char ** argv) {
  auto testData = readData(testInput);

  assert(part1(testData) == 138);

  std::cout << "part 1 test: " << part1(testData) << std::endl;
}
