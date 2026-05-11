class Swiftumlbridge < Formula
  desc "Generate architectural UML diagrams from Swift source"
  homepage "https://github.com/Joseph-Cursio/SwiftUMLStudio"
  url "https://github.com/Joseph-Cursio/SwiftUMLStudio/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "b44d65438c350367c89c557cd0d5ba4e4ee1cfe251358b2a05244ac949ffae38"
  license "MIT"
  head "https://github.com/Joseph-Cursio/SwiftUMLStudio.git", branch: "main"

  # Bridge's Package.swift declares swift-tools-version: 6.2 (ships with
  # Xcode 26+). The toolchain shipped with Xcode 15 / Swift 5.x will not
  # parse the manifest, so we gate explicitly.
  depends_on xcode: ["16.0", :build]
  depends_on :macos
  depends_on macos: :sequoia

  def install
    cd "SwiftUMLBridge" do
      system "swift", "build",
             "--disable-sandbox",
             "--configuration", "release",
             "--product", "swiftumlbridge"
      bin.install ".build/release/swiftumlbridge"
    end
  end

  test do
    assert_match "1.0.0", shell_output("#{bin}/swiftumlbridge --version")
    assert_match "swiftumlbridge", shell_output("#{bin}/swiftumlbridge --help")
  end
end
