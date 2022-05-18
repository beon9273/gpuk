import matplotlib.pyplot as plt
import os
from collections import defaultdict

def data_extraction(file_name):
    time = 0
    pre = ""

    with open(file_name, 'rt') as myfile:
        for l in myfile:
            if len(l.strip()) <= 0: continue
            if l.replace('-', '').strip().startswith('ending'):
                return float(pre.split(' ')[-1].replace('\n', ''))
            else:
                pre = l
    return 0

def generate_label(key):
    label = key.split('_')
    device, method = label[0], label[-1]
    L = ""
    if device == "GPU":
        L += "[Tesla_T4]"
        L += "CustomerInverter"
    else:
        L += "[Intel_Xeon_E5_2680V4]"
        L += method
    return L

def time_comparison_plotting(time_collection):

    trials = [10**i for i in range(6)]
    # clr = ('b', 'r', 'g', 'y')
    clr = {"GPU_Smoothing":'r', "CPU_Smoothing_CustomerInverter":'b', "CPU_Smoothing_EigenInverter":'b'}
    line = {"GPU_Smoothing":'solid', "CPU_Smoothing_CustomerInverter":'dotted', "CPU_Smoothing_EigenInverter":'dashed'}
    M = {"GPU_Smoothing":'x', "CPU_Smoothing_CustomerInverter":'o', "CPU_Smoothing_EigenInverter":'o'}
    # clr = {"GPU_no_Smoothing":'r', "CPU_no_Smoothing_CustomerInverter":'b', "CPU_no_Smoothing_EigenInverter":'b'}
    # line = {"GPU_no_Smoothing":'solid', "CPU_no_Smoothing_CustomerInverter":'dotted', "CPU_no_Smoothing_EigenInverter":'dashed'}
    # M = {"GPU_no_Smoothing":'x', "CPU_no_Smoothing_CustomerInverter":'o', "CPU_no_Smoothing_EigenInverter":'o'}
    plt.figure(figsize=(12, 12))
    count = 0
    time_min, time_max = float('inf'), 0.
    for key in time_collection:
        plt.plot([i for i in range(len(time_collection[key]))], time_collection[key], marker=M[key], color=clr[key], linestyle=line[key], label=generate_label(key))
        count += 1
        for time in time_collection[key]:
            if time_min > time:
                time_min = time
            if time_max < time:
                time_max = time
    plt.xticks([i for i in range(len(trials))], trials)
    plt.ylim(time_min, time_max)
    # plt.yticks([time_min, time_max])
    gap = (time_max - time_min) / 20.
    plt.yticks([time_min + gap*i for i in range(21)])
    plt.xlabel('Trials')
    plt.ylabel('KF Fitting Time-(milisecond)')
    plt.legend(loc='upper left', prop={'size':10})
    plt.yscale("log")

    plt.title('Time Consumpting between GPU vs.CPU with Smoothing')
    plt.savefig('KF_Time_Fitting_Comparison_Smoothing.pdf')
    plt.close()


if __name__ == '__main__':

    time_collection = defaultdict(list)
    
    path = os.getcwd()
    for f in os.listdir(path):
        if len(f.split('.')) == 1:
            folder = f.strip()
            if folder.split('_')[1] == 'no': continue
            for file_name in os.listdir(path + '/' + folder):
                if file_name.strip().split('.')[-1] == 'log':
                    time_collection[folder].append(data_extraction(path + '/' + folder + '/' + file_name))
    


    time_comparison_plotting(time_collection)
        
