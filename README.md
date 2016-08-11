# Requirements
 1. Docker Compose
 2. SQLite

# Usage

## Sample Usage

    # Create a project.
    $ fly project create MyProject /var/www/myproject

    # Add services.
    $ fly service create MyProject mysql bitnami/apache:latest redis php:5.6-alpine

    # Set MySQL root password as environment variable.
    $ fly container set MyProject mysql MYSQL_ROOT_PASSWORD root

    # Run your services.
    $ fly project up MyProject

    # After you're done, always bring down your services.
    $ fly project down MyProject

## Projects

### Creating

    # fly project create <unique-project-name> <project-path>
    $ fly project create MyProject /var/www/myproject

This will create the dir if it doesn't, exist, along with a `.fly/` dir.
It will also create an entry in Fly's database mapping the unique-project-name to the project-path.

### Listing

    $ fly project list

This will list all projects.

## Services
A service will run in a Docker container. A service can list another as a dependency. For example, you can define a service named `angular` and it can have `apache`, `mysql` and `redis` as a dependency.

### Discovering
If we know the names of the images we want, we can go ahead and add them. If we are unaware of what images exist, we can list them:

    $ fly service list

This displays all available services in the format `<hub-user>/<repo-name>`
The format is the same as it appears on Dockerhub.

We can also search for services:

    # fly service search <image-name>
    $ fly service search apac*

This will search for services that contain the `apach*` regexp pattern.

### Adding
Once we know what services we want to add to MyProject, we can go ahead and add them:

    # fly service create <unique-project-name> <image-name>...
    $ fly service create MyProject \
        mysql \
        bitnami/apache:latest \
        redis \
        php:5.6-alpine

> **NOTE:** This is the equivalent of manually creating a `docker-compose.yml` file.

This will create a service named `myproject` and create dependency services that use the following images:

 - mysql
 - bitnami/apache:latest
 - redis
 - php:5.6-alpine

> **NOTE:** `redis` and `php` have no `<hub-user>` component. In such cases, we will assume these are the official images.

Now, when the `myproject` is started, the added services will begin automatically since they are dependencies.

This command would create a `./fly/docker-compose.yml` file like this:

    version: '2'
    services:
        myproject:
            image: tianon/true
            depends_on:
                - mysql
                - bitnami.apache.latest
                - redis
                - php.5.6-alpine
        mysql:
            image: mysql
            env_file:
                - /var/www/myproject/.fly/mysql.env
        bitnami.apache.latest:
            image: bitnami/apache:latest
            env_file:
                - /var/www/myproject/.fly/bitnami.apache.latest.env
        redis:
            image: redis
            env_file:
                - /var/www/myproject/.fly/redis.env
        php.5.6-alpine:
            image: php:5.6-alpine
            env_file:
                - /var/www/myproject/.fly/php.5.6-alpine.env


We might change the way this works using the Docker Extends feature: 
https://docs.docker.com/compose/extends/


# Environment Variables
There are two types of environment variables:

 1. Native Fly Variables.
 2. Container Variables.

## Native Fly Variables
These environment variables are prefixed with `FLY` and are used for variable substitution in `docker-compose.yml`.

These variables should be stored in `.fly/fly.env` in the projects root dir and it should be sourced before running `docker-compose up` so that it's a Linux shell environment variable visible via the Linux `env` command.

## Container Variables
These are environment variables required by the container such as the `MYSQL_ROOT_PASSWORD` for the [MySQL](https://hub.docker.com/_/mysql/ "MySQL") image.

Also, in terms of security, it's not ideal to store passwords in text files. Ideally, the passwords would be an environment variable that your code would grab and use in your code. When we deploy out app to production, this is the desired practice we'd want. To simulate this real life situation, we can use Container Variables in our app contaner, during development, while keeping our host environment clean.

These variables should probably be stored in `.fly/<service-name>.env` in the projects root dir.


## Environment Setup (not always required)
Some images like the official MySQL image requires a Container Variable to be set, such as `MYSQL_ROOT_PASSWORD`. If this variable is not available to the MySQL container, it will not run.

The user is expected to understand the image requirements which they can do by reading the image documentation on Docker Hub. 

### Setting Container Variables
We can set this Container Variables like this:

    # fly container set <unique-project-name> <image-name> <container-env> <value>
    $ fly container set MyProject mysql MYSQL_ROOT_PASSWORD root

That will set `MYSQL_ROOT_PASSWORD=root` in `.fly/mysql.env` and will be used in creation of the container.

> **NOTE:** This variable can be overwritten as many times as you want which is why I'm using `set` as opposed to `create` (and therefore
> `update`).

We can also read a variable with:

    $ fly container get MyProject mysql MYSQL_ROOT_PASSWORD

We can also search for variables.

### Setting Service Options - TODO
The MySQL container also allows you to place an SQL file in a directory and if you mount that directory to `/docker-entrypoint-initdb.d` of the container, that SQL file will be imported into the database.

You can also mount a directory from your host machine to `/var/lib/mysql` so that the containers MySQL data files state will be saved on your host machine so that the data is not lost on exit of the container.

To make use of this feature, we have to set our service options which will be used in the `docker-compose.yml` file.

    # fly service set [<hub-user>/]<repo-name> <compose-directive> <value>
    $ fly service set mysql volumes /var/www/myproject/database/data:/var/lib/mysql
    
    $ fly service set mysql volumes /var/www/myproject/database/dump:/docker-entrypoint-initdb.d

> **NOTE:** In the above command, `<compose-directive>` can be any value allowed in the `docker-compose.yml` file that is listed in this page: https://docs.docker.com/compose/compose-file/#/volumes-volume-driver
> 
> Fly will have to understand where the command belongs (like, if it's a nested directive like `context` or `dockerfile`) and add it accordingly.

The above commands will create the appropriate entries in `.fly/fly.env` and in `docker-compose.yml`. Prior to execution of the `myproject` service, this file will be sourced so that it's available as an environment variable in the host and variable substitution will occur in the `docker-compose.yml` file.

## Running Services
Once we have everything ready to go, we just have to bring our containers up:

    # fly project up <unique-project-name>
    $ fly project up MyProject

> **NOTE:** This is the equivalent of running `docker-compose up`.

After you're done working on that project, you should always bring down your services:

    # fly project down <unique-project-name>
    $ fly project down MyProject

> **NOTE:** This is the equivalent of running `docker-compose down`.
