# Uncomment the next line to define a global platform for your project
# platform :ios, '10.0'

target 'Watson-Chat' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Watson-Chat
  pod 'BMSCore', '~> 2.0'
  pod 'MessageKit', '~> 0.13'
  
  post_install do |installer|
          installer.pods_project.targets.each do |target|
              if ['SwiftCloudant'].include? target.name
                  target.build_configurations.each do |config|
                      config.build_settings['SWIFT_VERSION'] = '3.2'
                  end
              end
          end
      end

  target 'Watson-ChatTests' do
    inherit! :search_paths
    # Pods for testing
  end

end
