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

def time_comparison_plotting(time_collection):

    threads = [10 + i * 10 for i in range(len(time_collection))]
    time_min, time_max = float('inf'), 0.
    for time in time_collection:
        if time_min > time:
            time_min = time
        if time_max < time:
            time_max = time

    plt.figure(figsize=(12, 12))
    plt.plot([i for i in range(len(time_collection))], time_collection, marker='o', color='b')

    # plt.yscale("log")
    plt.xticks([i for i in range(len(threads))], threads)
    plt.ylim(time_min, time_max)
    # plt.yticks([time_min, time_max])
    gap = (time_max - time_min) / 5.
    plt.yticks([time_min + gap*i for i in range(6)])
    plt.xlabel('numThreads')
    plt.ylabel('KF Fitting Time-(milisecond)')
    # plt.legend(loc='upper right', prop={'size':10})

    plt.title('Time Consumpting CPU along numThreads with EigenInverter')
    plt.savefig('KF_Time_Fitting_Comparison_CPU_EigenInverter.pdf')
    plt.close()


if __name__ == '__main__':

    time_collection = list()
    path = os.getcwd()
    file_list = list()

    for f in os.listdir(path):
        if f.strip().split('.')[-1] == 'log':
            file_list.append(f)
    
    file_list.sort(key = lambda x: int(x.strip().split('.')[0].replace('Thread', '')))

    for f in file_list:
        time_collection.append(data_extraction(f))

    time_comparison_plotting(time_collection)



    # for f in os.listdir(path):
    #     if len(f.split('.')) == 1:
    #         folder = f.strip()
    #         for file_name in os.listdir(path + '/' + folder):
    #             if file_name.strip().split('.')[-1] == 'log':
    #                 time_collection[folder].append(data_extraction(path + '/' + folder + '/' + file_name))
    

    # time_comparison_plotting(time_collection)
        
