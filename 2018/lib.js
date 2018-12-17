const fs = require('fs')
const util = require('util')

exports.readLines = function load(file) {
  return fs.readFileSync(file, 'utf8')
    .trim()
    .split("\n")
}




exports.group = function group(array, iteratee) {
  return array.reduce((memo, element) => {
    let key = iteratee(element)
    let group = memo[key] || []
    return {...memo, [key]: [...group, element]} // allocate 6 billion objects
  }, {})
}


exports.uniq = function uniq(array) {
  return [...new Set(array)]
}

exports.strpad = (s, len = 5) => s.length < len ? s + ' '.repeat(len - s.length) : s


exports.Range = class Range {
  constructor(start, end) {
    this.start = start
    this.end = end
  }

  includes(point) {

  }
}

exports.EventLog = class EventLog {
  constructor(events) {
    this.events = events
  }

  between(range) {

  }
  
}

function pipe(initialValue, ...fns) {
  const callFnDef = (value, fn, ...args) => {

    return Array.isArray(fn) ? callFnDef(value, fn[0], ...fn.slice(1))
      : typeof fn == 'string' ? value[fn](...args)
      : fn(value, ...args)
  }

  return fns.reduce(callFnDef, initialValue)
}
exports.pipe = pipe

// // test
// const wat = value => value + ', wat?'

// function omg(value, punctuation = '!') {
//   return value + ' omg' + punctuation
// }

// console.log('result should be:', pipe(['a', 'b', 'c'],
//   ['join', '_'],
//   'toUpperCase',
//   wat,
//   value => value + ' seriously???',
//   [omg, '!!!!!!!!!!']
// ))


// pipe(Math.random()*1000 + '',
//   pipe.parseInt(10),
//   pipe.Number.toFixed(10)
// )

exports.pairs = function pairs(object) {
  return Object.keys(object).map(key => [key, object[key]])
}

class FilledArray extends Array {
  constructor(size, initialValue) {
    super(size)
    for (let i=0; i<size; i++) {
      this[i] = typeof initialValue == 'function' ? initialValue(i, this) : initialValue;
    }
  }
}

exports.FilledArray = FilledArray

exports.print = function() {
  process.stdout.write(util.format.apply(this, arguments));
}