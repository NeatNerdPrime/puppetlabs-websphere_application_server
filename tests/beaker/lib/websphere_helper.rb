# Download a compressed file from http repository and uncompress it
#
# ==== Attributes
#
# * +hosts+ - The target host where the compressed file is downloaded and uncompressed.
# * +urllink+ - The http link to where the compressed file is located .
# * +compressed_file+ - The name of the compressed file.
# * +uncompress_to+ - The target directory on the host where all files/directories are uncompressed to.
#
# ==== Returns
#
# +nil+
#
# ==== Raises
#
# +Minitest::Assertion+ - Failed to download and/or uncompress.
#
# ==== Examples
#
# download_and_uncompress('agent'
#                  'http://int-resources.ops.puppetlabs.net/QA_resources/ibm_websphere/',
#                  'was.repo.8550.ihs.ilan_part1.zip',
#                  '"/ibminstallers/ibm/ndtrial"',)
def download_and_uncompress(host, installer_url, cfilename, dest_directory, directory_path)

  #ERB Template
  # installer_url = urllink
  # cfilename = compressed_file
  # dest_directory = uncompress_to
  #directory_path = dest_directory
  if cfilename.include? "zip"
    compress_type = 'zip'
  elsif cfilename.include? "tar.gz"
    compress_type = 'tar.gz'
  else
    fail_test "only zip or tar.gz are is valid compressed file "
  end

  local_files_root_path = ENV['FILES'] || "tests/files"
  manifest_template     = File.join(local_files_root_path, 'download_uncompress_manifest.erb')
  manifest_erb          = ERB.new(File.read(manifest_template)).result(binding)

  on(host, puppet('apply'), :stdin => manifest_erb, :exceptable_exit_codes => [0,2]) do |result|
    assert_no_match(/Error/, result.output, 'Failed to download and/or uncompress')
  end
end

# Verify if IBM Installation Manager is installed
#
# ==== Attributes
#
# * +installed_directory+ - The directory where IBM Installation Manager is installed
# By default, the directory is /opt/IBM. This can be configured by 'target' attribute
# in 'ibm_installation_manager' class
# Since IM a UI tool, the verification is only checking if the launcher, license file,
# and the version file are in the right locations.
#
# ==== Returns
#
# +nil+
#
# ==== Raises
#
# fail_test messages
#
# ==== Examples
#
# verify_im_installed?(custom_location)
def verify_im_installed?(installed_directory)
  step "Verify IBM Installation Manager is installed into directory: #{installed_directory}"
  step 'Verify 1/3: IBM Installation Manager Launcher'
  if agent.file_exist?("#{installed_directory}/eclipse/launcher") == nil
    fail_test "Launcher has not been found in: #{installed_directory}/eclipse"
  end

  step 'Verify 2/3: IBM Installation Manager License File'
  if agent.file_exist?("#{installed_directory}/license/es/license.txt") == nil
    fail_test "License file has not been found in: #{installed_directory}/license"
  end

  step 'Verify 3/3: IBM Installation Manager Version'
  if agent.file_exist?("#{installed_directory}/properties/version/IBM_Installation_Manager.*") == nil
    fail_test "Version has not been found in: #{installed_directory}/properties/version"
  end
end

# Verify if files/directories are created:
#
# ==== Attributes
#
# * +files+ - a file/directory or an array of files/directories that need to be verified
# if they are successfully created
#
# ==== Returns
#
# +nil+
#
# ==== Raises
#
# fail_test messages
#
# ==== Examples
#
# verify_file_exist?('/opt/log/websphere')
#
def verify_file_exist?(files)
  error_message = "File/Directory does not exist: #{files}"
  if files.kind_of?(Array)
    files.each do |file|
      if agent.file_exist?(file) == false
        fail_test error_message
      end
    end
  elsif files.kind_of(String)
    if agent.file_exist?(files) == false
      fail_test error_message
    end
  else
    raise Exception
  end
end

# remove websphere application server:
#
# ==== Attributes
#
# * +class_name+ - The websphere_application_server class that needs to
# * be removed
#
# ==== Returns
#
# +nil+
#
# ==== Raises
#
# fail_test messages
#
# ==== Examples
#
# remove_websphere('websphere_application_server')
#
def remove_websphere(class_name)
pp = <<-MANIFEST
  class { "#{class_name}":
    ensure => absent,
  }
MANIFEST
  create_remote_file(agent, "/root/remove_websphere.pp", pp)
  on(agent, "/opt/puppetlabs/puppet/bin/puppet apply /root/remove_websphere.pp")
end