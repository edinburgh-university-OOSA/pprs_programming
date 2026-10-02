#######################
# This script makes a #
# DEM from classified #
# lidar data          #
#######################


# install required commands
dependencies <- c('lidR', 'RCSF', 'RMCC', 'hash', 'geometry', 'raster')
new.packages <- dependencies[!(dependencies %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)
path.split <- function(x) if (dirname(x)==x) x else c(basename(x),path.split(dirname(x)))
future::plan(future::multisession, workers = 4L)

# these scripts call lidR commands
source('/geos/netdata/pprs/lidar_intro/L2_lidar_processing/R/lidR_operations.R')
source('/geos/netdata/pprs/lidar_intro/L2_lidar_processing/R/lidR_options.R')

# defaults
file <- '/geos/netdata/pprs//lidar_intro/ALS/raw/cardington.las'
outRoot="./test"
resolution <- 1 # DEM resolution (m)

# read command line
args <- commandArgs(trailingOnly = TRUE)
if(length(args)>1){
  for(i in 1:length(args)){
    if(args[i]=='-file'){
      file <- args[i+1]
      i <- i+1
    }else if(args[i]=='-outRoot'){
      outRoot <- args[i+1]
      i <- i+1
    }else if(args[i]=='-res'){
      resolution <- args[i+1]
      i <- i+1
    }
  }# command line parser
}

# settings
create_dtm[['algorithm']] <- 'tin'
create_dtm[['res']] <- as.numeric(resolution) # Pixel width (m)
create_dtm[['params']][['k']] <- 10L # k-nearest neighbours
create_dtm[['params']][['rmax']] <- 5 # Search radius (m, ignored by 'kriging')

create_chm[['algorithm']] <- 'dsmtin'
create_chm[['res']] <- as.numeric(resolution) ## CHM resolution (m)
create_chm[['params']][['max_edge']]  <- 10
create_chm[['params']][['highest']]  <- TRUE

# load data and run
## Options for output files
tilewidth <- 0 # 0 for file by file processing, otherwise edgelength of square in las units (m )
tilebuffer <- 30 # buffer around tile in las units (m)
las <- func.load_las(file,tilewidth,tilebuffer)

# make DTM and DSM
dtm <- func.create_dtm(las, create_dtm, outRoot)
dsm <- func.create_chm(las, create_chm, outRoot)

