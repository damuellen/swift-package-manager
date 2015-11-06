/*
 This source file is part of the Swift.org open source project

 Copyright 2015 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See http://swift.org/LICENSE.txt for license information
 See http://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import XCTest
import POSIX
@testable import sys

class PathTests: XCTestCase {
    func test() {
        XCTAssertEqual(Path.join("a","b","c","d"), "a/b/c/d")
        XCTAssertEqual(Path.join("/a","b","c","d"), "/a/b/c/d")

        XCTAssertEqual(Path.join("/", "a"), "/a")
        XCTAssertEqual(Path.join("//", "a"), "/a")
        XCTAssertEqual(Path.join("//", "//", "/", "///", "", "/", "//", "a"), "/a")
        XCTAssertEqual(Path.join("//", "//a//"), "/a")
        XCTAssertEqual(Path.join("/////"), "/")
    }

    func testPrecombined() {
        XCTAssertEqual(Path.join("a","b/c","d/"), "a/b/c/d")
        XCTAssertEqual(Path.join("a","b///c","d/"), "a/b/c/d")

        XCTAssertEqual(Path.join("/a","b/c","d/"), "/a/b/c/d")
        XCTAssertEqual(Path.join("/a","b///c","d/"), "/a/b/c/d")
    }

    func testExtraSeparators() {
        XCTAssertEqual(Path.join("a","b/","c/","d/"), "a/b/c/d")
        XCTAssertEqual(Path.join("/a","b/","c/","d/"), "/a/b/c/d")
    }

    func testEmpties() {
        XCTAssertEqual(Path.join("a","b/","","","c//","d/", ""), "a/b/c/d")
        XCTAssertEqual(Path.join("/a","b/","","","c//","d/", ""), "/a/b/c/d")
    }

    func testNormalizePath() {
        XCTAssertEqual("".normpath, ".")
        XCTAssertEqual("foo/../bar".normpath, "bar")
        XCTAssertEqual("foo///..///bar///baz".normpath, "bar/baz")
        XCTAssertEqual("foo/../bar/./".normpath, "bar")
        XCTAssertEqual("/".normpath, "/")
        XCTAssertEqual("////".normpath, "/")
        XCTAssertEqual("/abc/..".normpath, "/")
        XCTAssertEqual("/abc/def///".normpath, "/abc/def")
        XCTAssertEqual("../abc/def/".normpath, "../abc/def")
        XCTAssertEqual("../abc/../def/".normpath, "../def")

        // Only run tests using HOME if it is defined.
        if POSIX.getenv("HOME") != nil {
            XCTAssertEqual("~".normpath, Path.home)
            XCTAssertEqual("~abc".normpath, Path.join(Path.home, "..", "abc").normpath)
        }
    }

    func testJoinWithAbsoluteReturnsLastAbsoluteComponent() {
        XCTAssertEqual(Path.join("foo", "/abc/def"), "/abc/def")
    }

    func testParentDirectory() {
        XCTAssertEqual("foo/bar/baz".parentDirectory, "foo/bar")
        XCTAssertEqual("foo/bar/baz".parentDirectory.parentDirectory, "foo")
        XCTAssertEqual("/bar".parentDirectory, "/")
        XCTAssertEqual("/".parentDirectory.parentDirectory, "/")
        XCTAssertEqual("/bar/../foo/..//".parentDirectory.parentDirectory, "/")
    }
}

class WalkTests: XCTestCase {
    func testNonRecursive() {
        var expected = ["/usr", "/bin", "/sbin"]

        for x in walk("/", recursively: false) {
            if let i = expected.indexOf(x) {
                expected.removeAtIndex(i)
            }
            XCTAssertEqual(1, x.characters.split("/").count)
        }

        XCTAssertEqual(expected.count, 0)
    }

    func testRecursive() {
        var expected = ["/usr/share/locale/UTF-8/LC_CTYPE", "/usr/share/man/man1/yes.1"]

        for x in walk("/usr/share") {
            if let i = expected.indexOf(x) {
                expected.removeAtIndex(i)
            }
            XCTAssertGreaterThanOrEqual(x.characters.split("/").count, 2)
        }

        XCTAssertEqual(expected.count, 0)
    }
}

class StatTests: XCTestCase {
    func test_isdir() {
        XCTAssertTrue("/usr".isDirectory)
        XCTAssertTrue("/etc/passwd".isFile)
    }

    func test_isfile() {
        XCTAssertTrue(!"/usr".isFile)
        XCTAssertTrue("/etc/passwd".isFile)
    }

    func test_realpath() {
        XCTAssertEqual(try! realpath("."), try! getcwd())
    }

    func test_basename() {
        XCTAssertEqual("base", "foo/bar/base".basename)
        XCTAssertEqual("base.ext", "foo/bar/base.ext".basename)
        XCTAssertNotEqual("bar", "foo/bar/base".basename)
        XCTAssertNotEqual("base.ext", "foo/bar/base".basename)
    }
}


class RelativePathTests: XCTestCase {
    func testAbsolute() {
        XCTAssertEqual("2/3", Path("/1/2/3").relative(to: "/1/"))
        XCTAssertEqual("3/4", Path("/1/2////3/4///").relative(to: "////1//2//"))
    }

    func testRelative() {
        XCTAssertEqual("3/4", Path("1/2/3/4").relative(to: "1/2"))
    }

    func testMixed() {
        XCTAssertEqual("3/4", Path(try! getcwd() + "/1/2/3/4").relative(to: "1/2"))
    }
}