/*
 This source file is part of the Swift.org open source project

 Copyright 2015 - 2016 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See http://swift.org/LICENSE.txt for license information
 See http://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import struct PackageDescription.Version
import ManifestParser
import PackageType
import Utility

extension Package {
    // FIXME we *always* have a manifest, don't reparse it

    static func make(repo repo: Git.Repo) throws -> Package? {
        guard let origin = repo.origin else { throw Error.NoOrigin(repo.path) }
        let manifest = try Manifest(path: repo.path, baseURL: origin)
        let pkg = Package(manifest: manifest, url: origin)
        guard Version(pkg.versionString) != nil else { return nil }
        return pkg
    }
}

extension Package: Fetchable {
    var children: [(String, Range<Version>)] {
        return manifest.package.dependencies.map{ ($0.url, $0.versionRange) }
    }

    private var versionString: String.CharacterView {
        return path.basename.characters.dropFirst(name.characters.count + 1)
    }

    var version: Version {
        return Version(versionString)!
    }

    func constrain(to versionRange: Range<Version>) -> Version? {
        return nil
    }

    var availableVersions: [Version] {
        return [version]
    }

    func setVersion(newValue: Version) throws {
        throw Get.Error.InvalidDependencyGraph(url)
    }
}
