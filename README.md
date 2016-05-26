Toaster Container
========================
This repo is to create an image that is able to setup and use Toaster from
the Yocto Project.

Running the container
---------------------
* **Determine the workdir**

  The workdir you create will be used for all output from toaster. This means
  both configuration *and* output.

  *It is important that you are the owner of the directory.* The owner of the
  directory is what determines the user id used inside the container. If you
  are not the owner of the directory, you may not have access to the files the
  container creates.

  For the rest of the instructions we'll assume the workdir chosen was
  `/home/myuser/workdir`.

* **The docker command**

  Assuming you used the *workdir* from above, the command
  to run a container for the first time would be:

  ```
  docker run -it --rm -p 127.0.0.1:18000:8000 -v /home/myuser/workdir:/workdir crops/toaster
  ```
  You should see output similar to the following:
  ```
  ### Shell environment set up for builds. ###

  You can now run 'bitbake <target>'
  
  Common targets are:
      core-image-minimal
      core-image-sato
      meta-toolchain
      meta-ide-support
  
  You can also run generated qemu images with a command like 'runqemu qemux86'
  The system will start.
  Check if toaster can listen on 0.0.0.0:8000
  OK
  /home/usersetup/poky/bitbake/bin/toaster: line 248: kill: (119) - No such process
  Operations to perform:
    Synchronize unmigrated apps: staticfiles, messages, toastermain, bldcollector, toastergui, humanize
    Apply all migrations: sessions, admin, auth, contenttypes, orm, bldcontrol
  Synchronizing apps without migrations:
    Creating tables...
      Running deferred SQL...
    Installing custom SQL...
  Running migrations:
    No migrations to apply.
  Starting webserver...
  Webserver address:  http://0.0.0.0:8000/
  Successful start.
  toasteruser@da4419478a3e:/workdir/build$
  ```
  Let's discuss some of the options:
  * **_-v /home/myuser/workdir:/workdir_**   
    The default location of the workdir inside of the container is /workdir. So
    this part of the command says to use */home/myuser/workdir* as */workdir*
    inside the container.

  * **_-p 127.0.0.1:18000:8000_**:   
    * *127.0.01* is the ip address on which the webserver will listen. This
      can be changed.
    * *18000* is the port on which the webserver will listen. This
      can be changed.
    * *8000*: is the port that is being mapped to 18000 on your local
    machine. **Do not change this value or you will not be able to access
    the webserver**.

* Accessing the Toaster webpage

  At this point you should be able to access toaster by opening the following
  url in your web browser:
  ```
  http://localhost:18000
  ```

Building the container image
----------------------------
If for some reason you want to build your own image rather than using the one
on dockerhub, then run the command below in the directory containing the
Dockerfile:

```
docker build -t crops/toaster .
```

The argument to `-t` can be whatever you choose.
