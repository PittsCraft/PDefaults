#
# Be sure to run `pod lib lint PDefaults.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'PDefaults'
  s.version          = '0.1.0'
  s.summary          = 'Combiny, concise and strong UserDefaults property wrapper'
  s.swift_version    = '5.4'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  SwiftUI and Combine friendly property wrapper for UserDefaults, designed for performance and concision.
                       DESC

  s.homepage         = 'https://github.com/PittsCraft/PDefaults'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Pierre Mardon' => 'pierre@pittscraft.com' }
  s.source           = { :git => 'https://github.com/PittsCraft/PDefaults.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'
  s.osx.deployment_target  = '10.15'
  s.ios.deployment_target = '13.0'

  s.source_files = 'PDefaults/Classes/**/*'
  
  # s.resource_bundles = {
  #   'PDefaults' => ['PDefaults/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.frameworks = 'Combine'
  # s.dependency 'AFNetworking', '~> 2.3'
end
