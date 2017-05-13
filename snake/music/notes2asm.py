

LEGATO = 2
STACCATO = 1

notes = {
    '1':{
        'C': '9121',
        'C#': '8609',
        'D': '8126',
        'D#': '7670',
        'E': '7239',
        'F': '6833',
        'F#': '6449',
        'G': '6087',
        'G#': '5746',
        'A': '5423',
        'A#': '5119',
        'B': '4831',
        'N': '0'
    },
    '2':{
        'C': '4560',
        'C#': '4304',
        'D': '4063',
        'D#': '3834',
        'E': '3619',
        'F': '3416',
        'F#': '3224',
        'G': '3043',
        'G#': '2873',
        'A': '2711',
        'A#': '2559',
        'B': '2415'
    },
    '3': {
        'C': '2280',
        'C#': '2152',
        'D': '2031',
        'D#': '1917',
        'E': '1809',
        'F': '1715',
        'F#': '1612',
        'G': '1521',
        'G#': '1436',
        'A': '1355',
        'A#': '1292',
        'B': '1207'
    },
    '4': {'C': '1140'}
}


def note2freq(note):
    return notes[note[-1]][note[:-1]]

def parse(note):
    modif = STACCATO
    if note.endswith('.'):
        modif = LEGATO
        note = note[:-1]

    return (note2freq(note[1:]), 'SZ_%s' % note[0], modif)



def notes2asm(notesfile):
    with open(notesfile, mode='r') as f:
        yield from map(parse, ' '.join(f).split())


def main():
    from sys import argv, exit
    if len(argv) != 3:
        print('Usage: notes2asm.py <in> <out>')
        exit(1)

    with open(argv[2], mode='w') as f:
        for e in notes2asm(argv[1]):
            print('Muse <%s, %s, %s>' % e, file=f)


if __name__ == '__main__':
    main()
