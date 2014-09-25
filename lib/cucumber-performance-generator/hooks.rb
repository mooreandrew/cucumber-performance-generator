
Before do | scenario |

  $step = 0

  $function_call_name = []
  $function_call_data = []
  $function_call_arguments = []
  $function_call_start = 0

  $file_not_created = true

  page.driver.clear_network_traffic

end

AfterStep do | scenario |
  if (!ENV['GENERATE_PERFORMANCE_SCRIPT'].nil?) then
    generate_performance_test_script(scenario)
  end
end
