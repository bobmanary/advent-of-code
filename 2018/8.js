const fs = require('fs');
const assert = require('assert').strict;

function load() {
  return parse(fs.readFileSync('inputs/8.txt', 'utf8').trim());
}

function parse(str) {
  return str.split(" ").map(x => parseInt(x, 10));
}

function loadTest() { //               1  1 1 1 1 1
  //            0 1 2 3  4  5  6 7 8 9 0  1 2 3 4 5 
  return parse("2 3 0 3 10 11 12 1 1 0 1 99 2 1 1 2");
  //            h h h h  m  m  m h h h h  m m m m m
  //            0 0 1 1  1  1  1 2 2 3 3  3 2 0 0 0
  //            A A B B  B  B  B C C D D  D C A A A
}

function part1(input) {
  const allNodes = [];
  function makeNode(start) {
    const children = input[start];
    const mdSize = input[start + 1];
    let mdOffset;
    let nodes = [];
    if (children === 0) {
      mdOffset = start+2;
    } else {
      let childStart = start + 2;
      for (let currentChild = 0; currentChild < children; ++currentChild) {
        let childNode = makeNode(childStart);
        nodes.push(childNode);
        childStart = childNode.end + 1;
      }
      mdOffset = nodes[nodes.length-1].end + 1
    }
    let node = {
      children,
      mdSize,
      nodes,
      start,
      mdOffset,
      end: mdOffset + mdSize - 1
    };
    allNodes.push(node);
    return node;
  }

  let rootNode = makeNode(0);


  const metadataSum = allNodes.reduce((sum, node) => {
    return sum + getMetadata(input, node).reduce(add);
  }, 0);

  return {
    metadataSum,
    allNodes,
    rootNode
  }
}

function getMetadata(input, node) {
  return input.slice(node.mdOffset, node.mdOffset+node.mdSize);
}

function add(a, b) {return a+b}

function part2(input, rootNode) {
  let x = 0;
  function getNodeValue(node) {
    const metadata = getMetadata(input, node);
    let value = 0;
    if (node.children === 0) {
      value = metadata.reduce(add, 0);
    } else {
      x++;
      value = metadata.reduce((sum, entry) => {
        entry = entry-1;
        return sum + (entry < node.nodes.length ? getNodeValue(node.nodes[entry]) : 0);
      }, 0);
    }
    return value;
  }

  return getNodeValue(rootNode);
}

function main() {
  let testData = loadTest();
  let testResult = part1(testData);
  let realData = load();
  let realResult = part1(realData);
  assert(testResult.metadataSum == 138);
  console.log('part 1', realResult.metadataSum);
  assert(realResult.metadataSum === 45618);


  // part 2
  assert(part2(testData, testResult.allNodes[2]) == 0);
  assert(part2(testData, testResult.allNodes[0]) == 33);
  assert(part2(testData, testResult.rootNode) == 66);

  console.log('part 2', part2(realData, realResult.rootNode));
}

main();