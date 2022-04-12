#!/bin/sh
# FROM pytorch/pytorch:1.5-cuda10.1-cudnn7-devel

# ENV LC_ALL=C.UTF-8 \
#     LANG=C.UTF-8

conda install build-essential \
cifs-utils \
curl \
default-jdk \
dialog \
dos2unix \
git \

BUILD_DIR=${1:-'.'}
mkdir -p $BUILD_DIR

# Install app requirements first to avoid invalidating the cache
cp requirements.txt $BUILD_DIR/
cp setup.py $BUILD_DIR/

cd $BUILD_DIR
python -m pip install --user -r requirements.txt --no-warn-script-location && \
python -m pip install --user entmax && \
python -c "import nltk; nltk.download('stopwords'); nltk.download('punkt')"

# Cache the pretrained BERT model
python -c "from transformers import BertModel; BertModel.from_pretrained('bert-large-uncased-whole-word-masking')"

# Download & cache StanfordNLP
mkdir -p $BUILD_DIR/third_party && \
    cd $BUILD_DIR/third_party && \
    curl https://downloads.cs.stanford.edu/nlp/software/stanford-corenlp-full-2018-10-05.zip | jar xv

# Now copy the rest of the app
cp . $BUILD_DIR/

# Assume that the datasets will be mounted as a volume into /mnt/data on startup.
# Symlink the data subdirectory to that volume.
export CACHE_DIR=${2:-"$BUILD_DIR/data"}
mkdir -p $CACHE_DIR
mkdir -p $CACHE_DIR && \
    mkdir -p $BUILD_DIR/data && \
    cd $BUILD_DIR/data && \
    ln -snf $CACHE_DIR/spider spider && \
    ln -snf $CACHE_DIR/wikisql wikisql

# Convert all shell scripts to Unix line endings, if any
/bin/bash -c 'if compgen -G "$BUILD_DIR/**/*.sh" > /dev/null; then dos2unix $BUILD_DIR/**/*.sh; fi'

# Extend PYTHONPATH to load WikiSQL dependencies
export PYTHONPATH="$BUILD_DIR/third_party/wikisql/:${PYTHONPATH}" 
