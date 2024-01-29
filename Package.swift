// swift-tools-version:5.9
import PackageDescription

let package = Package(
	name: "endpoint-builder-urlsession",
	platforms: [
		.iOS(.v13),
		.tvOS(.v13),
		.macOS(.v10_15),
		.watchOS(.v6),
		.visionOS(.v1)
	],
	products: [
		.library(name: "EndpointBuilderURLSession", targets: ["EndpointBuilderURLSession"])
	],
	dependencies: [
		.package(url: "https://github.com/apple/swift-http-types", from: "1.0.0"),
		.package(url: "https://github.com/pixel-foundry/endpoint-builder", from: "0.0.2")
	],
	targets: [
		.target(
			name: "EndpointBuilderURLSession",
			dependencies: [
				.product(name: "EndpointBuilder", package: "endpoint-builder"),
				.product(name: "HTTPTypes", package: "swift-http-types")
			]
		),
		.testTarget(
			name: "EndpointBuilderURLSessionTests",
			dependencies: [
				.byName(name: "EndpointBuilderURLSession")
			]
		)
	]
)
