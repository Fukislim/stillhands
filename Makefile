.PHONY: help check build test app run icon docs signing clean
.DEFAULT_GOAL := help

ifeq ($(shell xcode-select -p),/Library/Developer/CommandLineTools)
TEST_FLAGS := -Xswiftc -plugin-path -Xswiftc /Library/Developer/CommandLineTools/usr/lib/swift/host/plugins/testing
endif

help:
	@printf '%s\n' \
		'make check     build with warnings as errors, then run the unit tests' \
		'make build     debug build' \
		'make test      unit tests' \
		'make app       build dist/Stillhands.app (universal) and its zip' \
		'make run       build the app and open it' \
		'make docs      re-render the screenshots in docs/images' \
		'make icon      re-draw the app icon, logo and README banners' \
		'make signing   once per machine: local signing certificate' \
		'make clean     remove build output'

check:
	swift build -Xswiftc -warnings-as-errors
	swift test $(TEST_FLAGS)

build:
	swift build

test:
	swift test $(TEST_FLAGS)

app:
	scripts/build-app.sh

run: app
	open dist/Stillhands.app

icon:
	scripts/make-icon.sh

docs: app
	scripts/render-docs.sh

signing:
	scripts/setup-signing.sh

clean:
	rm -rf .build dist
