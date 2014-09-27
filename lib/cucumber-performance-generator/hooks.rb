
Before do | scenario |

  if (!ENV['GENERATE_PERFORMANCE_SCRIPT'].nil?) then

    $step = 0

    $function_call_name = []
    $function_call_data = []
    $function_call_arguments = []
    $function_call_start = 0

    $file_not_created = true

    $performance_file_lines = ''

    $transaction_count = 0

    page.driver.clear_network_traffic
  end

end

AfterStep do | scenario |
  if (!ENV['GENERATE_PERFORMANCE_SCRIPT'].nil?) then
    generate_performance_test_script(scenario)
  end
end


After do |scenario|

  if (!ENV['GENERATE_PERFORMANCE_SCRIPT'].nil?) then

    if ($performance_file_lines != '') then

      scenario_name  = scenario.name.gsub('(','').gsub(')', '').gsub(/ /, '_').capitalize

      perf_file_name = 'performanceTests/' + scenario_name.downcase + '.rb'


      file_structure_end = %{
        end

        def v_end()

            #v_end end
        end

        end

      }

      write_line_to_performance_test_file(perf_file_name, file_structure_end, true)
      write_performance_file(perf_file_name)
    end
  end

end
