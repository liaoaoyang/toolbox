#!/bin/sh

function baseXencode() {
	awk 'BEGIN{b=split(ARGV[1],D,"");n=ARGV[2];do{d=int(n/b);i=D[n-b*d+1];r=i r;n=d}while(n!=0);print r}' "$1" "$2"
}

function base62encode() {
    baseXencode 0123465789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ "$1"
}

base62encode $1
