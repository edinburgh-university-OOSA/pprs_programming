// open up your classification asset
// note that you will need to update your project name
var classified = ee.Image('projects/gee-teaching-test/assets/classified')


// for each class (1-5), make a mask and generate points
for(var i=1; i < 6; i+=1) {
  var classMask = classified.eq(i).mask();
  // generate random points


}

ee.FeatureCollection.randomPoints(classified.filter)
ee.Filter.lt('CLOUDY_PIXEL_PERCENTAGE',1

