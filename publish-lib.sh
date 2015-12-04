#!/bin/sh

# first update version numbers:
# resources/build.properties && js/package.json)

set -e

BUILDPROPS=resources/build.properties
VERSION=`sed -n 's/^project.version=\(.*\)$/\1/p' $BUILDPROPS`
echo "Version: $VERSION"
WEB_ONLY=0

while [ $# -ge 1 ]; do
    #echo arg: $1
    case $1 in
        -w) 
          WEB_ONLY=1  
          echo "Web-only: true"
          ;;
    esac
    shift
done
echo

ant -f resources/build.xml build.js
ant -f resources/build.xml build

git add -u                       # add all tracked files
git add web/RiTa-${VERSION}.zip  # add newly created zip file

if [ $WEB_ONLY = 1 ]
then
    echo "*** Updating web only (no tags or npm) ***" 
    git commit -am "Update to v$VERSION"
    git push
else
    echo "Updating tags and NPM to ${VERSION}"
    ~/bin/git-tag.sh ${VERSION}
    cd js && ~/bin/git-tag.sh ${VERSION} && cd ..
    ant -f resources/build.xml npm.publish
fi
exit

echo Updating remote server... # pull from github and link rita.zip
echo
ssh $RED "cd ~/git/RiTa && git checkout HEAD^ web/rita.zip && git pull && cd web && ln -fs RiTa-${VERSION}.zip rita.zip && ls -l"  
