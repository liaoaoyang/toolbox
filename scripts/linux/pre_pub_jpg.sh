#!/bin/sh

wm_per=0.12
wm_fn=watermask.png
w_delta=20 
h_delta=20 
out_suffix="-out"
out_quality=95
for src_fn in `ls | grep -E '.jpg|.JPG' | grep -vE 'out|watermask'` 
do 
	src_fnn=`echo $src_fn | sed 's/.jpg//' | sed 's/.JPG//'`
	dst_fn=$src_fnn$out_suffix".jpg"

	convert $wm_fn -resize $(identify -format %w $src_tmp_fn | awk "{printf(\"%d\", \$1*$wm_per)}") -quality 100 tmpwm.png
	convert $src_fnn tmpwm.png -quality $out_quality -gravity southeast -geometry +$w_delta+$h_delta -composite $ext_opts $dst_fn
	printf $src_fn"\t=>\t"$dst_fn"\n"
	rm -f tmpwm.png 
done
