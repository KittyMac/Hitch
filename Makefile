SWIFT_BUILD_FLAGS=--configuration release

build:
	./meta/CombinedBuildPhases.sh
	swift build -v $(SWIFT_BUILD_FLAGS)

clean:
	rm -rf .build

test:
	swift test -v

update:
	swift package update

xcode:
	-killall Xcode.app
	swift package generate-xcodeproj
	meta/addBuildPhase Hitch.xcodeproj/project.pbxproj 'Hitch::Hitch' 'cd $${SRCROOT}; ./meta/CombinedBuildPhases.sh'
	sleep 2
	open ./Hitch.xcodeproj

docker:
	-docker buildx create --name local_builder
	-DOCKER_HOST=tcp://192.168.1.198:2376 docker buildx create --name local_builder --platform linux/amd64 --append
	-docker buildx use local_builder
	-docker buildx inspect --bootstrap
	-docker login
	docker buildx build --platform linux/amd64,linux/arm64 --push -t kittymac/pamphlet .
