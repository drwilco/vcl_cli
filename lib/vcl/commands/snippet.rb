module VCL
  class CLI < Thor
    desc "snippet ACTION NAME", "Manipulate snippets on a service. Available actions are create, delete, and list. Use upload command to update snippets."
    method_option :service, :aliases => ["--s"]
    method_option :version, :aliases => ["--v"]
    method_option :type, :aliases => ["--t"]
    method_option :dynamic, :aliases => ["--d"]
    def snippet(action,name=false)
      id = VCL::Utils.parse_directory unless options[:service]
      id ||= options[:service]

      abort "Could not parse service id from directory. Use --s <service> to specify, vcl download, then try again." unless id

      version = VCL::Fetcher.get_writable_version(id) unless options[:version]
      version ||= options[:version].to_i

      filename = "#{name}.snippet"

      case action
      when "upload"
        abort "Must supply a snippet name as second parameter" unless name

        abort "No snippet file for #{name} found locally" unless File.exists?(filename)

        active_version = VCL::Fetcher.get_active_version(id)

        snippets = VCL::Fetcher.get_snippets(id, active_version)

        abort "No snippets found in active version" unless snippets.is_a?(Array) && snippets.length > 0

        snippet = false
        snippets.each do |s|
          if s["name"] == name
            abort "This command is for dynamic snippets only. Use vcl upload for versioned snippets" if s["dynamic"] == "0"

            snippet = s
          end
        end

        abort "No snippet named #{name} found on active version" unless snippet

        # get the snippet from the dynamic snippet api endpoint so you have the updated content
        snippet = VCL::Fetcher.api_request(:get, "/service/#{id}/snippet/#{snippet["id"]}")

        new_content = File.read(filename)

        say(VCL::Utils.get_diff(snippet["content"],new_content))

        abort unless yes?("Given the above diff between the old dyanmic snippet content and the new content, are you sure you want to upload your changes? REMEMBER, THIS SNIPPET IS VERSIONLESS AND YOUR CHANGES WILL BE LIVE IMMEDIATELY!")

        VCL::Fetcher.api_request(:put, "/service/#{id}/snippet/#{snippet["id"]}", {:endpoint => :api, body: {
            content: new_content
          }
        })

        say("New snippet content for #{name} uploaded successfully")
      when "create"
        abort "Must supply a snippet name as second parameter" unless name

        content = "# Put snippet content here."

        VCL::Fetcher.api_request(:post,"/service/#{id}/version/#{version}/snippet",{
          params: {
            name: name,
            type: options[:type] ? options[:type] : "recv",
            content: content,
            dynamic: options.key?(:dynamic) ? 1 : 0
          }
        })
        say("#{name} created on #{id} version #{version}")

        unless File.exists?(filename)
          File.open(filename, 'w+') {|f| content }
          say("Blank snippet file created locally.")
          return
        end

        if yes?("Local file #{filename} found. Would you like to upload its content?")
          VCL::Fetcher.upload_snippet(id,version,File.read(filename),name)
          say("Local snippet file content successfully uploaded.")
        end
      when "delete"
        abort "Must supply a snippet name as second parameter" unless name

        VCL::Fetcher.api_request(:delete,"/service/#{id}/version/#{version}/snippet/#{name}")
        say("#{name} deleted on #{id} version #{version}")

        return unless File.exists?(filename)

        if yes?("Would you like to delete the local file #{name}.snippet associated with this snippet?")
          File.delete(filename)
          say("Local snippet file #{filename} deleted.")
        end
      when "list"
        snippets = VCL::Fetcher.api_request(:get,"/service/#{id}/version/#{version}/snippet")
        say("Listing all snippets for #{id} version #{version}")
        snippets.each do |d|
          say("#{d["name"]}: Subroutine: #{d["type"]}, Dynamic: #{d["dynamic"]}")
        end
      else
        abort "#{action} is not a valid command"
      end
    end
  end
end
