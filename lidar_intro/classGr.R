##########################
# This script classifies #
# ground in lidar data   #
##########################


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
rigidness <- 2L
cloth_resolution <- 0.5 # Cloth resolution (m)
class_threshold <- 0.5  # Height threshold for ground classification (m)
sloop_smooth <- TRUE    # apply slope smoothing

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
    }else if(args[i]=='-rigidness'){
      rigidness <- args[i+1]
      i <- i+1
    }else if(args[i]=='-res'){
      cloth_resolution <- args[i+1]
      i <- i+1
    }else if(args[i]=='-thresh'){
      class_threshold<- args[i+1]
      i <- i+1
    }
  }# command line parser
}


# set algorithm type. CSF is cloth simulation filter
classify_ground[['algorithm']] <- 'csf'

# set parameters
classify_ground[['params']][['rigidness']] <- c(rigidness)            # Rigidity of cloth. Choose from 1L (soft), 2L (medium) and 3L (rigid)
classify_ground[['params']][['cloth_resolution']] <- cloth_resolution # Cloth resolution (m)
classify_ground[['params']][['class_threshold']] <- class_threshold   # Height threshold for ground classification (m)
classify_ground[['params']][['sloop_smooth']] <- sloop_smooth         # Apply slope smoothing?

# load data and run
## Options for output files
tilewidth <- 0 # 0 for file by file processing, otherwise edgelength of square in las units (m )
tilebuffer <- 30 # buffer around tile in las units (m)
las <- func.load_las(file,tilewidth,tilebuffer)

# classify ground points
las <- func.classify_ground(las, classify_ground, outRoot)

print('Data written to',outRoot)

