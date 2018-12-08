const fs = require('fs')

const inputs = fs.readFileSync('inputs/1.txt', {encoding: 'utf8'})
  .trim()
  .split("\n")
  .map(n => parseInt(n, 10))

function part1(changes) {
  return changes.reduce((freq, change) => freq + change, 0)
}


function part2(changes) {
  let i = 0,
    freq = 0,
    change

  const len = inputs.length,
    log = new Set 
  
  while(true) {
    for (i = 0; i<len; ++i) {
      change = inputs[i]
      freq += change
      if (log.has(freq)) {
        return freq
      }
      log.add(freq)
    }
  }
}

console.log(part1(inputs))
console.log(part2(inputs))
