const assert = require('assert').strict
const file = require('fs').readFileSync('inputs/20.txt', 'utf8')

const isdef = a => typeof a !== 'undefined'
const undef = a => typeof a === 'undefined'
const min = (...values) => values.reduce((a, b) => a < b ? a : b, Number.POSITIVE_INFINITY)
const max = (...values) => values.reduce((a, b) => a > b ? a : b, Number.NEGATIVE_INFINITY)
const pluck = (array, prop) => array.map(el => el[prop])

const testInputs = [
  {file: '^WNE$', expect: 3},
  {file: '^ENWWW(NEEE|SSE(EE|N))$', expect: 10},
  {file: '^ENNWSWW(NEWS|)SSSEEN(WNSE|)EE(SWEN|)NNN$', expect: 18},
  {file: '^ESSWWN(E|NNENN(EESS(WNSE|)SSS|WWWSSSSE(SW|NNNE)))$', expect: 23},
  {file: '^WSSEESWWWNW(S|NENNEEEENN(ESSSSW(NWSW|SSEN)|WSWWN(E|WWS(E|SS))))$', expect: 31}
]

function getVisChar(room) {
  const {N, S, E, W} = room
  if (N && S && E && W) return "\u254B"
  if (N && E && W) return "\u253B"
  if (N && S && W) return "\u252B"
  if (N && S && E) return "\u2523"
  if (S && E && W) return "\u2533"
  if (N && E) return "\u2517"
  if (E && S) return "\u250F"
  if (S && W) return "\u2513"
  if (W && N) return "\u251B"
  if (E && W) return "\u2501"
  if (N && S) return "\u2503"
  if (N) return "\u2579"
  if (E) return "\u257A"
  if (S) return "\u257B"
  if (W) return "\u2578"
  return "\u2573"
}
function visualize(rooms) {
  let coords = [...rooms.keys()].map(key => {
    return {x: parseInt(key, 10), y: parseInt(key.split(',')[1], 10)}
  })
  let minX = min(...pluck(coords, 'x'))
  let maxX = max(...pluck(coords, 'x'))
  let minY = min(...pluck(coords, 'y'))
  let maxY = max(...pluck(coords, 'y'))
  // let width = maxX - minX
  // let height = maxY - minY
  // console.log('visualize', minX, maxX, minY, maxY)
  for (let y = maxY; y >= minY; --y) {
    let line = ''
    for (let x = minX; x <= maxX; ++x) {
      if (x === 0 && y === 0) {
        line = line + "\u2022"
      } else if (rooms.has(`${x},${y}`)) {
        line = line + getVisChar(rooms.get(`${x},${y}`))
      } else  {
        line = line + ' '
      }
    }
    console.log(line)
  }

}

function findLongestRoute(regex) {
  console.log(regex)
  const directions = {S: false, N: false, E: false, W: false}
  const rooms = new Map
  const roomAt = (key) => rooms.has(key) ? rooms.get(key) : rooms.set(key, {...directions, distances: new Set}).get(key)

  let offset = 0;
  function navigate(x, y, dist) {
    // console.log(' '.repeat(offset) + 'restart at offset', offset)

    const initial = {x, y, dist}

    while (offset < regex.length) {
      // console.log(' '.repeat(dist) + regex[offset])
      switch(regex[offset]) {
        case '(':
          offset++
          ({x, y, dist} = navigate(x, y, dist))
          // console.log(' '.repeat(dist) + 'resuming')
          break
        case ')':
          offset++
          return {x, y, dist}
        case '|':
          offset++
          if (regex[offset] === ')') {
            offset++
            // should not be returning initial, there should be a tree of alternative routes here
            // and the next thing should continue evaluating all future branches from here
            return initial
          } else {
            ({x, y, dist} = initial)
          }
          break

        default:
          dist++
          ({x, y} = move(x, y, regex[offset], dist))
          offset++
      }
    }
    return {x, y, dist}
  }

  function move(x, y, dir, distance) {
    const initialRoom = roomAt(`${x},${y}`)
    let oppositeDir
    switch(dir) {
      case 'N': y++; oppositeDir = 'S'; break;
      case 'E': x++; oppositeDir = 'W'; break;
      case 'S': y--; oppositeDir = 'N'; break;
      case 'W': x--; oppositeDir = 'E'; break;
      default: throw new Error(`wtf: found '${dir}' at ${offset}`)
    }
    
    newRoom = roomAt(`${x},${y}`)
    newRoom.distances.add(distance)
    initialRoom[dir] = true
    newRoom[oppositeDir] = true
    return {x, y}
  }
  
  // roomAt('0,0')
  navigate(0, 0, 0)

  // console.log(rooms)
  
  let roomDistances = pluck(Array.from(rooms.values()), 'distances')
  let shortestPathsToAllRooms = roomDistances.map(distances => min(...distances.values())).filter(isFinite)
  // console.log('shortest paths', shortestPathsToAllRooms)
  const furthest = max(...shortestPathsToAllRooms)
  const rooms1000Away = shortestPathsToAllRooms.filter(distance => distance >= 1000).length
  visualize(rooms)
  // const furthest = Array.from(rooms.values()).reduce((furthest, room) => max(furthest, min(...room.distances.values())))
  console.log('furthest is', furthest)
  console.log(`total rooms: ${shortestPathsToAllRooms.length}`)
  console.log(`rooms >= 1000 doors away: ${rooms1000Away}`)
  return {furthest, rooms}
}


const trim = regex => regex.substr(1, regex.length-2)

testInputs.forEach(input => {
  assert.equal(input.expect, findLongestRoute(trim(input.file)).furthest)
})

findLongestRoute(trim(file.trim()))