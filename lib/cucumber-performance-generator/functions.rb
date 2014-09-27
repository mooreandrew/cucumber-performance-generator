#####
## Function: recursive_list_variable
## Inputs: variable (any Hash/Array/nil) prev (string of current path)
## Outputs: Flat hash (key = path, value = value)
## Description: This function creates a flat hash of the object so it can be
##              easily used to paramterise the performance script.
##              This is a recursive function.
#####
def recursive_list_variable(variable, prev = '')

  # create the hash
  data = {}

  ## If the variable is an array we need to use .each_with_index.
  if (variable.kind_of?(Array)) then

    # Loop through the items of the array
    variable.each_with_index do |value, key|
      # build the variable path, this is the structure of the object
      variable_key = prev + '[' + key.to_s + ']'

      # If the child is either an Array or Hash then it needs to be put
      # back into this function.
      if ((variable[key].kind_of?(Array)) || (variable[key].kind_of?(Hash))) then
        data_ret = recursive_list_variable(variable[key], variable_key)
        data = data_ret.merge(data)
      else
        # Otherwise we're at the top for this part, so assign the value to the data hash
        data[variable_key] = value
      end
    end

  # The same code as above, but instead needs to use .each
  elsif (variable.kind_of?(Hash)) then

    # Loop through the items of the array
    variable.each do |key, value|

      # build the variable path, this is the structure of the object
      variable_key = prev + '["' + key.to_s + '"]'

      # If the child is either an Array or Hash then it needs to be put
      # back into this function.
      if ((variable[key].kind_of?(Array)) || (variable[key].kind_of?(Hash))) then
        data_ret = recursive_list_variable(variable[key], variable_key)
        data = data_ret.merge(data)
      else
      # Otherwise we're at the top for this part, so assign the value to the data hash
        data[variable_key] = value
      end

    end
    # If it is nil, then we need to return a hash still, this will be reworked in the future
  elsif (variable.nil?)
    data['nil'] = ''
  end

  # Return data hash
  return data
end




#####
## Function: recursive_escape_hasharray
## Inputs: variable (any Hash/Array/nil) prev (string of current path)
## Outputs: Flat hash (key = path, value = value)
## Description: This function creates a flat hash of the object so it can be
##              easily used to paramterise the performance script.
##              This is a recursive function.
#####
def recursive_escape_hasharray(variable, char='"')

  # create the hash

  data = variable

  ## If the variable is an array we need to use .each_with_index.
  if (variable.kind_of?(Array)) then

    # Loop through the items of the array
    variable.each_with_index do |value, key|

      # If the child is either an Array or Hash then it needs to be put
      # back into this function.
      if ((variable[key].kind_of?(Array)) || (variable[key].kind_of?(Hash))) then
        data[key] = recursive_escape_hasharray(variable[key])
      elsif (variable[key].kind_of?(String))
        data[key] = value.gsub(/#{char}/, '\\' + char)
      else
        data[key] = value
      end
    end

  # The same code as above, but instead needs to use .each
  elsif (variable.kind_of?(Hash)) then

    # Loop through the items of the array
    variable.each do |key, value|

      # If the child is either an Array or Hash then it needs to be put
      # back into this function.
      if ((variable[key].kind_of?(Array)) || (variable[key].kind_of?(Hash))) then
        data[key] = recursive_escape_hasharray(variable[key])
      elsif (variable[key].kind_of?(String))
        data[key] = value.gsub(/#{char}/, '\\' + char)
      else
        data[key] = value
      end

    end
    # If it is nil, then we need to return a hash still, this will be reworked in the future
  end

  # Return data hash
  return data
end





#####
## Function: generate_performance_test_script
## Inputs: scenario object (this contains data about the scenario. i.e. name)
## Outputs: None
## Description: This will generate the load test for a step.
## =>           This will use phantomjs to work out which http requests were made
## =>           It will work out the variables being used and paramatise them in the script
## =>           It will create the file if it doesn't exist
#####
def generate_performance_test_script(scenario)

  ## the scenario object doesn't know what the current step it, this will
  ## work it out and structure it how we want to use it
  step_name = scenario.steps.to_a[$step].name.gsub('(','').gsub(')', '').gsub(/ /, '_').capitalize

  ## Use a global variable to keep track of the step. As this fucntion is just
  ## called once per a step, so we can increase this by 1
  $step = $step + 1

  # get the scenario name, ( and ) can confuse regex and spaces we want as underscores
  scenario_name  = scenario.name.gsub('(','').gsub(')', '').gsub(/ /, '_').capitalize

  # We only want to do something if there was any http traffic
  if (page.driver.network_traffic.to_a.count > 0) then

    perf_file_name = 'performanceTests/' + scenario_name.downcase + '.rb'


    # We want to recreate the script each time it runs. This variable keeps track of it
    #if (!File.file?(perf_file_name))
    if ($file_not_created == true) then
      # Set this to another value so we don't keep recreating the performance script
      $file_not_created = false

      if (!File.directory?(File.expand_path('performanceTests/').to_s)) then
        Dir.mkdir(File.expand_path('performanceTests/').to_s)
      end




      # Lets create the basic structure of the file
      file_structure = %{

# Scenario Name: #{scenario.name}

    class #{scenario_name}

      def initialize()

      end

      def v_init()


          #v_init end
      end

      def v_action()
          @curl = Curl::Easy.new
          @curl.follow_location = true
          @curl.enable_cookies = true



      }

      write_line_to_performance_test_file(perf_file_name, file_structure, true)

      # Lets write that to a file
      #File.open(perf_file_name, 'w') { |file| file.write(file_structure) }

    end

    # This bit gets complex. We record which functions were being called.
    # If this is above 0 then we want to understand this fucntions as this is
    # key to being able to paramertise the script
    if ($function_call_name.count > 0) then

      # Loop through the function calls as we only want to use the new ones
      for i in $function_call_start..$function_call_name.count - 1

        function_argouments = ''
        #puts $function_call_arguments[i]

        if (!$function_call_arguments[i].nil?)
          $function_call_arguments[i].each do |key, value|

           # We need to build, up the functions arguments, seperated by a string
           if (function_argouments != '') then
             function_argouments = function_argouments + ', '
           end
            if (value.class.to_s == 'String') then

              # assigned the value to a temp variable.
              func_value = value.to_s
              # we can only parameterise the second and following functions.
              if (i > 0) then
                # Loop through the previous functions to the one that is current.
                # This means we don't accidently assign the current function a value
                # that its self returns
                for i2 in 0..i - 1
                  # the variable $function_call_data contains the data that is returned
                  # from each function. However this data is nested in a hash.
                  # We need to get a flat structure.

                  temp_function_call_data = recursive_escape_hasharray($function_call_data[i2])

                  value_list = recursive_list_variable(temp_function_call_data)
                    # Loop through the flat structure results to do a replace
                    # on the value with a variable
                    value_list.each do |data_key, data_value|
                      # We only want to replace values that are greater than 0 length
                      if (data_value.to_s.length > 0) then
                        # replace the actual value with the variable
                        func_value = func_value.gsub(/#{data_value.to_s}/i, '#{' + "genData#{i2}" + data_key + '}')
                    end
                  end
                end
              end
              # concat the function_argouments, the list of arguments for the function
              function_argouments = function_argouments + '"' + func_value + '"'


            else

              # assigned the value to a temp variable.
              func_value = value.to_s
              # we can only parameterise the second and following functions.
              if (i > 0) then
                # Loop through the previous functions to the one that is current.
                # This means we don't accidently assign the current function a value
                # that its self returns
                for i2 in 0..i - 1
                  # the variable $function_call_data contains the data that is returned
                  # from each function. However this data is nested in a hash.
                  # We need to get a flat structure.

                  temp_function_call_data = recursive_escape_hasharray($function_call_data[i2])
                  value_list = recursive_list_variable(temp_function_call_data)
                  # Loop through the flat structure results to do a replace
                  # on the value with a variable
                  value_list.each do |data_key, data_value|
                    # We only want to replace values that are greater than 0 length
                    if (data_value.to_s.length > 0) then
                      # replace the actual value with the variable
                      func_value = func_value.gsub(/"#{data_value.to_s}"/is, '"#{' + "genData#{i2}" + data_key + '}"')

                      func_value = func_value.gsub(/ "#{data_value.to_s.gsub('(', '\(').gsub(')', '\)')}"/is, ' "#{' + "genData#{i2}" + data_key + '}"')
                      func_value = func_value.gsub(/"#{data_value.to_s.gsub('(', '\(').gsub(')', '\)')}",/is, '"#{' + "genData#{i2}" + data_key + '}",')
                      func_value = func_value.gsub(/\=\>"#{data_value.to_s.gsub('(', '\(').gsub(')', '\)')}\}"/is, '=>"#{' + "genData#{i2}" + data_key + '}"}')
                      func_value = func_value.gsub(/\["#{data_value.to_s.gsub('(', '\(').gsub(')', '\)')}"\]/is, '["#{' + "genData#{i2}" + data_key + '}"]')

                      func_value = func_value.gsub(/ #{data_value.to_s.gsub('(', '\(').gsub(')', '\)')},/is, " genData#{i2}" + data_key + ',')
                      func_value = func_value.gsub(/ #{data_value.to_s.gsub('(', '\(').gsub(')', '\)')}\)/is, " genData#{i2}" + data_key + ')')
                      func_value = func_value.gsub(/ #{data_value.to_s.gsub('(', '\(').gsub(')', '\)')}\]/is, " genData#{i2}" + data_key + ']')

                      func_value = func_value.gsub(/#{data_value.to_s.gsub('(', '\(').gsub(')', '\)')},/is, "genData#{i2}" + data_key + ',')
                      func_value = func_value.gsub(/\=\>#{data_value.to_s.gsub('(', '\(').gsub(')', '\)')}\}/is, '=>' + "genData#{i2}" + data_key + '}')
                      func_value = func_value.gsub(/\[#{data_value.to_s.gsub('(', '\(').gsub(')', '\)')}\]/is, '[' + "genData#{i2}" + data_key + ']')

                    end
                  end
                end
              end

              # concat the function_argouments, the list of arguments for the function
              function_argouments = function_argouments + func_value
            end
          end

        end


        # build up the action step with the code
        v_action_text = %{

        genData#{i} = #{$function_call_name[i]}(#{function_argouments})
        }

        # write the code to the performance test script file.
        write_line_to_performance_test_file(perf_file_name, v_action_text, true)

      end

      # Update which function we are up to.
      $function_call_start = $function_call_name.count

    end

    $transaction_count += 1
    # We are going to put transactions in based on the step being executed
    v_action_text = %{

        trans_time#{$transaction_count} = start_traction("#{step_name}")
    }

    write_line_to_performance_test_file(perf_file_name, v_action_text, true)

    prevredirect = '';

    page.driver.network_traffic.each do |request|

      # We only want valid http calls, not data calls (These are just managed in the front end)
      if (!request.url.include? 'data:application') then

        # A http request may forward onto multiple urls. We don't want each of these
        # and only want the final one, as these steps wont be reproduced in the script
        # as we will automatically forward
        if (prevredirect == '') then

          # Build up the action step for submit data
          v_action_text = %{
                data = {}
             data["header"] = {}
          }
          # write this to the performance test script file
          write_line_to_performance_test_file(perf_file_name, v_action_text)

          # Have we got any headers for this http request?
          if (request.headers.count > 0) then

            # If so, let's loop through them and add them to the script
            request.headers.each do |value|
              # We don't want the Content-Length one, as this will differ
              if (value['name'] != 'Content-Length') then
                # Record the headers
                v_action_text = %{
                          data["header"]["#{value['name']}"] = "#{value['value']}"
                }
                # write each header to file
                write_line_to_performance_test_file(perf_file_name, v_action_text)

              end

            end

          end

          # assign the request url to a variable (notice the . and _)
          request_url = request.url

          # The url could contain a parameter (i.e. a title number) so we need to
          # check for that and paramterise it
          # So lets loop through all the function data we know
          for i in 0..$function_call_data.count - 1

            # Get a flat list of the hash values
            value_list = recursive_list_variable($function_call_data[i])

            # Loop through each of the hash values
            value_list.each do |data_key, data_value|

              # We don't want to include anything too small. An example is the letter M (for male)
              if (data_value.to_s.length > 1) then

                # We want to sure the value matches and is case sensitive
                if (request_url.include? "#{CGI::escape(data_value.to_s)}")

                  # Replace the value in the url, but it needs to be escaped
                  # so is in the url format
                  request_url = request_url.gsub(/#{CGI::escape(data_value.to_s)}/i, '#{' + "genData#{i}" + data_key + '}')

                end
              end

            end

          end

          # The request can either be a GET or POST, so we need to check which type it is
          if (request.method == 'POST')

              # Phantomjs returns the data in a Base64 encode, let's decode it
              begin
                data_str = Base64.decode64(request.data)
              rescue Exception=>e
                raise "Are you sure you're running the custom version of phantomjs from https://github.com/mooreandrew/phantomjs ?"
              end

              # lets define a post_data value in the script
              v_action_text = %{
                    data["post_data"] = {}
              }

              # lets write that
              write_line_to_performance_test_file(perf_file_name, v_action_text)

              # we have a long string of data, lets split is by &
              data_str_and = data_str.split('&')

              # lets loop through each of the items
              data_str_and.each do |elements|
                # each item contains the key and value seperated by an equal.
                data_str_keyvalue = elements.split('=')

                # lets unescaspe the value
                post_key = CGI::unescape(data_str_keyvalue[0])

                # if the value is nil, lets make it an empty string
                if (data_str_keyvalue[1].nil?) then
                  data_str_keyvalue[1] = ''
                end

                # all http headers are strings, so lets make them strings in our data hash
                post_value = '"' + CGI::unescape(data_str_keyvalue[1]).gsub('"', '\"') + '"'

                # Lets loop through the function call data and replace any post data with parameters
                for i in 0..$function_call_data.count - 1

                    # Get a flat list of the hash values
                    value_list = recursive_list_variable($function_call_data[i])

                    # Loop through each of the hash values
                    value_list.each do |data_key, data_value|
                      # If value from the post data identically matches the a functionc call, lets use that instead
                      if (CGI::unescape(data_str_keyvalue[1]).to_s == data_value.to_s) then
                        post_value = "genData#{i}#{data_key.to_s}"
                      #  puts data_key.to_s + ' - ' + data_value.to_s
                      else
                        if (data_value.to_s.length > 1) then
                          post_value = post_value.gsub(data_value.to_s, '#{' + "genData#{i}#{data_key.to_s}" + '}')
                        end
                      end
                    end

                end

                # write the post data keys to the performance script
                v_action_text = %{
                      data["post_data"]["#{post_key}"] = #{post_value}
                }

                write_line_to_performance_test_file(perf_file_name, v_action_text)

              end

              # write the post data to the performance script
              v_action_text = %{
                    response = http_post(@curl, data, "#{request_url}")
              }

            else
              # If it isn't a post, it must be a get


              v_action_text = %{
                    response = http_get(@curl, data, "#{request_url}")
              }


            end

            # write the http (get or post) call
            write_line_to_performance_test_file(perf_file_name, v_action_text)

          end

          # The scripts will run with auto redirect, so we only want to check the final step, not all of them.
          if (request.response_parts[request.response_parts.count - 1].redirect_url.to_s == '') then

            # Lets assert to see if the response from the http call matches that we should expect
            v_action_text = %{
            assert_http_status(response, #{request.response_parts[request.response_parts.count -1].status})
            }

            write_line_to_performance_test_file(perf_file_name, v_action_text, true)

          end

      end

      # Assign the prevredirect variable with the current redirect url.
      prevredirect = request.response_parts[request.response_parts.count - 1].redirect_url.to_s


    end

    # End the transaction
    v_action_text = %{
        end_traction("#{step_name}", trans_time#{$transaction_count})
    }

    write_line_to_performance_test_file(perf_file_name, v_action_text, true)

  end

  # Clear out the network traffic log so we don't end up with duplicates
  page.driver.clear_network_traffic

end


#####
## Function: decode_value
## Inputs: object (any object type)
## Outputs: object (transformed object)
## Description: This function should be called within other functions to transform
##              the object into something that can be converted to a string.
## =>           an example is Cucumber::Ast::Table is a text table, but it needs to be
## =>           the raw version.
#####
def decode_value(variable_item)
  # If the item is a nil, then change it to a nil
  if variable_item.nil? then
    item = nil
  # Arrays are ok to pass through as they are
  elsif (variable_item.class.to_s == 'Array') then
    item = variable_item
  elsif (variable_item.class.to_s == 'String') then
    item = variable_item
  # A Cucumber Docstring needs to be checked if it is empty or not
  elsif (variable_item.class.to_s == 'Cucumber::Ast::DocString') then
    if variable_item.to_s.empty? then
      item = nil
    else
      item = variable_item
    end
  # A Cucumber Table needs to be the raw format
  elsif (variable_item.class.to_s == 'Cucumber::Ast::Table') then
    if variable_item.to_s.empty? then
      item = nil
    else
      item = variable_item.raw
    end
  else
    # else keep it as it is
    item = variable_item
  end

  return item

end




#####
## Function: write_line_to_performance_test_file
## Inputs: perf_file_name (String) v_action_text (String)
## Outputs: None
## Description: This will write the action text to the performance test script
#####
def write_line_to_performance_test_file(perf_file_name, v_action_text, doublespace = false)

  $performance_file_lines = $performance_file_lines + '             ' + v_action_text.strip + "\n"

  if (doublespace == true) then
    $performance_file_lines = $performance_file_lines + "\n"

  end

end

def write_performance_file(perf_file_name)
  open(File.expand_path(perf_file_name).to_s, 'w') { |file| file.puts($performance_file_lines) }
end
