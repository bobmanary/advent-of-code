const assert = require('assert').strict
const fs = require('fs')

function toClaim (line) {
  let [_, id, x, y, w, h] = line.split(/[#|@|:|,|x]/).map(s => parseInt(s.trim(), 10))
  return {id, x, y, w, h}
}

function makeGrid(w, h) {
  let columns = Array(w)
  return function grid(x, y, claim) {
    if (!claim && !columns[x])    return []
    if (!claim && !columns[x][y]) return []
    if (!claim)                   return columns[x][y]

    if (!columns[x])    columns[x] = Array(h)
    if (!columns[x][y]) columns[x][y] = Array()

    columns[x][y].push(claim)
    if (columns[x][y].length > 1) columns[x][y].forEach(claim => claim.overlaps = true)

    return grid
  }
}

function getCoveredSquares({x, y, w, h}) {
  let values = []
  for (let i=x; i<x+w; ++i) {
    for (let j=y; j<y+h; ++j) {
      values.push([i, j])
    }
  }
  return values
}

const max = (a, b) => a < b ? b : a
const pad = (s, space = 5) => s.length < space ? s + ' '.repeat(space - s.length) : s

const cell = (claims) => claims.length === 0 ? pad('.')
  : claims.length === 1 ? pad(claims[0].id + '')
  : pad('x')


function part1(claims) {
  let {xMax, yMax} = claims.reduce(({xMax, yMax}, {x, y, w, h}) => {
    return {xMax: max(x+w, xMax), yMax: max(y+h, yMax)}
  });

  // console.log(`xMax: ${xMax}, yMax: ${yMax}`)
  let grid = makeGrid(xMax, yMax)
  claims.map(claim => [claim, getCoveredSquares(claim)])
    .forEach(([claim, squares]) => squares.forEach(([x, y]) => grid(x, y, claim)))

  // console.log(
  //   [...Array(yMax).keys()].map(y => {
  //     return [...Array(xMax).keys()].map(x => cell(grid(x, y))).join('')
  //   }).join("\n")
  // )

  let single = 0
  let none = 0
  let many = 0

  for (let x=0; x<xMax; ++x) {
    for (let y=0; y<yMax; ++y) {
      let claimCount = grid(x, y).length
      
      if (claimCount === 0) none++
      if (claimCount === 1) single++
      if (claimCount > 1)   many++
    }
  }

  return {single, none, many}
}

function part2(claims) {
  part1(claims)
  return claims.filter(claim => !claim.overlaps)
}

const add = (a, b) => a+b


function testClaims () {
  return `#1 @ 1,3: 4x4
    #2 @ 3,1: 4x4
    #3 @ 5,5: 2x2`
    .split("\n")
    .map(c => toClaim(c.trim()))
}

function loadClaims() {
  return fs.readFileSync('inputs/3.txt', 'utf8')
    .trim()
    .split("\n")
    .map(toClaim)
}

function part1Test(claims) {
  // .    .    .    .    .    .    .
  // .    .    .    2    2    2    2
  // .    .    .    2    2    2    2
  // .    1    1    x    x    2    2
  // .    1    1    x    x    2    2
  // .    1    1    1    1    3    3
  // .    1    1    1    1    3    3

  const testFill = getCoveredSquares({x: 1, y: 2, w: 3, h: 4})
  assert(testFill.length === 3*4)
  assert.deepEqual(testFill[0], [1, 2])
  assert.deepEqual(testFill[11], [3, 5])
  assert.deepEqual(claims[0], {id: 1, x: 1, y: 3, w: 4, h: 4})
  assert.deepEqual(makeGrid(3, 3)(2, 2), [])
  assert.deepEqual(makeGrid(3, 3)(1, 1, 'x')(1, 1, 'y')(1, 1), ['x', 'y'])
  
  const part1Expected = {single: 28, none: 17, many: 4}
  const part1Actual = part1(claims)
  assert.deepEqual(part1Actual, part1Expected)
  assert.equal(49, Object.values(part1Actual).reduce(add))
  // console.log(part1Actual)
}

function part1Real(claims) {

  const results = part1(claims)
  
  assert.equal(999*999, Object.values(results).reduce(add))
  console.log(`${results.many} sq in. of overlapping claims`)
}


part1Test(testClaims())
part1Real(loadClaims())

function part2Test(claims) {
  const results = part2(claims)
  assert.equal(1, results.length)
  assert.equal(3, results[0].id)
  // console.log(`non-overlapping claim: ${results[0].id}`)
}

function part2Real(claims) {
  const results = part2(claims)
  assert.equal(1, results.length)
  console.log(`only non-overlapping claim: #${results[0].id}`)
}

part2Test(testClaims())
part2Real(loadClaims())
