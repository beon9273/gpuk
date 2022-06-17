import xlsxwriter
from collections import defaultdict

def data_extraction(f):
    step_info = defaultdict(lambda: defaultdict(lambda: defaultdict(lambda: defaultdict(str)))) # Track id->Surface id->Step id->step info
    kalman_info = defaultdict(lambda: defaultdict(lambda: defaultdict(str))) # Track id->Surface id->covariance, smoothed

    data_recording_flag = False
    track_id, surface_id, step_id = "", "", ""

    with open(f, 'rt') as myfile:
        for l in myfile:
            if l.strip().startswith("INFO: Time (ms) to run simulation"): data_recording_flag = True
            elif data_recording_flag:
                line = l.strip()
                if len(line) <= 0: continue
                if line.startswith("track id"):
                    track_id = "track_" + str(int(line.split(' ')[-1]))
                elif line.startswith("surface id"):
                    surface_id = "surface_" + str(int(line.split(' ')[-1]))
                elif line.startswith("step id"):
                    step_id = "step_" + str(int(line.split(' ')[-1]))
                elif line.startswith("state pos"):
                    step_info[track_id][surface_id][step_id]["Pos"] = line.split(": (")[-1].replace(')', '')
                elif line.startswith("state dir"):
                    step_info[track_id][surface_id][step_id]["Dir"] = line.split(": (")[-1].replace(')', '')
                elif line.startswith("state momentum"):
                    step_info[track_id][surface_id][step_id]["Momentum"] = line.split(": ")[-1]
                elif line.startswith("state charge"):
                    step_info[track_id][surface_id][step_id]["Charge"] = line.split(": ")[-1]
                elif line.startswith("state num of stepTrails"):
                    step_info[track_id][surface_id][step_id]["Trials"] = line.split(": ")[-1]
                elif line.startswith("smoothed value"):
                    kalman_info[track_id][surface_id]["smoothed_val"] = line.split(": ")[-1]
                elif line.startswith("cov"):
                    key = line.split('] ')[0].replace('[', '-').replace(', ', '_')
                    kalman_info[track_id][surface_id][key] = line.split(": ")[-1]
    return step_info, kalman_info

def write_to_csv(step_info, kalman_info, file_name, num_surf=11):

    workbook = xlsxwriter.Workbook(file_name)
    worksheet = workbook.add_worksheet("data")

    merge_format = workbook.add_format({'align':'center', 'valign':'vcenter',})
    write_format = workbook.add_format({'align':'center', 'valign':'vcenter',})

    track_row, track_col = 2, 2
    sur_row, sur_col = track_row, track_col + 1
    step_row, step_col = sur_row, sur_col + 1

    worksheet.write(track_row, track_col, "Track ID", write_format)
    worksheet.write(sur_row, sur_col, "Surface ID", write_format)
    worksheet.write(step_row, step_col, "Step ID", write_format)

    track_row, track_col = track_row + 1, track_col
    sur_row, sur_col = track_row, track_col + 1
    step_row, step_col = sur_row, sur_col + 1

    title_step_print = True
    title_kalman_print = True

    track_sorted = sorted(list(step_info.keys()), key=lambda x: int(x.split('_')[-1]))
    for track_id in track_sorted:
        surf_sorted = sorted(list(step_info[track_id].keys()), key=lambda x: int(x.split('_')[-1]))
        while len(surf_sorted) > num_surf:
            surf_sorted.pop()
        for surf_id in surf_sorted:
            step_sorted = sorted(list(step_info[track_id][surf_id].keys()), key=lambda x: int(x.split('_')[-1]))
            step_col_pin = step_col
            for step_id in step_sorted:
                step_col = step_col_pin
                worksheet.write(step_row, step_col, int(step_id.split('_')[-1]), write_format)
                step_col += 1
                features = sorted(list(step_info[track_id][surf_id][step_id].keys()))
                for feature in features:
                    if title_step_print:
                        worksheet.write(step_row-1, step_col, feature, write_format)
                    worksheet.write(step_row, step_col, step_info[track_id][surf_id][step_id][feature], write_format)
                    step_col += 1
                step_row += 1
                title_step_print = False
            if step_row-1 - sur_row >= 1:
                worksheet.merge_range(sur_row, sur_col, step_row-1, sur_col, int(surf_id.split('_')[-1]), merge_format)
            else:
                worksheet.write(sur_row, sur_col, int(surf_id.split('_')[-1]), write_format)
            
            kalman_feats = sorted(list(kalman_info[track_id][surf_id].keys()))
            for kalman_feat in kalman_feats:
                if title_kalman_print:
                    worksheet.write(sur_row - 1, step_col, kalman_feat, write_format)
                if step_row-1-sur_row >= 1:
                    worksheet.merge_range(sur_row, step_col, step_row-1, step_col, kalman_info[track_id][surf_id][kalman_feat], merge_format)
                else:
                    worksheet.write(step_row-1, step_col, kalman_info[track_id][surf_id][kalman_feat], write_format)
                step_col += 1
            title_kalman_print = False
            sur_row = step_row
            step_col = sur_col + 1
        if sur_row-1-track_row >= 1:
            worksheet.merge_range(track_row, track_col, sur_row-1, track_col, int(track_id.split('_')[-1]), merge_format)
        else:
            worksheet.write(track_row, track_col, int(track_id.split('_')[-1]), write_format)
        track_row = sur_row
    workbook.close()
    return

if __name__ == "__main__":
    file_name = "track1000_smoothing.log"
    step_info, kalman_info = data_extraction(file_name)
    write_to_csv(step_info, kalman_info, "step_kalman_info_smoothing.xlsx")