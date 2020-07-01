##
## Create an image that can be used to play with
## mathify commands.
##
## To create the image:
##    docker build -t openstax/mathify:latest .
##
## To start the container:
##    docker run --mount type=bind,source=$(pwd),target=/src -it openstax/mathify:latest /bin/bash
## where the mathify repo has been cloned into the
## current working directory.
##
## To run the code:
##    cd /src/typeset
##    node start -i <input> -c <style> -o <output>
## where <X> are filenames, e.g.:
##    node start -i ../test-simple.xhtml -o output.html
## See:
##    https://github.com/openstax/mathify
## for details.
##

FROM node:12-slim
RUN apt update
RUN apt -y install libpangocairo-1.0-0 libx11-xcb1 libxcomposite1 libxcursor1 libxdamage1 libxi6 libxtst6 libnss3 libcups2 libxss1 libxrandr2 libasound2 libatk1.0-0 libgtk-3-0

COPY . /src
WORKDIR /src/
RUN npm install
COPY ./.dockerfiles/docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]
