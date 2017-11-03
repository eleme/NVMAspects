#
# Be sure to run `pod lib lint NVMAspects.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'NVMAspects'
  s.version          = '0.9'
  s.license          = 'mit'
  s.summary          = 'Yet another AOP library for Objective-C.'

  # This description is used to generate tags and improve search results.
  #   * Think: What does it do? Why did you write it? What is the focus?
  #   * Try to keep it short, snappy and to the point.
  #   * Write the description between the DESC delimiters below.
  #   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  TODO: Add long description of the pod here.
  DESC

  s.homepage         = "https://github.com/eleme/NVMAspects"
  s.author           = { 'Karl Peng' => 'codelife2012@gmail.com' }
  s.source           = { :git => 'git@github.com:eleme/NVMAspects.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'

  s.source_files = ['NVMAspects/Classes/**/*', 'NVMAspects/NVMAspects.h', 'NVMAspects/libffi/*.h']
  s.vendored_library = 'NVMAspects/libffi/libffi.a'

  # s.resource_bundles = {
  #   'NVMAspects' => ['NVMAspects/Assets/NVMAspects.bundle/**/*']
  # }

  s.public_header_files = ['NVMAspects/NVMAspects.h', 'NVMAspects/Classes/Aspects.h']
  
  s.frameworks = 'Foundation'
end
