.PHONY: test scrub

test: scrub
	swift test
	python3 -I scripts/test_chat_core_provenance.py

scrub:
	sh scripts/scrub.sh
