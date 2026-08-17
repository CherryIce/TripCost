#!/usr/bin/env ruby
# frozen_string_literal: true

require 'xcodeproj'

root = File.expand_path('..', __dir__)
project_path = File.join(root, 'ios', 'Runner.xcodeproj')
project = Xcodeproj::Project.open(project_path)
runner = project.targets.find { |target| target.name == 'Runner' }
raise 'Runner target not found' unless runner

def file_reference(group, path)
  group.files.find { |file| file.path == path } || group.new_file(path)
end

def add_source(target, reference)
  return if target.source_build_phase.files_references.include?(reference)

  target.source_build_phase.add_file_reference(reference)
end

runner_group = project.main_group.find_subpath('Runner', true)
generated_group = runner_group.find_subpath('Generated', true)
generated_group.path = 'Generated'
add_source(runner, file_reference(generated_group, 'PlatformApis.g.swift'))
add_source(runner, file_reference(runner_group, 'PlatformApiStubs.swift'))
add_source(runner, file_reference(runner_group, 'VisionOcrService.swift'))

config_group = project.main_group.find_subpath('Config', true)
config_group.path = 'Config'
identifiers_config = file_reference(config_group, 'Identifiers.xcconfig')

widget = project.targets.find { |target| ['AppWidget', 'TripCostWidget'].include?(target.name) }
unless widget
  widget = project.new_target(:app_extension, 'AppWidget', :ios, '15.0')
  runner.add_dependency(widget)
end
widget.name = 'AppWidget'
widget.product_name = 'AppWidget'
widget.product_reference.path = 'AppWidget.appex'
runner.dependencies.each do |dependency|
  next unless dependency.target == widget

  dependency.name = 'AppWidget'
  dependency.target_proxy.remote_info = 'AppWidget' if dependency.target_proxy
end

widget_group = project.main_group.find_subpath('TripCostWidget', true)
widget_group.path = 'TripCostWidget'
widget_source = file_reference(widget_group, 'TripCostWidget.swift')
add_source(widget, widget_source)
file_reference(widget_group, 'Info.plist')

localizations = widget_group.children.find do |group|
  group.isa == 'PBXVariantGroup' && group.name == 'Localizable.strings'
end
unless localizations
  localizations = widget_group.new_variant_group('Localizable.strings')
  localizations.new_file('en.lproj/Localizable.strings')
  localizations.new_file('zh-Hans.lproj/Localizable.strings')
end
unless widget.resources_build_phase.files_references.include?(localizations)
  widget.resources_build_phase.add_file_reference(localizations)
end

embed_phase = runner.copy_files_build_phases.find { |phase| phase.name == 'Embed App Extensions' }
unless embed_phase
  embed_phase = runner.new_copy_files_build_phase('Embed App Extensions')
  embed_phase.dst_subfolder_spec = '13'
end
unless embed_phase.files_references.include?(widget.product_reference)
  embed_phase.add_file_reference(widget.product_reference)
end

# Flutter's Thin Binary phase reads the assembled app bundle. Embed extensions
# first to avoid an Xcode dependency cycle through Runner.app/Info.plist.
runner.build_phases.delete(embed_phase)
thin_binary_index = runner.build_phases.index do |phase|
  phase.respond_to?(:name) && phase.name == 'Thin Binary'
end
runner.build_phases.insert(thin_binary_index || runner.build_phases.length, embed_phase)

project.build_configurations.each do |configuration|
  configuration.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
end

runner.build_configurations.each do |configuration|
  configuration.build_settings['DEVELOPMENT_TEAM'] = ''
  configuration.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
  configuration.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = '$(APP_RUNNER_BUNDLE_ID)'
end

tests = project.targets.find { |target| target.name == 'RunnerTests' }
tests&.build_configurations&.each do |configuration|
  configuration.build_settings['DEVELOPMENT_TEAM'] = ''
  configuration.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
  configuration.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = '$(APP_RUNNER_BUNDLE_ID).RunnerTests'
end

widget.build_configurations.each do |configuration|
  configuration.base_configuration_reference = identifiers_config
  configuration.build_settings['APPLICATION_EXTENSION_API_ONLY'] = 'YES'
  configuration.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
  configuration.build_settings['CURRENT_PROJECT_VERSION'] = '1'
  configuration.build_settings['DEVELOPMENT_TEAM'] = ''
  configuration.build_settings['GENERATE_INFOPLIST_FILE'] = 'NO'
  configuration.build_settings['INFOPLIST_FILE'] = 'TripCostWidget/Info.plist'
  configuration.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
  configuration.build_settings['MARKETING_VERSION'] = '1.0.0'
  configuration.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = '$(APP_WIDGET_BUNDLE_ID)'
  configuration.build_settings['PRODUCT_NAME'] = 'AppWidget'
  configuration.build_settings['SKIP_INSTALL'] = 'YES'
  configuration.build_settings['SWIFT_VERSION'] = '5.0'
  configuration.build_settings['TARGETED_DEVICE_FAMILY'] = '1,2'
end

project.save
