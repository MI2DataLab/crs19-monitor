import os
import itertools

from Bio.Blast.NCBIXML import parse


def detect_mutations(input: str, db: str, out: str):
    os.system(f"blastx -query {input} -subject {db} -subject_besthit -max_hsps 1 -outfmt 5 > tmp.blast.xml")
    with open("tmp.blast.xml", "r") as f:
        with open(out, "w") as fh:
            done = 0
            for p in parse(f):
                mutations = []
                for alignment in p.alignments:
                    al_mutations = []
                    hsps = alignment.hsps[0]
                    query = hsps.query
                    subject = hsps.sbjct
                    if (len(query)) != len(subject):
                        continue
                    for i in range(len(subject)):
                        if query[i] not in ['X', '-', '*'] and query[i] != subject[i]:
                            al_mutations.append(f"{alignment.title.split('|')[0]} {subject[i]}{i + hsps.sbjct_start}{query[i]}")

                    mutations.append(al_mutations)
                    done += 1
                fh.write(f"{p.query};")
                fh.write(','.join(list(itertools.chain.from_iterable(mutations))))
                fh.write("\n")
    os.unlink("tmp.blast.xml")


if __name__ == '__main__':
    detect_mutations(os.environ.get('FASTA_TO_MUTATION'),
                     os.environ.get('FASTA_TO_MUTATION_DB'),
                     os.environ.get('FASTA_TO_MUTATION_OUT'))
