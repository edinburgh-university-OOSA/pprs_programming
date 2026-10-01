dependencies <- c('lidR', 'RCSF', 'RMCC', 'hash', 'geometry', 'raster')
new.packages <- dependencies[!(dependencies %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)
path.split <- function(x) if (dirname(x)==x) x else c(basename(x),path.split(dirname(x)))
future::plan(future::multisession, workers = 4L)


source('/geos/netdata/pprs/lidar_intro/L2_lidar_processing/R/lidR_operations.R')
source('/geos/netdata/pprs/lidar_intro/L2_lidar_processing/R/lidR_options.R')

file <- list()
out <- list()
tile <- list()

file <- '/home/shancoc2/data_teaching/pprs/lidar_intro/ALS/raw/cardington.las'

print(file)


# set algorithm type. CSF is cloth simulation filter
classify_ground[['algorithm']] <- 'csf'

# set parameters
classify_ground[['params']][['rigidness']] <- 2L # Rigidity of cloth. Choose from 1L (soft), 2L (medium) and 3L (rigid)
classify_ground[['params']][['cloth_resolution']] <- 0.5 # Cloth resolution (m)
classify_ground[['params']][['class_threshold']] <- 0.5 # Height threshold for ground classification (m)
classify_ground[['params']][['sloop_smooth']] <- TRUE # Apply slope smoothing?


## Options for Point density rasterisation
#calc_density[['res']] <- 1 # Pixel width (m)


# load data and run
## Options for output files
tile$width <- 0 # 0 for file by file processing, otherwise edgelength of square in las units (m )
tile$buffer <- 30 # buffer around tile in las units (m)
las <- func.load_las(file,tile$width,tile$buffer)

# classify ground points
outRoot="./test"
las <- func.classify_ground(las, classify_ground, outRoot)

print('Data written to',outRoot)
