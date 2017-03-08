# plexpost
Docker based plex + postprocessor that handles commercial cutting and transcoding

# Overview

I'm a plexpass subscriber and I've just started leveraging the (still-in-beta) DVR capabilities of plex.  I am also a docker user and I started using the official docker plex implementation as soon as it came out.

This project leverages docker and docker-compose to create a service of two containers:

1. The standard plexpass container, modified by injecting my postprocessing script (in *src/plexpost*)
2. My "plexpost" container, which detects new recordings and processes them according to a variety of settings

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

If you are familiar with the docker-compose system (*recommended*), you will see a volume created called "queue".  This volume is mapped by both containers (*plex* and *plexpost*).  The postprocessing script will create an entry in the queue container.  The plexpost container will then detect that the entry is there and it will do its work.

# Sources
In addition to the official plex:plexpass docker image, i'm leveraging components from other contributors.  Many thanks to these for the fantastic work they have done, without which this project would not have happened.
* comskip by [**Erik Kaashoek**](http://github.com/erikkaashoek/Comskip)
* The comchap/comcut scripts by [**BrettSheleski**](http://github.com/BrettSheleski/comchap)

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

  /usr/local/bin/plexpost

# docker-compose.yml Configuration
