module VCL
  class CLI < Thor
    desc "create_service SERVICE_NAME", "Create a blank service. If --customer is supplied and you are an admin, the command will ask for a password and then move the service to that customer's account."
    option :customer
    def create_service(name)
      service = VCL::Fetcher.api_request(:post, "/service", { body: "name=#{URI.escape(name)}"})

      if options[:customer]
        say("This command works by creating a service on your account and moving it to the target account. It will prompt you for your password.")
        self.move(service["id"],options[:customer])
      end

      if yes?("Service #{service["id"]} has been created. Would you like to open the configuration page?")
        VCL::Utils.open_service(service["id"])
      end
    end
  end
end
