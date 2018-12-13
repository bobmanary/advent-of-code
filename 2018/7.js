const assert = require('assert').strict;
const { readLines } = require('./lib.js');

class Node {
  constructor(name) {
    this.deps = new Set;
    this.reverseDeps = new Set;
    this.name = name;
    this.completed = false;
  }

  addDep(name) {
    this.deps.add(name);
    return this;
  }

  addReverseDep(name) {
    this.reverseDeps.add(name);
  }

  complete() {
    if (this.completed) {
      console.log(`${this.name} already completed`);
      return false
    }
    return (this.completed = true);
  }

  resolveLast(graph, order) {
    console.log(`resolving ${this.name}`)
    Array.from(this.deps).sort().forEach(dep => {
      graph.get(dep).resolveLast(graph, order);
    });
    if (this.complete()) {
      order.push(this.name);
    }
    return order;
  }

  resolveFirst(graph, order) {
    this.complete();
    order.push(this.name);
    this.findAvailable(graph, order).forEach(node => {
      node.re;
    })
  }
}

class NodeMap extends Map {
  addDep(name, dep) {
    if (!this.has(name)) this.set(name, new Node(name));
    if (dep) this.get(name).addDep(dep);
  }
  addReverseDep(name, rdep) {
    if (!this.has(name)) this.set(name, new Node(name));
    if (rdep) this.get(name).addReverseDep(rdep);
  }
}

function part1(input) {
  const graph = new NodeMap();
  input
    .map(line => line.match(/Step (\w+) must.* step (\w+) can/).slice(1))
    .forEach(([prereq, name]) => {
      graph.addDep(name, prereq);
      graph.addReverseDep(prereq, name);
    });
  
  // console.log(graph);
  
  const first = graph.get(
    Array.from(graph.values())
    .filter(node => node.deps.size === 0)
    .map(node => node.name)
    .sort()[0]
  );
  console.log('first:', first.name)
  let completed = `${first.name}`;
  first.complete();

  const nodePrereqsAreSatisfied = (node) => {
    const completedParents = Array.from(node.deps).filter(parent => graph.get(parent).completed);
    return node.deps.size === completedParents.length;
  }

  while(completed.length < graph.size) {
    let available = Array.from(graph.values())
      .filter(nodePrereqsAreSatisfied)
      .filter(node => !node.completed);
    let current = available.map(n => n.name).sort()[0];
    console.log('available', available.map(n => n.name), ', choosing:', current, ', ordered: ', available.map(n => n.name).sort());
    graph.get(current).complete();
    completed += current;
  }
  console.log('---', completed)
  return completed;
  // const last = Array.from(graph.values()).find(node => node.reverseDeps.size === 0);

  // console.log(graph);
  // const order = last.resolveLast(graph, []).join('');
  // const order = last.resolveFirst(graph, []).join('');
  // console.log(order);
  // return order;

}

const testData = `Step C must be finished before step A can begin.
Step C must be finished before step F can begin.
Step A must be finished before step B can begin.
Step A must be finished before step D can begin.
Step B must be finished before step E can begin.
Step D must be finished before step E can begin.
Step F must be finished before step E can begin.`.split("\n");

const expected1 = "CABDFE";
const input = readLines('inputs/7.txt');
// const test1Result = part1(testData);

assert.equal(expected1, part1(testData));
// GCKMUWXFAIHSYDNLJQTREOPZBV is wrongo
console.log(`part 1: ${part1(input)}`);
