# A simple Pandoc machine for pandoc with filters, fonts and the latex bazaar
#
# Based on :
#    https://github.com/jagregory/pandoc-docker/blob/master/Dockerfile
#    https://github.com/geometalab/docker-pandoc/blob/develop/Dockerfile
#    https://github.com/vpetersson/docker-pandoc/blob/master/Dockerfile

FROM debian:stretch-slim

# Proxy to APT cacher: e.g. http://apt-cacher-ng.docker:3142
ARG APT_CACHER

# Set the env variables to non-interactive
ENV DEBIAN_FRONTEND noninteractive
ENV DEBIAN_PRIORITY critical
ENV DEBCONF_NOWARNINGS yes

#
# Debian
#
RUN set -x && \
    # Setup a cacher to speed up build
    if [ -n "${APT_CACHER}" ] ; then \
        echo "Acquire::http::Proxy \"${APT_CACHER}\";" | tee /etc/apt/apt.conf.d/01proxy ; \
    fi; \
    apt-get -qq update && \
    apt-get -qy install --no-install-recommends \
        # for locales and utf-8 support
        locales \
        # for deployment
        openssh-client \
        rsync \
        # for ghc (haskell compiler) cabal (haskell package manager)
        zlibc \
#        zlib1g \
#        zlib1g-dev \
        libghc-zlib-dev \
        libghc-zlib-prof \
        libghc-zlib-bindings-dev \
        libghc-zlib-bindings-prof \
        ghc \
        ghc-prof \
        ghc-doc \
        # latex toolchain
        lmodern \
        texlive \
        texlive-lang-french \
		texlive-lang-german \
        texlive-luatex \
        texlive-pstricks \
        texlive-xetex \
		xzdec \
        # reveal (see issue #18)
        netbase \
        # fonts
        fonts-lato \
		fonts-liberation \
        # build tools
        make \
        git \
        parallel \
        wget \
        unzip \
        # panflute requirements
        python3-pip \
        python3-setuptools \
        python3-wheel \
        python3-yaml \
        # required for PDF meta analysis
        poppler-utils \
		# for emojis
		librsvg2-bin \
    # add en_US Locale including UTF-8 support
    && rm -rf /var/lib/apt/lists/* \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 \
    # clean up
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/* /etc/apt/apt.conf.d/01proxy

#
# Set a Locale for UTF-8 support (in this case en_US)
#
ENV LANG en_US.UTF-8

#
# SSH pre-config / useful for Gitlab CI
#
RUN mkdir -p ~/.ssh && \
    echo "Host *\n\tStrictHostKeyChecking no\n\n" > ~/.ssh/config

#
# Add local cache/. It's empty by default so this does not change the final
# image on Docker Hub.
#
# However, once warmed with make warm-cache, it can save a lots of bandwidth.
#
ADD cache/ ./cache


#
# Install cabal-install (Haskell build manager) from sources using ghc (haskell compiler)
#
RUN wget --output-document ./cache/cabal-install-2.4.1.0.tar.gz http://hackage.haskell.org/package/cabal-install-2.4.1.0/cabal-install-2.4.1.0.tar.gz && \
    tar xvfz ./cache/cabal-install-2.4.1.0.tar.gz --directory cache/ && \
    cd ./cache/cabal-install-2.4.1.0 && sh ./bootstrap.sh
ENV PATH ${PATH}:/root/.cabal/bin/

RUN cabal --version


#
# Update to newest version of cabal (Haskell build manager)
#
#RUN cabal update \
#    && cabal install Cabal cabal-install --global
#RUN cabal --version

#
# Install Pandoc haskell filters (using cabal build manager)
# see https://github.com/lierdakil/pandoc-crossref
#
ARG PANDOC_VERSION=2.6
ARG PANDOC_CROSSREF_VERSION=0.3.4
ARG PANDOC_CITEPROC_VERSION=0.16.1
RUN cabal new-update --global
RUN echo "Inhalt der Config `cat /root/.cabal/config`"
#    && cabal sandbox init \
RUN cabal new-install --global --allow-newer \
#        pandoc-${PANDOC_VERSION} \
        pandoc \
        pandoc-crossref \
        pandoc-citeproc
#        pandoc-crossref-${PANDOC_CROSSREF_VERSION} \
 #       pandoc-citeproc-${PANDOC_CITEPROC_VERSION}


#
# Install pandoc from upstream. Debian package is too old.
# Cabal also installed an old Pandoc version that will be overwritten here on purpose
#
# ARG PANDOC_VERSION=2.6
# ADD fetch-pandoc.sh /usr/local/bin/
# RUN fetch-pandoc.sh ${PANDOC_VERSION} ./cache/pandoc.deb && \
#     dpkg --install ./cache/pandoc.deb && \
#     rm -f ./cache/pandoc.deb

#
# Install Pandoc python filters
#
ADD requirements.txt ./
RUN pip3 --no-cache-dir install --find-links file://${PWD}/cache -r requirements.txt


#
# eisvogel template
#
ARG TEMPLATES_DIR=/root/.pandoc/templates
RUN mkdir -p ${TEMPLATES_DIR} && \
    wget https://raw.githubusercontent.com/Wandmalfarbe/pandoc-latex-template/master/eisvogel.tex -O ${TEMPLATES_DIR}/eisvogel.latex
RUN tlmgr init-usertree && \
    tlmgr install ly1 inconsolata sourcesanspro sourcecodepro mweights noto

#
# emojis support for latex
# https://github.com/mreq/xelatex-emoji
#
ARG TEXMF=/usr/share/texmf/tex/latex/
ARG EMOJI_DIR=/tmp/twemoji
RUN git clone --single-branch --depth=1 --branch gh-pages https://github.com/twitter/twemoji.git $EMOJI_DIR && \
	# fetch xelatex-emoji
	mkdir -p ${TEXMF} && \
    cd ${TEXMF} && \
    git clone --single-branch --branch images https://github.com/daamien/xelatex-emoji.git && \
	# convert twemoji SVG files into PDF files
    cp -r $EMOJI_DIR/2/svg xelatex-emoji/images && \
	cd xelatex-emoji/images && \
	../bin/convert_svgs_to_pdfs ./*.svg && \
	# clean up
	rm -f *.svg && \
	rm -fr ${EMOJI_DIR} && \
	# update texlive
	cd ${TEXMF} && \
	texhash

VOLUME /pandoc
WORKDIR /pandoc

# Compatibility with Pandoc 1.x arguments
# use `--entrypoint=pandoc1.sh` to activate it
ADD pandoc1.sh /usr/local/bin

ENTRYPOINT ["pandoc"]
