# Introduction to lidar

This practical demonstrates processing lidar data to make a DTM and DSM. It has two scripts:

* classGr.R - classifies ground in a point cloud
* makeDEM.R - produces a DTM and DSM from a classified point cloud


## Ground classification

Run the following command:

    Rscript classGr.R

It has the following options:

    -file name     Input lidar filename
    -outRoot name  Output filename root, including directory
    -rigidness x   Rigidness parameter for cloth simulation. 1L, 2L or 3L
    -res x         Cloth resolution in same units as lidar data
    -thresh x      Cloth threshold in same units as lidar data

It will output a new lidar file starting with outRoot, defined above. All values above have defaults.

## DTM generation

Run the following command to produce a DTM and a DSM. Note that the DSM will have "chm" in the filename, but it is a DSM.

    Rscript makeDEM.R

It has the following options:

    -file name     Input lidar filename
    -outRoot name  Output filename root, including directory
    -res x         DTM resolution in same units as lidar data

