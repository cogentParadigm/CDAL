#
# Be sure to run `pod lib lint CDAL.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "CDAL"
  s.version          = "0.1.0"
  s.summary          = "Core Data Abstraction Layer written in Swift."

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!  
  s.description      = <<-DESC
- Written in Swift
- Creates a CoreData stack and allows the end-user to choose between local and cloud storage
- Backend protocols allow additional backends to be created (local and iCloud backends included)
- Handles migrating data between local and cloud storage when needed (eg. when cloud storage is enabled and local data exists)
- Performs model migrations progressively and handles failures gracefully
                       DESC

  s.homepage         = "https://github.com/cogentParadigm/CDAL"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "Ali Gangji" => "ali@neonrain.com" }
  s.source           = { :git => "https://github.com/cogentParadigm/CDAL.git", :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'
  s.resource_bundles = {
    'CDAL' => ['Pod/Assets/*.png']
  }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
