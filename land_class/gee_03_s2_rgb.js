function maskS2clouds(image) {  //this will filter for clouds
  var qa = image.select('QA60');
  var cloudBitMask = 1 << 10;
  var cirrusBitMask = 1 << 11;
  var mask = qa.bitwiseAnd(cloudBitMask).eq(0)
      .and(qa.bitwiseAnd(cirrusBitMask).eq(0));
  return image.updateMask(mask).divide(10000);
}

// open the sentinel 2 data and filter for clouds
var dataset = ee.ImageCollection('COPERNICUS/S2_SR_HARMONIZED')
                  .filterDate('2026-10-01', '2026-11-11')
                  // Pre-filter to get less cloudy granules.
                  .filter(ee.Filter.lt('CLOUDY_PIXEL_PERCENTAGE',1))
                  .map(maskS2clouds);

// tell GEE which bands to show
var visualization = {
  min: 0.0,
  max: 0.3,
  bands: ['B4', 'B3', 'B2'],
};

Map.setCenter( -3.9 ,56.8, 8); // Center on Scotland
Map.addLayer(dataset.mean(), visualization, 'RGB');

