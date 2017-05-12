import itertools as it
from itertools import combinations, permutations
from collections import Counter


d = ('1', '3', '4', '6')
s = ('+', '*', '-', '/')
counter = Counter()


def place(a):
    for b in permutations(a, 4):
        signify(b)


def signify(a):
    for c in it.product(s, repeat=3):
        v = []
        for i in range(len(a) + len(c)):
            v.append((a, c)[i % 2][i // 2])

        brackety(v)


def brackety(a):


    for i, j in bracket_indexies(len(a)+1):
        v = []
        c = 0
        for e in a + ['$']:
            if c == i:
                v.append('(')
            if c == j:
                v.append(')')
            if e != '$':
                v.append(e)
            c += 1

        register(v)




def bracket_indexies(len_a):

    for i in range(0, len_a):
        for j in range(i, len_a):
            if i % 2 == 0 and j % 2 == 1:
                yield i, j



def register(a):
    r = res(a)
    print(''.join(a), ' = ', r)
    # if r == 24:
        # print("HORRAY")
        # __import__('sys').exit(0)
    counter[r] += 1


def res(a):
    t = ''
    try:
        t = eval(''.join(a))
    except Exception as e:
        t = 'Error: ' + str(e)
        counter[22.8] += 1
    return t


def main():
    place(d)
    r = sorted(counter.most_common(), key=lambda x: x[0])
    [print(e) for e in r if 22 < e[0] < 26]

if __name__ == '__main__':
    main()
