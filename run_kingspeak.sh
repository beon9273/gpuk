#!/bin/bash

# declare -i nThreads=1
# declare -i CorePerSocket=14
# declare -i Socket=2

# while [ $nThreads -lt $((CorePerSocket*Socket)) ]
# do
#     ./INSTALL/bin/KalmanFitterCPUTest -a Intel_Xeon_E5_2680V4 -r ${nThreads} -t 100000 --smoothing 1 -o 0 >> result_kingspeak/CPU_Time_Comparison_By_Threads_EigenInverter/Thread${nThreads}.log    
#     ./INSTALL/bin/KalmanFitterGPUTest -d cpu -a Intel_Xeon_E5_2680V4 -r ${nThreads} -t 100000 -g 5120x1 -b 8x8x1 --smoothing 1 -o 0 >> result_kingspeak/CPU_Time_Comparison_By_Threads_CustomerInverter/Thread${nThreads}.log 
#     nThreads=$((nThreads*2))
# done

# nThreads=$((CorePerSocket*Socket))
# ./INSTALL/bin/KalmanFitterCPUTest -a Intel_Xeon_E5_2680V4 -r ${nThreads} -t 100000 --smoothing 1 -o 0 >> result_kingspeak/CPU_Time_Comparison_By_Threads_EigenInverter/Thread${nThreads}.log    
# ./INSTALL/bin/KalmanFitterGPUTest -d cpu -a Intel_Xeon_E5_2680V4 -r ${nThreads} -t 100000 -g 5120x1 -b 8x8x1 --smoothing 1 -o 0 >> result_kingspeak/CPU_Time_Comparison_By_Threads_CustomerInverter/Thread${nThreads}.log

# nThreads=$((2*CorePerSocket*Socket))
# ./INSTALL/bin/KalmanFitterCPUTest -a Intel_Xeon_E5_2680V4 -r ${nThreads} -t 100000 --smoothing 1 -o 0 >> result_kingspeak/CPU_Time_Comparison_By_Threads_EigenInverter/Thread${nThreads}.log    
# ./INSTALL/bin/KalmanFitterGPUTest -d cpu -a Intel_Xeon_E5_2680V4 -r ${nThreads} -t 100000 -g 5120x1 -b 8x8x1 --smoothing 1 -o 0 >> result_kingspeak/CPU_Time_Comparison_By_Threads_CustomerInverter/Thread${nThreads}.log

declare -i nTracks=1

for ((i=0; i<=5; i++))
do
    ./INSTALL/bin/KalmanFitterCPUTest -a Intel_Xeon_E5_2680V4 -r 56 -t ${nTracks} --smoothing 0 -o 0 >> result_kingspeak/Time_Comparison_Step_RK4/CPU_no_Smoothing_EigenInverter/Track${nTracks}.log   
    ./INSTALL/bin/KalmanFitterCPUTest -a Intel_Xeon_E5_2680V4 -r 56 -t ${nTracks} --smoothing 1 -o 0 >> result_kingspeak/Time_Comparison_Step_RK4/CPU_Smoothing_EigenInverter/Track${nTracks}.log  
    ./INSTALL/bin/KalmanFitterGPUTest -d cpu -a Intel_Xeon_E5_2680V4 -r 56 -t ${nTracks} -g 5120x1 -b 8x8x1 --smoothing 0 -o 0 >> result_kingspeak/Time_Comparison_Step_RK4/CPU_no_Smoothing_CustomerInverter/Track${nTracks}.log
    ./INSTALL/bin/KalmanFitterGPUTest -d cpu -a Intel_Xeon_E5_2680V4 -r 56 -t ${nTracks} -g 5120x1 -b 8x8x1 --smoothing 1 -o 0 >> result_kingspeak/Time_Comparison_Step_RK4/CPU_Smoothing_CustomerInverter/Track${nTracks}.log
    nTracks=$((nTracks*10))
done