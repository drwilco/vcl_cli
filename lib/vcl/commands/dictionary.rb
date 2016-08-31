module VCL
  class CLI < Thor
    desc "dictionary ACTION DICTIONARY_NAME=none KEY=none VALUE=none", "Manipulate edge dictionaries. Actions: create, delete, list, upsert, remove, list_items, bulk_add. Options: --service --version"
    option :service
    option :version
    def dictionary(action, name=false, key=false, value=false)
      id = VCL::Utils.parse_directory unless options[:service]
      id ||= options[:service]

      abort "Could not parse service id from directory. Specify service id with --service or use from within service directory." unless id

      version = VCL::Fetcher.get_writable_version(id) unless options[:version]
      version ||= options[:version]

      case action
      when "create"
        abort "Must specify name for dictionary" unless name
        VCL::Fetcher.api_request(:post, "/service/#{id}/version/#{version}/dictionary", body: "name=#{URI.escape(name)}")

        say("Dictionary #{name} created.")
      when "delete"
        abort "Must specify name for dictionary" unless name
        VCL::Fetcher.api_request(:delete, "/service/#{id}/version/#{version}/dictionary/#{name}")

        say("Dictionary #{name} deleted.")
      when "list"
        resp = VCL::Fetcher.api_request(:get, "/service/#{id}/version/#{version}/dictionary")

        say("No dictionaries on service in this version.") unless resp.length > 0

        resp.each do |d|
          puts "#{d["id"]} - #{d["name"]}"
        end
      when "upsert"
        abort "Must specify name for dictionary" unless name
        abort "Must specify key and value for dictionary item" unless (key && value)
        dict = VCL::Fetcher.api_request(:get, "/service/#{id}/version/#{version}/dictionary/#{name}")
        VCL::Fetcher.api_request(:put, "/service/#{id}/dictionary/#{dict["id"]}/item/#{key}", body: "item_value=#{value}")   

        say("Dictionary item #{key} set to #{value}.")   
      when "remove"
        abort "Must specify name for dictionary" unless name
        abort "Must specify key for dictionary item" unless key
        dict = VCL::Fetcher.api_request(:get, "/service/#{id}/version/#{version}/dictionary/#{name}")
        VCL::Fetcher.api_request(:delete, "/service/#{id}/dictionary/#{dict["id"]}/item/#{key}")

        say("Item #{key} removed from dictionary #{name}.")
      when "list_items"
        abort "Must specify name for dictionary" unless name
        dict = VCL::Fetcher.api_request(:get, "/service/#{id}/version/#{version}/dictionary/#{name}")
        resp = VCL::Fetcher.api_request(:get, "/service/#{id}/dictionary/#{dict["id"]}/items")

        say("No items in dictionary.") unless resp.length > 0
        resp.each do |i|
          puts "#{i["item_key"]} : #{i["item_value"]}"
        end
      when "bulk_add"
        abort "Must specify name for dictionary" unless name
        abort "Must specify JSON blob of operations in key field. Documentation on this can be found here: https://docs.fastly.com/api/config#dictionary_item_dc826ce1255a7c42bc48eb204eed8f7f"
        dict = VCL::Fetcher.api_request(:get, "/service/#{id}/version/#{version}/dictionary/#{name}")

        VCL::Fetcher.api_request(:patch, "/service/#{id}/dictionary/#{dict["id"]}/items", body: key)

        say("Bulk add operation completed successfully.")
      end
    end
  end
end
