########################################################################################
## Classify ground and write to .las
########################################################################################
# classify_ground(las, algorithm, last_returns = TRUE)
#     las: An object of class LAS or LAScatalog.
#     algorithm: An algorithm for classification. lidR has has pmf, csf, mcc for ground classification.
#     last_returns: logical. The algorithm will use only the last returns (including the first returns in cases of a single return) to run the algorithm. If FALSE all the returns are used. If the attributes 'ReturnNumber' or 'NumberOfReturns' are absent, 'last_returns' is turned to FALSE automatically.
#     class: The ASPRS class to attribute to the points that meet the criterion.
#     poi: a formula of logical predicates. The points that are TRUE will be classified class.
#     roi: A SpatialPolygons*, from sp or a sf/sfc_POLYGON from sf. The points that are in the region of interest delimited by the polygon(s) are classified class.
#     inverse_roi: bool. Inverses the roi. The points that are outside the polygon(s) are classified class.
#     by_reference bool. Updates the classification in place (LAS only).
#     Ground classification algorithms:
#         csf:
#             sloop_smooth: logical. When steep slopes exist, set this parameter to TRUE to reduce errors during post-processing.
#             class_threshold: scalar. The distance to the simulated cloth to classify a point cloud into ground and non-ground. The default is 0.5.
#             cloth_resolution: scalar. The distance between particles in the cloth. This is usually set to the
#             average: distance of the points in the point cloud. The default value is 0.5.
#             rigidness: integer. The rigidness of the cloth. 1 stands for very soft (to fit rugged terrain), 2 stands for medium, and 3 stands for hard cloth (for flat terrain). The default is 1.
#             iterations: integer. Maximum iterations for simulating cloth. The default value is 500. Usually, there is no need to change this value.
#             time_step: scalar. Time step when simulating the cloth under gravity. The default value is 0.65. Usually, there is no need to change this value. It is suitable for most cases.
#         mcc:
#             s: numeric. Scale parameter. The optimal scale parameter is a function of 1) the scale of the objects (e.g., trees) on the ground, and 2) the sampling interval (post spacing) of the lidar data.
#             t: numeric. Curvature threshold
#         pmf:
#             ws: numeric. Sequence of windows sizes to be used in filtering ground returns. The values must be positive and in the same units as the point cloud (usually meters, occasionally feet).
#             th: numeric. Sequence of threshold heights above the parameterized ground surface to be considered a ground return. The values must be positive and in the same units as the point cloud.
#             b: numeric. This is the parameter b in Zhang et al. (2003) (eq. 4 and 5).
#             dh0: numeric. This is dh0 in Zhang et al. (2003) (eq. 7).
#             dhmax: numeric. This is dhmax in Zhang et al. (2003) (eq. 7).
#             s: numeric. This is s in Zhang et al. (2003) (eq. 7).
#             max_ws: numeric. Maximum window size to be used in filtering ground returns. This
#             limits: the number of windows created.
#             exp: logical. The window size can be increased linearly or exponentially (eq. 4 or 5).

## Define ground classification options
classify_ground <- hash::hash()
classify_ground[['algorithm']] <- 'csf'
classify_ground[['last_returns']] <- TRUE

if (classify_ground[['algorithm']]=='csf') {
    classify_ground[['params']] <- hash::hash()
    classify_ground[['params']][['sloop_smooth']] <- TRUE#FALSE
    classify_ground[['params']][['class_threshold']] <- 0.05 # 0.5
    classify_ground[['params']][['cloth_resolution']] <- 0.05 # 0.5
    classify_ground[['params']][['rigidness']] <- 3L #1L
    classify_ground[['params']][['iterations']] <- 500L
    classify_ground[['params']][['time_step']] <- 0.65
} else if (classify_ground[['algorithm']]=='mcc') {
    classify_ground[['params']] <- hash::hash()
    classify_ground[['params']][['s']] <- 1/sqrt(density.pulse)
    classify_ground[['params']][['t']] <- 0.3
} else if (classify_ground[['algorithm']]=='pmf') {
    classify_ground[['params']] <- hash::hash()
    classify_ground[['params']][['ws']] = seq(3,12, 3)
    classify_ground[['params']][['th']] = seq(0.1, 1.5, length.out=4)
    classify_ground[['params']][['b']] = 2
    classify_ground[['params']][['dh0']] = 0.5
    classify_ground[['params']][['dhmax']] = 3
    classify_ground[['params']][['s']] = 1
    classify_ground[['params']][['max_ws']] = 20
    classify_ground[['params']][['exp']] = FALSE
} else {
    print('Unknown ground classification algorithm')
}

########################################################################################
## Generate DTM
########################################################################################
# rasterize_terrain(las, res = 1, algorithm = tin(), use_class = c(2L, 9L), shape = 'convex',)
#     las: An object of class LAS or LAScatalog.
#     algorithm: function. A function that implements an algorithm to compute a digital terrain model. lidR implements tin, and kriging for digital terrain models.
#     res: numeric. The size of a grid cell in point cloud coordinates units. Can also be RasterLayer or a stars or a SpatRaster used as layout.
#     pkg: str. Use "terra|raster|stars" to get an output in SpatRaster, RasterLayer or stars format. Default is getOption("lidR.raster.default").
#     use_class: integer vector. By default the terrain is computed by using ground points (class 2) and water points (class 9).
#     shape: y default the interpolation is made only within the 'convex' hull of the point cloud to get a DTM with the shape of the point cloud. This prevents meaningless interpolations where there is no data. It can also be 'concave' or 'bbox'. It can also be an sfc to define a polygon in which to perform the interpolation.
#     DTM algorithms:
#         knnidw(k = 10, p = 2, rmax = 50)
#             k: integer. Number of k-nearest neighbours. Default 10.
#             p: numeric. Power for inverse-distance weighting. Default 2.
#             rmax: numeric. Maximum radius where to search for knn. Default 50.
#         kriging(model = gstat::vgm(0.59, "Sph", 874), k = 10L)
#             model: A variogram model computed with vgm() from package gstat. If NULL it performs an ordinary or weighted least squares prediction.
#             k: numeric. Number of k-nearest neighbours. Default 10.
#         tin(extrapolate = knnidw(3, 1, 50))
#             extrapolate: There are usually a few points outside the convex hull, determined by the ground points at the very edge of the dataset, that cannot be interpolated with a triangulation. Extrapolation is done using knnidw by default.

## Define DTM generation options
create_dtm <- hash::hash()
create_dtm[['algorithm']] <- 'tin'
create_dtm[['res']] <- 1
create_dtm[['use_class']] <- c(2L, 9L)
create_dtm[['shape']] <- 'convex'

if (create_dtm[['algorithm']]=='knnidw') {
    create_dtm[['params']] <- hash::hash()
    create_dtm[['params']][['k']] <- 10L
    create_dtm[['params']][['p']] <- 2
    create_dtm[['params']][['rmax']] <- 50
} else if (create_dtm[['algorithm']]=='kriging') {
    create_dtm[['params']] <- hash::hash()
    create_dtm[['params']][['model']] <- gstat::vgm(0.59, "Sph", 874)
    create_dtm[['params']][['k']] <- 10L
} else if (create_dtm[['algorithm']]=='tin') {
    create_dtm[['params']] <- hash::hash()
    create_dtm[['params']][['k']] <- 10L
    create_dtm[['params']][['p']] <- 2
    create_dtm[['params']][['rmax']] <- 50
} else {
    print('Unknown DTM creation algorithm')
}

########################################################################################
## Create normalised pointcloud
########################################################################################

# DTM normalisation:
#     nlas <- las - dtm
# Point cloud normalisation:
#     normalize_height(las, algorithm, use_class = c(2L, 9L), dtm = NULL, ...)
#         las: An object of class LAS or LAScatalog.
#         algorithm: (1) An algorithm for spatial interpolation. lidR has tin, kriging, knnidw or a raster representing a digital terrain model. (2) An algorithm for intensity normalization. lidR currently has range_correction.
#         use_class: integer vector. By default the terrain is computed by using ground points (class 2) and water points (class 9). Relevant only for a normalization without a raster DTM.
#         dtm: raster. If dtm is provided, then the DTM is used in place of ground points. This is different than providing a DTM in algorithm. If algorithm = dtm the dtm is subtracted naively. If algorithm = tin() and dtm = raster the ground points are not used and the DTM is interpolated as if it were made of regularly-spaced ground points.
#         add_lasattribute: bool. TRUE to add the elevation above see level as an extra byte attribute
#         Wdegenerated: bool. FALSE to silence the warning about degenerated ground points.

## Define height normalization options
normalize_las <- hash::hash()
normalize_las[['algorithm']] <- 'dtm'
normalize_las[['use_class']] <- c(2L, 9L)
normalize_las[['add_lasattribute']] <- FALSE
normalize_las[['Wdegenerated']] <- TRUE

if (normalize_las[['algorithm']]=='knnidw') {
    normalize_las[['params']] <- hash::hash()
    normalize_las[['params']][['k']] <- 10L
    normalize_las[['params']][['p']] <- 2
    normalize_las[['params']][['rmax']] <- 50
} else if (normalize_las[['algorithm']]=='kriging') {
    normalize_las[['params']] <- hash::hash()
    normalize_las[['params']][['model']] <- gstat::vgm(0.59, "Sph", 874)
    normalize_las[['params']][['k']] <- 10L
} else if (normalize_las[['algorithm']]=='tin') {
    normalize_las[['params']] <- hash::hash()
    normalize_las[['params']][['extrapolate']] <- lidR::knnidw(10L, 1, 50)
} else if (normalize_las[['algorithm']]=='dtm') {
    normalize_las[['params']] <- hash::hash()
} else {
    print('Unknown pointcloud normalization algorithm')
}

########################################################################################
## Create CHMs
########################################################################################
# rasterize_canopy(las, res = 1, algorithm = p2r())
#     algorithm: function. A function that implements an algorithm to compute a digital surface model. lidR implements p2r, dsmtin, pitfree for digital surface models.
#     pkg: str. Use "terra|raster|stars" to get an output in SpatRaster, RasterLayer or stars format. Default is getOption("lidR.raster.default").
#     use_class: integer vector. Point class to use in computation.
#     shape: By default the interpolation is made only within the "convex" hull of the point cloud to get a DTM with the shape of the point cloud. This prevents meaningless interpolations where there is no data. It can also be "concave" or "bbox". It can also be an sfc to define a polygon in which to perform the interpolation.
#     DSM algorithms:
#         dsmtin(max_edge = 0, highest = TRUE)
#             max_edge: numeric. Maximum edge length of a triangle in the Delaunay triangulation. If a triangle has an edge length greater than this value it will be removed to trim dummy interpolation on non-convex areas. If max_edge = 0 no trimming is done (see examples).
#             highest: bool. By default it keeps only the highest point per pixel before to triangulate to decrease computation time. If highest = FALSE all first returns are used.
#         pitfree(thresholds = c(0, 2, 5, 10, 15), max_edge = c(0, 1), subcircle = 0, highest = TRUE)
#             thresholds: numeric. Set of height thresholds according to the Khosravipour et al. (2014) algorithm description (see references)
#             max_edge: numeric. Maximum edge length of a triangle in the Delaunay triangulation. If a triangle has an edge length greater than this value it will be removed. The first number is the value for the classical triangulation (threshold = 0, see also dsmtin), the second number is the value for the pit-free algorithm (for thresholds > 0). If max_edge = 0 no trimming is done (see examples).
#             subcircle: numeric. radius of the circles. To obtain fewer empty pixels the algorithm can replace each return with a circle composed of 8 points (see details).
#             highest: bool. By default it keeps only the highest point per pixel before to triangulate to decrease computation time. If highest = FALSE all first returns are used.    
#         p2r(subcircle = 0, na.fill = NULL)
#             subcircle: numeric. Radius of the circles. To obtain fewer empty pixels the algorithm can replace each return with a circle composed of 8 points (see details).
#             na.fill: function. A function that implements an algorithm to compute spatial interpolation to fill the empty pixel often left by points-to-raster methods. lidR has knnidw, tin, and kriging. Default NULL.

## Define CHM generation options
create_chm <- hash::hash()
create_chm[['algorithm']] = 'p2r'
create_chm[['res']] = 1
create_chm[['shape']] = 'convex'

if (create_chm[['algorithm']]=='dsmtin') {
    create_chm[['params']] <- hash::hash()
    create_chm[['params']][['max_edge']] = 0
    create_chm[['params']][['highest']] = TRUE
} else if (create_chm[['algorithm']]=='pitfree') {
    create_chm[['params']] <- hash::hash()
    create_chm[['params']][['thresholds']] = c(0, 2, 5, 10, 15)
    create_chm[['params']][['max_edge']] = c(0, 1)
    create_chm[['params']][['subcircle']] = 0
    create_chm[['params']][['highest']] = TRUE
} else if (create_chm[['algorithm']]=='p2r') {
    create_chm[['params']] <- hash::hash()
    create_chm[['params']][['subcircle']] = 0
} else {
    print('Unknown CHM creation algorithm')
}

########################################################################################
## Decimate pointcloud
########################################################################################
# Reduce the number of points to specified point density (other algorithms are available but not yet implemented)

decimate <- hash::hash()
decimate[['density']] <- 100 # Points per meter squared

########################################################################################
## Write point density raster
########################################################################################

# rasterize_density(las, res = 1, ...)
#     res: numeric. The size of a grid cell in point cloud coordinates units. Can also be RasterLayer or a stars or a SpatRaster used as layout
#     shape: By default the interpolation is made only within the "convex" hull of the point cloud to get a DTM with the shape of the point cloud. This prevents meaningless interpolations where there is no data. It can also be "concave" or "bbox". It can also be an sfc to define a polygon in which to perform the interpolation.
calc_density <- hash::hash()
calc_density[['res']] = 1
calc_density[['shape']] = 'convex'

########################################################################################
## Locate individual trees
########################################################################################
# locate_trees(las, algorithm, uniqueness = "incremental")
#     las: An object of class LAS or LAScatalog. Can also be a raster from raster, stars or terra representing a canopy height model, in which case it is processed like a regularly-spaced point cloud.
#     algorithm: An algorithm for individual tree detection. lidR has: lmf and manual. More experimental algorithms may be found in the package lidRplugins.
#     uniqueness: character. A method to compute a unique ID. Can be ’incremental’, ’gpstime’ or ’bitmerge’. See section ’Uniqueness’. This feature must be considered as ’experimental’.
# Tree location algorithms:
#     lmf(ws, hmin = 2, shape = c("circular", "square"), ws_args = "Z")
#         ws: numeric or function. Length or diameter of the moving window used to detect the local maxima in the units of the input data (usually meters). If it is numeric a fixed window size is used. If it is a function, the function determines the size of the window at any given location on the canopy. By default function takes the height of a given pixel or point as its only argument and return the desired size of the search window when centered on that pixel/point. This can be controled with the ‘ws_args‘ parameter
#         hmin: numeric. Minimum height of a tree. Threshold below which a pixel or a point cannot be a local maxima. Default is 2.
#         shape: character. Shape of the moving window used to find the local maxima. Can be "square" or "circular".
#         ws_args: list. Named list of argument for the function ‘ws‘ if ‘ws‘ is a function.

## Locate individual trees
tree_loc <- hash::hash()
tree_loc[['algorithm']] <- 'lmf'
tree_loc[['uniqueness']] <- 'incremental'

if (tree_loc[['algorithm']] == 'lmf') {
    tree_loc[['params']] <- hash::hash()
    tree_loc[['params']][['ws']] <- 5
    tree_loc[['params']][['hmin']] <- 2
    tree_loc[['params']][['shape']] <- c("circular", "square")
    tree_loc[['params']][['ws_args']] <- "Z"
} else {
    print('Unknown tree location algorithm')
}

########################################################################################
## Calculate pixel & profile metrics
########################################################################################
calc_metric <- hash::hash()
calc_metric[['metrics']] <- c('PAI', 'canopy_cover', 'ENL', 'entropy', 'gap_fraction', 'PAD', 'RH_metrics', 'rumple_index')
calc_metric[['res']] <- 5
calc_metric[['dz']] <- 1
calc_metric[['zmin']] <- 2
