# pandocker - A Docker Image for Pandoc with multiple pandoc-filters


A simple docker image for pandoc 2.6 with filters, templates, fonts and the
latex bazaar deriving from pip3 (python) and cabal (haskell) repositories.


Based on the great image of https://github.com/dalibo/pandocker and extended with new python and haskell based pandoc filters.

Following pandoc filters are supported:

+ haskell based
    + pandoc-crossref
    + pandoc-siteproc
+ python based
    + panflute
    + pandocfilters
    + pandoc-latex-admonition
    + pandoc-latex-environment
    + pandoc-latex-barcode
    + pandoc-latex-levelup
    + pandoc-mustache
    + pandoc-dalibo-guidelines
    + pypdf2
    + pandoc-minted
    + pygments
    + pandoc-include


## How To

As of right now, this image is not available at the registry https://hub.docker.com/.

Therefore, it needs to be built first using `docker build`. Depending on the machine, this could take up to 1 hour.

## Build it

+ Install docker from https://www.docker.com/get-started.
+ Run `docker build -tag misamura/pandocker .` from the base path of this git project.


### Run it

Run `misamura/pandocker`  with regular `pandoc` args. Mount your files at `/pandoc`.

``` console
$ docker run --rm -u `id -u`:`id -g` -v `pwd`:/pandoc misamura/pandocker README.md README.pdf
```

Tip: use a shell alias to use `pandocker` just like `pandoc`.
Add this to your `~/.bashrc` :

``` console
$ alias pandoc="docker run --rm -u `id -u`:`id -g` -v `pwd`:/pandoc misamura/pandocker"
$ pandoc document.md
```

Note: if SELinux is enabled on you system, you might need to add the
`--privileged` tag to force access to the mouting points. See
https://docs.docker.com/engine/reference/run/#runtime-privilege-and-linux-capabilities .

Note: When using the ["pandoc-include"](https://pypi.org/project/pandoc-include) filter to include other files, the working directory `pwd` to mount in docker *should* be a common parent directory of all referenced files to include. As `!include [mypath/myfile.md]` statements within markdown *should* be relative paths, the docker arg `--workdir="my/path/to/markdownfolder"` should be used to name the folder that the markdown file including the includes resides in. Full working example: `docker run --rm -v $(pwd):/pandoc --workdir="/pandoc/my/sub/folder/to-markdown-file" misamura/pandocker --filter pandoc-include --pdf-engine=xelatex --template=eisvogel --listings --toc --toc-depth=3 ./myfile.md -o myfile-generated.pdf'`


## Embedded template : Eisvogel

We're shipping a latex template inside the image so that you can produce a
nice PDF without installing anything.  The template is called [eisvogel] and
you can use it simply by adding `--template=eisvogel` to your compilation
lines:

``` console
$ docker run [...] --pdf-engine=xelatex --template=eisvogel foo.md -o foo.pdf
```

✋ W**Warning:** you need to remove the `-u` option when using [eisvogel].

[eisvogel]: https://github.com/Wandmalfarbe/pandoc-latex-template 
