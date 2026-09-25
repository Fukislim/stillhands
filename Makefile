.PHONY: build test app run icon docs signing clean

build:
	swift build

ifeq ($(shell xcode-select -p),/Library/Developer/CommandLineTools)
TEST_FLAGS := -Xswiftc -plugin-path -Xswiftc /Library/Developer/CommandLineTools/usr/lib/swift/host/plugins/testing
endif

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
