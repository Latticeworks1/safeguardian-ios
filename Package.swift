// swift-tools-version: 5.9
// Package.swift for SafeGuardian with llama.cpp Integration

import PackageDescription

let package = Package(
    name: "SafeGuardian",
    platforms: [
        .iOS(.v17), // iOS 17+ required for advanced features
        .macOS(.v14) // macOS support for development
    ],
    products: [
        .library(
            name: "SafeGuardian",
            targets: ["SafeGuardian"]
        )
    ],
    dependencies: [
        // MARK: - llama.cpp Integration
        
        // Primary llama.cpp Swift wrapper - Production ready
        .package(
            url: "https://github.com/ShenghaiWang/SwiftLlama.git",
            from: "0.4.0"
        ),
        
        // Alternative academic implementation (commented out - choose one)
        // .package(
        //     url: "https://github.com/StanfordBDHG/llama.cpp",
        //     .upToNextMinor(from: "0.1.0")
        // ),
        
        // Additional AI/ML utilities if needed
        // .package(
        //     url: "https://github.com/apple/swift-transformers.git",
        //     from: "0.1.0"
        // ),
        
        // MARK: - Networking and Communication
        
        // For enhanced networking capabilities
        .package(
            url: "https://github.com/apple/swift-nio.git",
            from: "2.65.0"
        ),
        
        // MARK: - Utility Libraries
        
        // Async algorithms for streaming
        .package(
            url: "https://github.com/apple/swift-async-algorithms.git",
            from: "1.0.0"
        ),
        
        // Collections for optimized data structures
        .package(
            url: "https://github.com/apple/swift-collections.git",
            from: "1.1.0"
        )
    ],
    targets: [
        .target(
            name: "SafeGuardian",
            dependencies: [
                // llama.cpp integration
                .product(name: "SwiftLlama", package: "SwiftLlama"),
                
                // Alternative Stanford package (commented out)
                // .product(name: "llama", package: "llama.cpp"),
                
                // Networking
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOCore", package: "swift-nio"),
                
                // Async utilities
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
                
                // Collections
                .product(name: "Collections", package: "swift-collections")
            ],
            path: "Sources/SafeGuardian",
            swiftSettings: [
                // Enable C++ interoperability for llama.cpp (if using Stanford package)
                // .interoperabilityMode(.Cxx),
                
                // Concurrency settings
                .enableUpcomingFeature("BareSlashRegexLiterals"),
                .enableUpcomingFeature("ConciseMagicFile"),
                .enableUpcomingFeature("ForwardTrailingClosures"),
                .enableUpcomingFeature("StrictConcurrency"),
                
                // Optimization for production
                .define("SWIFT_PACKAGE"),
                .define("SAFEGUARDIAN_LLAMA_CPP", .when(configuration: .release))
            ],
            linkerSettings: [
                // Metal framework for GPU acceleration
                .linkedFramework("Metal"),
                .linkedFramework("MetalKit"),
                .linkedFramework("MetalPerformanceShaders"),
                
                // Core frameworks
                .linkedFramework("Foundation"),
                .linkedFramework("Network"),
                .linkedFramework("AVFoundation"),
                .linkedFramework("Speech"),
                .linkedFramework("Vision")
            ]
        ),
        
        // MARK: - Test Targets
        
        .testTarget(
            name: "SafeGuardianTests",
            dependencies: [
                "SafeGuardian",
                .product(name: "SwiftLlama", package: "SwiftLlama")
            ],
            path: "Tests/SafeGuardianTests",
            swiftSettings: [
                .define("TESTING")
            ]
        ),
        
        // MARK: - Performance Test Target
        
        .testTarget(
            name: "SafeGuardianPerformanceTests",
            dependencies: [
                "SafeGuardian"
            ],
            path: "Tests/PerformanceTests",
            swiftSettings: [
                .define("PERFORMANCE_TESTING")
            ]
        ),
        
        // MARK: - Example/Demo Target
        
        .executableTarget(
            name: "SafeGuardianDemo",
            dependencies: [
                "SafeGuardian"
            ],
            path: "Examples/Demo",
            swiftSettings: [
                .define("DEMO_MODE")
            ]
        )
    ]
)

#if canImport(PackageDescription)
// MARK: - Platform-specific Configuration

#if os(iOS)
// iOS-specific optimizations
package.targets.forEach { target in
    if target.name == "SafeGuardian" {
        target.swiftSettings?.append(contentsOf: [
            .define("IOS_OPTIMIZED"),
            .define("METAL_ACCELERATION_AVAILABLE")
        ])
    }
}
#endif

#if os(macOS)
// macOS development optimizations
package.targets.forEach { target in
    if target.name == "SafeGuardian" {
        target.swiftSettings?.append(contentsOf: [
            .define("MACOS_DEVELOPMENT"),
            .define("FULL_METAL_SUPPORT")
        ])
    }
}
#endif

#endif