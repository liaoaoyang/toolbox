#!/bin/sh

SOFTWARES_DIR=/tmp/toolbox/softwares
BASE_DIR=$(dirname $0)
DOWNLOADS_DIR=$BASE_DIR/../downloads
GIT_VERSION=2.11.1
git_now_version=`git --version 2>>/dev/null | grep -oP '(\d+\.)+\d+'`

if [ ! -z $1 ]; then
    GIT_VERSION=$1
fi

if [ $git_now_version"x" \> $GIT_VERSION"x" ]; then
    echo "Git $git_now_version newer than this version"
fi

if [ ! -d $SOFTWARES_DIR ]; then
    mkdir -p $SOFTWARES_DIR
fi

if [ ! -d $DOWNLOADS_DIR ]; then
    mkdir -p $DOWNLOADS_DIR
fi

git_tgz_file=$DOWNLOADS_DIR/"git-v"$GIT_VERSION".tar.gz"

if [ ! -f $git_tgz_file ]; then
    wget "https://github.com/git/git/archive/v"$GIT_VERSION".tar.gz" -O $git_tgz_file

    if [ $? -ne 0 ]; then
        echo "Failed to download "$git_tgz_file
        exit
    fi
fi

git_src_dir=$DOWNLOADS_DIR/"git-"$GIT_VERSION

if [ ! -d $git_src_dir ]; then
    cd $DOWNLOADS_DIR
    tar -xzvf "git-v"$GIT_VERSION".tar.gz"
fi

cd $git_src_dir

if [ `rpm -qa | grep -E '^(autoconf|perl-ExtUtils-MakeMaker|gcc|libcurl-devel|expat-devel|gettext-devel|openssl-devel|zlib-devel)' | wc -l` -ne 8 ]; then
    yum install autoconf perl-ExtUtils-MakeMaker gcc curl-devel expat-devel gettext-devel openssl-devel zlib-devel -y
fi

autoconf
./configure

MAKE_J=`cat /proc/cpuinfo |grep -P 'processor\s+:\s\d+' | wc -l`

if [ -z $MAKE_J ]; then
    MAKE_J=1
fi

make "-j"$MAKE_J
make install

git_bins=`ls /usr/bin/git* | grep -v '.old'`

for git_bin in $git_bins
do
    if [ ! -h $git_bin ]; then
        mv $git_bin $git_bin".old."`date +%Y%m%d%H%M%S`
    fi
done

new_git_bins=`ls /usr/local/bin/git*`
for new_git_bin in $new_git_bins
do
    new_git_link=`echo $new_git_bin | sed 's/local\///'`
    echo $new_git_link
    ln -s $new_git_bin $new_git_link
done
