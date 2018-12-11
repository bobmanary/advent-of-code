#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <iterator>
#include <vector>
#include <cassert>
#include <optional>
#include <iomanip>

struct Coordinate {
  int32_t x;
  int32_t y;
  bool isInfinite = false;
  int32_t area;
};

int32_t abs(int32_t initial) {
  return initial < 0 ? -initial : initial;
}

std::vector<Coordinate> loadCoordinates(std::istream &ifs) {
  std::vector<Coordinate> coords;
  std::string skip;
  int x;
  int y;

  while(
    ifs >> x &&
    getline(ifs, skip, ',') &&
    ifs >> y
  ) {
    coords.push_back(Coordinate {.x = x, .y = y});
  }  
  return coords;
}

std::istringstream testData(R"(1, 1
1, 6
8, 3
3, 4
5, 5
8, 9)");

std::optional<int32_t> findPointIndex(const std::vector<Coordinate>& points, int32_t x, int32_t y) {
  for (int32_t i=0; i<points.size(); ++i) {
    if (x == points.at(i).x && y == points.at(i).y) return i;
  }
  return std::nullopt;
}

std::pair<Coordinate, Coordinate> findCorners(const std::vector<Coordinate>& points) {
  auto max = [](int32_t a, int32_t b){return a < b ? b : a;};
  auto min = [](int32_t a, int32_t b){return a < b ? a : b;};

  Coordinate topLeft {.x = INT32_MAX, .y = INT32_MAX};
  Coordinate bottomRight {.x = INT32_MIN, .y = INT32_MIN};

  for (const auto& point : points) {
    topLeft.x = min(topLeft.x, point.x);
    topLeft.y = min(topLeft.y, point.y);
    bottomRight.x = max(bottomRight.x, point.x);
    bottomRight.y = max(bottomRight.y, point.y);
  }

  topLeft.x--;
  topLeft.y--;
  bottomRight.x++;
  bottomRight.y++;


  return std::make_pair(topLeft, bottomRight);
}

bool draw(const std::vector<Coordinate>& points, int32_t cellWidth = 1) {
  Coordinate topLeft;
  Coordinate bottomRight;
  std::tie(topLeft, bottomRight) = findCorners(points);

  std::cout << topLeft.x << "," << topLeft.y << " -> "
    << bottomRight.x << "," << bottomRight.y << std::endl;
  
  for (int32_t y = topLeft.y; y <= bottomRight.y; ++y) {
    for (int32_t x = topLeft.x; x <= bottomRight.x; ++x) {
      auto idx = findPointIndex(points, x, y);
      if (idx.has_value()) {
        std::cout << std::setw(5) << idx.value();
      } else {
        std::cout << std::setw(5) << ".";
      }
    }
    std::cout << std::endl;
  }
  return true;
}

int32_t distanceBetween(Coordinate& point, int32_t x, int32_t y) {
  return abs(point.x - x) + abs(point.y - y);
}

bool isOnEdge(int32_t x, int32_t y, Coordinate& topLeft, Coordinate& bottomRight) {
  return (
    x == topLeft.x
    || x == bottomRight.x
    || y == topLeft.y
    || y == bottomRight.y
  );
}

std::vector<Coordinate*> findNearestPoints(std::vector<Coordinate>& coords, int32_t x, int32_t y) {
  std::vector<Coordinate*> nearestPoints;
  int32_t shortestDistance = INT32_MAX;
  int32_t compareDistance = INT32_MAX;

  for (auto & point : coords) {
    compareDistance = distanceBetween(point, x, y);

    if (compareDistance < shortestDistance) {
      nearestPoints.clear();
      nearestPoints.push_back(&point);
      shortestDistance = compareDistance;
    } else if (compareDistance == shortestDistance) {
      nearestPoints.push_back(&point);
    }
  }
  return nearestPoints;
}

int part1(std::vector<Coordinate> coords) {
  if (coords.size() == 0) return 0;
  Coordinate topLeft;
  Coordinate bottomRight;
  std::tie(topLeft, bottomRight) = findCorners(coords);

  for (auto x = topLeft.x; x <= bottomRight.x; ++x) {
    for (auto y = topLeft.y; y <= bottomRight.y; ++y) {
      // - find one or more coordinates that have the shortest distance to this point
      // - if more than one found, this point does not contribute to a coordinate's area
      // - if only one is found, this point SHOULD contribute to a coordinate's area
      // - if one found and (x, y) is on any edge (comparing against topLeft/bottomRight),
      //   the nearest coordinate should be marked infinite
      auto nearestPoints = findNearestPoints(coords, x, y);

      if (nearestPoints.size() == 1) {
        nearestPoints.at(0)->area++;
        if (isOnEdge(x, y, topLeft, bottomRight)) nearestPoints.at(0)->isInfinite = true;
      }
    }
  }

  Coordinate* largestArea = &coords[0];
  for (auto & point : coords) {
    if (point.isInfinite) continue;
    if (point.area > largestArea->area) largestArea = &point;
  }

  return largestArea->area;
}

int main() {
  std::ifstream file("inputs/6.txt");
  auto coords = loadCoordinates(file);
  auto testCoords = loadCoordinates(testData);

  draw(testCoords);
  assert(part1(testCoords) == 17);

  draw(coords);
  int32_t part1Results = part1(coords);
  assert(part1Results == 4589);
  std::cout << "part 1: " << part1Results << std::endl;


  return 0;
}
