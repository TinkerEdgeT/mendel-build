#!/bin/bash -xe
(
	flock -e 200
	( cd $PRODUCT_OUT/packages; apt-ftparchive packages . > Packages )
) 200>$PRODUCT_OUT/obj/packages-lock
