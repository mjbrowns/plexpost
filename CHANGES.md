# Change Log

## Version 1.17
I have no idea why, but after the latest docker CE update, the ADD function didn't seem to work correctly.  
I had used the add statement to pull the S6 archive into the image and then unpack it; it seemed to do the download but then when it got to the next line in the dockerfile to unpack it the 
file wasn't there.  I dug around quite a bit and it wasn't anywhere.  So I have no idea why, but I had to update my build process to handle this separately.  Ironically its probably a
better design this way :-)

Also: Removed the date printing from the queueman and plexprocess scripts - since docker's output manager is timestamped this is redundant.

## Version 1.16
...and figured out that i needed to include the tzdata package so that the container would sync time with timzeone support.

## Version 1.15
In the 1.12 update I trimmed down the plexpost image but in the process introduced an error - I did not have the ca-certificates installed so the slack posting process failed.
This update adds ca-certificates to the images so slack alerting now works again.

## Version 1.14
* Plex made a permanent change to their DVR process; rather than outputting native streams (usually TS files) they are remuxing all DVR streams to mkv.  This version changes the flow of post processing to handle both TS input files and mkv automatically.
* Corrected error handling to properly call back to the alerting functions in more scenarios
* Updates comskip, s6, etc.

## Version 1.13
* Updated s6 component

## Version 1.12
* reorganized build process. Fixed up some permissions

## Version 1.11
* switched over to a new tool to send messages to slax
* fixed a few minor bugs

## Version 1.10
* Updated comskip
* Added ffmpeg flags to fix timestamp conversion issues with ffmpeg conversions of OTA .ts streams.

## Version 1.09
* Added slack webhook capability for notification instead of just email.

## Version 1.08
* Fixes; original version published to docker hub
