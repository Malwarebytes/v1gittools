module V1gittools
  class DevelopStoryTool < V1gittools::BaseTool

    def develop(v1_story_id, branch_name=nil)
      branch_name ||= v1_story_id
      v1_story = v1.getAsset(v1_story_id.dup)
      if v1_story.nil?
        puts "Sorry, story/defect #{v1_story_id} not found! Can't start development on unknown story/defect!"
        return
      end

      git.checkout(repo_config[:develop_branch])
      git.pull(repo_config[:github_remote], repo_config[:develop_branch])
      git.branch(branch_name).checkout

      repo_config[:branches][branch_name] = v1_story_id
      V1gittools::update_repo_config
      v1.updateAsset(v1_story.getProp(:_sObjectType__id), v1_story.getProp(:_iObjectId__id),'Status', config[:v1_story_statuses][:develop])

      v1_story = v1.getAsset(v1_story_id.dup)

      puts " - Switched to a new branch '#{branch_name}' based off of '#{repo_config[:develop_branch]}'."
      puts " - Set #{v1_story_id} to the status #{v1_story.getProp(:"Status.Name")}.\n\n"
      puts "Implement story/defect in branch (Don't forget to push!). When complete, use:\n\n"
      puts "     v1git qa\n\n"
    end
  end
end