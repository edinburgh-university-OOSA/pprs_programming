# Principles and Practices of Remote Sensing

Code for the Principles and Practices of Remote Sensing MSc course. This is an introduction to python and then uses Python to batch process lidar data to make a biomass map.

There are two jupyter notebooks

* python\_foundations.ipynb
* batch\_process.ipynb


## python\_foundations.ipynb

Gives a brief overview of a few aspects of python.



## batch\_process.ipynb

Provides some pre-written functions which can be used to process lidar data to make biomass. The notebook takes students through how to modify the code to batch process a large area and visualise the data.



## Pre-process data

There is insufficient space on Noteable to store the full-res geotiffs. So we shapp coarsen them to 10 m resolution first. The mean elevation for the DTM and the maximum elevation for the DSM. This uses an Rscript:

In

    /geos/netdata/key_methods/week10/ALS/res3m



Move the DTMs and DSMs to a subdirectory with that name.

Run
    Rscript /home/shancoc2/teaching/key_methods/2020-21/week10/code/data/scripts/preProcess1.R
    /home/shancoc2/teaching/key_methods/2020-21/week10/code/data/scripts/rename1.csh

And then in
    /geos/netdata/key_methods/week10/ALS/res10m

Run
    Rscript /home/shancoc2/teaching/key_methods/2020-21/week10/code/data/scripts/preProcess2.R
    /home/shancoc2/teaching/key_methods/2020-21/week10/code/data/scripts/rename2.csh

