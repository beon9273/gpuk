import os
import xlsxwriter
from collections import defaultdict

def data_collection(f):
    data = defaultdict(lambda : defaultdict(list))
    with open(f, 'rt') as myfile:
        for l in myfile:
            if l.strip().startswith('Steps'):
                step, surface, cycle = l.strip().split('; ')
                data[int(surface)]["step"].append(int(step.split(' ')[-1]))
                data[int(surface)]["cycle"].append(int(cycle))
    return data

def write_to_csv(data):

    workbook = xlsxwriter.Workbook("step_collection.xlsx")
    worksheet = workbook.add_worksheet("statistics")
    row_pin, col_pin = 2, 2

    worksheet.write(row_pin, col_pin, 'surface')
    worksheet.write(row_pin, col_pin+1, 'step_min')
    worksheet.write(row_pin, col_pin+2, 'step_max')
    worksheet.write(row_pin, col_pin+3, 'step_avg')
    worksheet.write(row_pin, col_pin+4, 'cycle_min')
    worksheet.write(row_pin, col_pin+5, 'cycle_max')
    worksheet.write(row_pin, col_pin+6, 'cycle_avg')

    surfaces = sorted(list(data.keys()))

    for sur in surfaces:
        row_pin += 1
        worksheet.write(row_pin, col_pin, sur)
        steps = data[sur]["step"]
        cycles = data[sur]["cycle"]
        worksheet.write(row_pin, col_pin+1, min(steps))
        worksheet.write(row_pin, col_pin+2, max(steps))
        worksheet.write(row_pin, col_pin+3, sum(steps) / len(steps))
        worksheet.write(row_pin, col_pin+4, min(cycles))
        worksheet.write(row_pin, col_pin+5, max(cycles))
        worksheet.write(row_pin, col_pin+6, sum(cycles) / len(cycles))

    workbook.close()

if __name__ == '__main__':
    file_name = "surface_step_collection.log"

    surface_step_time = data_collection(file_name)
    write_to_csv(surface_step_time)
    