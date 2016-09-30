Toaster Container
========================
This repo is to create an image that is able to setup and use Toaster from
the Yocto Project.

The instructions will be slightly different depending on whether Linux, Windows or Mac is used. There are setup instructions for using **Windows/Mac** at https://github.com/crops/docker-win-mac-docs/wiki. When referring to **Windows/Mac** in the rest of the document, it is assumed the instructions at https://github.com/crops/docker-win-mac-docs/wiki were followed.

Running the container
---------------------
* **Create workdir or volume**
  * **Linux**

    The workdir you create will be used for all output from toaster. This means
    both configuration *and* output. For example a user could create a directory using the command
  
    ```
    mkdir -p /home/myuser/toasterstuff
    ```

    *It is important that you are the owner of the directory.* The owner of the
    directory is what determines the user id used inside the container. If you
    are not the owner of the directory, you may not have access to the files the
    container creates.

    For the rest of the Linux instructions we'll assume the workdir chosen was
    `/home/myuser/toasterstuff`.
    
  * **Windows/Mac**

    On Windows or Mac a workdir isn't needed. Instead the volume called *myvolume* will be used. This volume should have been created when following the instructions at https://github.com/crops/docker-win-mac-docs/wiki.

* **Starting Toaster**
  * **Linux**

    Assuming you used the *workdir* from above, the command
    to run a container for the first time would be:

    ```
    docker run -it --rm -p 127.0.0.1:18000:8000 -v /home/myuser/toasterstuff:/workdir crops/toaster
    ```
  * **Mac**

    ```
    docker run -it --rm -p 127.0.0.1:18000:8000 -v myvolume:/workdir crops/toaster
    ```

  * **Windows**

    ```
    docker run -it --rm -p 0.0.0.0:18000:8000 -v myvolume:/workdir crops/toaster
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

* **Accessing the Toaster webpage**

  At this point you should be able to access toaster by opening the following
  url in your web browser:
  * **Linux/Mac**

    ```
    http://localhost:18000
    ```
  * **Windows**
  
    On *Windows* you would find the ip address to use by running ```docker-machine ip``` in the quickstart terminal. For example if that address were *192.168.99.100* you would access toaster using:
    
     ```
     http://192.168.99.100:18000
     ```
