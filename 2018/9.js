const assert = require('assert').strict
const realData = parseLine(
  require('fs')
  .readFileSync('inputs/9.txt', 'utf8')
  .trim()
)
const {FilledArray, strpad, print} = require('./lib.js')

const DRAW=false


function parseLine(line) {
  let [, players, lastMarble] = line
    .match(/(\d+) players; last marble is worth (\d+) points/)
    .map((val, i) => i > 0 ? parseInt(val, 10) : val)
  return {players, lastMarble}
}

const testInputs = `
9 players; last marble is worth 25 points: high score is 32
10 players; last marble is worth 1618 points: high score is 8317
13 players; last marble is worth 7999 points: high score is 146373
17 players; last marble is worth 1104 points: high score is 2764
21 players; last marble is worth 6111 points: high score is 54718
30 players; last marble is worth 5807 points: high score is 37305
`.trim().split("\n").map(line => {
  let [first, rest] = line.split(":")
  let expectedScore = parseInt(rest.split("score is ")[1], 10)
  return {
    expectedScore,
    input: parseLine(first),
  }
})

const CCW = -1 // counter-clockwise
const CW = 1

function drawGameBoard(marbles, players) {
  let heading = strpad(`[${strpad((players.current()+1) + ':', 4)} ${strpad(players.currentScore() + '', 6)}]`, 10)

  let text = marbles.map((m, i) => {
    let pad = i === marbles.currentIndex() ? "()" : "  "
    return strpad(`${pad[0]}${m}${pad[1]}`, 5)
  }).join(' ')

  return `${heading} ${text}`
}

const currentMarbleIdx = Symbol()
class Marbles extends Array {
  constructor() {
    super()
    this[currentMarbleIdx] = -1
  }

  placeMarble(marble) {
    return this.insertRelative(marble)
  }

  removeMarble() {
    let removedMarbleIdx = this.rotateCurrentPosition(-7)
    let removedMarble = this[removedMarbleIdx]
    this.splice(this[currentMarbleIdx], 1)
    if (this[currentMarbleIdx] >= this.length) this[currentMarbleIdx] = 0
    return removedMarble

  }

  insertRelative(marble, offset = 2) {
    while(offset > 0) {
      this[currentMarbleIdx]++
      offset--
      if (offset === 0 && this[currentMarbleIdx] === this.length) {
        this.push(marble)
        return this[currentMarbleIdx]
      }
      if (this[currentMarbleIdx] >= this.length) {
        this[currentMarbleIdx] = 0
      }
    }
    this.splice(this[currentMarbleIdx], 0, marble)
  }

  rotateCurrentPosition(count) {
    // supports clockwise/counterclockwise, but only used for finding a counterclockwise marble position.
    // increments in steps of 1 to handle going past the start/end of the circle repeatedly with circle
    // sizes smaller than the step count.
    let dir = count < 0 ? CCW : CW
    count = Math.abs(count)
    while (count > 0) {
      this[currentMarbleIdx] += dir
      if (this[currentMarbleIdx] < 0) {
        this[currentMarbleIdx] = this.length-1
      }
      if (this[currentMarbleIdx] >= this.length) {
        this[currentMarbleIdx] = 0
      }
      count--
    }
    return this[currentMarbleIdx]
  }

  currentIndex() {
    return this[currentMarbleIdx]
  }
}

const playerIndex = Symbol()
class Players extends FilledArray {
  constructor(length, initialValue) {
    super(length, initialValue)
    this[playerIndex] = 0
  }

  advance() {
    this[playerIndex]++
    if (this[playerIndex] >= this.length) this[playerIndex] = 0
    return this[playerIndex]
  }

  current() {
    return this[playerIndex]
  }

  currentScore() {
    return this[this[playerIndex]]
  }

  increase(points) {
    this[this[playerIndex]] += points
  }
}

function part1({players: playerCount, lastMarble}) {
  let moveLog = []
  const marbles = new Marbles()
  const players = new Players(playerCount, 0)
  marbles.placeMarble(0)
  const printStatus = (currentMarble) => {
    process.stdout.clearLine()
    process.stdout.cursorTo(0)
    print('  marble ' + currentMarble + '/' + lastMarble)
  }
  for(let currentMarble = 1; currentMarble <= lastMarble; ++currentMarble) {
    if (currentMarble % 23 === 0) {
      players.increase(currentMarble)
      players.increase(marbles.removeMarble())
    } else {
      marbles.placeMarble(currentMarble)
    }

    if (DRAW) moveLog.push(drawGameBoard(marbles, players))
    if (currentMarble%100 === 0) printStatus(currentMarble)
    players.advance()

  }
  
  if (DRAW) moveLog.forEach(line => console.log(line))

  printStatus(lastMarble)

  return players.reduce((max, p) => p > max ? p : max, 0)
}

// console.log(testInputs[0])
// assert.equal(part1(testInputs[0].input), testInputs[0].expectedScore)
testInputs.forEach(({input, expectedScore}) => {
  console.log(`testing part1(${JSON.stringify(input)}) == ${expectedScore}...`)
  assert.equal(part1(input), expectedScore)
  print(" ok.\n")
})

console.log("calculating part 1...")
const part1Result = part1(realData)
print(` result: ${part1Result}\n`)
