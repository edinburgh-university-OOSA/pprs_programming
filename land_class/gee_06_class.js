// this is an example script provided by Google


// 1. Define your Region of Interest (ROI) or center the map
Map.setCenter(-3.728574,57.181384,13); // Center on Bagaduish


function maskS2clouds(image) {  //this will filter for clouds
  var qa = image.select('QA60');
  var cloudBitMask = 1 << 10;
  var cirrusBitMask = 1 << 11;
  var mask = qa.bitwiseAnd(cloudBitMask).eq(0)
      .and(qa.bitwiseAnd(cirrusBitMask).eq(0));
  return image.updateMask(mask).divide(10000);
}

// 2. Load and filter a satellite image collection
var s2 = ee.ImageCollection('COPERNICUS/S2_SR_HARMONIZED')
         .filterDate('2026-06-01', '2026-08-21')
         // Pre-filter to get less cloudy granules.
         .filter(ee.Filter.lt('CLOUDY_PIXEL_PERCENTAGE',1))
         .map(maskS2clouds).median();

// Select the 20 m and finer res bands
var bands = ['B2','B3', 'B4', 'B5', 'B6', 'B7', 'B8', 'B8A', 'B11', 'B12'];
var image = s2.select(bands);

// 3. Load training data (FeatureCollection with a numeric 'class' property)
var points = ee.FeatureCollection('GOOGLE/EE/DEMOS/demo_landcover_labels');
var label = 'landcover';

// 4. Sample the imagery at the training point locations
var training = image.sampleRegions({
  collection: points,
  properties: [label],
  scale: 20   // at Sentinel-2's medium resolution
});

// 5. Train a classifier (here a Random Forest)
var classifier = ee.Classifier.smileRandomForest(10).train({
  features: training,
  classProperty: label,
  inputProperties: bands
});

// 6. Classify the image
var classified = image.classify(classifier);

// 7. Display the input composite and the classification result
Map.addLayer(s2, {bands: ['B4', 'B3', 'B2'], min: 0, max: 0.25}, 'RGB Image');
Map.addLayer(classified, {min: 0, max: 4, palette: ['blue', 'green', 'yellow', 'red', 'brown']}, 'Land Cover Classification');

