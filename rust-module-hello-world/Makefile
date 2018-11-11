.PHONY: all clean rust

all: rust

clean:
	rm -f library/rust_helloworld
	cd module-src && \
	cargo clean

rust:
	cd module-src && \
	cargo build && \
	cp -v target/debug/helloworld ../library/rust_helloworld
