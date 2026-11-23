// define cloud filtering function
function maskS2clouds(image) {  //this will filter for clouds
  var qa = image.select('QA60');
  var cloudBitMask = 1 << 10;
  var cirrusBitMask = 1 << 11;
  var mask = qa.bitwiseAnd(cloudBitMask).eq(0)
      .and(qa.bitwiseAnd(cirrusBitMask).eq(0));
  return image.updateMask(mask).divide(10000);
}
  
// Load and filter a satellite image collection
var s2summer = ee.ImageCollection('COPERNICUS/S2_SR_HARMONIZED')
         .filterBounds(roi)
         .filterDate('2023-05-01','2023-08-31')
         .filter(ee.Filter.lt('CLOUDY_PIXEL_PERCENTAGE',5))
         .map(maskS2clouds).median();
var s2winter = ee.ImageCollection('COPERNICUS/S2_SR_HARMONIZED')
         .filterBounds(roi)
         .filterDate('2022-10-01','2023-04-30')
         .filter(ee.Filter.lt('CLOUDY_PIXEL_PERCENTAGE',10))
         .map(maskS2clouds).median();

// Select the 20 m and finer res bands
var bands = ['B2','B3', 'B4', 'B5', 'B6', 'B7', 'B8', 'B8A', 'B11', 'B12'];


// Open PALSAR-2 ScanSAR data
var palsar = ee.ImageCollection('JAXA/ALOS/PALSAR-2/Level2_2/ScanSAR')
  .filterDate('2023-01-01', '2024-01-01')  // Three years of data
  .filterBounds(roi).median();

var image = s2summer.select(bands).addBands(s2winter.select(bands)).addBands(palsar);

// Make a FeatureCollection from the hand-made geometries.
// YOU NEED TO EDIT FOR YOUR CLASS NAMES HERE
var polygons = water.merge(grass).merge(urban).merge(tree).merge(moor);

// Get the values for all pixels in each polygon in the training.
var training = image.sampleRegions({
  // Get the sample from the polygons FeatureCollection.
  collection: polygons,
  // Keep this list of properties from the polygons.
  properties: ['landcover'],
  // Set the scale to get Landsat pixels in the polygons.
  scale: 20
});

// Define a 10-tree random forest classifier
var  classifier = ee.Classifier.smileRandomForest(10)

// Train the classifier.
var trained = classifier.train(training,'landcover', bands);

// Classify the image.
var classified = image.classify(trained);

// Display the classification result and the input image.
Map.setCenter(-3.728574,57.181384,10); // Center on Bagaduish
Map.addLayer(polygons, {color: 'yellow'}, 'training polygons');
Map.addLayer(classified, {min: 1, max: 5, palette: ['blue','yellow','red', 'green','purple']}, 'Classified Image');
Map.addLayer(s2summer,
             {bands: ['B4', 'B3', 'B2'], min: 0, max: 0.5},
             'summer');
Map.addLayer(s2winter,
             {bands: ['B4', 'B3', 'B2'], min: 0, max: 0.5},
             'winter');
Map.addLayer(palsar,
             {bands: ['HH', 'HV', 'HV'], min: 0, max: 8000},
             'palsar');

// and save as a geotiff
Export.image.toDrive({
  image: classified,
  description: 'classified',
  folder: 'introEO',
  fileNamePrefix: 'classified',
  region: roi,
  scale: 20,
  crs: 'EPSG:32630'
});

//save the data for later use
Export.image.toAsset({
  image: classified,
  description: 'classified',
  assetId: 'classified',
  region: roi,
  scale: 20,
  crs: 'EPSG:32630'
});

