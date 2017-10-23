#! /usr/bin/env bash

VERSION:=$(shell grep Version: DESCRIPTION|sed 's/Version: //')
NAME:=$(shell grep Package: DESCRIPTION|sed 's/Package: //')
PACKAGEFILE:=../$(NAME)_$(VERSION).tar.gz

all: $(PACKAGEFILE) README.md

.PHONY: all install

install:
	R -e 'devtools::install_bitbucket("ahwbest/dr4pl")'	

localInstall:
	R -e 'devtools::install()'

man: R/*.R 
	R -e 'devtools::document()'
	touch man


inst/doc: vignettes/*.Rnw R/*.R
	R -e 'devtools::build_vignettes()'
	touch inst/doc inst/image

README.md: README.Rmd R/*.R
	make localInstall
	R -e 'knitr::opts_chunk$$set(fig.path="inst/image/");knitr::knit("README.Rmd")'
	sed '/^---$$/,/^---$$/d' README.md --in-place
	
$(PACKAGEFILE): man R/*.R DESCRIPTION inst/doc
	sed -i "s/^Date:.*$$/Date: `date +%Y-%m-%d`/" DESCRIPTION
	R -e 'devtools::check(cran=TRUE);devtools::build()'
