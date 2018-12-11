const assert = require('assert').strict;
const fs = require('fs');
const {strpad} = require('./lib.js');

const input = fs.readFileSync('inputs/5.txt', 'utf8').trim();

function opposite(char = "") {
  return char.toLowerCase() === char ? char.toUpperCase() : char.toLowerCase();
}

function test() {
  const testInput1 = "dabAcCaCBAcCcaDA";

  const result1b = part1b(testInput1);
  assert(result1b === 10);

  const result2 = part2(testInput1);
  assert(result2.polymerLength === 4);
}

function part1b(input) {
  let i = 0;
  do {
    if (input[i] === opposite(input[i+1])) {
      input = input.substr(0, i) + input.substr(i+2);
      i = i-1;
    } else {
      i++;
    }
  } while (i<input.length)
  return input.length;
}

function part2(input) {
  const offset = 'a'.charCodeAt(0);
  const units = [...new Set(input.toLowerCase().split("")).values()]

  const lengths = units.map(unit => {
    const replaced = input.replace(new RegExp(`[${unit}${unit.toUpperCase()}]`, 'g'), '')
    return {
      unitRemoved: unit,
      polymerLength: part1b(replaced),
      lower: replaced.indexOf(unit),
      upper: replaced.indexOf(unit.toUpperCase()),
      input: replaced.length > 50 ? replaced.substr(0, 50) + '...' : replaced
    }
  }).sort((a, b) => a.polymerLength - b.polymerLength);
  return lengths[0];
}


test();

const result1 = part1b(input);
assert(11476 === result1);
console.log(`part 1b: ${input.length} -> ${result1}`);

const {unitRemoved, polymerLength} = part2(input);
console.log('part 2:', {unitRemoved, polymerLength});
