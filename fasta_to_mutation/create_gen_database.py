import os

from Bio import SeqIO

gbk_filename = os.environ.get('FASTA_TO_MUTATION_GENOME')
faa_filename = os.environ.get('FASTA_TO_MUTATION_DB')
input_handle = open(gbk_filename, "r")
output_handle = open(faa_filename, "w")

for seq_record in SeqIO.parse(input_handle, "genbank"):
    for seq_feature in seq_record.features:
        if seq_feature.type == "CDS":
            assert len(seq_feature.qualifiers['translation']) == 1
            output_handle.write(">%s|%s\n%s\n" % (
                   seq_feature.qualifiers['gene'][0],
                   seq_record.name,
                   seq_feature.qualifiers['translation'][0]))

output_handle.close()
input_handle.close()
