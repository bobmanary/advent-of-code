const fs = require('fs')

const inputs = fs.readFileSync('inputs/2.txt', {encoding: 'utf8'})
  .trim()
  .split("\n")

function withRepeatedLetters(count) {
  return function(id) {
    const map = Object.create(null)
    const sorted = id.split('').sort()
    for (let letter of sorted) {
      map[letter] = (map[letter] || 0) + 1
    }
    return Object.values(map).includes(count)
  }
}

function part1(inputs) {
  return inputs.filter(withRepeatedLetters(2)).length * inputs.filter(withRepeatedLetters(3)).length
}

function matchingLetters(a, b) {
  return Array.prototype.filter.call(a, (letter, idx) => letter === b[idx]).join('')
}

function part2(inputs) {
  for (let a of inputs) {
    let potentialMatches = inputs.filter(b => matchingLetters(a, b).length === a.length-1)
    if (potentialMatches.length === 1) {
      return matchingLetters(a, potentialMatches[0])
    }
  }
}

console.log(part1(inputs))
console.log(part2(inputs))
