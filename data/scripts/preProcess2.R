


# load packages
library(rgdal)
library(sp)
library(raster)


# list files
dirList <- c("/geos/netdata/key_methods/week10/ALS/res3m/DTM","/geos/netdata/key_methods/week10/ALS/res3m/DSM")

funs <- c("mean","mean")

i <- 1
for(inDir in dirList){
  fileList=list.files(path=inDir, pattern = "*.tif")

  for(filename in fileList){
    wholeName=paste(inDir,filename,sep='/')
    print(wholeName)

    # read data
    data <- raster(wholeName)

    # coarsen the resolution to get MCH
    endRes=10  # 10 m resolutio
    coarseFact=round(endRes/res(data)[1])
    coarseData <- aggregate(data, fact=coarseFact,fun=funs[i])

    # write to a new geotiff
    outName=filename
    writeRaster(coarseData,outName, format="GTiff",overwrite=TRUE)
    print(outName)
  }
  i <- i+1
}

