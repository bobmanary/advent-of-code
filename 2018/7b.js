const assert = require('assert').strict;
const { readLines } = require('./lib.js');
const ASCII_OFFSET = 64;

class Node {
  constructor(name, duration) {
    this.deps = new Set;
    this.name = name;
    this.completed = false;
    this.duration = duration;
    this.inProgress = false;
  }

  addDep(name) {
    this.deps.add(name);
    return this;
  }

  begin() {
    if (this.inProgress) return false;
    return this.inProgress = true;

  }

  complete() {
    if (this.completed) {
      console.log(`${this.name} already completed`);
      return false;
    }
    return (this.completed = true);
  }
}

class NodeMap extends Map {
  addDep(name, dep, taskDuration) {
    if (!this.has(name)) this.set(name, new Node(name, taskDuration));
    if (dep) this.get(name).addDep(dep);
  }
}

class Worker {
  constructor() {
    this.completion = 0;
    this.available = true;
    this.task = null;
  }
  begin(task, now) {
    if (!task.begin()) return false;
    this.completion = now + task.duration;
    this.available = false;
    this.task = task;
    return true;
  }
  complete(now) {
    if (now !== this.completion) return {completed: false, task: null};
    this.available = true;
    this.completion = 0;
    let completedTask = this.task;
    this.task.complete();
    this.task = null;
    return {completed: true, task: completedTask};
  }
}

class WorkerList extends Array {
  constructor(size) {
    super();
    for (let i=0; i<size; i++) {
      this.push(new Worker);
    }
  }
  busy() {
    return this.filter(worker => !worker.available);
  }
  available() {
    return this.filter(worker => worker.available);
  }
}

function part2(input, workerCount, baseDuration) {
  const graph = new NodeMap();
  let completed = '';
  const workers = new WorkerList(workerCount);
  let now = 0;
  function nodePrereqsAreSatisfied(node) {
    const completedParents = Array.from(node.deps)
      .filter(parent => graph.get(parent).completed);
    return node.deps.size === completedParents.length;
  }

  input
    .map(line => line.match(/Step (\w+) must.* step (\w+) can/).slice(1))
    .forEach(([prereq, name]) => {
      graph.addDep(name, prereq, baseDuration + (name.charCodeAt(0) - ASCII_OFFSET));
      graph.addDep(prereq, null, baseDuration + (prereq.charCodeAt(0) - ASCII_OFFSET));
    });

  const first = Array.from(graph.values())
    .filter(task => task.deps.size === 0)
    .map(task => task.name)
    .sort()
    .map(taskName => graph.get(taskName));

  while(completed.length < graph.size) {

    workers.busy().forEach(worker => {
      let status = worker.complete(now);
      if (status.completed) {
        completed += status.task.name;
      }
    });

    workers.available().forEach(worker => {
      let availableTasks = Array.from(graph.values())
        .filter(nodePrereqsAreSatisfied)
        .filter(task => !task.completed && !task.inProgress);

        if (availableTasks.length > 0) {
        let firstTask = availableTasks.map(task => task.name).sort()[0];
        worker.begin(graph.get(firstTask), now);
      }
    });
    console.log(`${now}, [ ${workers.map(w => w.task ? w.task.name : '.').join(', ')} ], '${completed}'`);
    now++;
  }
  return {completed, now: now-1};

}

const testData = `Step C must be finished before step A can begin.
Step C must be finished before step F can begin.
Step A must be finished before step B can begin.
Step A must be finished before step D can begin.
Step B must be finished before step E can begin.
Step D must be finished before step E can begin.
Step F must be finished before step E can begin.`.split("\n");

const expected2 = {completed: "CABFDE", now: 15};
const input = readLines('inputs/7.txt');

assert.deepEqual(expected2, part2(testData, 2, 0));
console.log(`part 2:`, part2(input, 5, 60));
