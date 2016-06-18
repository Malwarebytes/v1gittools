module V1gittools
  class BaseTool
    attr_reader :v1, :git, :args, :config, :repo_config

    def initialize args=nil
      @args = args
      @config = V1gittools::config
      @repo_config = V1gittools::repo_config
      @git = Git.open(Dir.pwd)
      @v1 = VersiononeSdk::Client.new(@config[:v1config])
    end

  end
end