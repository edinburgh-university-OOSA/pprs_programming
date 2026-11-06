########################################################################################
## Function to read in las files and process
########################################################################################

## !!!
## Test different file formats
## !!!

func.load_las = function(file.las, tile.width, tile.buffer, out.raster='.tif', out.vector='.geojson') {
    print('Loading files')
    ## Read in LAS file & print header
    las <- lidR::readLAScatalog(file.las,
        chunk_size = tile.width,
        chunk_buffer = tile.buffer)
    print(las)
    
    lidR::opt_progress(las) <- TRUE
    las@output_options$drivers$raster$extension <- out.raster
    las@output_options$drivers$raster$param$overwrite <- TRUE
    las@output_options$drivers$terra$extension <- out.raster
    las@output_options$drivers$terra$param$overwrite <- TRUE
    las@output_options$drivers$stars$extension <- out.raster
    las@output_options$drivers$stars$param$overwrite <- TRUE
    las@output_options$drivers$Spatial$extension <- out.vector
    las@output_options$drivers$Spatial$param$overwrite <- TRUE
    las@output_options$drivers$sf$extension <- out.vector
    las@output_options$drivers$sf$param$overwrite <- TRUE
        
    ## Check LAS file for corruption, point duplication etc.
    # if (class(las)=='LAS') {
    #     lidR::las_check(las, print=FALSE, deep=FALSE)
    # } else if (class(las)=='LAScatalog') {
    #     lidR::las_check(las, print=FALSE, deep=TRUE)
    # } else {
    #     print('Data not of type LAS')    
    # }
    return (las)
}

########################################################################################
## Decimation function
########################################################################################

func.decimate = function(las, decimate, out.root, tile.buffer) {
    print('Decimating pointcloud')
    lidR::opt_output_files(las) <- paste(out.root,'decimated', '{XLEFT}', '{YBOTTOM}', sep='_')
    las <- lidR::decimate_points(las, lidR::random(decimate[['density']]))
    lidR::opt_chunk_buffer(las) <- tile.buffer
    return (las)
}

########################################################################################
## Ground classification function
########################################################################################
func.classify_ground = function(las, classify_ground, out.root) {
    print('Running ground classification')
    print(classify_ground)
    lidR::opt_output_files(las) <- paste(out.root,'classified', classify_ground[['algorithm']], '{XLEFT}', '{YBOTTOM}', sep='_')
    ## Run ground classification
    if (classify_ground[['algorithm']] == 'csf') {
        las <- lidR::classify_ground(las,
            algorithm = lidR::csf(
                sloop_smooth = classify_ground[['params']][['sloop_smooth']],
                class_threshold = classify_ground[['params']][['class_threshold']],
                cloth_resolution = classify_ground[['params']][['cloth_resolution']],
                rigidness = classify_ground[['params']][['rigidness']],
                iterations = classify_ground[['params']][['iterations']],
                time_step = classify_ground[['params']][['time_step']]
            ),
            last_returns = classify_ground[['last_returns']]
        )
    } else if (classify_ground[['algorithm']]=='mcc') {
        las <- lidR::classify_ground(las,
            algorithm = lidR::mcc(
                s = classify_ground[['params']][['s']],
                t = classify_ground[['params']][['t']]
            ),
            last_returns = classify_ground[['last_returns']]
        )
    } else if (classify_ground[['algorithm']]=='pmf') {
        lidR::util_makeZhangParam(
                b = classify_ground[['params']][['b']],
                dh0 = classify_ground[['params']][['dh0']],
                dhmax = classify_ground[['params']][['dhmax']],
                s = classify_ground[['params']][['s']],
                max_ws = classify_ground[['params']][['max_ws']],
                exp = classify_ground[['params']][['exp']]
            )
        las <- lidR::classify_ground(las,
            algorithm = lidR::pmf(
                classify_ground[['params']][['ws']],
                classify_ground[['params']][['th']]
            ),
            last_returns = classify_ground[['last_returns']]
        )
    } else {
        print('Unknown ground classification algorithm!')
    }
    return (las)
}

########################################################################################
## DTM generation function
########################################################################################
func.create_dtm = function(las, create_dtm, out.root) {
    print('Creating DTM')
    print(create_dtm)
    lidR::opt_output_files(las) <- ""
    ## Run DTM creation
    if (create_dtm[['algorithm']]=='knnidw') {
        dtm <- lidR::rasterize_terrain(las,
            algorithm = lidR::knnidw(
                k = create_dtm[['params']][['k']],
                p = create_dtm[['params']][['p']],
                rmax = create_dtm[['params']][['rmax']]
            ),
            res = create_dtm[['res']],
            use_class = create_dtm[['use_class']],
            shape = create_dtm[['shape']],
            pkg = 'raster'
        )
    } else if (create_dtm[['algorithm']]=='kriging') {
        dtm <- lidR::rasterize_terrain(las,
            algorithm = lidR::kriging(
                model = create_dtm[['params']][['model']],
                k = create_dtm[['params']][['k']]
            ),
            res = create_dtm[['res']],
            use_class = create_dtm[['use_class']],
            shape = create_dtm[['shape']],
            pkg = 'raster'
        )
    } else if (create_dtm[['algorithm']]=='tin') {
        alg <- lidR::tin(
                #extrapolate = create_dtm[['params']][['extrapolate']]
        )
        dtm <- lidR::rasterize_terrain(las,
            algorithm = alg,
            res = create_dtm[['res']],
            use_class = create_dtm[['use_class']],
            shape = create_dtm[['shape']],
            pkg = 'raster'
        )
    } else {
        print('Unknown DTM creation algorithm')
    }
    if (!is.null(out.root)) {
        file.dtm <- paste(out.root,'dtm.tif',sep='_')
        terra::writeRaster(dtm, file.dtm, overwrite=TRUE)
        return (dtm)
    } else {
        return (dtm)
    }
}

########################################################################################
## Reprojection function (using PDAL)
########################################################################################
func.json = function(las.in, las.out, epsg.in, epsg.out) {
        input <- gsub('\\\\', '/', las.in)
        output <- gsub('\\\\', '/', las.out)
        f <- sprintf(
'[
    "%s",
    {
        "type":"filters.reprojection",
        "in_srs":"EPSG:%s",
        "out_srs":"EPSG:%s"
    },
    "%s"
]',
                     input, epsg.in, epsg.out, output)
        return (f)
    }

func.reproject = function(file.las, epsg.in, epsg.out, tile) {
    ## Check coordinate reference systems
    epsg <- list()
    if (epsg.in == 0) {
        epsg.in <- readline("Can't read EPSG code from measurement file. Measurement EPSG code = EPSG:") 
    } else {
        epsg.in <- las$CRS
    }
    
    if (epsg.out == 0) {
        epsg.out <- readline("Can't read EPSG code for output. Reference EPSG code = EPSG:") 
    } else {
        epsg.out <- ref$CRS
    }
    ## Reproject so files in same projection
    file.las.ext <- tools::file_ext(file.las)
    file.reproj <- sub(paste0('.',file.las.ext,'$'), paste0("_reproj.",file.las.ext), file.las)
    file.reproj.json <- 'reproj.json'
    json <- func.json(file.las, file.reproj, epsg.in, epsg.out)
    print(json)
    write(json,
        file = file.reproj.json,
        ncolumns = 1,
        append = FALSE, sep = " ")
    pdal.command <- sprintf('pdal pipeline %s', file.reproj.json)
    print(pdal.command)
    system(pdal.command)
    las <- func.load_las(file.reproj, tile$width, tile$buffer)
    return (las)
}

########################################################################################
## Function for alignment with reference pointcloud
########################################################################################
func.align_las = function(las, ref, tile) {
    ## Prepare for iterative fitting
    res = c(8, 4, 2, 1)
    dtm <- list()
    dtm$dx <- 0
    dtm$dy <- 0
    dtm$dz <- NULL

    ## Rasterise at progressively finer resolution, minimising error for each resolution
    for (resi in res) {
        print(sprintf('Aligning %sm rasters', resi))
        create_dtm[['res']] <- resi
        use_class <- create_dtm[['use_class']]
        create_dtm[['use_class']] <- c(0L, 1L, 2L, 9L)
        dtm$las <- func.create_dtm(las, create_dtm, NULL)
        create_dtm[['use_class']] <- use_class
        dtm$ref <- func.create_dtm(ref, create_dtm, NULL)
        if (is.null(dtm$dz)) {
            difference =  raster::crop(dtm$ref, dtm$las) - raster::crop(dtm$las, dtm$ref)
            dtm$dz <- raster::cellStats(difference, stat='mean', na.rm=TRUE)
        }
        dx.vec = seq(-5.0, 5.0, 1.0) * create_dtm[['res']] + dtm$dx
        dy.vec = seq(-5.0, 5.0, 1.0) * create_dtm[['res']] + dtm$dy
        df = data.frame()
        err = 1000000
        for (dxi in dx.vec) {
            for (dyi in dy.vec) {
                shifted = raster::shift(dtm$las+dtm$dz, dx=dxi, dy=dyi)
                erri = func.dtm.mae(shifted, dtm$ref)
                if (erri < err) {
                    dtm$dx <- dxi
                    dtm$dy <- dyi
                }
            }
        }
        shifted = raster::shift(dtm$las, dx=dtm$dx, dy=dtm$dy)
        difference =  raster::crop(dtm$ref, shifted) - raster::crop(shifted, dtm$ref)
        dtm$dz <- raster::cellStats(difference, stat='mean', na.rm=TRUE)
    }
    
    ## Print shift required
    print(sprintf('XYZ shift needed: %s, %s, %s', dtm$dx, dtm$dy, dtm$dz))
    
    ## !!!
    ## Need to add shift application
    ## !!!

    return (las)
}

########################################################################################
## Height normalisation function
########################################################################################
func.normalize_las = function(las, normalize_las, out.root) {
    print('Creating normalised pointcloud')
    print(normalize_las)
    lidR::opt_output_files(las) <- paste(out.root,'normalized', normalize_las[['algorithm']], '{XLEFT}', '{YBOTTOM}', sep='_')
    ## Run height normalisation
    if (normalize_las[['algorithm']]=='knnidw') {
        nlas <- lidR::normalize_height(las,
            algorithm = lidR::knnidw(
                k = normalize_las[['params']][['k']],
                p = normalize_las[['params']][['p']],
                rmax = normalize_las[['params']][['rmax']]
            ),
            use_class = normalize_las[['use_class']],
            dtm = normalize_las[['dtm']],
            add_lasattribute = normalize_las[['add_lasattribute']],
            Wdegenerated = normalize_las[['Wdegenerated']]
        )
    } else if (normalize_las[['algorithm']]=='kriging') {
        nlas <- lidR::normalize_height(las,
            algorithm = lidR::kriging(
                model = normalize_las[['params']][['model']],
                k = normalize_las[['params']][['k']]
            ),
            use_class = normalize_las[['use_class']],
            dtm = normalize_las[['dtm']],
            add_lasattribute = normalize_las[['add_lasattribute']],
            Wdegenerated = normalize_las[['Wdegenerated']]
        )
    } else if (normalize_las[['algorithm']]=='tin') {
        nlas <- lidR::normalize_height(las,
            algorithm = lidR::tin(
                extrapolate = normalize_las[['params']][['extrapolate']]
            ),
            use_class = normalize_las[['use_class']],
            dtm = normalize_las[['dtm']],
            add_lasattribute = normalize_las[['add_lasattribute']],
            Wdegenerated = normalize_las[['Wdegenerated']]
        )
    }  else if (normalize_las[['algorithm']]=='dtm') {
        nlas <- lidR::normalize_height(las,
            algorithm = dtm,
            use_class = normalize_las[['use_class']],
            dtm = normalize_las[['dtm']],
            add_lasattribute = normalize_las[['add_lasattribute']],
            Wdegenerated = normalize_las[['Wdegenerated']]
        )
    }
    return (nlas)
}

########################################################################################
## CHM creation function
########################################################################################
func.create_chm = function(nlas, create_chm, out.root) {
    print('Creating CHM')
    print(create_chm)
    lidR::opt_output_files(nlas) <- ""
    if (create_chm[['algorithm']]=='dsmtin') {
        chm <- lidR::rasterize_canopy(nlas,
            algorithm = lidR::dsmtin(
                max_edge = create_chm[['params']][['max_edge']],
                highest = create_chm[['params']][['highest']]
            ),
            res = create_chm[['res']],
            use_class = create_chm[['use_class']],
            shape = create_chm[['shape']]
        )
    } else if (create_chm[['algorithm']]=='pitfree') {
        chm <- lidR::rasterize_canopy(nlas,
            algorithm = lidR::pitfree(
                thresholds = create_chm[['params']][['thresholds']],
                max_edge = create_chm[['params']][['max_edge']],
                subcircle = create_chm[['params']][['subcircle']],
                highest = create_chm[['params']][['highest']]
            ),
            res = create_chm[['res']],
            use_class = create_chm[['use_class']],
            shape = create_chm[['shape']]
        )
    } else if (create_chm[['algorithm']]=='p2r') {
        chm <- lidR::rasterize_canopy(nlas,
            algorithm = lidR::p2r(
                subcircle = create_chm[['params']][['subcircle']],
                na.fill = create_chm[['params']][['na.fill']]
            ),
            res = create_chm[['res']],
            use_class = create_chm[['use_class']],
            shape = create_chm[['shape']]
        )
    } else {
        print('Unknown CHM creation algorithm')
    }

    ## !!!
    ## Add gap filling / smoothing option
    ## !!!
    # fill.na <- function(x, i=5) { if (is.na(x)[i]) { return(mean(x, na.rm = TRUE)) } else { return(x[i]) }}
    # w <- matrix(1, 3, 3)
    # filled <- terra::focal(chm, w, fun = fill.na) ## gap filled
    # smoothed <- terra::focal(chm, w, fun = mean, na.rm = TRUE) ## smoothed
    file.chm <- paste(out.root,'_chm.tif', sep='')
    terra::writeRaster(chm, file.chm, overwrite=TRUE)
    return (chm)
}

########################################################################################
## Point density raster generation function
########################################################################################
func.map_point_density = function(las, calc_density, out.root) {
    print('Creating point density raster')
    lidR::opt_output_files(las) <- "" #paste(out.root,'point_density_all','{XLEFT}','{YBOTTOM}',sep='_')
    density.point.raster <- lidR::rasterize_density(las,
        res = calc_density[['res']],
        shape = calc_density[['shape']]
    )
    file.point_density <- paste(out.root,'point_density_all.tif',sep='_')
    terra::writeRaster(density.point.raster, file.point_density, overwrite=TRUE)
    return (density.point.raster)
}

########################################################################################
## Individual tree location function
########################################################################################
func.locate_trees = function(las, tree_loc, out.root) {
    print('Locating trees')
    print(tree_loc)
    lidR::opt_output_files(las) <- ""
    if (tree_loc[['algorithm']]=='lmf') {
        ttops <- lidR::locate_trees(las,
            algorithm = lidR::lmf(
                ws = tree_loc[['params']][['ws']],
                hmin = tree_loc[['params']][['hmin']],
                shape = tree_loc[['params']][['shape']],
                ws_args = tree_loc[['params']][['ws_args']]
            ),
            uniqueness = tree_loc[['uniqueness']]
        )
    } else {
        print('Unknown tree location algorithm')
    }
    file.tree_loc <- paste(out.root,'tree_locations.geojson',sep='_')
    sf::st_write(ttops, file.tree_loc)
    return (ttops)
}

########################################################################################
## Entropy calculation function
########################################################################################
wrap.entropy = function (chunk) {
    ## Calculate entropy profile for chunk of LAScatalog
    las = lidR::readLAS(chunk)
    if (lidR::is.empty(las)) {
        return(NULL)
    } else {
        return (lidR::voxel_metrics(
            las,
            ~lidR::entropy(Z,
                dz=calc_metric[['dz']],
                zmax=zmax),
            res = calc_metric[['metric_res']],
        ))
    }
}

########################################################################################
## Gap fraction calculation functions
######################################################################################## 
func.gap_fraction = function(Z, dz, z0) {
    ## Calculate gap fraction profile for height array Z
    df <- lidR::gap_fraction_profile(Z,
        dz=calc_metric[['dz']],
        z0=calc_metric[['zmin']])
    if (length(df$gf)>1) {
        return (df$gf[[length(df$gf)]])
    } else {
        return (df$gf)
    }
}

wrap.gap_fraction = function (chunk) {
    ## Calculate gap fraction profile for chunk of LAScatalog
    las = lidR::readLAS(chunk)
    if (lidR::is.empty(las)) {
        return(NULL)
    } else {
        return (lidR::voxel_metrics(
            las,
            ~func.gap_fraction(Z,
                dz=calc_metric[['dz']],
                z0=calc_metric[['zmin']]),
                res = calc_metric[['metric_res']],
            all_voxels = TRUE)
        )
    }
}

########################################################################################
## Plant Area Density calculation function
########################################################################################
func.PAD = function(Z, dz, k, z0) {
    ## Calculate Plant Area Density for height array Z
    df <- lidR::LAD(Z,
        dz=calc_metric[['dz']],
        k=k,
        z0=calc_metric[['zmin']])
    if (length(df$lad)>1) {
        return (df$lad[[length(df$lad)]])
    } else {
        return (df$lad)
    }
}

wrap.PAD = function (chunk) {
    ## Calculate Plant Area Density for chunk of LAScatalog
    las = lidR::readLAS(chunk)
    if (lidR::is.empty(las)) {
        return(NULL)
    } else {
        return (lidR::voxel_metrics(
            las,
            ~func.PAD(Z,
                dz=calc_metric[['dz']],
                k=0.5,
                z0=calc_metric[['zmin']]),
            res = calc_metric[['metric_res']],
            all_voxels = TRUE)
        )
    }
}

########################################################################################
## Canopy cover calculation function
########################################################################################
func.canopy_cover = function(Z) {
    ## Calculate canopy cover as 1 - total gap fraction for height array Z
    df <- lidR::gap_fraction_profile(Z,
        dz=calc_metric[['dz']],
        z0=calc_metric[['zmin']])
    sum(df$gf, na.rm=TRUE)
    cv <- 1-sum(df$gf, na.rm=TRUE)
    return (cv)
}

wrap.canopy_cover = function(chunk) {
    ## Calculate canopy cover for chunk of LAScatalog
    las = lidR::readLAS(chunk)
    if (lidR::is.empty(las)) {
        return(NULL)
    } else {
        return (lidR::pixel_metrics(
            las,
            ~func.canopy_cover(Classification),
            res = calc_metric[['metric_res']]
        ))
    }
}

########################################################################################
## Effective Number of Layers calculation function
########################################################################################
func.ENL = function(Z, dz, k, z0) {
    ## Calculate Effective Number of Layers for height array Z
    ## Based on MacArthur-Horn method implemented in calc_enl.R in forestR package
    if (max(Z) <= z0) {
        return (0)
    } else {
        data <- lidR::LAD(Z, dz=dz, k=k, z0=z0) ## Calculate leaf area density profiles
        z.count <- stats::aggregate(lad ~ z, data = data, FUN = function(X) sum(X != 0) ) # This counts the number of filled cells
        N.cells <- sum(z.count$lad) # The number of total filled cells
        if (N.cells > 0) {
            z.count$p.i <- (z.count$lad / N.cells)^2 # Proportion of cells at each level
            if (sum(z.count$p.i) > 0) {
                enl <- 1 / (sum(z.count$p.i)) # The effective number of layers
                return(enl)
            } else {
                return (0)
            }
        } else {
            return (0)
        }
    }
}

wrap.ENL = function(chunk) {
    ## Calculate Effective Number of Layers for chunk of LAScatalog
    las = lidR::readLAS(chunk)
    if (lidR::is.empty(las)) {
        return(NULL)
    } else {
        return (lidR::pixel_metrics(
            las,
            ~func.ENL(Z,
                dz=calc_metric[['dz']],
                k=0.5,
                z0=calc_metric[['zmin']]
            ),
            res = calc_metric[['metric_res']]
        ))
    }
}

########################################################################################
## Plant Area Index calculation functions
########################################################################################
func.PAI = function(Z, dx, dz) {
    ## Calculate Plant Area Index for height array Z
    df <- lidR::LAD(Z, dz=dz)
    return (as.numeric(sum(df$lad)))
}

wrap.PAI = function(chunk) {
    ## Calculate Plant Area Index for chunk of LAScatalog
    las = lidR::readLAS(chunk)
    if (lidR::is.empty(las)) {
        return(NULL)
    } else {
        return (lidR::pixel_metrics(
            las,
            ~func.PAI(Z, dx=calc_metric[['metric_res']], dz=calc_metric[['dz']]),
            res = calc_metric[['metric_res']]
        ))
    }
}

########################################################################################
## Relative Height (RH) metric calculation functions
########################################################################################
func.RH_metrics = function(Z) {
    ## Calculate Relative Height metrics of height array Z
    rhbins = seq(0.0, 1.0, 0.01)
    rh <- as.list(stats::quantile(Z, rhbins))
    names(rh) <- paste("RH", 100 * rhbins)
    return (rh)
}

wrap.RH_metrics = function(chunk) {
    ## Calculate Relative Height metrics for chunk of LAScatalog
    las = lidR::readLAS(chunk)
    if (lidR::is.empty(las)) {
        return(NULL)
    } else {
        return (lidR::pixel_metrics(
            las,
            ~func.RH_metrics(Z),
            res = calc_metric[['metric_res']])
        )
    }
}

########################################################################################
## Rumple Index calculation function
########################################################################################
wrap.rumple_index = function(chunk) {
    ## Calculate Rumple Index for chunk of LAScatalog
    las = lidR::readLAS(chunk)
    if (lidR::is.empty(las)) {
        return(NULL)
    } else {
        return (lidR::pixel_metrics(
            las,
            ~lidR::rumple_index(X, Y, Z),
            res = calc_metric[['metric_res']]
        ))
    }
}

########################################################################################
## Vertical Complexity Index calculation function
########################################################################################
wrap.VCI = function(chunk) {
    ## Calculate Vertical Complexity Index for chunk of LAScatalog
    las = lidR::readLAS(chunk)
    print(zmax)
    if (lidR::is.empty(las)) {
        return(NULL)
    } else {
        return (lidR::pixel_metrics(
            las,
            ~lidR::VCI(
                Z,
                zmax,
                by=calc_metric[['dz']]),
            res = calc_metric[['metric_res']]
        ))
    }
}

func.getZmax = function(chunk) {
    las <- lidR::readLAS(chunk)
    if (lidR::is.empty(las)) {
        return(NULL)
    } else {
        return (max(las$Z, na.rm=TRUE))
    }
}

########################################################################################
## Wrapper for metric calculations
########################################################################################
func.calc_metrics = function(las, calc_metrics, out.root) {
    metrics <- list()
    zmax <<- as.numeric(max(as.numeric(lidR::catalog_apply(nlas, func.getZmax))))
    ## 3D metrics
    if ('entropy' %in% calc_metrics[['metrics']]) {
        lidR::opt_output_files(las) <- paste(out$root,'{XLEFT}_{YBOTTOM}_entropy', sep='_')
        metrics$entropy <- lidR::catalog_apply(las, wrap.entropy)
    }
    if ('gap_fraction' %in% calc_metrics[['metrics']]) {
        lidR::opt_output_files(las) <- paste(out$root,'{XLEFT}_{YBOTTOM}_gap_fraction_profiles', sep='_')
        metrics$gap_fraction <- lidR::catalog_apply(las, wrap.gap_fraction)
    }
    if ('PAD' %in% calc_metrics[['metrics']]) {
        lidR::opt_output_files(las) <- paste(out$root,'{XLEFT}_{YBOTTOM}_PAD', sep='_')
        metrics$PAD <- lidR::catalog_apply(las, wrap.PAD)
    }
    ## 2D metrics
    if ('canopy_cover' %in% calc_metrics[['metrics']]) {
        lidR::opt_output_files(las) <- paste(out$root,'{XLEFT}_{YBOTTOM}_canopy_cover', sep='_')
        metrics$canopy_cover <- lidR::catalog_apply(las, wrap.canopy_cover)
    }
    if ('ENL' %in% calc_metrics[['metrics']]) {
        lidR::opt_output_files(las) <- paste(out$root,'{XLEFT}_{YBOTTOM}_enl', sep='_')
        metrics$ENL <- lidR::catalog_apply(las, wrap.ENL)
    }
    if ('PAI' %in% calc_metrics[['metrics']]) {
        lidR::opt_output_files(las) <- paste(out$root,'{XLEFT}_{YBOTTOM}_pai', sep='_')
        metrics$PAI <- lidR::catalog_apply(las, wrap.PAI)
    }
    if ('RH_metrics' %in% calc_metrics[['metrics']]) {
        lidR::opt_output_files(las) <- paste(out$root,'{XLEFT}_{YBOTTOM}_rh_metrics', sep='_')
        metrics$RH_metrics <- lidR::catalog_apply(las, wrap.RH_metrics)
    }
    if ('rumple_index' %in% calc_metrics[['metrics']]) {
        lidR::opt_output_files(las) <- paste(out$root,'{XLEFT}_{YBOTTOM}_rumple_index', sep='_')
        metrics$rumple_index <- lidR::catalog_apply(las, wrap.rumple_index)
    }
}

########################################################################################
## DTM Root Mean Square Error function
########################################################################################
func.dtm.rmse = function(dtm, dtm.ref) {
    abs_difference = (raster::crop(dtm, dtm.ref) - raster::crop(dtm.ref, dtm))**2
    return (raster::cellStats(abs_difference, stat='mean', na.rm=TRUE)**0.5)
}

########################################################################################
## DTM Mean Absolute Error function
########################################################################################
func.dtm.mae = function(dtm, dtm.ref) {
    abs_difference = abs(raster::crop(dtm, dtm.ref) - raster::crop(dtm.ref, dtm))
    return (raster::cellStats(abs_difference, stat='mean', na.rm=TRUE))
}