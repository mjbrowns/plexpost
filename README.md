# plexpost
Docker based plex + postprocessor that handles commercial cutting and transcoding

# Overview

This project leverages docker and docker-compose to create a service of two containers:

1. The standard plexpass container, modified by injecting my postprocessing script (in *src/plexpost*)
2. My "plexpost" container, which detects new recordings and processes them according to a variety of settings

# Docker Container is available on dockerhub

This is now published as a built container now on dockerhub.  See [**here**](https://hub.docker.com/r/mbrown/plexpost/).

# Change Log
The change log can be found in [CHANGES.md](https://github.com/mjbrowns/plexpost/blob/master/CHANGES.md)

# Build instructions

Build instructions can be found in [BUILD.md](https://github.com/mjbrowns/plexpost/blob/master/BUILD.md)

# Directory Hierarchy
To help you understand the flow, here's a hierarchy of the directory structure used in this project:

| Directory | Notes |
| --------- | ------ |
| *plex*    | Base directory.  In my examples, this is */docker/data/plex* |
| *plex/data* | Subdirectory to hold data for the plex container.  This is not strictly necessary, but the subdirectories map to volumes in the standard plexpass image.  If you change those pointers in the docker-compose.yml file, this is not necessary. |
| *plex/data/Library* | This is where Plex will create/store its metadata |
| *plex/data/transcode-temp* | Plex uses this directory to store files it creates when it does transcoding.  Technically this has nothing to do with the DVR, this is where it does its streaming and client conversion work. |
| *plex/plexpost* | This is where you clone this repo |
| *plex/plexpost/src* | This holds the source files for the postprocessor image |
| *plex/plexpost/comchap* | This is where the update script will put copies of the comchap scripts (*see **sources** below*) |
| *plex/plexpost/comskip* | this is where the update script will put the comskip binaries (*see **sources** below*) |

# Workflow

If you are familiar with the docker-compose system (*[recommended reading](https://docs.docker.com/compose/overview/)*), you will see a volume created called *postdata*.  This volume is mapped by both containers (*plex* and *plexpost*).  When the *plexpost* container starts, it will copy the postprocessing script to a *bin* directory inside the *postdata* volume.  Using the defaults, the *postdata* volume will be mapped/mounted inside both containers at */postdata*.  Thus, the postprocessing script will end up in */postdata/bin/plexpost*.

The postprocessing script, run after every recording, will create an entry in the *postdata* volume.  Using defaults this can be seen from either container at the path */postdata/queue*.  The plexpost container scans the queue folder every QUEUETIMER seconds and launches the actual postprocessing tasks as it finds new jobs.

# Sources
In addition to the official plex:plexpass docker image, i'm leveraging components from other contributors.  Many thanks to these for the fantastic work they have done, without which this project would not have happened.
* comskip by [**Erik Kaashoek**](http://github.com/erikkaashoek/Comskip) - [**Donations Recommended**](http://www.comskip.org)
* The comchap/comcut scripts by [**Brett Sheleski**](http://github.com/BrettSheleski/comchap)
* The Famous [**HandBrake**](https://handbrake.fr/)

# Setup
Setup is fairly simple.  After installing the latest version of docker-ce, you will have both docker and docker-compose available.

1. Create a directory for the service.  In my case I used */docker/data/plex*.
2. Create a subdirectory for plex data.  In my example: */docker/data/plex/data*.  Alternatively you can simply change the volume mapping in the docker-compose file to point to wherever you want your data to go.  If you are already a plex user on linux, you can move your data over, for example:

    *mv /var/lib/plexmediaserver/Library /docker/data/plex/data*

3. Clone this git repo into a subdirectory named *plexpost* or whatever you want the prostprocessing container to be named.  The build script will name the container it builds using the name of this directory.  In my example:

    *git clone https://github.com/mjbrowns/plexpost /docker/data/plex/plexpost*

    The build script will then name the postprocessing container *plexpost*

4. Update the source directory.

  To do the update, simply execute the *update* script found in the *src* subdirectory (*/docker/data/plex/plexpost/src*).  It does the following things:
  * grabs the comchap and comcut scripts from github and puts them in the *comchap* subdirectory of *src*
  * creates and runs a temporary container using the ubuntu base image, clones the comskip repo, builds comskip and extracts the executables.
  **NOTE** Be aware that compilation of comskip generates a bunch of irrelevant warnings.  You can ignore this.

5. Build the postprocessor docker image.  To do this simply run the *build* script found in the postprocessor main directory (*/docker/data/plex/plexpost*).  This creates the docker image that will be used to run the postprocessor.

6. Copy the *docker-compose-sample.yml* file from the *src* directory (*/docker/data/plex/plexpost/src*) to the upper level plex directory (*/docker/data/plex*).  Configure this to suit your needs.  See **Configuration** below for details.

7. Start it up.

  cd */docker/data/plex*
  docker-compose up -d

8. Check the logs
  * For plex logs, *docker logs*
  * You can also use native docker commands to see the logs of each container:
    * *docker logs plex*
    * *docker logs plexpost*

9. Configure Plex.  If you imported a previous plex Library directory, you should have very little to do.  Follow the instructions on the plex forums:
  * [Plex Docker Forum](https://forums.plex.tv/discussion/250499/official-plex-media-server-docker-images-getting-started)
  * [Plex DVR BETA Forum](https://forums.plex.tv/categories/dvr-beta)
  * Configure the postprocess script in the Plex DVR settings.  You must set the postprocess script to:

    **/postdata/bin/plexpost**

  **NOTE** Do not configure plex to automatically transcode.  The postprocessor will handle that, and it expects only .ts source files.

# docker-compose.yml Configuration

This section describes configuration settings that are specific to my implementation of plex and the plexpost containers.  For more information refer to the [docker-compose documentation](https://docs.docker.com/compose/compose-file/compose-file-v2/)

For more information on the *plexpost* image environment variables, see the comments in the *Dockerfile*

1. Plex container section
  * The port mappings should probably all stay the same.
  * Make sure PLEX_UID and PLEX_GID are set to something useful.  Make sure that those UID/GID own or have access to the media directory structures mapped under volumes.
  * The standard plex:plexpass image created its own network, so here I force it to mine, which I called bridge.  You can map this however you want.  I map the plexpost container to the same network but it really isn't that necessary as the plexpost container doesn't even need the network.
  * Basically the only real change we introduce to the standard *plex* container configuration is addition of the volume entry:

    \- *postdata:/postdata*

    Which is what makes sure our *postdata* volume gets mounted into the plex conatiner.
2. Plexpost container section.
  * If you use a different subdirectory name other than *plexpost* you will need to update the image name here accordingly.  You can also change the container name to match, though that's optional.  Hostname is immaterial but should match what you set in the **MAIL** environment settings.
  * **COMSKIP_*** variables.  These must be set to match what the *Plex* container uses for its **PLEX_*** variables.
  * **TVDIR** and **MVDIR** These must point to the location in the container where the postprocessor can find your media libraries.
  * **QUEUETIMER** Set this to how many seconds should elapse between queue scans by the postprocessor.
  * **COMCUT** if set to 0 (*default*) the postprocessor will:
    * Convert the recorded ts file to an mkv file with chapter marks around detected commercials.
    * Transcode the result into h.264 and put the result into the plex library with the original name but an extension of .mkv
  If set to 1, the postprocessor will:
    * Convert the original .ts file to .mkv and add chapter marks.  The resulting file will be in the plex library with an extension of .mkv-ts so that Plex doesn't see the file.  Its there for safekeeping.
    * Cut the commercials out of the file
    * Transcode the result into h.264 and put the result into the plex library with the original name but an extension of .mkv
  * **REMOVETS** If this is set to 1, it will immediately delete the .mkv-ts file!  If set to 0 it leaves it alone
  * **TSCLEAN** Default is 1.  If enabled, once per day the queue manager will scan the media libraries for .mkv-ts files, and if they are older than **TSDAYS** it will delete them.  The point here is to make sure you have the original recording around for a while in case automated commercial removal makes a mess of things.
  * **MAIL** settings.  See the examples in the docker-compose.yml.  Fairly self explanatory and very easy to use if you have an outbound relay set up on your network, or an ISP that is permissive to their subscribers without auth.  Basically if MAILTO is set it will send an email to alert you if anything goes wrong during post-processing.
  * **SLACK_HOOK** Default is blank.  If set, sends notifications to the SLACK channel linked to the webhook URL.
  * **TRANSCODE** Default is blank.  If set, will use the path specified as the transcoder to use.  If not specified, defaults to /usr/local/bin/plexprocess-transcode.  Script should take $1 as input file path and $2 as output file path.
  * **COMSKIP_INI** Default is /config.  Setting this changes the location of the comskip.ini files.  The standard default comskip.ini is copied from /usr/local/etc/comskip.ini into this directory at container start if it is not already there.  If this directory contains a **filters.cfg** file, this file will be parsed as a set of match statements that correspond to TV show names (some wildcard support).  The processor will use the file with the first match that succeeds, or comskip.ini if none match.

# PlexPost Manager

PlexPost now has a simple web based management GUI.  Its not secure, has no password, and is just really barebones.  But at least its there.  By default it exposes the web interface on port 8080, change it however you want in the docker-compose file.  If you really want it to be secure, add an nginx instance to the service definition and proxy it.
