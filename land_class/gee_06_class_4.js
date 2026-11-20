// 1. Define training polygons as a FeatureCollection with a 'class' property.
// (Alternatively, draw polygons in the Code Editor and set a 'class' property.)
var tree = /* color: #98ff00 */ee.FeatureCollection(
        [ee.Feature(
            ee.Geometry.Polygon(
                [[[-3.741490452201479, 57.16380537993468],
                  [-3.7396880077434713, 57.161524812596404],
                  [-3.7357397960735494, 57.162455673396444],
                  [-3.735997288138979, 57.165201576234494]]]),
            {
              "class": 1,
              "system:index": "0"
            })]),
    water = /* color: #0c1fff */ee.FeatureCollection(
        [ee.Feature(
            ee.Geometry.Polygon(
                [[[-3.71378149429602, 57.16531192391301],
                  [-3.7193604890469967, 57.163124532835546],
                  [-3.7166997377042232, 57.16070428979315],
                  [-3.7077733461026607, 57.16112318934763],
                  [-3.7045117799405514, 57.16456729466964],
                  [-3.7070008699063717, 57.16656845175644]]]),
            {
              "class": 2,
              "system:index": "0"
            })]),
    moor = /* color: #8a3eba */ee.FeatureCollection(
        [ee.Feature(
            ee.Geometry.Polygon(
                [[[-3.7498215876980145, 57.16717728984015],
                  [-3.7504224025173505, 57.165315782533554],
                  [-3.748362465993913, 57.16528087837642],
                  [-3.747160836355241, 57.16752631202607]]]),
            {
              "class": 3,
              "system:index": "0"
            })]);

polygons=ee.FeatureCollection(tree,water,moor)

// 2. Load Sentinel-2 surface reflectance imagery and create a median composite.
var bands = ['B2', 'B3', 'B4', 'B8'];
var image = ee.ImageCollection('COPERNICUS/S2_SR_HARMONIZED')
  .filterBounds(polygons.geometry().bounds())
  .filterDate('2024-05-01', '2024-08-31')
  .filter(ee.Filter.lt('CLOUDY_PIXEL_PERCENTAGE', 20))
  .select(bands)
  .median();

// 3. Extract pixel values inside the training polygons at 10m scale.
var training = image.sampleRegions({
  collection: polygons,
  properties: ['class'],
  scale: 10
});

// 4. Train a Random Forest classifier and classify the image.
var classifier = ee.Classifier.smileRandomForest(50)
  .train({
    features: training,
    classProperty: 'class',
    inputProperties: bands
  });

var classified = image.classify(classifier);

// 5. Display results on the map.
Map.centerObject(polygons, 12);
Map.addLayer(image, {bands: ['B4', 'B3', 'B2'], min: 200, max: 3000}, 'RGB Composite');
Map.addLayer(polygons, {color: 'yellow'}, 'Training Polygons');
Map.addLayer(classified, {min: 0, max: 1, palette: ['gray', 'green']}, 'Classified Map');

