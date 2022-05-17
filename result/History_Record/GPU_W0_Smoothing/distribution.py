import matplotlib.pyplot as plt

def data_extraction(f):
    steps, time_cycle = [], []
    step = []
    flag = False
    cycle_target = 0
    with open(f, 'rt') as myfile:
        for l in myfile:
            if l.strip().startswith("INFO: Time (ms)"):
                flag = (flag == False)
            elif flag:
                s, cycle = l.strip().split(", ")
                s, cycle = int(s), int(cycle)
                if cycle < 0:
                    # cycle = cycle - (-2**63) + 2**63
                    continue
                if cycle == cycle_target:
                    step.append(s)
                else:
                    time_cycle.append(cycle)
                    if len(step) > 0:
                        steps.append(sum(step) / len(step))
                    step = [s]
                    cycle_target = cycle
    
    steps.append(sum(step) / len(step))
    return steps, time_cycle

def hist_plotting(steps, time_cycle, num_track):
    fig, ax = plt.subplots(1, 1)
    ax.hist(steps, bins=20, label="RK4 Steps per warp")
    ax.set_title("num of steps in RK4 with " + str(num_track) + " tracks")
    ax.legend(loc='upper right', prop={'size':10})
    ax.set_xlabel("steps", fontsize=20)
    ax.set_ylabel("num of warps", fontsize=20)

    fig.savefig("Step_Distribution_" + str(num_track) + "Tracks.pdf")
    plt.close(fig)

    fig, ax = plt.subplots(1, 1)
    ax.hist(time_cycle, bins=20, label="RK4 time cycles per warp")
    ax.set_title("time cycles in RK4 with " + str(num_track) + " tracks")
    ax.legend(loc='upper right', prop={'size':10})
    ax.set_xlabel("time cycles", fontsize=20)
    ax.set_ylabel("num of warps", fontsize=20)

    fig.savefig("Cycle_Distribution_" + str(num_track) + "Tracks.pdf")
    plt.close(fig)


if __name__ == '__main__':

    num_track = 10
    for i in range(5):
        file_name = "Track" + str(num_track) + ".log"
        steps, time_cycle = data_extraction(file_name)
        hist_plotting(steps, time_cycle, num_track)
        num_track *= 10

