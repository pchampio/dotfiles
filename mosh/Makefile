# This is an upgrade of the script made by zmil...@cs.wisc.edu that does do
# some error checking as it works.
# TODO: version number variables, make shell script to download this and build it on remote host,
#       possibly use the protobuf files that seem to ship with mosh?

.PHONY: all clean
.PRECIOUS: %.tar.gz
.SECONDARY: mosh-1.3.2.tar.gz protobuf-2.6.1.tar.gz protoc

all: ${HOME}/dotfiles/bin/mosh

clean:
	echo 'rm stuff'

${HOME}/dotfiles/bin/mosh: ${HOME}/.mosh/local/bin/mosh
	ln -f $< $@

${HOME}/.mosh/local/bin/mosh: ${HOME}/.mosh/build/mosh-1.3.2/Makefile
	cd $(<D) && \
		export PROTOC=${HOME}/.mosh/local/bin/protoc && \
		export protobuf_CFLAGS=${HOME}/.mosh/local/include && \
		export protobuf_LIBS=${HOME}/.mosh/local/lib/libprotobuf.a && \
		make VERSION && \
		cd scripts && \
		make install

${HOME}/.mosh/build/mosh-1.3.2/Makefile: ${HOME}/.mosh/downloads/mosh-1.3.2.tar.gz ${HOME}/.mosh/local/bin/protoc
	tar axf $< -C ${HOME}/.mosh/build/
	cd $(@D) && \
		export PROTOC=${HOME}/.mosh/local/bin/protoc && \
		export protobuf_CFLAGS=${HOME}/.mosh/local/include && \
		export protobuf_LIBS=${HOME}/.mosh/local/lib/libprotobuf.a && \
		./configure --prefix=${HOME}/.mosh/local

${HOME}/.mosh/local/bin/protoc: ${HOME}/.mosh/build/protobuf-2.6.1/Makefile
	cd ${HOME}/.mosh/build/protobuf-2.6.1 && make install

${HOME}/.mosh/build/protobuf-2.6.1/Makefile: ${HOME}/.mosh/downloads/protobuf-2.6.1.tar.gz
	mkdir -p ${HOME}/.mosh/build/
	mkdir -p ${HOME}/.mosh/local/
	tar axf $< -C ${HOME}/.mosh/build/
	cd $(@D) && ./configure --prefix=${HOME}/.mosh/local --disable-shared

${HOME}/.mosh/downloads/mosh-1.3.2.tar.gz:
	mkdir -p $(@D)
	wget -O $@ https://mosh.mit.edu/mosh-1.3.2.tar.gz

${HOME}/.mosh/downloads/protobuf-2.6.1.tar.gz:
	mkdir -p $(@D)
	wget -O $@ https://github.com/google/protobuf/releases/download/v2.6.1/protobuf-2.6.1.tar.gz
