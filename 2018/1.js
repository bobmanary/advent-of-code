const fs = require('fs')

const inputs = fs.readFileSync('inputs/1.txt', {encoding: 'utf8'})
  .trim()
  .split("\n")
  .map(n => parseInt(n, 10))
const log = new Set 
let freq = 0

console.log(`final frequency after one set: ${inputs.reduce((freq, change) => freq + change, 0)}`)

while(true) {
  inputs.forEach(change => {
    freq += change
    if (log.has(freq)) {
      console.log(`first frequency repeated: ${freq}`)
      process.exit(0)
    }
    log.add(freq)
  })
}
