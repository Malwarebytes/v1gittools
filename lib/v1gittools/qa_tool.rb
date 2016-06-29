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


      pr = @github.pull_requests.create(repo_config[:github_owner], repo_config[:github_repo],
        {
          title: "[#{v1_story_id}] #{v1_story.getProp(:Name)}",
          body: "#{v1_story.getProp(:_sObjectUrl__id)}",
          head: branch,
          base: repo_config[:develop_branch]
      })

      puts " - Created PR for this branch (PR ##{pr.number})."
      puts " - Set 'Build' field in story to '#{branch}'."
      puts " - Set #{v1_story_id} to the status #{v1_story.getProp(:"Status.Name")}.\n\n"

      Launchy.open(pr.html_url)
    end
  end
end