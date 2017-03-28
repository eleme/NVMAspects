source 'git@git.elenet.me:eleme.mobile.ios/ios-specs.git'
source 'git@git.elenet.me:arch.mobile/iOS_specs.git'
source 'git@git.elenet.me:eleme.mobile.ios/Specs.git'

use_frameworks!

workspace 'NVMAspects'

def declare_pods_from_podspec
  IO.readlines(Dir.glob('*.podspec').first)
    .find_all { |x| x =~ /^\s*?\w+\.dependency\s*/ }
    .map { |x| x.strip.gsub(/^\s*?\w*?\.dependency\s*/, '') }
    .map { |x| x.gsub(/'|"/, "").split(/,\s*/) }
    .each { |x| pod *x }
end

def declare_pods
  pod  'libffi-iOS', :git => 'https://github.com/sunnyxx/libffi-iOS.git'
end

target 'NVMAspects' do
  project 'NVMAspects'
  declare_pods

  target 'NVMAspectsTests' do
    inherit! :search_paths
  end
end

target 'NVMAspectsDemo' do
  project 'Demo/NVMAspectsDemo/NVMAspectsDemo'
  declare_pods
end

