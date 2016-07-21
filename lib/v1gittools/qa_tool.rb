require 'launchy'
module V1gittools
  class QATool < V1gittools::BaseTool
    def qa
      branch = git.current_branch
      v1_story_id = repo_config[:branches][branch.to_sym]


      if v1_story_id.nil?
        puts "This branch was not created with v1git tool. Cannot send this branch/story to QA."
        return
      end
      v1_story = v1.getAsset(v1_story_id.dup)
      if v1_story.nil?
        puts "Sorry, story/defect #{v1_story_id} not found! Can't mark story for QA! Was the story deleted?"
        return
      end

      if v1_story.asHash.keys.include?(:FixedInBuild)
        build_field = 'FixedInBuild'
      else
        build_field = 'LastVersion'
      end

      v1.updateAsset(v1_story.getProp(:_sObjectType__id), v1_story.getProp(:_iObjectId__id),'Status', config[:v1_story_statuses][:test])
      v1.updateAsset(v1_story.getProp(:_sObjectType__id), v1_story.getProp(:_iObjectId__id),build_field,branch)

      v1_story = v1.getAsset(v1_story_id.dup)

      begin
        pr = @github.pull_requests.create(repo_config[:github_owner], repo_config[:github_repo],
          {
            title: "[#{v1_story_id}] #{v1_story.getProp(:Name)}",
            body: "https://#{config[:v1config][:hostname]}/#{config[:v1config][:instance]}/story.mvc/Summary?oidToken=#{v1_story.getProp(:_sObjectType__id)}:#{v1_story.getProp(:_iObjectId__id)}",
            head: branch,
            base: repo_config[:develop_branch]
        })
        puts " - Created PR for this branch (PR ##{pr.number})."
      rescue Github::Error::UnprocessableEntity => e
        ## TODO: Need to change all these errors to use error_messages instead of trying to analyze it manually.
        if e.error_messages.include?({:resource=>"PullRequest", :code=>"custom", :message=>"No commits between develop and add_truth_statements"})
          puts "Cannot create Pull Request! There have been no changes between #{branch} and #{repo_config[:develop_branch]}. Did you forget to commit your code?"
          exit
        elsif e.to_s.include?('field: head, code: invalid')
          puts "Branch '#{branch}' does not exist on github. Did you forget to `git push`? Cannot create PR!"
          exit
        elsif e.to_s.include?('A pull request already exists for')
          puts " - Pull Request for branch '#{branch}' already exists. Skipped creating PR."
        else
          raise e
        end
      end



      puts " - Set 'Build' field in story to '#{branch}'."
      puts " - Set #{v1_story_id} to the status '#{v1_story.getProp(:"Status.Name")}'.\n\n"

      Launchy.open(pr.html_url) if pr
    end
  end
end
