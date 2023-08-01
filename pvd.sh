#!/bin/bash

# Help function that displays the usage of the script and available options.
show_help() {
    echo "Usage: $0 [COMMAND] [OPTION]"
    echo
    echo "Available commands:"
    echo "  init [OPTION]       Initialize the application with the specified option."
    echo "                      Available options:"
    echo "                      - dev: Development configuration."
    echo "                      - prod: Production configuration."
    echo "                      - moodle: Moodle-specific configuration."
    echo "                      If no option is provided, 'dev' will be used by default."
    echo "  start [OPTION]      Start the application with the specified option."
    echo "                      Available options:"
    echo "                      - dev: Development configuration."
    echo "                      - prod: Production configuration."
    echo "                      - moodle: Moodle-specific configuration."
    echo "                      If no option is provided, 'dev' will be used by default."
    echo "  stop [OPTION]       Stop the application with the specified option."
    echo "                      Available options:"
    echo "                      - dev: Development shutdown."
    echo "                      - prod: Production shutdown."
    echo "                      If no option is provided, 'dev' will be used by default."
    echo "  clean [OPTION]"
    echo "                      : Execute a command into the selected container."
    echo "                      Available options:"
    echo "                      - all: clean code and database"
    echo "                      - code: clean code"
    echo "                      - code: clean database data"
    echo "                      - help: Show this help and exit."
    echo "  container [OPTION]  Clean the application with the specified container."
    echo "                      Available options:"
    echo "                      - help: Show this help and exit."
    echo "                      - ls: List all running containers."
    echo "                      - stop  [CONTAINER_NAME]: Stop a running container."
    echo "                      - start [CONTAINER_NAME]: Start a stopped container."
    echo "                      - rm    [CONTAINER_NAME]: Remove a stopped container."
    echo "                      - exec  [CONTAINER_NAME] [CMD]: Execute a command inside a container."
    echo "  help, -h, --help    Show this help and exit."
}

# Function to initialize the application in development mode.
initialize_development() {
    echo "Initializing the application in development mode."
    # Place the code for initialization in development here.
}

# Function to initialize the application in production mode.
initialize_production() {
    echo "Initializing the application in production mode."
    # Place the code for initialization in production here.
}

# Function to initialize the application with Moodle-specific configuration.
initialize_moodle() {
    echo "Initializing the application with Moodle-specific configuration."
    mkdir -p moodle
    mkdir -p moodledata
    cp src/phpinfo.php ./moodle/
    rm -rf src
    ln -s moodle src
}

# Function to start the application in development mode.
start_development() {
    echo "Starting the application in development mode."
    docker compose up -d --force-recreate
}

# Function to start the application in production mode.
start_production() {
    echo "Starting the application in production mode."
    docker compose -f docker-compose-prod.yaml up -d --force-recreate
}

# Function to start the application with Moodle-specific configuration.
start_moodle() {
    echo "Starting the application with Moodle-specific configuration."
    docker compose -f docker-compose-moodle.yaml up -d --force-recreate
}

# Function to stop the application in development mode.
stop_development() {
    echo "Stopping the application in development mode."
    docker compose down
}

# Function to stop the application in production mode.
stop_production() {
    echo "Stopping the application in production mode."
    docker compose -f docker-compose-prod.yaml down
}

stop_moodle() {
    echo "Stopping the application in production mode."
    docker compose -f docker-compose-moodle.yaml down
}
show_clean_help(){
    # Display help for the 'container' command.
    echo "Usage: $0 clean [COMMAND]"
    echo
    echo "Available commands:"
    echo "  help            Show this help and exit."
    echo "  all             Stop a running container."
    echo "  database        Start a stopped container."
    echo "  src             Remove a stopped container."
}
# Function to clean everything.
clean_all() {
    echo "Cleaning everything: development, production, and Moodle."
    clean_source_code
    clean_database
}

# Function to clean the database.
clean_database() {
    echo "Cleaning the database."
    rm -rf db-data/*
}

# Function to clean the source code.
clean_source_code() {
    echo "Cleaning the source code."
    rm -rf src
    mkdir -p src
    cp ./init/phpinfo.php src
}
clean_containers(){
  echo "Cleaning PHP container image."
  docker image rm php-dev-docker-php
}

run_inside_docker() {
    local container_name="$1"
    shift # Remove the container name from the arguments list
    local command_to_run="$@" # Get the command to execute inside the container

    if [ -z "$container_name" ]; then
        echo "Please provide a container name as the first argument."
        show_help
        exit 1
    fi

    if [ -z "$command_to_run" ]; then
        echo "Please provide a command to execute inside the Docker container."
        show_help
        exit 1
    fi

    local docker_command="docker exec $container_name $command_to_run"
    echo "Running the command '$command_to_run' inside the Docker container '$container_name'."

    # Execute the command inside the Docker container.
    $docker_command
}

help_container(){
  # Display help for the 'container' command.
  echo "Usage: $0 container [COMMAND]"
  echo
  echo "Available commands:"
  echo "  help                                  Show this help and exit."
  echo "  ls                                    List all running containers."
  echo "  stop [CONTAINER_NAME]                 Stop a running container."
  echo "  start [CONTAINER_NAME]                Start a stopped container."
  echo "  rm [CONTAINER_NAME]                   Remove a stopped container."
  echo "  exec [CONTAINER_NAME] [CMD]           Execute a command inside a container with shell."
  echo "  unattended|un [CONTAINER_NAME] [CMD]  Execute a command inside a container unattended."
}

run_inside_container() {
    local container_name="$1"
    local command_to_run="${2:-/bin/bash}" # Default to /bin/bash if no command is provided

    if [ -z "$container_name" ]; then
        echo "Please provide a container name as the first argument."
        show_help
        exit 1
    fi

    local docker_command="docker exec -it $container_name $command_to_run"
    echo "Running the command '$command_to_run' inside the container '$container_name'."

    # Execute the command inside the Docker container.
    $docker_command
}

run_inside_container_unattended() {
    local container_name="$1"
    local command_to_run="${2:-/bin/bash}" # Default to /bin/bash if no command is provided

    if [ -z "$container_name" ]; then
        echo "Please provide a container name as the first argument."
        show_help
        exit 1
    fi

    local docker_command="docker exec $container_name $command_to_run"
    echo "Running the command '$command_to_run' inside the container '$container_name'."

    # Execute the command inside the Docker container.
    $docker_command
}

# Function to start a Docker container.
start_container() {
    local container_name="$1"

    if [ -z "$container_name" ]; then
        echo "Please provide a container name as the argument."
        show_help
        exit 1
    fi

    local docker_command="docker start $container_name"
    echo "Starting the container '$container_name'."

    # Start the Docker container.
    $docker_command
}

# Function to stop a Docker container.
stop_container() {
    local container_name="$1"

    if [ -z "$container_name" ]; then
        echo "Please provide a container name as the argument."
        show_help
        exit 1
    fi

    local docker_command="docker stop $container_name"
    echo "Stopping the container '$container_name'."

    # Stop the Docker container.
    $docker_command
}

# Function to remove a Docker container.
remove_container() {
    local container_name="$1"

    if [ -z "$container_name" ]; then
        echo "Please provide a container name as the argument."
        show_help
        exit 1
    fi

    local docker_command="docker rm $container_name"
    echo "Removing the container '$container_name'."

    # Remove the Docker container.
    $docker_command
}
ls_container(){
  docker compose ps
}

# Check if the script was invoked with no arguments or with the help option.
if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_help
    exit 0
fi

# Process the commands passed as arguments.
case "$1" in
    init)
        case "$2" in
            dev)
                initialize_development
                ;;
            prod)
                initialize_production
                ;;
            moodle)
                initialize_moodle
                ;;
            "")
                # If no option is provided, use 'dev' by default.
                initialize_development
                ;;
            *)
                echo "Invalid option for 'init' command."
                show_help
                exit 1
                ;;
        esac
        ;;
    start)
        case "$2" in
            dev)
                start_development
                ;;
            prod)
                start_production
                ;;
            moodle)
                start_moodle
                ;;
            "")
                # If no option is provided, use 'dev' by default.
                start_development
                ;;
            *)
                echo "Invalid option for 'start' command."
                show_help
                exit 1
                ;;
        esac
        ;;
    stop)
        case "$2" in
            dev)
                stop_development
                ;;
            prod)
                stop_production
                ;;
            moodle)
                            stop_moodle
                            ;;
            "")
                # If no option is provided, use 'dev' by default.
                stop_development
                ;;
            *)
                echo "Invalid option for 'stop' command."
                show_help
                exit 1
                ;;
        esac
        ;;
    clean)
        case "$2" in
            all)
                clean_all
                ;;
            database)
                clean_database
                ;;
            src)
                clean_source_code
                ;;
            containers)
                clean_containers
                ;;
            help)
                show_clean_help
                exit 0
                ;;
            "")
                echo "You must provide a suboption for the 'clean' command."
                show_help
                exit 1
                ;;
            *)
                echo "Invalid suboption for the 'clean' command."
                show_help
                exit 1
                ;;
        esac
        ;;
    container)
            # Handle container-related commands.
            case "$2" in
                help)
                    help_container
                    exit 0
                    ;;
                ls)
                    # List all running containers.
                    ls_container
                    exit 0
                    ;;
                stop)
                    # Stop a running container.
                    stop_container "$3"
                    exit 0
                    ;;
                start)
                    # Start a stopped container.
                    start_container "$3"
                    exit 0
                    ;;
                rm)
                    # Remove a stopped container.
                    remove_container "$3"
                    exit 0
                    ;;

                unattended | un)
                    # Execute a command inside a container.
                    shift 2 # Remove 'container exec' from the arguments list.
                    run_inside_container_unattended "$@"
                    exit 0
                    ;;
                exec)
                    # Execute a command inside a container.
                    shift 2 # Remove 'container exec' from the arguments list.
                    run_inside_container "$@"
                    ;;
                *)
                    echo "Invalid option for 'container' command. Use '$0 container help' to see available options."
                    exit 1
                    ;;
            esac
            ;;
    help | -h | --help)
            show_help
            exit 0
            ;;
    *)
        echo "Invalid command. Use '$0 help' to see available options."
        exit 1
        ;;
esac

exit 0
