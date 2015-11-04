platform :ios, '6.0'

target :'pop-tests-ios', :exclusive => true do
  pod 'OCMock', '~> 2.2'
end

target :'pop-tests-tvos', :exclusive => true do
  platform :tvos, "9.0"

  pod 'OCMock', '~> 2.2'
end

target :'pop-tests-osx', :exclusive => true do
  platform :osx, '10.8'
  pod 'OCMock', '~> 2.2'
end

# Add XCTests to generated xcconfigs
post_install do
  pop_test_xcconfigs = [
    "./Pods/Target Support Files/Pods-pop-tests-ios/Pods-pop-tests-ios.debug.xcconfig",
    "./Pods/Target Support Files/Pods-pop-tests-ios/Pods-pop-tests-ios.profile.xcconfig",
    "./Pods/Target Support Files/Pods-pop-tests-ios/Pods-pop-tests-ios.release.xcconfig",
    "./Pods/Target Support Files/Pods-pop-tests-tvos/Pods-pop-tests-tvos.debug.xcconfig",
    "./Pods/Target Support Files/Pods-pop-tests-tvos/Pods-pop-tests-tvos.profile.xcconfig",
    "./Pods/Target Support Files/Pods-pop-tests-tvos/Pods-pop-tests-tvos.release.xcconfig",
    "./Pods/Target Support Files/Pods-pop-tests-osx/Pods-pop-tests-osx.debug.xcconfig",
    "./Pods/Target Support Files/Pods-pop-tests-osx/Pods-pop-tests-osx.profile.xcconfig",
    "./Pods/Target Support Files/Pods-pop-tests-osx/Pods-pop-tests-osx.release.xcconfig",
  ]

  pop_test_xcconfigs.each do |pop_test_xcconfig|
    new_xcconfig = File.read(pop_test_xcconfig).gsub(/OTHER_LDFLAGS/, "POD_OTHER_LDFLAGS")
    new_xcconfig << "\nOTHER_LDFLAGS = $(POD_OTHER_LDFLAGS) -framework XCTest"
    new_xcconfig << "\nFRAMEWORK_SEARCH_PATHS = $(inherited) \"$(PLATFORM_DIR)/Developer/Library/Frameworks\""
    File.write(pop_test_xcconfig, new_xcconfig)
  end

end
