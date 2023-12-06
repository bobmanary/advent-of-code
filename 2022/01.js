const fs = require('fs');

let elves = fs.readFileSync('inputs/01.txt', {encoding: 'utf8'})
  .split('\n\n')
  .map((x) => {
      return x.split('\n')
      .map(i => parseInt(i, 10))
      .reduce((previous, current) => previous + current, 0)
    }
  )
  .filter(x => !isNaN(x))
  .sort((a, b) => a - b)
  .reverse()

let mostCalories = elves[0];
let top3Calories = elves[0] + elves[1] + elves[2];

console.log(mostCalories)
console.log(top3Calories)

