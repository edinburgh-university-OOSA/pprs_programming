// this is an example script provided by Google


// 1. Define your Region of Interest (ROI) or center the map
Map.setCenter(-3.9, 50.5, 8);

// 2. Load and filter a satellite image collection (e.g., Landsat 8 Surface Reflectance)
var l8Image = ee.ImageCollection('LANDSAT/LC08/C02/T1_L2')
  .filterDate('2026-05-01', '2026-09-01')
  .median();

// Select the optical and thermal bands
var bands = ['SR_B2', 'SR_B3', 'SR_B4', 'SR_B5', 'SR_B6', 'SR_B7', 'ST_B10'];
var image = l8Image.select(bands);

// 3. Load training data (FeatureCollection with a numeric 'class' property)
// Note: In practice, create and merge your own labeled polygon geometries using the Geometry tools in GEE.
var points = ee.FeatureCollection('GOOGLE/EE/DEMOS/demo_landcover_labels');
var label = 'landcover';

// 4. Sample the imagery at the training point locations
var training = image.sampleRegions({
  collection: points,
  properties: [label],
  scale: 30
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
Map.addLayer(image, {bands: ['SR_B4', 'SR_B3', 'SR_B2'], min: 0, max: 0.25}, 'RGB Image');
Map.addLayer(classified, {min: 0, max: 4, palette: ['blue', 'green', 'yellow', 'red', 'brown']}, 'Land Cover Classification');

