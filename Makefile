.PHONY: test scrub

test: scrub
	swift test

scrub:
	sh scripts/scrub.sh
