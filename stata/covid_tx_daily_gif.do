version 16

cscript

local start =  date("05/07/2020", "MDY")
local end = date(c(current_date), "DMY") - 1

local count = `end' - `start'

python:
import imageio as io

with io.get_writer('../output/texas.gif', mode='I', duration=0.5) as writer:
	for i in range(0, `count', 1):
		image = io.imread("../output/t"+str(i)+".png")
		writer.append_data(image)
writer.close()


end

