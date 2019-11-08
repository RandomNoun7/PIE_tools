plan splunk::configure_splunk(
  String[1] $splunk_server,
  String[1] $pe_master,
  String[2] $splunk_token_name
) {
  info('running splunk::configure_splunk')

  # Use these tasks to install modules using Puppetfile, useful when you want to pin to a specific version
  # $output = run_task('splunk::get_module_path', $pe_master)
  # $modpath = $output.first.value['_output']
  # run_task('splunk::upload_modules', 'localhost', dest_module_path => $modpath, install_node => $pe_master)

  # Install the splunk_hec module
  run_command('puppet module install puppetlabs-splunk_hec', $pe_master, '_catch_errors' => true)

  run_task('splunk::bootstrap_splunk', $splunk_server, hec_token_name => $splunk_token_name)
  run_task('splunk::splunk', $splunk_server, state => 'start', options => '--accept-license --no-prompt')
  run_task('splunk::configure_a_hec', $splunk_server, hec_token_name => $splunk_token_name)
  run_task('splunk::enable_hec', $splunk_server, hec_token_name => $splunk_token_name)
  run_task('splunk::splunk', $splunk_server, state => 'restart')

  $token_result = run_task('splunk::get_hec_token', $splunk_server, hec_token_name => $splunk_token_name)
  $token = $token_result.first.value['_output']
  run_task('splunk::add_hec_token', $pe_master, server => $splunk_server, splunk_hec_token => $token)

  run_task('splunk::install_ta_viewer', $splunk_server, version => '2.0.0')
  run_task('splunk::splunk', $splunk_server, state => 'restart')

  info('splunk::configure_splunk complete')
}
