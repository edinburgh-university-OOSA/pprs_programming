// open up your classification asset
// note that you will need to update your project name
var classified = ee.Image('projects/gee-teaching-test/assets/classified')


// for each class (1-5), make a mask and generate points
for(var i=1; i < 6; i+=1) {
  var classMask = classified.eq(i).mask();
  // generate random points
  var randomPoints = classMask.sample({
    region: roi,
    scale: 30,           // Pixel resolution in meters (match your image's native scale)
    numPixels: 5,      // Target number of random points
    seed: 42,            // Optional: keeps results reproducible
    geometries: true     // Essential: returns point geometries instead of just a data table
  });
}

ee.FeatureCollection.randomPoints(classified.filter)
ee.Filter.lt('CLOUDY_PIXEL_PERCENTAGE',1

