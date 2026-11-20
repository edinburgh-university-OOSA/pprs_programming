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
var s2 = ee.ImageCollection('COPERNICUS/S2_SR_HARMONIZED')
         .filterDate('2026-06-01', '2026-08-21')
         // Pre-filter to get less cloudy granules.
         .filter(ee.Filter.lt('CLOUDY_PIXEL_PERCENTAGE',1))
         .map(maskS2clouds).median();

// Select the 20 m and finer res bands
var bands = ['B2','B3', 'B4', 'B5', 'B6', 'B7', 'B8', 'B8A', 'B11', 'B12'];
var image = s2.select(bands);

// Manually created polygons.
var water = /* color: #1a0ed6 */ee.FeatureCollection(
        [ee.Feature(
            ee.Geometry.Polygon(
                [[[-3.713798485124984, 57.1647616776473],
                  [-3.7123393634208823, 57.16117795850771],
                  [-3.703756294573226, 57.164389359359404],
                  [-3.7056445697197105, 57.16587861001682]]]),
            {
              "system:index": "0"
            })]),
    tree = /* color: #98ff00 */ee.FeatureCollection(
        [ee.Feature(
            ee.Geometry.Polygon(
                [[[-3.741490452201479, 57.16380537993468],
                  [-3.7396880077434713, 57.161524812596404],
                  [-3.7357397960735494, 57.162455673396444],
                  [-3.735997288138979, 57.165201576234494]]]),
            {
              "system:index": "1"
            })]),
    moor = /* color: #7831c6 */ee.FeatureCollection(
        [ee.Feature(
            ee.Geometry.Polygon(
                [[[-3.749558536918276, 57.166900210640236],
                  [-3.7502451824260885, 57.16522484572613],
                  [-3.748914806754702, 57.165201576234494],
                  [-3.7479706691814596, 57.166388301637596],
                  [-3.747584431083315, 57.16727250364484]]]),
            {
              "system:index": "2"
            })]);

// Make a FeatureCollection from the hand-made geometries.
var polygons = ee.FeatureCollection(water,tree,moor);

// Get the values for all pixels in each polygon in the training.
var training = image.sampleRegions({
  // Get the sample from the polygons FeatureCollection.
  collection: polygons,
  // Keep this list of properties from the polygons.
  //properties: ['system:index'],
  // Set the scale to get Landsat pixels in the polygons.
  scale: 30
});

// Create an SVM classifier with custom parameters.
var classifier = ee.Classifier.libsvm({
  kernelType: 'RBF',
  gamma: 0.5,
  cost: 10
});

// Train the classifier.
var trained = classifier.train(training, 'class', bands);

// Classify the image.
var classified = image.classify(trained);

// Display the classification result and the input image.
Map.setCenter(-3.728574,57.181384,13); // Center on Bagaduish
Map.addLayer(image,
             {bands: ['B4', 'B3', 'B2'], min: 0, max: 0.25},
             'image');
Map.addLayer(polygons, {color: 'yellow'}, 'training polygons');
Map.addLayer(classified,
             {min: 0, max: 4},
             'classification map');

