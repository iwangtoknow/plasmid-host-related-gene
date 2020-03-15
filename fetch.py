#!/usr/bin/env python3
#=====================
"""
Fetch protein from mysql database

Usage:
        fetch.py clust
    clust is protein clust number
"""
# 10-Mar-2020 
#=====================

from sys import argv
import mysql.connector
mydb = mysql.connector.connect(host = "localhost", user = "root", database = "bacteria_2018")
mycursor = mydb.cursor()

c = argv[1].split(".")[0].split("/")[1]
species = 'Escherichia'
#get plasmid protein
mycursor.execute("select p.id, p.protein_ID, p.name, p.symbol, p.sequence, g.organism_ID, g.Organism, c.Replicon_Type, c.Size FROM plsmcl50 l, proteins p, contigs c, genomes g where l.id=p.id and p.contig_ID=c.contig_ID and c.organism_ID=g.organism_ID and g.Organism like '"+species+"%' and l.clust="+str(c)+" and c.contig_ID not in ('20141', '20143', '20218', '20220', '20241', '20269', '20272', '20273', '20275');")
pls_result=mycursor.fetchall()
#get chromosome homology protein
mycursor.execute("select en.sseqid, p.protein_ID, p.name, p.symbol, p.sequence, g.organism_ID, g.Organism, c.Replicon_Type, c.Size FROM plsmcl50 l, proteins p, contigs c, genomes g, escherichia_needle en where l.id=en.qseqid and en.sseqid = p.id and en.identity > 40 and p.contig_ID=c.contig_ID and c.organism_ID=g.organism_ID and c.Replicon_Type='Chromosome' and g.Organism like '"+species+"%' and l.clust="+str(c)+";")
chr_result=mycursor.fetchall()

def non_redundant_result(x):
    rddt_dict={}
    nrddt_dict={}
    nrddt_list=[]
    for i in x:
        rddt_dict[i[0]]=i[4]
    for key, value in rddt_dict.items():
        if value not in nrddt_dict.values():
            nrddt_dict[key]=value
    for p in x:
        if p[0] in nrddt_dict:
            nrddt_list.append(p)
    return nrddt_list

        
#my_result = pls_result + non_redundant_result(chr_result)
my_result = pls_result + chr_result
for i in my_result:
    p_id=str(i[0])
    p_protein_ID=str(i[1])
    p_name=str(i[2])
    p_symbol=str(i[3])
    p_sequence=str(i[4])
    g_organism_ID=str(i[5])
    g_organism=str(i[6])
    c_Replicon_Type=str(i[7])
    c_Size=str(i[8])
    
    #write protein id and sequence
    with open(argv[1], 'a') as seqfile:
        seqfile.write('>'+p_id+'\n'+p_sequence+'\n')
    #write protein names    
    with open(argv[2], 'a') as namefile:
        namefile.write(p_id+'\t'+g_organism+'\n')
    #write protein info
    with open(argv[3], 'a') as infofile:
        infofile.write("\t".join([c, p_id, p_protein_ID, g_organism_ID, g_organism, p_name, p_symbol, c_Replicon_Type, c_Size, p_sequence])+'\n')