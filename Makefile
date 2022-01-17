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
	open ./Hitch.xcodeproj

docker:
	-DOCKER_HOST=tcp://192.168.1.209:2376 docker buildx create --name cluster --platform linux/arm64/v8 --append
	-DOCKER_HOST=tcp://192.168.1.198:2376 docker buildx create --name cluster --platform linux/amd64 --append
	-docker buildx use cluster
	-docker buildx inspect --bootstrap
	-docker login
	#docker buildx build --platform linux/amd64,linux/arm64/v8 .
	docker buildx build --platform linux/amd64 .