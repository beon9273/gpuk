#!/bin/bash

# declare -i nThreads=1
# declare -i CorePerSocket=28
# declare -i Socket=2

# while [ $nThreads -lt $((CorePerSocket*Socket)) ]
# do
#     ./INSTALL/bin/KalmanFitterCPUTest -a Intel_Xeon_Gold_6330R -r ${nThreads} -t 100000 --smoothing 1 -o 0 >> result/CPU_Time_Comparison_By_Threads_EigenInverter/Thread${nThreads}.log    
    # ./INSTALL/bin/KalmanFitterGPUTest -d cpu -a Intel_Xeon_Gold_6330R -r ${nThreads} -t 100000 -g 5120x1 -b 8x8x1 --smoothing 0 -o 0 >> result/CPU_Time_Comparison_By_Threads_CustomerInverter/Thread${nThreads}.log 
#     nThreads=$((nThreads*2))
# done

# nThreads=$((CorePerSocket*Socket))
# ./INSTALL/bin/KalmanFitterCPUTest -a Intel_Xeon_Gold_6330R -r ${nThreads} -t 100000 --smoothing 1 -o 0 >> result/CPU_Time_Comparison_By_Threads_EigenInverter/Thread${nThreads}.log    
# ./INSTALL/bin/KalmanFitterGPUTest -d cpu -a Intel_Xeon_Gold_6330R -r ${nThreads} -t 100000 -g 5120x1 -b 8x8x1 --smoothing 0 -o 0 >> result/CPU_Time_Comparison_By_Threads_CustomerInverter/Thread${nThreads}.log

# nThreads=$((2*CorePerSocket*Socket))
# ./INSTALL/bin/KalmanFitterCPUTest -a Intel_Xeon_Gold_6330R -r ${nThreads} -t 100000 --smoothing 1 -o 0 >> result/CPU_Time_Comparison_By_Threads_EigenInverter/Thread${nThreads}.log    
# ./INSTALL/bin/KalmanFitterGPUTest -d cpu -a Intel_Xeon_Gold_6330R -r ${nThreads} -t 100000 -g 5120x1 -b 8x8x1 --smoothing 0 -o 0 >> result/CPU_Time_Comparison_By_Threads_CustomerInverter/Thread${nThreads}.log

declare -i nTracks=1

for ((i=0; i<=5; i++))
do
    ncu --set detailed -o ./result_kingspeak/Num_Reg_Comparing_T4/Reg_Unlimited/no_Smoothing/Track${nTracks} ./INSTALL/bin/KalmanFitterGPUTest -d gpu -t ${nTracks} -g 5120x1 -b 8x8x1 --smoothing 0 -o 0
    ncu --set detailed -o ./result_kingspeak/Num_Reg_Comparing_T4/Reg_Unlimited/Smoothing/Track${nTracks} ./INSTALL/bin/KalmanFitterGPUTest -d gpu -t ${nTracks} -g 5120x1 -b 8x8x1 --smoothing 1 -o 0
    # ./INSTALL/bin/KalmanFitterGPUTest -d gpu -t ${nTracks} -g 5120x1 -b 8x8x1 --smoothing 0 -o 0 >> result/Time_Comparison_Step_RK4/GPU_no_Smoothing/Track${nTracks}.log
    # ./INSTALL/bin/KalmanFitterGPUTest -d gpu -t ${nTracks} -g 5120x1 -b 8x8x1 --smoothing 1 -o 0 >> result/Time_Comparison_Step_RK4/GPU_Smoothing/Track${nTracks}.log
    # ./INSTALL/bin/KalmanFitterCPUTest -a Intel_Xeon_Gold_6330R -r 104 -t ${nTracks} --smoothing 0 -o 0 >> result/Time_Comparison_Step_RK4/CPU_no_Smoothing_EigenInverter/Track${nTracks}.log   
    # ./INSTALL/bin/KalmanFitterCPUTest -a Intel_Xeon_Gold_6330R -r 52 -t ${nTracks} --smoothing 1 -o 0 >> result/Time_Comparison_Step_RK4/CPU_Smoothing_EigenInverter/Track${nTracks}.log  
    # ./INSTALL/bin/KalmanFitterGPUTest -d cpu -a Intel_Xeon_Gold_6330R -r 52 -t ${nTracks} -g 5120x1 -b 8x8x1 --smoothing 0 -o 0 >> result/Time_Comparison_Step_RK4/CPU_no_Smoothing_CustomerInverter/Track${nTracks}.log
    # ./INSTALL/bin/KalmanFitterGPUTest -d cpu -a Intel_Xeon_Gold_6330R -r 104 -t ${nTracks} -g 5120x1 -b 8x8x1 --smoothing 1 -o 0 >> result/Time_Comparison_Step_RK4/CPU_Smoothing_CustomerInverter/Track${nTracks}.log
    # ./INSTALL/bin/KalmanFitterCPUTest -a Intel_Xeon_Gold_6230R -t ${nTracks} --smoothing 0 -o 0 >> result/Time_Comparison_Step_RK4/CPU_W0_Smoothing/Track${nTracks}.log
    # ./INSTALL/bin/KalmanFitterCPUTest -a Intel_Xeon_Gold_6230R -t ${nTracks} --smoothing 1 -o 0 >> result/Time_Comparison_Step_RK4/CPU_Smoothing/Track${nTracks}.log    
    # ./INSTALL/bin/KalmanFitterGPUTest -d cpu -a Intel_Xeon_Gold_6230R -t ${nTracks} -g 5120x1 -b 8x8x1 --smoothing 0 -o 0 >> result/Time_Comparison_Step_RK4/GPU_W0_Smoothing/Track${nTracks}.log
    # ./INSTALL/bin/KalmanFitterGPUTest -d cpu -a Intel_Xeon_Gold_6230R -t ${nTracks} --smoothing 0 -o 0 >> result/Time_Comparison_Step_RK4/CPU_W0_Smoothing/Track${nTracks}.log
    # ./INSTALL/bin/KalmanFitterGPUTest -d cpu -a Intel_Xeon_Gold_6230R -t ${nTracks} -o 0 >> result/Time_Comparison_Step_RK4/CPU_Smoothing/Track${nTracks}.log
    nTracks=$((nTracks*10))
done

# for ((i=0; i<=5; i++))
# do
#     ./INSTALL/bin/KalmanFitterCPUTest -a Intel_Xeon_Gold_6230R -t ${nTracks} --smoothing 0 -o 0 >> result/Time_Comparison_Step_RK4/CPU_W0_Smoothing/Track${nTracks}.log
#     ./INSTALL/bin/KalmanFitterCPUTest -a Intel_Xeon_Gold_6230R -t ${nTracks} --smoothing 1 -o 0 >> result/Time_Comparison_Step_RK4/CPU_Smoothing/Track${nTracks}.log
#     nTracks=$((nTracks*10))
# done

# nTracks=$((nTracks / nTracks))

# for ((i=0; i<=5; i++))
# do
#     ./INSTALL/bin/KalmanFitterGPUTest -d gpu -t ${nTracks} -g 5120x1 -b 8x8x1 --smoothing 0 -o 0 >> result/nTracks_wo_Smoothing/Track${nTracks}.log
#     nTracks=$((nTracks*10))
# done

# declare -a bidim=("8x8x1" "16x16x1" "32x32x1")
# declare -a unidim=("64x1x1" "256x1x1" "1024x1x1")
# declare -i nStreams=1
# for ((i=0; i<=1; i++)); 
# do
#     for val in ${bidim[@]};
#     do
#     ./INSTALL/bin/KalmanFitterGPUTest -d gpu -t 10000 -g 5120x1 -b ${val} --streams ${nStreams} -o 0 >> result/Grid_Size_5120/bidim/b${val}_stream${nStreams}.log
#     done
#     for val in ${unidim[@]};
#     do
#     ./INSTALL/bin/KalmanFitterGPUTest -d gpu -t 10000 -g 5120x1 -b ${val} --streams ${nStreams} -o 0 >> result/Grid_Size_5120/unidim/b${val}_stream${nStreams}.log
#     done
#     nStreams=$((nStreams+3))
# done

# nStreams=$((nStreams/nStreams))
# for ((i=0; i<=1; i++)); 
# do
#     for val in ${bidim[@]};
#     do
#     ./INSTALL/bin/KalmanFitterGPUTest -d gpu -t 10000 -g 100000x1 -b ${val} --streams ${nStreams} -o 0 >> result/Grid_Size_100000/bidim/b${val}_stream${nStreams}.log
#     done
#     for val in ${unidim[@]};
#     do
#     ./INSTALL/bin/KalmanFitterGPUTest -d gpu -t 10000 -g 100000x1 -b ${val} --streams ${nStreams} -o 0 >> result/Grid_Size_100000/unidim/b${val}_stream${nStreams}.log
#     done
#     nStreams=$((nStreams+3))
# done


