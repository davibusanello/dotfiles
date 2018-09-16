# Aliases for environments running inside docker containers
# Default and common Functions
function _default_docker_validations() {
    if [ "$#" -lt 1 ]; then
        echo  "Please insert at least one argument"
        exit 1
    fi
}

# Environment specific functions to use
# from inside Docker container like it was local

# PHP Composer
function composer () {
    echo "Running inside docker.."
    tty=
    tty -s && tty=--tty
    docker container run -it --rm \
        $tty \
        --name=composer \
        --user $(id -u):$(id -g) \
        -v $COMPOSER_HOME:/tmp \
        --volume $PWD:/app \
        --volume /etc/passwd:/etc/passwd:ro \
        --volume /etc/group:/etc/group:ro \
        $COMPOSER_DOCKER_IMAGE "$@"

    return $?
}

# PHP
function php_docker () {
    _default_docker_validations "$@"
    # echo "Running inside docker from image $PHP_DOCKER_IMAGE ..."
    tty=
    tty -s && tty=--tty
    docker container run -it --rm \
        $tty \
        --user $(id -u):$(id -g) \
        --network=host \
        -v "$HOME":"$HOME":ro \
        -v $COMPOSER_HOME:/tmp \
        --volume $PWD:/app:ro \
        --volume /etc/passwd:/etc/passwd:ro \
        --volume /etc/group:/etc/group:ro \
        $PHP_DOCKER_IMAGE php "$@"

    return $?

}
