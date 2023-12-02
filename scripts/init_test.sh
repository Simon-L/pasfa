#! /bin/bash

dir=$(mktemp -d)
cd ${dir}

wget https://raw.githubusercontent.com/Simon-L/pasfa/main/config.lua
touch db.sqlite

conf=$(realpath config.lua)
db=$(realpath db.sqlite)

echo "Folder ready, Ctrl-C now to edit and run docker later, press Enter to execute:"
echo "docker run --name pasfa-$(basename ${dir}) -p 8080:8080"
echo    "   -v ${conf}:/root/work/config.lua"
echo    "   -v ${db}:/root/work/pasfa.sqlite"
echo    "   -it pasfa:latest"
read -n1

docker run --name pasfa-$(basename ${dir}) -p 8080:8080 \
    -v ${conf}:/root/work/config.lua \
    -v ${db}:/root/work/pasfa.sqlite \
    -it fergusl2/pasfa:latest

echo "Ready in ${dir} with ${conf} and ${db}"
docker ps -a | grep pasfa-$(basename ${dir})