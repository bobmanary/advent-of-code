const fs = require('fs')
const assert = require('assert').strict

const testSample = `Before: [3, 2, 1, 1]
9 2 1 2
After:  [3, 2, 2, 1]`

const NUM_OPCODES=16

const opcodes = {
  addr: (r, [_,a,b,c]) => r[c] = r[a] + r[b],
  addi: (r, [_,a,b,c]) => r[c] = r[a] + b,

  mulr: (r, [_,a,b,c]) => r[c] = r[a] *r[b],
  muli: (r, [_,a,b,c]) => r[c] = r[a] * b,

  banr: (r, [_,a,b,c]) => r[c] = r[a] & r[b],
  bani: (r, [_,a,b,c]) => r[c] = r[a] & b,

  borr: (r, [_,a,b,c]) => r[c] = r[a] | r[b],
  bori: (r, [_,a,b,c]) => r[c] = r[a] | b,

  setr: (r, [_,a,b,c]) => r[c] = r[a],
  seti: (r, [_,a,b,c]) => r[c] = r[c] = a,

  gtir: (r, [_,a,b,c]) => r[c] = a > r[b] ? 1 : 0,
  gtri: (r, [_,a,b,c]) => r[c] = r[a] > b ? 1 : 0,
  gtrr: (r, [_,a,b,c]) => r[c] = r[a] > r[b] ? 1 : 0,

  eqir: (r, [_,a,b,c]) => r[c] = a === r[b] ? 1 : 0,
  eqri: (r, [_,a,b,c]) => r[c] = r[a] === b ? 1 : 0,
  eqrr: (r, [_,a,b,c]) => r[c] = r[a] === r[b] ? 1 : 0,
}


for (let op in opcodes) {
  let fn = opcodes[op]
  opcodes[op] = (registers, instruction) => {
    // clone register status and pass a mutable copy to the original function
    // (for testing and to keep the opcode implementations shorter)
    let clone = [...registers]
    fn(clone, instruction)
    return clone
  }
}

function deepEqual(a, b) {
  // this is what exceptions are for, right
  try {
    assert.deepEqual(a, b)
    return true;
  } catch (ex) {
    return false;
  }
}

function findMatchingOpcodes({before, instruction, after}) {
  const matches = []
  for (let opcode in opcodes) {
    if (deepEqual(opcodes[opcode](before, instruction), after)) {
      matches.push(opcode)
    }
  }
  return matches
}
assert.deepEqual(
  ['mulr', 'addi', 'seti'].sort(),
  findMatchingOpcodes(parseSample(testSample)).sort()
)

function piBase10 (n) {return parseInt(n, 10)}

function parseSample(sample) {
  const lines = sample.split("\n")
  return {
    before: lines[0].split('[')[1].split(',').map(piBase10),
    instruction: instruction = lines[1].split(' ').map(piBase10),
    after: lines[2].split('[')[1].split(',').map(piBase10)
  }
}
assert.deepEqual({before: [3, 2, 1, 1], after: [3, 2, 2, 1], instruction: [9, 2, 1, 2]}, parseSample(testSample))

function writeMissingInstructionDocumentation(samples) {
  // figure out what opcode names map to each numeric instruction id
  // by looping over the sample data, finding a sample that
  // - initially is solved by only one opcode
  // - or is solved only by (opcodes found already) + (one new opcode)
  const opcodeMap = Object.create(null)
  const foundIds = []
  foundNames = []

  const foundNewCode = (potential) => {
    // subtract already-found opcode names from the list of opcodes that match this sample,
    // and if only one opcode is remaining, return that
    let remaining = potential.filter(p => !foundNames.includes(p))
    if (remaining.length === 1) return remaining[0]
    return null
  }

  for (let i = 0; i < NUM_OPCODES; i++) {
    let newCode
    for (let sample of samples) {
      let id = sample.instruction[0]
      if (foundIds.includes(id)) continue // skip, mapped this opcode already

      const potentialOpcodes = findMatchingOpcodes(sample)
      if ((newCode = foundNewCode(potentialOpcodes))) {
        opcodeMap[id] = newCode
        foundNames.push(newCode)
        foundIds.push(id)
        // console.log(`found ${newCode}: ${id}`)
        break;
      }
    }
    if (!newCode) {
      throw new Error(`Found no opcode on iteration ${i}`)
    }
  }

  return opcodeMap;
}

function part1(samples) {
  let gte3 = 0;
  samples.forEach(sample => {
    if (findMatchingOpcodes(sample).length >= 3) gte3++;
  })
  return gte3;
}

function part2(samples, program) {
  const opcodeMap = writeMissingInstructionDocumentation(samples)
  
  let registers = [0,0,0,0]

  program.forEach(instruction => {
    let id = instruction[0]
    let name = opcodeMap[id]
    const impl = opcodes[name]
    // console.log(name, registers, instruction)
    registers = impl(registers, instruction)
  })
  // console.log('    ', registers)
  return registers[0]
}

function loadSamples(input) {
  return input.split("\n\n\n")[0].trim().split("\n\n").map(parseSample);
}

function loadProgram(input) {
  return input.split("\n\n\n")[1].trim().split("\n").map(line => line.split(' ').map(piBase10))
}


//----------
const file = fs.readFileSync('inputs/16.txt', 'utf8').trim()
const samples = loadSamples(file)
const part1Result = part1(samples)
console.log(`samples matching >= 3 opcodes: ${part1Result} out of ${samples.length}`)
assert(part1Result === 560)

const program = loadProgram(file)
console.log(`part 2 register 0: ${part2(samples, program)}`)
