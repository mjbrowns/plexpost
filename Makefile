
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
BUILDENV=mbrown/buildenv
PLEXPOST=$(ME)/plexpost
TINYCGI=$(TARGET)/usr/local/bin/tinycgi
COMCHAP=$(TARGET)/usr/local/bin/comchap
COMCUT=$(TARGET)/usr/local/bin/comcut
COMSKIP=$(TARGET)/usr/local/bin/comskip
SLACKPOST=$(TARGET)/usr/local/bin/slackpost
DIRS=$(TARGET) $(LOGS)
ELEMENTS=$(TARGET)/init $(TINYCGI) $(COMCHAP) $(COMCUT) $(COMSKIP) $(SLACKPOST) 

all: $(PLEXPOST) 

.PHONY: clean
clean: 
	$(RM) -r $(DIRS)

tinycgi: $(TINYCGI)

$(TINYCGI): src/tinycgi.go build/make-tinycgi
	mkdir -p $(DIRS)
	docker run --rm --name build-tinycgi -it \
        -v $(BUILD):/tmp/build \
		-v $(SOURCE):/tmp/src \
		-v $(TARGET):/tmp/out \
		-u $(MYUID):$(MYGID) \
        $(BUILDENV) bash -c "/tmp/build/make-tinycgi $(PACK)" | tee $(LOGS)/build-tinycgi.log

comchap: $(COMCHAP)
comcut: $(COMCUT)

$(COMCUT): $(COMCHAP)
$(COMCHAP): build/make-comchap
	mkdir -p $(DIRS)
	docker run --rm --name build-comchap -it \
        -v $(BUILD):/tmp/build \
		-v $(SOURCE):/tmp/src \
		-v $(TARGET):/tmp/out \
		-u $(MYUID):$(MYGID) \
        $(BUILDENV) bash -c /tmp/build/make-comchap | tee $(LOGS)/build-comchap.log

comskip: $(COMSKIP)
$(COMSKIP): build/make-comskip
	mkdir -p $(DIRS)
	docker run --rm --name build-comskip -it \
        -v $(BUILD):/tmp/build \
		-v $(SOURCE):/tmp/src \
		-v $(TARGET):/tmp/out \
		-u $(MYUID):$(MYGID) \
        $(BUILDENV) bash -c /tmp/build/make-comskip | tee $(LOGS)/build-comskip.log

slackpost: $(SLACKPOST)
$(SLACKPOST): build/make-slackpost
	mkdir -p $(DIRS)
	docker run --rm --name build-slackpost -it \
        -v $(BUILD):/tmp/build \
		-v $(SOURCE):/tmp/src \
		-v $(TARGET):/tmp/out \
		-u $(MYUID):$(MYGID) \
        $(BUILDENV) bash -c "/tmp/build/make-slackpost $(PACK)" | tee $(LOGS)/build-slackpost.log

s6: $(TARGET)/init
$(TARGET)/init: 
	mkdir -p $(DIRS)
	build/get-s6 $(TARGET) 2>&1 | tee $(LOGS)/get-s6.log

prepare: $(ELEMENTS)

docker: $(ELEMENTS)
	docker build --build-arg=WRKDIR=$(WRK) --build-arg=SRCDIR=$(SRC) --pull --tag $(PLEXPOST):latest . 2>&1 | tee $(LOGS)/build-plexpost.log

$(PLEXPOST): docker 

push: $(PLEXPOST)
ifndef VERSION
	@echo You must specify a version to push
	@echo use: make VERSISON=1.99
else
	docker tag $(PLEXPOST):latest $(PLEXPOST):$(VERSION)
	docker push $(PLEXPOST):latest
	docker push $(PLEXPOST):$(VERSION)
endif
