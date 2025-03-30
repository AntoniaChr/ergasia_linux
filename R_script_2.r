#!/usr/bin/env Rscript

library(ape)

reference_tree <- read.tree("./merge_seq_tree/merge_seq_tree.treefile")
tree_list <- readLines("gene_treefiles.txt")

for (i in 1:length(tree_list)) {
     current_tree_file <- paste("./gene_trees/", tree_list[i], sep="")
     current_tree <- read.tree(current_tree_file)
     
     rf_distance <- dist.topo(reference_tree, current_tree)

     cat(paste("RF_", tree_list[i],"\t",rf_distance,"\n", sep=""))
}