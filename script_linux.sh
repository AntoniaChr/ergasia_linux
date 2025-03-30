#!/bin/bash

#It separates the first 500 alignments in new files
separate_exon_alignments() {
mkdir -p "exon_alignments"
chmod +w exon_alignments
count=0
while read -r line; do
    if [[ "$line" == *hg38* ]]; then
        ((count++))
        if [ $count -eq 501 ]; then
        break
        fi 
        echo "$line" > "exon_alignments/exon_alignment_${count}"  
    elif [[ -n "$line" ]]; then
        echo "$line" >> "exon_alignments/exon_alignment_${count}"
    elif [[ -z "$line" ]]; then
        continue
    fi    
done < "knownCanonical.exonNuc.fa"
}
separate_exon_alignments

#Check if iqtree is install
if ! command -v iqtree2 > /dev/null 2>&1; then
    echo "please install iqtree2 to proceed"
    exit 1
fi

#it creates 500 trees, one for each exon alignment
create_exon_trees() {
    mkdir -p "exon_trees"
    count=0
    for files in exon_alignments/exon_alignment_* ; do
        ((count++))
        iqtree2 -s "$files" -nt AUTO -bb 1000 -alrt 1000 -pre "exon_trees/exon_tree_${count}"
    done
}
create_exon_trees

#I get inside the exon file and merge all its contex in a new file, using a simple pipeline
cd exon_alignments
ls | ../merge_sequences | tee ../merge_seq
cd ..

#Construction of a phylogenetic tree for the whole alignment
iqtree2 -s "merge_seq" -nt AUTO -bb 1000 -alrt 1000 -pre "merge_seq_tree/merge_seq_tree"
 

#Compare the exon_trees with the merge_seq_tree
cd exon_trees  #I create a file with all the name of the trees I need to compare
ls | grep -E "^exon_tree_([0-9]{1,3})\.treefile$" | sort -V > ../exon_treefiles.txt 
cd ..

match_tree_names(){  #I modifie the name of the organisms in the trees, in order to be the same in all trees and enable the comparison, between trees.
local list_of_organism=("hg38" "panTro4" "panPan1" "gorGor3" "ponAbe2" "nomLeu3" "rheMac3" "macFas5" "papAnu2" "chlSab2" "nasLar1" "rhiRox1" "calJac3" "saiBol1" "tarSyr2" "micMur1" "otoGar3" "tupBel1" "mm10" "canFam3")
    
    for file in exon_trees/exon_tree_*.treefile; do
        if [[ -f "$file" ]]; then
            for item in "${list_of_organism[@]}"; do
                sed -i -E "s|[a-zA-Z0-9._]+_${item}_([0-9]+)_([0-9]+):([0-9.]+)|\
                 ${item}:\3|g" "$file"
            done
            sed -i 's/[[:space:]]\+//g' "$file"
        fi
    done
}   
match_tree_names 

tree_comparison() { #compare each exon tree with the merge_alignment tree
   Rscript R_script_tree_comparison > compare_exon_trees_results1
   sort -k2,2n compare_exon_trees_results1 > compare_exon_trees_results
   rm -r compare_exon_trees_results1
}
tree_comparison

separate_gene() { #separate each gene_alignment in a different file
if [ -d "gene_alignments" ]; then
   rm -r "gene_alignments"
fi    
mkdir -p "gene_alignments"
chmod +w gene_alignments
count=0
prev_line_empty=false #separate genes, when I find two empty lines in the row
while read -r line; do
    if [[ "$line" == ">uc010pht.3_hg38_1_22 85 0 1 chr1:156858537-156858621-" ]]; then
        break
        fi
    if [[ "$line" == *hg38_1_* ]]; then
        ((count++))
        echo "$line" > "gene_alignments/gene_alignment_${count}"  
    elif [[ -n "$line" ]]; then
        echo "$line" >> "gene_alignments/gene_alignment_${count}"
    fi
    if [ -z "$line" ]; then
        if [ "$prev_line_empty"=true ]; then
            continue
        fi
        prev_line_empty=true
        else
        prev_line_empty=false
       fi
done < "knownCanonical.exonNuc.fa"
}
separate_gene

#separate the exon of each gene in different files, in order to be able to use the merge file script
separate_gene_alignments_1() {
local file_1="$1"
local file_2="$2"
local count=0
while read -r line; do
    if [[ "$line" == *hg38* ]]; then
        ((count++))
        if [ $count -eq 501 ]; then
        break
        fi 
        echo "$line" > "$file_2/separate_gene_${count}"  
    elif [[ -n "$line" ]]; then
        echo "$line" >> "$file_2/separate_gene_${count}"
    elif [[ -z "$line" ]]; then
        continue
    fi    
done < "$file_1"
}

#merge the exon of each gene, in order to have every gene separate
separate_gene_alignments_2() {
local counter=0
local file_count=0
mkdir -p "all_separate_gene"
chmod +w all_separate_gene
mkdir -p final_genes
chmod +w final_genes

for file in gene_alignments/gene_alignment_*; do
      ((counter++))
    if [ "$counter" -eq 43 ]; then
      break
    fi   
    mkdir -p all_separate_gene/"separate_genes.${counter}"
    chmod +w all_separate_gene/separate_genes.${counter}
    separate_gene_alignments_1 "$file" "all_separate_gene/separate_genes.${counter}"
done

for file in all_separate_gene/separate_genes*; do
    ((file_count++))
    cd $file
    ls | ../../merge_sequences > ../../final_genes/gene_${file_count}  
cd ../../
done
rm -r all_separate_gene
}
separate_gene_alignments_2

#create a tree for each gene
create_gene_trees() {
    mkdir -p "gene_trees"
    count=0
    for files in final_genes/gene_* ; do
        ((count++))
        iqtree2 -s "$files" -nt AUTO -bb 1000 -alrt 1000 -pre "gene_trees/gene_tree_${count}"
    done
}
create_gene_trees

#create a text file with the name of all the gene trees in order to do the comparison
cd gene_trees
ls | grep -E "^gene_tree_([0-9]{1,3})\.treefile$" | sort -V > ../gene_treefiles.txt 
cd ..

#compare each gene tree with the merge sequence tree
tree_comparison_2 () {
   Rscript R_script_2.r > compare_gene_trees_results1
   sort -k2,2n compare_gene_trees_results1 > compare_gene_trees_results
   rm -r compare_gene_trees_results1
}
tree_comparison_2