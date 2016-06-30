require 'json'
require 'yaml'
require 'v1gittools/deep_hash_with_indifferent_access'
require 'socket'
require 'faraday'
require 'io/console'

module V1gittools
  @config = nil
  def self.config
    if @config.nil?
      # load config from file
      V1gittools::load_config_file
    end

    @config
  end

  def self.default_config_file
    '~/.v1git.conf'
  end

  def self.load_config_file filename=nil
    filename = V1gittools::default_config_file if filename.nil?
    filename = File.expand_path(filename)
    unless File.exists?(filename)
      raise "Config file #{filename} must exist and be properly configured before running this tool! Please refer to v1git.conf.example."
    end

    @config = DeepHashWithIndifferentAccess.convert_hash(YAML::load(File.open(filename)))
  end

  @repo_config = nil
  def self.repo_config
    if @repo_config.nil?
      V1gittools::load_repo_config
    end

    @repo_config
  end

  @repo_config_path = nil
  def self.repo_config_path
    if @repo_config_path.nil?
      git_root_path = `git rev-parse --show-toplevel`.strip
      raise git_root_path if $?.to_i != 0
      @repo_config_path = git_root_path + '/.git/v1git.conf'
    end

    @repo_config_path
  end

  def self.load_repo_config
    config_path = V1gittools::repo_config_path

    unless File.exists?(config_path)
      puts "v1git has not been setup for this repository yet. Please run #{$0} init to initialize and setup v1git."
      exit
    end

    @repo_config = DeepHashWithIndifferentAccess.convert_hash(YAML::load(File.open(config_path)))
  end

  def self.generate_repo_config config_path
    return if File.exists?(config_path)
    puts "NOTICE: v1git has never been used for this project before. Generating default config...\n\n"

    `git status`
    if $?.to_i == 128
      puts "Your current working directory isn't even a git repository! Goodbye!"
      exit
    end

    # guessing github address from git remote origin url
    git_remote_url = `git config --get remote.origin.url`.strip

    if git_remote_url.start_with?('http')
      # http connection is easy!
      github_url=git_remote_url.chomp('.git')

    elsif git_remote_url.start_with?('git')
      github_host, github_project_uri = git_remote_url.match(/git@(.+?):(.+?)\.git/).captures
      github_url = "https://#{github_host}/#{github_project_uri}"
    else
      github_url=''
    end
    url_parts = github_url.split('/')
    github_repo = url_parts.pop
    github_owner = url_parts.pop

    default_config_hash = {
        github_url: github_url,
        github_owner: github_owner,
        github_repo: github_repo,
        develop_branch: 'develop',
        branches: {}
    }

    V1gittools::write_repo_config(config_path,default_config_hash)

    if github_url == ''
      raise "ERROR: Couldn't guess github config options. Please modify github config options manually in '#{config_path}'"
    else
      puts "Config generated with the following guessed/assumed values:\n\n"
      puts "Develop branch: #{default_config_hash[:develop_branch]}"
      puts "github_url: #{github_url}\n\n"
      puts "github_owner: #{github_owner}\n\n"
      puts "github_repo: #{github_repo}\n\n"
      puts "If these values are not correct, please correct it in \"#{config_path}\".\n\n"
    end
  end

  def self.update_repo_config
    V1gittools::write_repo_config(V1gittools::repo_config_path, @repo_config)
  end

  def self.write_repo_config config_path, config_hash
    File.open(config_path,'w') do |f|
      f.write("# This file is autogenerated and updated by v1git! Comments and formatting will be lost!\n\n")
      f.write(config_hash.to_yaml)
    end
  end

  def self.initialize_github
    if V1gittools::config[:github] && V1gittools::config[:github][:oauth_token] == 'AUTOGENERATE'
      print 'V1git requires a github access token for creating PRs. We will be requesting github for an access token'
      puts 'using your credentials. This will only be a one time operation.'
      if V1gittools::config[:github] && V1gittools::config[:github][:endpoint]
        endpoint = V1gittools::config[:github][:endpoint]
        puts "\nV1Git is configured to connect to: #{endpoint}\n"
      else
        endpoint = nil
        puts "\nV1Git is configured to connect to: api.github.com\n\n"
      end


      print "\nGithub Username: "
      username = STDIN.gets.chomp
      print "Github Password (no echo): "
      password = STDIN.noecho(&:gets).chomp
      puts "\nAutogenerating github repo authtoken with #{username} credentials..."



      gh = Github.new basic_auth: "#{username}:#{password}", endpoint: endpoint
      token = gh.oauth.create scopes: ['repo'], note: "v1gittools token for computer #{Socket.gethostname}"


      # load the file as a string
      config_data = File.read(File.expand_path(V1gittools::default_config_file))
      # globally substitute "install" for "latest"
      filtered_data = config_data.gsub(/oauth_token: *"AUTOGENERATE"/, "oauth_token: \"#{token.token}\"")
      # open the file for writing
      File.open(File.expand_path(V1gittools::default_config_file), "w") do |f|
        f.write(filtered_data)
      end

      puts "Credential generated and written to #{V1gittools::default_config_file} config file."
    end
  end

  def self.validate_config
    # write some checks here to make sure that
    # - v1 works
    response = Faraday.get "https://#{V1gittools::config[:v1config][:hostname]}/#{V1gittools::config[:v1config][:instance]}/Account.mvc/LogIn"

    if response.status == 200
      puts 'Validating VersionOne URL... PASSED'
    else
      puts 'Validating VersionOne URL... FAILED'
      puts 'Please verify that the VersionOne (v1config block) hostname and instance is correct.'
      exit
    end

    print 'Validating VersionOne credentials... '
    response = VersiononeSdk::Client.new(V1gittools::config[:v1config]).getAssets('State') # run a test query

    if response.empty?
      puts 'FAILED'
      puts 'Please validate that the VersionOne credentials is correct (you may need to regenerate a new token).'
    else
      puts 'PASSED'
    end



    # - git works
    `git status`
    if $?.to_i == 128
      puts 'Validating git config... FAILED'
      puts "Your current working directory isn't even a git repository! Please make sure you're in the correct directory."
      exit
    else
      puts 'Validating git config... PASSED'
    end

    # - github works
    print 'Validating github endpoint... '
    response = Faraday.get @config[:github][:endpoint]
    begin
      json_response = JSON.parse(response.body)
    rescue
      puts 'FAILED'
      puts 'Please verify that github[:endpoint] config option is set correctly. Could not contact github.'
      exit
    end

    if json_response['message'] == 'Must authenticate to access this API.'
      puts 'PASSED'
    else
      puts 'FAILED'
      puts 'Please verify that github[:endpoint] config option is set correctly. Could not contact github.'
      exit
    end

    print 'Validating github credentials...'
    github = Github.new(Hash[V1gittools::config[:github].map{ |k, v| [k.to_sym, v] }])
    begin
      response = github.pull_requests.list(V1gittools::repo_config[:github_owner], V1gittools::repo_config[:github_repo])
    rescue ArgumentError
      puts 'FAILED'
      puts "Please verify that github_owner and github_repo in #{V1gittools::repo_config_path} is set."
    rescue Github::Error::Unauthorized
      puts 'FAILED'
      puts "Please verify that the github oauth configuration setting is set correctly in #{V1gittools::default_config_file}"
    end

    puts 'PASSED'
  end
end