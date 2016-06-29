require 'io/console'
require 'github_api'

module V1gittools
  class BaseTool
    attr_reader :v1, :git, :args, :config, :repo_config, :github

    def initialize args=nil
      @args = args


      @config = V1gittools::config
      check_proper_init
      @repo_config = V1gittools::repo_config
      @git = Git.open(Dir.pwd)
      @v1 = VersiononeSdk::Client.new(@config[:v1config])
      @github = Github.new(Hash[@config[:github].map{ |k, v| [k.to_sym, v] }])
    end

    def check_proper_init
      if @config[:github] && @config[:github][:oauth_token] == 'AUTOGENERATE'
        puts "v1git has not been setup for this repository yet. Please run #{$0} init to initialize and setup v1git."
        exit
      end
    end
  end
end
