#
# Be sure to run `pod lib lint NVMAspects.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'NVMAspects'
  s.version          = '0.2.2'
  s.summary          = 'A short description of NVMAspects.'

  # This description is used to generate tags and improve search results.
  #   * Think: What does it do? Why did you write it? What is the focus?
  #   * Try to keep it short, snappy and to the point.
  #   * Write the description between the DESC delimiters below.
  #   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  TODO: Add long description of the pod here.
  DESC

  s.homepage         = "https://git.elenet.me/eleme.mobile.ios/NVMAspects"
  s.license          = { :type => 'Commercial', :file => 'LICENSE' }
  s.author           = { 'Karl Peng' => 'codelife2012@gmail.com' }
  s.source           = { :git => 'git@git.elenet.me:eleme.mobile.ios/NVMAspects.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'

  s.source_files = ['NVMAspects/Classes/**/*', 'NVMAspects/NVMAspects.h', 'NVMAspects/libffi/*.h']
  s.vendored_library = 'NVMAspects/libffi/libffi.a'

  # s.resource_bundles = {
  #   'NVMAspects' => ['NVMAspects/Assets/NVMAspects.bundle/**/*']
  # }

  s.public_header_files = ['NVMAspects/NVMAspects.h', 'NVMAspects/Classes/Aspects.h']
  
  s.frameworks = 'Foundation'
  
  s.pod_target_xcconfig = { 'ENABLE_BITCODE' => 'NO' }
end
