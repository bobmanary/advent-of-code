const fs = require('fs')
const assert = require('assert').strict

const {uniq, readLines, group, strpad, pairs} = require('./lib.js')

function load() {
  return readLines('inputs/4.txt').sort()
}


function drawGraph(sleepStates) {
  const LEFT_COL_WIDTH = 8
  let tens = [...Array(60).keys()].map(i => Math.floor(i/10)).join('')
  let ones = [...Array(60).keys()].map(i => i.toString().substr(i.toString().length-1, 1)).join('')
  sleepStates = Array.from(sleepStates).sort((a, b) =>  a.guard - b.guard)
  console.log(
    strpad('', LEFT_COL_WIDTH) + tens + "\n" +
    strpad('', LEFT_COL_WIDTH) + ones + "\n" +
    sleepStates.map(({guard, log}) => {
      return `${strpad(`#${guard}`, LEFT_COL_WIDTH)}${log.map(asleep => asleep ? 'x' : '.').join('')}`
    }).join("\n")
  )
}

const getMinute = (event) => parseInt(event.split(':')[1], 10)

function getSleepStates(shifts) {
  return shifts.map(shift => {
    let guardId = parseInt(shift.shift().split('#')[1], 10)

    let minutes = [...Array(60)].map(asleep => false)

    if (shift.length > 0) {
      for (let i = 0; i < shift.length; ++i) {
        let asleep = shift[i].includes('asleep')

        let start = getMinute(shift[i])
        let end = (!shift[i+1] ? 59 : getMinute(shift[i+1]))
        let duration = end - start
        for (let j = 0; j < duration; ++j) {
          minutes[j+start] = asleep
        }
      }
    }
    return {guard: guardId, log: minutes}
  })
}

function getGroupedShiftEvents(events) {
  const shifts = []
  events.forEach(event => {
    event.includes('Guard #') ? shifts.push([event]) : shifts[shifts.length-1].push(event)
  })
  return shifts
}

class NumberMap extends Map {
  add(key, value) {
    this.set(key, (this.has(key) ? this.get(key) : 0) + value)
    return this
  }
}

function part1(events) {
  const shifts = getGroupedShiftEvents(events)

  let sleepStates = getSleepStates(shifts)

  drawGraph(sleepStates)

  let timeSpentSleeping = sleepStates.reduce((memo, state) => {
    return memo.add(state.guard, state.log.filter(isSleeping => isSleeping).length)
  }, new NumberMap)

  let sleepiestGuards = Array.from(timeSpentSleeping.entries())
    .sort(([guard1, minutes1], [guard2, minutes2]) => minutes2 - minutes1)
  
  let minuteSummary = Array.from(Array(60), () => 0)
  let bestMinute = sleepStates.filter(state => state.guard === sleepiestGuards[0][0])
    .reduce((memo, state) => state.log.map((wasSleeping, minute) => memo[minute] + Number(wasSleeping)), minuteSummary)
    .reduce((memo, timesSleeping, minute) => timesSleeping > memo.timesSleeping ? {minute, timesSleeping} : memo, {minute: -1, timesSleeping: -1})
  
  return {guard: sleepiestGuards[0][0], minute: bestMinute.minute, count: bestMinute.timesSleeping}
}

function part2(events) {
  const shifts = getGroupedShiftEvents(events)
  const sleepStates = getSleepStates(shifts)
  const guardsMinutesSpentAsleep = Array.from(Array(60)).map(minute => new NumberMap)
  sleepStates.forEach(({guard, log}) => {
    log.forEach((isSleeping, minute) => guardsMinutesSpentAsleep[minute].add(guard, isSleeping ? 1 : 0))
  })

  let highest = {guard: null, minute: -1, count: -1}

  for (let minute = 0; minute < 60; ++minute) {
    let map = guardsMinutesSpentAsleep[minute]
    for (let [guard, count] of map.entries()) {
      if (count > highest.count) {
        highest = {guard, minute, count}
      }
    }
  }

  return highest

}

let testData = `[1518-11-01 00:00] Guard #10 begins shift
[1518-11-01 00:05] falls asleep
[1518-11-01 00:25] wakes up
[1518-11-01 00:30] falls asleep
[1518-11-01 00:55] wakes up
[1518-11-01 23:58] Guard #99 begins shift
[1518-11-02 00:40] falls asleep
[1518-11-02 00:50] wakes up
[1518-11-03 00:05] Guard #10 begins shift
[1518-11-03 00:24] falls asleep
[1518-11-03 00:29] wakes up
[1518-11-04 00:02] Guard #99 begins shift
[1518-11-04 00:36] falls asleep
[1518-11-04 00:46] wakes up
[1518-11-05 00:03] Guard #99 begins shift
[1518-11-05 00:45] falls asleep
[1518-11-05 00:55] wakes up`.split("\n")
assert.deepEqual(part1(testData), {guard: 10, minute: 24, count: 2})


const events = load()
const result1 = part1(events)
console.log(result1, result1.guard * result1.minute)
assert.deepEqual({ guard: 73, minute: 44, count: 14 }, result1)
assert.equal(3212, result1.guard * result1.minute)

assert.deepEqual(part2(testData), {guard: 99, minute: 45, count: 3})
const result2 = part2(events)
console.log(result2, result2.guard * result2.minute)