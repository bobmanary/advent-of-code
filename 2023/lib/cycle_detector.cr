# https://rosettacode.org/wiki/Cycle_detection#Ruby
# Author: Paul Anton Chernoch
# Purpose:
#   Find the cycle length and start position of a numerical seried using Brent's cycle algorithm.
#
# Given a recurrence relation X[n+1] = f(X[n]) where f() has
# a finite range, you will eventually repeat a value that you have seen before.
# Once this happens, all subsequent values will form a cycle that begins
# with the first repeated value. The period of that cycle may be of any length.
#
# Parameters:
#   x0 ...... First integer value in the sequence
#   block ... Block that takes a single integer as input 
#             and returns a single integer as output.
#             This yields a sequence of numbers that eventually repeats.
# Returns:
#   Two values: lambda and mu
#   lambda .. length of cycle
#   mu ...... zero-based index of start of cycle
#
module CycleDetector(T)
  def self.find(x0) : {Int32, Int32, Array(T)}
    # Copied from the ruby example, with sequence_values added.
    # With that change there might be a better algorithm *shrug*
    power = lambda = 1
    tortoise = x0
    sequence_values = [] of T
    hare = yield(x0)

    # Find lambda, the cycle length
    while tortoise != hare
      sequence_values << hare
      if power == lambda
        tortoise = hare
        power *= 2
        lambda = 0
      end
      hare = yield(hare)
      lambda += 1
    end

    # Find mu, the zero-based index of the start of the cycle
    hare = x0
    lambda.times { hare = yield(hare) }

    tortoise, mu = x0, 0
    while tortoise != hare
      tortoise = yield(tortoise)
      hare = yield(hare)
      mu += 1
    end

    return lambda, mu, sequence_values
  end
end

# # A recurrence relation to use in testing
# def f(x) (x * x + 1) % 255 end

# # Display the first 41 numbers in the test series
# puts (1..40).reduce([3]){|acc,_| acc << f(acc.last)}.join(",")

# # Test the find_cycle function
# clength, cstart = find_cycle(3) { |x| f(x) }
# puts "Cycle length = #{clength}\nStart index = #{cstart}"