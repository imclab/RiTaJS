#/bin/sh

set -e # die on errors 

if [ $# -lt "1"  ]
then
    echo
    echo "  error:   tag or version required"
    echo
    echo "  usage:   make-lib.sh [tag] [-p -D -M] "
    echo "           make-lib.sh 1.0.63a -p -D -M"
    echo
    echo "  options:"
    echo "       -p = publish-after-build "
    echo "       -D = dont-make-docs"
    echo "       -M = dont-minimize-lib"
    echo "       -Z = dont-make-zip"
    echo "       -F = do fake-minimize"
    echo "       -c = -DMZ (just combine js)" 
    exit
fi

VERSION=$1
MAKE_ZIP=1
DO_PUBLISH=0
INCLUDE_DOCS=1
MINIMIZE_SRC=1
FAKE_MINIMIZE=0
LINE="------------------------------------------------------"

while [ $# -ge 1 ]; do
    case $1 in
        -D) INCLUDE_DOCS=0  ;;
    esac
    case $1 in
        -Z) MAKE_ZIP=0  ;;
    esac
    case $1 in
        -p) DO_PUBLISH=1  ;;
    esac
    case $1 in
        -M) MINIMIZE_SRC=0  ;;
    esac
    case $1 in
        -F) FAKE_MINIMIZE=1  ;;
    esac
    case $1 in
        -c) MINIMIZE_SRC=0  
            INCLUDE_DOCS=0
            MAKE_ZIP=0  
            ;;
    esac
    shift
done
#echo "DOCS=$INCLUDE_DOCS"
#echo "PUB=$DO_PUBLISH"
#echo "MIN=$MINIMIZE_SRC"

##############################################################

BUILD=../build
DOWNLOAD_INDEX=$BUILD/www/download/index.html
COMPILE="java -jar ../tools/compiler-latest/compiler.jar"

JSDOC=../tools/jsdoc-toolkit
SRC_VERSIONED=/tmp/rita-versioned.js
ALL_SRC="../src/rita_dict.js ../src/rita_lts.js ${SRC_VERSIONED}"

DOWNLOAD_DIR=../www/download
LIB_DIR=../www/js
DIST_DIR=../dist
REF_DIR=../www/reference
RITA_CODE=$DOWNLOAD_DIR/rita-$VERSION.js
RITA_CODE_MIN=$DOWNLOAD_DIR/rita-$VERSION.min.js

ZIP_TMP=/tmp/rita-$VERSION
ZIP_FILE=ritajs-full-$VERSION.zip

P5_LIB=~/Documents/Processing/libraries/RiTa/library/rita.js
LATEST=~/Documents/eclipse-workspace/RiTa/latest/rita.js

echo
echo "Building RiTaJS v$VERSION ------------------------------"
echo

###COMPILE-JS###################################################

echo Removing rita.js 
echo   from $P5_LIB
rm -f $P5_LIB
echo   from $LATEST
rm -f $LATEST
echo

echo Copying rita.js to $SRC_VERSIONED
cp ../src/rita.js $SRC_VERSIONED
sed -i "" "s/##version##/${VERSION}/g" $SRC_VERSIONED

rm -f $RITA_CODE
echo "Combining rita-*.js as ${RITA_CODE}" 
cat $ALL_SRC >> $RITA_CODE
echo

rm -f $RITA_CODE_MIN
if [ $MINIMIZE_SRC = 1 ]
then
    if [ $FAKE_MINIMIZE = 1 ]
    then
        FILE=/tmp/rita-$VERSION.min.js
        echo "Copying $FILE to ${RITA_CODE}"
        cp $FILE $RITA_CODE_MIN || exit !?
    else
        echo "Compiling rita-*.js as ${RITA_CODE_MIN}"; 
        $COMPILE --js  ${ALL_SRC} --js_output_file $RITA_CODE_MIN --summary_detail_level 3 \
           --compilation_level SIMPLE_OPTIMIZATIONS  #ADVANCED_OPTIMIZATIONS
    fi
else
    echo
    echo Skipping minimization
fi

###MAKE-DOCS#######################################################

if [ $INCLUDE_DOCS = 1 ]
then
    echo $LINE
    echo Building js-docs...
    #rm -rf $REF_DIR/*
    #java -Xmx512m -jar $JSDOC/jsrun.jar $JSDOC/app/run.js -d=$REF_DIR -a \
    #    -t=$JSDOC/templates/ritajs -D="status:alpha" -D="version:$VERSION" $SRC > docs-err.txt 
   ./make-docs.sh 
else
    echo $LINE
    echo Skipping docs...
fi


###EXAMPLES##########################################################

#echo
#echo Copying examples
#echo

###JS_FULL_ZIP#######################################################

#if [ $INCLUDE_DOCS = 1 ]
#then
#    echo Making complete zip 
#    rm -rf $ZIP_TMP
#    mkdir $ZIP_TMP
#    cd ../www
#    cp -r examples js download/*.js reference tutorial css $ZIP_TMP

#    ### make the zip
#    cd - 
#    cd $ZIP_TMP
#    jar cf $ZIP_FILE *
#    cd -
#    mv $ZIP_TMP/$ZIP_FILE $DOWNLOAD_DIR
#    rm -rf $ZIP_TMP
#    echo $LINE
#fi

###COPY->BUILD#######################################################

echo Copying into $BUILD 

rm -rf $BUILD
mkdir $BUILD
cp -r ../www $BUILD
sed -i "" "s/##version##/${VERSION}/g" $DOWNLOAD_INDEX 
#ls -l $BUILD

###COPY-P5_LIB#######################################################

####### 2 jars here? ################################################

echo $LINE
echo Copying $RITA_CODE 
echo " -> $P5_LIB"  # libraries dir
cp $RITA_CODE $P5_LIB

###COPY-RITA.LATEST##################################################
if [ $MINIMIZE_SRC = 1 ]
then
    echo " -> $LATEST"  # lib
    cp $RITA_CODE_MIN $LATEST
    #less $RITA_CODE_MIN
fi

###COPY-www/js(for RiTaBanner#########################################
echo " -> $LIB_DIR/"
cp $RITA_CODE_MIN $LIB_DIR/rita.js
echo $LINE

######################################################################

ls ../build/www/js/

echo $LINE
echo Done [use pub-jslib.sh [-r] to publish]

if [ $DO_PUBLISH = 1 ]
then
./pub-jslib.sh $VERSION
fi

