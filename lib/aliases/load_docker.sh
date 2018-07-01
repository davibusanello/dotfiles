# Aliases for environments running inside docker containers
# Ready images
# REPOSITORY:TAG          
# composer:1.6          
# php:7.0-alpine3.7
# php:7.1-alpine3.7
# php:7.2-alpine3.7
# postgres:10-alpine    

# PHP
IMG_COMPOSER="composer:1.6"
IMG_PHP="php:7.0-alpine3.7"


function composer () {
    docker container run -it --rm \
        --name=composer \
        -v $COMPOSER_HOME:/tmp \
        --user $(id -u):$(id -g) \
        --volume $PWD:/app \
        --volume /etc/passwd:/etc/passwd:ro \
        --volume /etc/group:/etc/group:ro \
        $IMG_COMPOSER "$@"
}

