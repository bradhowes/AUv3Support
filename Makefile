
default: coverage

build: clean
	swift build -v

test: build
	swift test -v --enable-code-coverage

LLVM_COV_ARGS = -instr-profile .build/debug/codecov/default.profdata -ignore-filename-regex='.build/|Tests/'

cov.txt: test
	set -- $$(find . -name '*.xctest'); \
    xcrun llvm-cov report $$1/Contents/MacOS/*PackageTests $(LLVM_COV_ARGS) > cov.txt
	@cat cov.txt

percentage.txt: cov.txt
	@awk '{c=$$10} END {print c}' < cov.txt > percentage.txt
	@echo "$$(< percentage.txt)"

coverage: percentage.txt
	@if [[ -n "$$GITHUB_ENV" ]]; then \
		echo "PERCENTAGE=$$(< percentage.txt)" >> $$GITHUB_ENV; \
	fi

clean:
	rm -rf cov.txt percentage.txt .build

.PHONY: build test coverage clean
