#!/bin/csh -f

set fileList=`ls coarsen*_1M_D?M_PHASE1.tif`

foreach file( $fileList )
  set newName=`echo $file|sed -e s%"_1M_"%"_3M_"%`

  mv $file $newName
  echo "$newName"
end

