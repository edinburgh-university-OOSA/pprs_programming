// make sure your land cover map is still in your map
var image = classified;

ee.FeatureCollection.randomPoints(classified.filter)

ee.Filter.lt('CLOUDY_PIXEL_PERCENTAGE',1

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
  scale: 30
});

// Define a 10-tree random forest classifier
var  classifier = ee.Classifier.smileRandomForest(10)

// Train the classifier.
var trained = classifier.train(training,'landcover', bands);

// Classify the image.
var classified = image.classify(trained);

// Display the classification result and the input image.
Map.setCenter(-3.728574,57.181384,10); // Center on Bagaduish
Map.addLayer(image,
             {bands: ['B4', 'B3', 'B2'], min: 0, max: 0.25},
             'image');
Map.addLayer(polygons, {color: 'yellow'}, 'training polygons');
Map.addLayer(classified, {min: 1, max: 5, palette: ['blue','yellow','red', 'green','purple']}, 'Classified Image');


