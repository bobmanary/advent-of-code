lines = [line.rstrip('\n') for line in open('inputs/1.txt')]

frequency = 0
number_set = set()
while True:
    frequency += int(lines[0])
    if frequency in number_set:
        print frequency
        break
    else:
        number_set.add(frequency)
    lines.append(lines.pop(0))
