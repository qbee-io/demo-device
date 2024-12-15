# build base image

Build a base image based meta-qbee and meta-rauc/meta-rauc-community (as described in docs)

NB: Do not define bootstrap key as this will create the .bootstrap-env file, debugfs cannot
overwrite files, just copy in new ones.

