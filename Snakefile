shell.executable("/bin/bash")

#test
#essegene = [157, 206]
essegene = [8, 157, 206, 1042, 1064, 1480, 1728, 2495, 5715, 7706, 8952, 14177, 16282, 19413, 19414, 33371, 33507, 33508, 33553, 41485, 41487, 42117, 42118, 42167]

rule all:
        input: 'all.done'
        #input: expand('{sample}/{sample}.{suf}', suf=["faa", "names", "info", "phy", "phy.treefile", "phy.treefile.rooted", "iTOL.txt", "iTOL.zip"], sample=essegene), 'all.done'
                #'all.done', "phy.treefile.uploded"
#fetch proteins from mysql database
rule fetch:
        output: '{sample}/{sample}.faa', '{sample}/{sample}.names', '{sample}/{sample}.info'
        threads: 1
        shell: 
                '''
                touch {output[0]} {output[1]} {output[2]}
                python fetch.py {output[0]} {output[1]} {output[2]}
                '''
#alignment
rule mafft:
        input: '{sample}/{sample}.faa'
        output: '{sample}/{sample}.phy'
        threads: 4
        shell: 'mafft --auto --quiet --phylipout --thread {threads} {input} > {output}'
#phylogeny
rule iqtree:
        input: '{sample}/{sample}.phy'
        output: '{sample}/{sample}.phy.treefile'
        threads: 8
        shell: 'iqtree -nt {threads} -bb 1000 -wbtl -mset LG -madd LG4X -quiet -s {input}'
        #shell: 'iqtree -nt {threads} -mset LG -quiet -s {input}'
#root
rule mad:
        input: '{sample}/{sample}.phy.treefile'
        output: '{sample}/{sample}.phy.treefile.rooted'
        threads: 1
        shell: 'python mad.py {input}'
#file for tree display
rule iTOL_prepare:
        input:  '{sample}/{sample}.info', 'dataset_color_strip.txt'
        output: temp("{sample}/{sample}.iTOL.temp.txt"), "{sample}/{sample}.iTOL.txt"
        threads: 1
        shell: 
                '''
                cat {input[0]} | awk -F '\t' '{{print $2, $8}}' | sed 's/Plasmid/\#00ff00/g' | sed 's/Chromosome/\#ff0000/g' > {output[0]}
                cat {input[1]} {output[0]} > {output[1]}
                '''
#upload to iTOL
rule iTOL_upload:
        input: "{sample}/{sample}.iTOL.txt", '{sample}/{sample}.phy.treefile.rooted'
        output: "{sample}/{sample}.iTOL.zip", temp("{sample}/{sample}.done")
        threads: 1
        shell:
                '''
                zip {output[0]} {input[0]} {input[1]}
                curl -F "zipFile=@/home/wang/p2chr_blast/data/escherichia/essential/{output[0]}" -F "APIkey=2nkpnJv4y8RAQTeV2THzug" -F "projectName=essetree" https://itol.embl.de/batch_uploader.cgi
                touch {output[1]}
                '''
#finish
rule finish:
        input: expand('{sample}/{sample}.done', sample=essegene)
        output: touch('all.done')
