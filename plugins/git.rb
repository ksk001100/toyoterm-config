Toyoterm::Plugin.define "git" do |plugin|
  plugin.version = "0.0.1"

  plugin.command :select_branch do |ctx|
    result = Toyoterm.spawn('git', '--no-pager', 'branch', cwd: ctx.pane.cwd)
    if result.success?
      branch_list = result.stdout
      branch_array = branch_list.split("\n")
      Toyoterm.select(title: "Select Branch", items: branch_array) do |branch, ctx|
        next if branch.nil?

        ctx.pane.send_text("git checkout #{branch.strip}\n")
      end
    end
  end

  plugin.command :stash_all do |ctx|
    ctx.pane.send_text('git', 'stash', '-u', cwd: ctx.pane.cwd)
  end
end
