# =============================================================================
# Git Plugin
# =============================================================================

Toyoterm.command :select_branch do |context|
  cwd = context.pane.cwd
  result = Toyoterm.spawn(
    "git", "--no-pager", "branch", "--format=%(refname:short)", cwd: cwd
  )
  next unless result.success?

  branches = result.stdout.split("\n").map { |branch| branch.strip }
  branches.reject! { |branch| branch.empty? }
  next if branches.empty?

  Toyoterm.select(title: "Select Branch", items: branches) do |branch|
    next if branch.nil?

    checkout = Toyoterm.spawn("git", "checkout", branch, cwd: cwd)
    unless checkout.success?
      Toyoterm.log(:error, "git checkout failed: #{checkout.stderr.strip}")
    end
  end
end

Toyoterm.command :stash_all do |context|
  result = Toyoterm.spawn("git", "stash", "-u", cwd: context.pane.cwd)
  unless result.success?
    Toyoterm.log(:error, "git stash failed: #{result.stderr.strip}")
  end
end
