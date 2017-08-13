
# Building Plexpost

1. You really need to have docker installed first :-)
1. Clone the github repo
1. make

It does the rest.

## Notes

Two docker images will be built:
1.  *buildenv* This docker image consists of a build environment necessary to build the various tools that compiled into the plexpost image
1.  *<username>/plexpost* This is the main plexpost docker image.  Use this image along with the sample docker-compose file to get things running

