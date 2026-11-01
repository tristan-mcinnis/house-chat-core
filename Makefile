.PHONY: help build test scrub

SWIFT_FLAGS := -Xswiftc -warnings-as-errors

help:
	@echo "make build   swift build, warnings are errors"
	@echo "make test    scrub gate, then swift test, warnings are errors"
	@echo "make scrub   scrub gate only"
	@echo "No install target: this is a library with no installed artifact."

build:
	swift build $(SWIFT_FLAGS)

test: scrub
	swift test $(SWIFT_FLAGS)

scrub:
	sh scripts/scrub.sh
