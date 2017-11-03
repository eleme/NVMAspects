
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

