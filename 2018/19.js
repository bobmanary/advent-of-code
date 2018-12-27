const fs = require('fs')
const assert = require('assert').strict
const {strpad, strpadr} = require('./lib')

const testProgram = `#ip 0
seti 5 0 1
seti 6 0 2
addi 0 1 0
addr 1 2 3
setr 1 0 0
seti 8 0 4
seti 9 0 5`

const opcodes = {
  addr: (r, [,a,b,c]) => r[c] = r[a] + r[b],
  addi: (r, [,a,b,c]) => r[c] = r[a] + b,

  mulr: (r, [,a,b,c]) => r[c] = r[a] *r[b],
  muli: (r, [,a,b,c]) => r[c] = r[a] * b,

  banr: (r, [,a,b,c]) => r[c] = r[a] & r[b],
  bani: (r, [,a,b,c]) => r[c] = r[a] & b,

  borr: (r, [,a,b,c]) => r[c] = r[a] | r[b],
  bori: (r, [,a,b,c]) => r[c] = r[a] | b,

  setr: (r, [,a,b,c]) => r[c] = r[a],
  seti: (r, [,a,b,c]) => r[c] = a,

  gtir: (r, [,a,b,c]) => r[c] = a > r[b] ? 1 : 0,
  gtri: (r, [,a,b,c]) => r[c] = r[a] > b ? 1 : 0,
  gtrr: (r, [,a,b,c]) => r[c] = r[a] > r[b] ? 1 : 0,

  eqir: (r, [,a,b,c]) => r[c] = a === r[b] ? 1 : 0,
  eqri: (r, [,a,b,c]) => r[c] = r[a] === b ? 1 : 0,
  eqrr: (r, [,a,b,c]) => r[c] = r[a] === r[b] ? 1 : 0,
}


for (let op in opcodes) {
  let fn = opcodes[op]
  opcodes[op] = (registers, instruction) => {
    // clone register status and pass a mutable copy to the original function
    // (for testing and to keep the opcode implementations shorter)
    // let clone = [...registers]
    fn(registers, instruction)
    return registers
  }
}

function p(int) {return strpadr(int.toString(), 6)}
function piBase10 (n) {return parseInt(n, 10)}

 function execute(instructionPointerRegister, instructions, initialRegisters = [0,0,0,0,0,0]) {
  const ip = instructionPointerRegister
  let registers = initialRegisters
  let ipv = registers[ip]

  while (ipv < instructions.length) {
    registers[ip] = ipv
    let iip = ipv
    let ireg = [...registers]
    let instruction = instructions[ipv]
    registers = opcodes[instruction[0]](registers, instruction)
    console.log(`ip=${strpad(iip.toString(), 3)} [${ireg.map(p).join(',')}] ${instruction.join(' ')} [${registers.map(p).join(',')}]`)
    // await keypress()
    ipv = registers[ip]
    ipv++
  }
  console.log('ip', ipv)
  return registers
}

const keypress = async () => {
  process.stdin.setRawMode(true)
  return new Promise(resolve => process.stdin.once('data', data => {
    const byteArray = [...data]
    if (byteArray.length > 0 && byteArray[0] === 3) {
      console.log('^C')
      process.exit(1)
    }
    process.stdin.setRawMode(false)
    resolve()
  }))
}

function loadProgram(input) {
  let [ip, ...instructions] = input.split("\n")
  return {
    ip: ip.split(' ')[1],
    instructions: instructions.map(line => {
      let [opcode, ...args] = line.split(' ')
      return [opcode, ...args.map(piBase10)]
    })
  }
}


//----------

let program = loadProgram(testProgram)
// console.log(program)
console.log(execute(program.ip, program.instructions))

const file = fs.readFileSync('inputs/19.txt', 'utf8').trim()
program = loadProgram(file)
// console.log(execute(program.ip, program.instructions, [1,0,0,0,0,0]))
// console.log(execute(program.ip, program.instructions, [10551329+1,10551329+1,0,10551329,9,10551329]))
console.log(execute(program.ip, program.instructions))


