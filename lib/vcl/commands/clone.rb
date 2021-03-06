module VCL
  class CLI < Thor
    desc "clone SERVICE_ID TARGET_SERVICE_ID", "[ADMIN] Clone a service version to another service."
    method_option :version, :aliases => ["--v"]
    def clone(id,target_id)
      version = VCL::Fetcher.get_active_version(id) unless options[:version]
      version ||= options[:version]

      result = VCL::Fetcher.api_request(:put, "/service/#{id}/version/#{version}/copy/to/#{target_id}")

      say("#{id} version #{version} copied to #{target_id} version #{result["number"]}")

      active_version = VCL::Fetcher.get_active_version(target_id)

      domains = VCL::Fetcher.api_request(:get,"/service/#{target_id}/version/#{active_version}/domain")
      domains_that_where_copied = VCL::Fetcher.api_request(:get,"/service/#{target_id}/version/#{result["number"]}/domain")

      say("Restoring domains that were lost during cloning (if any)...")
      domains.each do |d|
        copied = false
        domains_that_where_copied.each do |c|
          if d["name"] == c["name"]
            copied = true
            break
          end
        end

        next if copied === true

        VCL::Fetcher.api_request(:post,"/service/#{target_id}/version/#{result["number"]}/domain", {
          params: { name: d["name"], comment: d["comment"] }
        })

        say("Restoring domain: #{d["name"]}...")
      end
    end
  end
end
