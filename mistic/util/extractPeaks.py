# -*- coding: utf-8 -*-


import os
import sys
import string
import getopt
import tempfile

# ###########################################################################################
# Object 
class Extract_node() :

    def __init__(self, id_node, gene_id, line):
        self.id = str(id_node)
        self.gene_id = gene_id
        self.in_valid_peak = True
        self.peak_id = "0"
        self.line = line

class Extract_peak() :
    def __init__(self, id_peak, gene1, gene2, corr, max_diff_corr):
        self.id = str(id_peak)
        self.genes = {}
        self.genes[gene1.id] = gene1
        self.genes[gene2.id] = gene2
        self.valid_peak = True
        self.min_corr = corr
        self.max_corr = corr
        self.num_gene_valid = 2

        gene1.peak_id = self.id
        gene2.peak_id = self.id

    def gene_in_peak(self, key):
        if key in self.genes :
            return True
        return False

    def print_peak(self, min_gene, min_diff_corr, outF=None) :
        #print ("in print peak")
        genes_in_peaks = ""
        if len(self.genes) < min_gene :
            return genes_in_peaks

        if min_diff_corr != 0 and min_diff_corr > (self.max_corr-self.min_corr) :
            return genes_in_peaks

        #print ("print peak")
        for i_gene in self.genes :
            genes_in_peaks += self.genes[i_gene].gene_id + ";"

        peaks = "" + self.id + "\t" + str(len(self.genes)) + "\t" + str(self.min_corr) + "\t" + str(self.max_corr) + "\t" + genes_in_peaks
        if not (outF is None):
            outF.write(peaks + "\n")

        return genes_in_peaks

    def len_peak(self) :
        return len(self.genes)

    def delta_peaks(self, peak) :
        return max(self.max_corr, peak.max_corr) - min(self.min_corr, peak.min_corr)

    def invalid_peak(self) :
        self.valid_peak = False
        for i_gene in self.genes : 
              self.genes[i_gene].in_valid_peak = False

    def add_gene(self, gene, corr, stay_valid) :
        if gene.id not in self.genes :
            self.genes[gene.id] = gene
            gene.peak_id = self.id

            if self.valid_peak : 
                if stay_valid :
                    if corr < self.min_corr :
                        self.min_corr = corr
                    if corr > self.max_corr :
                        self.max_corr = corr
                    self.num_gene_valid += 1
                else :
                    for i_gene in self.genes : 
                        self.genes[i_gene].in_valid_peak = False
                    self.valid_peak = False
            else : 
                gene.in_valid_peak = False

    def add_peak(self, peak) :
        #print ("add peak " + self.id + " deleted peak : " + peak.id)
        for i_gene in peak.genes :
            peak.genes[i_gene].peak_id = self.id

        self.genes = dict(self.genes.items() + peak.genes.items())
        self.num_gene_valid += peak.num_gene_valid

# ###########################################################################################
# Secondary functions 
def get_node(nodes, key):
    try :
        return nodes[key]
    except KeyError :
        sys.exit("Error get_node : key not found:\n"+ key)

def get_peak(peaks, key):
    try :
        return peaks[key]
    except KeyError :
        #print (len(peaks))
        sys.exit("Error get_peak : key not found:\n"+ key)

def create_peak(node1, node2, corr, peaks, id_peak, max_diff_corr):
    peaks[id_peak] = Extract_peak(id_peak, node1, node2, corr, max_diff_corr)

def merge_peak(node1, node2, corr, min_gene, max_gene, min_diff_corr, max_diff_corr, peaks, outF=None) :
    peaks_str = []

    if node1.peak_id == "0" :
        peak = get_peak(peaks,node2.peak_id)

        stay_valid = peak.valid_peak
        stay_valid = stay_valid and (len(peak.genes)+1 <= max_gene)
        if max_diff_corr != 0 : 
            delta = max(peak.max_corr, corr) - min(peak.min_corr,corr)
            stay_valid = stay_valid and (delta <= max_diff_corr)

        if peak.valid_peak and stay_valid == False :
            peak_str = peak.print_peak(min_gene, min_diff_corr, outF)
            if len(peak_str) != 0 :  peaks_str.append(peak_str)

        peak.add_gene(node1, corr, stay_valid)
    else :
        if node2.peak_id == "0" :
            peak = get_peak(peaks,node1.peak_id)

            stay_valid = peak.valid_peak
            stay_valid = stay_valid and (len(peak.genes)+1 <= max_gene)
            if max_diff_corr != 0 : 
                delta = max(peak.max_corr, corr) - min(peak.min_corr,corr)
                stay_valid = stay_valid and (delta <= max_diff_corr)

            if peak.valid_peak and stay_valid == False :
                peak_str = peak.print_peak(min_gene, min_diff_corr, outF)
                if len(peak_str) != 0 :  peaks_str.append(peak_str)

            peak.add_gene(node2, corr, stay_valid)
        else :

            peak1 = get_peak(peaks,node1.peak_id)
            peak2 = get_peak(peaks,node2.peak_id)

            both_valid = (peak1.valid_peak and  peak2.valid_peak)
            if both_valid :
                stay_valid = (len(peak1.genes) + len(peak2.genes) <= max_gene)
                if max_diff_corr != 0 : 
                    stay_valid = stay_valid and (peak1.delta_peaks(peak2) <= max_diff_corr)

                if stay_valid == False:
                    if peak1.valid_peak :
                        peak_str = peak1.print_peak(min_gene, min_diff_corr, outF)
                        if len(peak_str) != 0 :  peaks_str.append(peak_str)
                        peak1.invalid_peak()
                    if peak2.valid_peak :
                        peak_str = peak_str + peak2.print_peak(min_gene, min_diff_corr, outF)
                        if len(peak_str) != 0 :  peaks_str.append(peak_str)
                        peak2.invalid_peak()
                else :
                    if len(peak1.genes) <= len(peak2.genes) :
                        peak2.add_peak(peak1)
                        del peaks[peak1.id]
                    else :
                        peak1.add_peak(peak2)
                        del peaks[peak2.id]
            else :
                if peak1.valid_peak :
                    peak_str = peak1.print_peak(min_gene, min_diff_corr, outF)
                    if len(peak_str) != 0 :  peaks_str.append(peak_str)
                    peak1.invalid_peak()
                if peak2.valid_peak :
                    peak_str = peak2.print_peak(min_gene, min_diff_corr, outF)
                    if len(peak_str) != 0 :  peaks_str.append(peak_str)
                    peak2.invalid_peak()

    return peaks_str
      
      



# ###########################################################################################
# Primary functions
def read_nodes (reader) :

    nodes = {}

    #read the header
    line = reader.readline().rstrip('\n')
    
    line = reader.readline().rstrip('\n')
    while len(line)!=0 and line[0] == "n" :
        attribute = line.split(" ")
        nodes[attribute[1]] = Extract_node(attribute[1], attribute[2].split("=")[1], line)

        line = reader.readline().rstrip('\n')
        
    return nodes, line


def extract_peaks (reader, last_line, nodes, min_gene, max_gene, min_diff_corr, max_diff_corr, outF=None) :
    peaks = {}
    peaks_str = []
    line = last_line
    cpt_id = 1

    while len(line)!=0 :
        #print(line)
        attribute = line.split(" ")
        node1 = get_node(nodes, attribute[1])
        node2 = get_node(nodes, attribute[2])

        if (node1.peak_id !="0" or node2.peak_id != "0") :
            peaks_str = peaks_str + merge_peak(node1, node2, float(attribute[3].split("=")[1]), min_gene, max_gene, min_diff_corr, max_diff_corr, peaks, outF)
        else :
            create_peak(node1, node2, float(attribute[3].split("=")[1]), peaks, str(cpt_id), max_diff_corr)
            cpt_id += 1
            
                

        line = reader.readline().rstrip('\n')
    return peaks_str


# ###########################################################################################
# Main function
def exec_extract_peaks(inF, min_gene, max_gene, min_diff_corr, max_diff_corr, writter_out=None):
    print("in extract")    
    print(writter_out)                
    reader_in = open(inF,'r')
    nodes, last_line = read_nodes(reader_in)

    if not (writter_out is None) :
        writter_out.write("PICK_ID\tN_GENES\tMIN_CORR\tMAX_CORR\tGENES\n")
    
    peaks_str = extract_peaks(reader_in, last_line, nodes, min_gene, max_gene, min_diff_corr, max_diff_corr, writter_out)
    
    print("end of extract")

    reader_in.close()
    
    return peaks_str
        




