PLATFORM_IOS = iOS Simulator,name=iPhone 14 Pro
PLATFORM_MACOS = macOS

default: percentage

test-iOS:
	rm -rf "$(PWD)/DerivedData-iOS"
	xcodebuild test \
		-scheme AUv3-Support-iOS \
		-derivedDataPath "$(PWD)/DerivedData-iOS" \
		-destination platform="$(PLATFORM_IOS)"
		-enableCodeCoverage YES

coverage-iOS: test-iOS
	xcrun xccov view --report --only-targets $(PWD)/DerivedData-iOS/Logs/Test/*.xcresult > coverage_iOS.txt
	cat coverage_iOS.txt

test-macOS:
	rm -rf "$(PWD)/DerivedData-macOS"
	xcodebuild test \
		-scheme AUv3-Support-macOS \
		-derivedDataPath "$(PWD)/DerivedData-macOS" \
		-destination platform="$(PLATFORM_MACOS)" \
		-enableCodeCoverage YES

coverage-macOS: test-macOS
	xcrun xccov view --report --only-targets $(PWD)/DerivedData-macOS/Logs/Test/*.xcresult > coverage_macOS.txt
	cat coverage_macOS.txt

test: test-iOS test-macOS

coverage: coverage-iOS coverage-macOS

percentage: coverage
	awk '/ AUv3-Support / { print $$4 }' coverage_macOS.txt > percentage.txt
	cat percentage.txt
	@if [[ -n "$$GITHUB_ENV" ]]; then \
        echo "PERCENTAGE=$$(< percentage.txt)" >> $$GITHUB_ENV; \
    fi

.PHONY: test test-iOS test-macOS coverage-iOS coverage-macOS coverage percentage
