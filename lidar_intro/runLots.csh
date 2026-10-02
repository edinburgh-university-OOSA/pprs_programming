#!/bin/csh -f

set resList="0.5 1 2 10 50"
set rigList="1L 2L 3L"
set threshList="0.01 0.1 0.5"

foreach res( $resList )
  foreach rigid( $rigList )
    foreach thresh( $threshList )
      set outRoot="gr.r.$rigid.res.$res.t.$thresh"

      Rscript classGr.R --rigid $rigid --res $res --threshold $thresh -outRoot $outRoot
    end
  end
end

