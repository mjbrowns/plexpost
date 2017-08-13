
PWD=$(shell pwd)
MYUID=$(shell id -u)
MYGID=$(shell id -g)
ME=$(shell id -un)
SRC=src
WRK=workdir
SOURCE=$(PWD)/$(SRC)
TARGET=$(PWD)/$(WRK)
BUILD=$(PWD)/build
LOGS=$(PWD)/logs
BUILDENV=buildenv
PLEXPOST=$(ME)/plexpost
TINYCGI=$(TARGET)/usr/local/bin/tinycgi
COMCHAP=$(TARGET)/usr/local/bin/comchap
COMCUT=$(TARGET)/usr/local/bin/comcut
COMSKIP=$(TARGET)/usr/local/bin/comskip
SLACKPOST=$(TARGET)/usr/local/bin/slackpost

BUILDENVID != docker image ls -q $(BUILDENV):latest
ifdef BUILDENVID
MAKEBUILD=$(TARGET)
else
MAKEBUILD=makebuildenv
endif
ifneq (,$(findstring B,$(MAKEFLAGS)))
MAKEBUILD=makebuildenv
endif

all: prepare $(PLEXPOST)

clean:
	$(RM) -r $(TARGET)
	$(RM) -r $(LOGS)

blank: ;

prepare: $(MAKEBUILD)
	@mkdir -p $(LOGS)
	@mkdir -p $(TARGET)

makebuildenv: prepare Dockerfile.buildenv
	docker build --pull --tag $(BUILDENV):latest -f Dockerfile.$(BUILDENV) . 2>&1 | tee $(LOGS)/build-buildenv.log

$(BUILDENV): $(MAKEBUILD) ;

tinycgi: $(TINYCGI)
	ls -l $(TINYCGI)

$(TINYCGI): src/tinycgi.go build/make-tinycgi
	docker run --rm --name build-tinycgi -it \
        -v $(BUILD):/tmp/build \
		-v $(SOURCE):/tmp/src \
		-v $(TARGET):/tmp/out \
		-u $(MYUID):$(MYGID) \
        buildenv bash -c /tmp/build/make-tinycgi $(PACK) | tee $(LOGS)/build-tinycgi.log

comchap: prepare $(COMCHAP)
comcut: prepare $(COMCUT)

$(COMCUT): $(COMCHAP)
$(COMCHAP): build/make-comchap
	docker run --rm --name build-comchap -it \
        -v $(BUILD):/tmp/build \
		-v $(SOURCE):/tmp/src \
		-v $(TARGET):/tmp/out \
		-u $(MYUID):$(MYGID) \
        buildenv bash -c /tmp/build/make-comchap | tee $(LOGS)/build-comchap.log

comskip: prepare $(COMSKIP)
$(COMSKIP): build/make-comskip
	docker run --rm --name build-comskip -it \
        -v $(BUILD):/tmp/build \
		-v $(SOURCE):/tmp/src \
		-v $(TARGET):/tmp/out \
		-u $(MYUID):$(MYGID) \
        buildenv bash -c /tmp/build/make-comskip | tee $(LOGS)/build-comskip.log

slackpost: prepare $(SLACKPOST)
$(SLACKPOST): build/make-slackpost
	docker run --rm --name build-slackpost -it \
        -v $(BUILD):/tmp/build \
		-v $(SOURCE):/tmp/src \
		-v $(TARGET):/tmp/out \
		-u $(MYUID):$(MYGID) \
        buildenv bash -c /tmp/build/make-slackpost $(PACK) | tee $(LOGS)/build-slackpost.log

$(TARGET)/init: 
	build/get-s6 $(TARGET) 2>&1 | tee $(LOGS)/get-s6.log

s6: prepare $(TARGET)/init

prepare: prepare $(TARGET)/init $(TINYCGI) $(COMCHAP) $(COMCUT) $(SLACKPOST) 

docker: prepare $(TARGET) $(SOURCE)
	docker build --build-arg=WRKDIR=$(WRK) --build-arg=SRCDIR=$(SRC) --pull --tag $(PLEXPOST):latest -f Dockerfile.plexpost . 2>&1 | tee $(LOGS)/build-plexpost.log

$(PLEXPOST): $(TARGET)/init $(TINYCGI) $(COMCHAP) $(COMCUT) $(SLACKPOST) docker

push: $(PLEXPOST)
ifndef VERSION
	@echo You must specify a version to push
	@echo use: make VERSISON=1.99
else
	docker tag $(PLEXPOST):latest $(PLEXPOST):$(VERSION)
	docker push $(PLEXPOST):latest
	docker push $(PLEXPOST):$(VERSION)
endif
