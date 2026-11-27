#!/usr/bin/env ruby
# frozen_string_literal: true
#
# W-06: adds the DaymarkWidgets WidgetKit extension to Runner.xcodeproj.
#
#   gem install xcodeproj   # if needed
#   ruby ios/scripts/add_widget_extension.rb      (from Frontend/)
#
# What it does (idempotent: running it again changes nothing):
# - a DaymarkWidgets app-extension target (iOS 15) with the Swift sources,
#   Info.plist, entitlements (App Group group.com.devquorix.daymark) and the
#   asset catalog in ios/DaymarkWidgets/;
# - ios/Shared/*.swift in both Runner and the extension (App Group helpers and
#   the interactive DaymarkWidgetIntent), ios/Runner/AddTaskIntent.swift in
#   Runner only;
# - Runner embeds the extension ("Embed Foundation Extensions", placed before
#   Flutter's "Thin Binary" script to avoid a build cycle) and gets
#   Runner/Runner.entitlements with the same App Group.
#
# The extension doesn't link Flutter or the plugins: in the extension the
# intent records the tap in the App Group (the app applies it), in the app it
# also runs the Dart callback through home_widget.

require 'xcodeproj'

IOS_DIR = File.expand_path('..', __dir__)
PROJECT_PATH = File.join(IOS_DIR, 'Runner.xcodeproj')
EXTENSION = 'DaymarkWidgets'
DEPLOYMENT_TARGET = '15.0'
APP_GROUP_ENTITLEMENTS = 'Runner/Runner.entitlements'

project = Xcodeproj::Project.open(PROJECT_PATH)
runner = project.targets.find { |t| t.name == 'Runner' } or abort('Runner target not found')

def group_for(project, name, path)
  project.main_group.children.find { |g| g.display_name == name } ||
    project.main_group.new_group(name, path)
end

def file_ref(group, path)
  group.files.find { |f| f.path == path } || group.new_reference(path)
end

def add_source(target, ref)
  return if target.source_build_phase.files_references.include?(ref)

  target.source_build_phase.add_file_reference(ref)
end

# --- Runner: App Group entitlements and the Runner-only intent --------------
runner.build_configurations.each do |config|
  config.build_settings['CODE_SIGN_ENTITLEMENTS'] = APP_GROUP_ENTITLEMENTS
  # Shared/DaymarkWidgetIntent.swift runs the Dart callback only in the app,
  # which links home_widget (the extension can see the module but doesn't
  # link it, so canImport can't tell them apart).
  conditions = Array(config.build_settings['SWIFT_ACTIVE_COMPILATION_CONDITIONS'] || '$(inherited)')
  conditions = conditions.flat_map { |c| c.split(' ') }
  conditions << 'DAYMARK_APP' unless conditions.include?('DAYMARK_APP')
  config.build_settings['SWIFT_ACTIVE_COMPILATION_CONDITIONS'] = conditions.join(' ')
end
runner_group = project.main_group.children.find { |g| g.display_name == 'Runner' }
file_ref(runner_group, 'Runner.entitlements')
add_source(runner, file_ref(runner_group, 'AddTaskIntent.swift'))

# --- Shared sources (both targets) --------------------------------------------
shared_group = group_for(project, 'Shared', 'Shared')
shared_refs = %w[DaymarkWidgetShared.swift DaymarkWidgetIntent.swift].map { |f| file_ref(shared_group, f) }
shared_refs.each { |ref| add_source(runner, ref) }

# --- The extension target -----------------------------------------------------
extension = project.targets.find { |t| t.name == EXTENSION }
unless extension
  extension = project.new_target(:app_extension, EXTENSION, :ios, DEPLOYMENT_TARGET, nil, :swift)
  extension.product_reference.name = "#{EXTENSION}.appex"
end

# new_target links Foundation.framework through a path into one specific SDK
# version; Swift links it automatically, so drop that reference.
extension.frameworks_build_phase.files.dup.each do |build_file|
  ref = build_file.file_ref
  next unless ref && ref.path.to_s.end_with?('Foundation.framework')

  build_file.remove_from_project
  ref.remove_from_project if ref.build_files.empty?
end

widgets_group = group_for(project, EXTENSION, EXTENSION)
%w[DaymarkWidgetsBundle.swift WidgetModels.swift WidgetStyle.swift TasksWidget.swift NextReminderWidget.swift]
  .each { |f| add_source(extension, file_ref(widgets_group, f)) }
shared_refs.each { |ref| add_source(extension, ref) }
file_ref(widgets_group, 'Info.plist')
file_ref(widgets_group, "#{EXTENSION}.entitlements")
assets = file_ref(widgets_group, 'Assets.xcassets')
unless extension.resources_build_phase.files_references.include?(assets)
  extension.resources_build_phase.add_file_reference(assets)
end

runner_settings = runner.build_configurations.first.build_settings
team = runner_settings['DEVELOPMENT_TEAM']
bundle_id = runner_settings['PRODUCT_BUNDLE_IDENTIFIER'] || 'com.devquorix.daymark'
flutter_xcconfigs = project.files.select { |f| f.path.to_s.end_with?('.xcconfig') && f.path.to_s =~ /(Debug|Release)\.xcconfig/ }

extension.build_configurations.each do |config|
  s = config.build_settings
  s['PRODUCT_NAME'] = '$(TARGET_NAME)'
  s['PRODUCT_BUNDLE_IDENTIFIER'] = "#{bundle_id}.#{EXTENSION}"
  s['INFOPLIST_FILE'] = "#{EXTENSION}/Info.plist"
  s['GENERATE_INFOPLIST_FILE'] = 'NO'
  s['CODE_SIGN_ENTITLEMENTS'] = "#{EXTENSION}/#{EXTENSION}.entitlements"
  s['CODE_SIGN_STYLE'] = 'Automatic'
  s['DEVELOPMENT_TEAM'] = team if team
  s['IPHONEOS_DEPLOYMENT_TARGET'] = DEPLOYMENT_TARGET
  s['SWIFT_VERSION'] = '5.0'
  s['TARGETED_DEVICE_FAMILY'] = '1,2'
  s['SKIP_INSTALL'] = 'YES'
  s['APPLICATION_EXTENSION_API_ONLY'] = 'YES'
  s['ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME'] = ''
  s['LD_RUNPATH_SEARCH_PATHS'] = ['$(inherited)', '@executable_path/Frameworks', '@executable_path/../../Frameworks']
  s['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO'
  # FLUTTER_BUILD_NAME / FLUTTER_BUILD_NUMBER for the Info.plist versions,
  # which must match the app's.
  wanted = config.name == 'Debug' ? 'Debug.xcconfig' : 'Release.xcconfig'
  xcconfig = flutter_xcconfigs.find { |f| File.basename(f.path) == wanted }
  config.base_configuration_reference = xcconfig if xcconfig
end

# --- Embed the extension in Runner ------------------------------------------------
runner.add_dependency(extension) unless runner.dependencies.any? { |d| d.target == extension }
embed = runner.copy_files_build_phases.find { |p| p.name == 'Embed Foundation Extensions' }
unless embed
  embed = project.new(Xcodeproj::Project::Object::PBXCopyFilesBuildPhase)
  embed.name = 'Embed Foundation Extensions'
  embed.symbol_dst_subfolder_spec = :plug_ins
  embed.dst_path = ''
  # Before Flutter's "Thin Binary" script, or Xcode reports a dependency cycle.
  thin = runner.build_phases.index { |p| p.respond_to?(:name) && p.name == 'Thin Binary' }
  if thin
    runner.build_phases.insert(thin, embed)
  else
    runner.build_phases << embed
  end
end
unless embed.files_references.include?(extension.product_reference)
  build_file = embed.add_file_reference(extension.product_reference)
  build_file.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
end

project.save

# xcodeproj rewrites the comment on Flutter's Swift package reference; the
# Flutter tool looks for the original text, so put it back.
pbxproj = File.join(PROJECT_PATH, 'project.pbxproj')
text = File.read(pbxproj)
fixed = text.gsub(
  'XCLocalSwiftPackageReference "FlutterGeneratedPluginSwiftPackage"',
  'XCLocalSwiftPackageReference "Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage"'
)
File.write(pbxproj, fixed) unless fixed == text
puts "#{EXTENSION} is set up in #{PROJECT_PATH}."
