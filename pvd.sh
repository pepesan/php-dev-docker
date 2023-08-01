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
    echo "  clean [OPTION]      Clean the application with the specified option."
    echo "                      Available options:"
    echo "                      - all: Clean everything (development, production, Moodle)."
    echo "                      - database: Clean the database."
    echo "                      - src: Clean the source code."
    echo "                      - help: Show this help and exit."
    echo "  -h, --help         Show this help and exit."
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

# Function to clean everything.
clean_all() {
    echo "Cleaning everything: development, production, and Moodle."
    rm -rf src
    mkdir -p src
    cp ./init/phpinfo.php src
    rm -rf db-data/*
}

# Function to clean the database.
clean_database() {
    echo "Cleaning the database."
    # Place the code for cleaning the database here.
}

# Function to clean the source code.
clean_source_code() {
    echo "Cleaning the source code."
    # Place the code for cleaning the source code here.
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
            help)
                show_help
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
    *)
        echo "Invalid command. Use '$0 --help' to see available options."
        exit 1
        ;;
esac

exit 0
