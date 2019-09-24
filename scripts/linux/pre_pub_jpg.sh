#!/bin/sh

if [ -z $wm_per ]; then
	wm_per=0.12
fi

if [ -z $wm_fn ]; then
	wm_fn=~/Tools/watermask.png
fi

if [ -z $w_delta ]; then
	w_delta=20 
fi

if [ -z $h_delta ]; then
	h_delta=20 
fi

if [ -z $out_suffix ]; then
	out_suffix="-out"
fi

if [ -z $out_width ]; then
	out_width=1
fi

if [ -z $out_quality ]; then
	out_quality=95
fi

if [ -z $ext_opts ]; then
	ext_opts="-strip"
fi

for src_fn in `ls | awk '/(jpg|JPG)$/ {print $1}' | grep -vE '_ppj_tmp|out|watermask'` 
do 
	src_fnn=`echo $src_fn | sed 's/.jpg//' | sed 's/.JPG//'`
	dst_fn=$src_fnn$out_suffix".jpg"
	src_tmp_fn=$src_fnn"_ppj_tmp.jpg"

	if [ $out_width -le 1 ]; then
		 cp $src_fn $src_tmp_fn
	else
		 convert $src_fn -resize $out_width -quality 100 $src_tmp_fn
	fi

	convert $wm_fn -resize $(identify -format %w $src_tmp_fn | awk "{printf(\"%d\", \$1*$wm_per)}") -quality 100 tmpwm.png
	convert $src_tmp_fn tmpwm.png -quality $out_quality -gravity southeast -geometry +$w_delta+$h_delta -composite $ext_opts $dst_fn
	printf $src_fn"\t=>\t"$dst_fn"\n"
	rm -f tmpwm.png $src_tmp_fn
done
