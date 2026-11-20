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
var moor = ee.Geometry.Polygon(
                [[[-3.654362658968273, 57.15435697527349],
                  [-3.653794030657116, 57.15220385267592],
                  [-3.649792174806896, 57.153100032442524],
                  [-3.653590182771984, 57.15458391873256],
                  [-3.65443776082069, 57.154316241684754]]]),
    tree = ee.Geometry.Polygon(
                [[[-3.6714843787673646, 57.15605036016949],
                  [-3.668179897261017, 57.15321066968999],
                  [-3.662085918379181, 57.15602708490416],
                  [-3.6662487067702942, 57.157702866571]]]),
    water = ee.Geometry.Polygon(
                [[[-3.7170215097972936, 57.16564903279936],
                  [-3.7166781870433874, 57.16085526328322],
                  [-3.7075801340648717, 57.16220502823711],
                  [-3.7076659647533483, 57.16592826235351]]]),
    grass = ee.Geometry.Polygon(
                [[[-3.6855745237304105, 57.14450858418571],
                  [-3.6867010515166654, 57.14360637551402],
                  [-3.6838257234527005, 57.14313488997297],
                  [-3.6837077062560453, 57.14467156147098],
                  [-3.684662572665347, 57.144962590552126]]]),
    tarmac = ee.Geometry.Polygon(
                [[[-3.6626161488320252, 57.147094596431245],
                  [-3.662594691159906, 57.14683559558513],
                  [-3.661849037053766, 57.14669008869643],
                  [-3.6596925410057923, 57.14648346793129],
                  [-3.6595852526451966, 57.14672210026106],
                  [-3.661725655439081, 57.14684723611152],
                  [-3.6624820383812806, 57.14701602333244]]]);

// Make a FeatureCollection from the hand-made geometries.
var polygons = ee.FeatureCollection([
  ee.Feature(moor, {'class': 0}),
  ee.Feature(tree, {'class': 1}),
  ee.Feature(water, {'class': 2}),
  ee.Feature(grass, {'class': 3}),
  ee.Feature(tarmac, {'class': 4}),
]);

// Get the values for all pixels in each polygon in the training.
var training = image.sampleRegions({
  // Get the sample from the polygons FeatureCollection.
  collection: polygons,
  // Keep this list of properties from the polygons.
  properties: ['class'],
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

