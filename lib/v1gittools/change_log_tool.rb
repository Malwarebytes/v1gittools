module V1gittools
  class ChangeLogTool < V1gittools::BaseTool

    def generate_changelog (start_snapshot, end_snapshot)
      @git.log(999999).between(start_snapshot,end_snapshot).each do |commit|
        if match = commit.message.match(/Merge pull request (#\d+) from ((.*?)\n\n([^\n]*).*)/m)
          pr_id, full_message, branch_name, pr_title = match.captures

          # puts "pr_id = #{pr_id}"
          # puts "branch_name = #{branch_name}"
          # puts "pr_title = #{pr_title}"
          # puts "full_message = #{full_message}"
          prefixes = @config[:v1config][:type_prefixes].keys.join('|')
          stories = full_message.scan(/\b([#{prefixes}]-\d{4,6})\b/m)
          v1_stories = {}

          stories.each do |story_array|
            story = story_array[0]

            v1_stories[story] = @v1.getAsset(story)
          end

          v1_stories.each do |story_id, v1_story|
            if v1_story.nil?
              v1_title = 'Cannot Find Story in V1!'
              v1_url = ''

              puts "WARNING: Cannot Find Story [#{story_id}] in V1!"
            else
              v1_title = v1_story.getProp('Name')
              v1_url = v1_story.getProp(:_sObjectUrl__id)
            end

            if @args[:title] == 'git'
              title = pr_title
            else
              title = v1_title
            end
            puts "[#{story_id}] - #{title} (#{v1_url}) - PR #{pr_id} "
          end

          if v1_stories.empty?
            puts "[No Story ID] - #{pr_title} - PR #{pr_id}"
          end
        end
      end
    end
  end
end