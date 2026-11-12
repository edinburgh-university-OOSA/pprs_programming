function maskS2clouds(image) {  //this will filter for clouds
  var qa = image.select('QA60');
  var cloudBitMask = 1 << 10;
  var cirrusBitMask = 1 << 11;
  var mask = qa.bitwiseAnd(cloudBitMask).eq(0)
      .and(qa.bitwiseAnd(cirrusBitMask).eq(0));
  return image.updateMask(mask).divide(10000);
}


//define where you want to look. This uses the UN region database
var dataExtent = ee.FeatureCollection("FAO/GAUL/2015/level1")
                  .filter(ee.Filter.eq('ADM0_NAME', 'Scotland')); //filter for entry that equals the UN country name 'Scotland'



// open the sentinel 2 data and filter for clouds
var dataset = ee.ImageCollection('COPERNICUS/S2_SR_HARMONIZED')
                  .filterDate('2024-07-01', '2024-08-30')
                  // Pre-filter to get less cloudy granules.
                  .filter(ee.Filter.lt('CLOUDY_PIXEL_PERCENTAGE',20))
                  .map(maskS2clouds);

// Calculate NDVI from bands 8 and 4
var addNDVI = function(image) {
  var ndvi = image.normalizedDifference(['B8', 'B4']).rename('NDVI');
  return image.addBands(ndvi);
};

//calculate NDVI
var S2_NDVI = dataset.map(addNDVI);

// get the mean across this month
var mean_S2 = ee.Image(S2_NDVI.mean());

// draw the map
var NDVIpalette = ['FFFFFF', 'CE7E45', 'DF923D', 'F1B555', 'FCD163', '99B718', '74A901', '66A000', '529400', '3E8601', '207401', '056201', '004C00', '023B01', '012E01', '011D01', '011301']; // the colour scheme to use
Map.setCenter( -3.9 ,56.8, 8); // Center on Scotland
Map.addLayer(mean_S2.select('NDVI'), {palette: NDVIpalette}, 'Recent Sentinel NDVI');

