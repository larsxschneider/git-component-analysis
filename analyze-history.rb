#!/usr/bin/env ruby
#
# This script analyses the Git history by reading the connection between files
# changed together in a single commit. The result is written to a file for
# further processing.
#
# ## INSTALL:
# Install the required gems: `gem install rugged`
#
# ## USAGE:
# Run the script with the repository to analyze as first parameter and the
# name of the output file as second parameter.
#
# ## EXAMPLE:
# ./analyze-history.rb connections.file
#
require 'rugged'

if ARGV.length < 2
  puts "Too few arguments"
  exit
end

repo_path = ARGV[0]
output_file = ARGV[1]

###############################################################################
# Config
###############################################################################
# Very large histories might be expensive to process. Therefore, limit the
# processing to the last X commits on the default branch.
max_commits = 10000

# We are not looking at commits with a very large number of changed files as
# these commits are usually refactorings over the entire code base that are
# not helpful to identify components.
max_files_changed_per_commit = 20


###############################################################################
# Implementation
###############################################################################
repo = Rugged::Repository.new(repo_path)
walker = Rugged::Walker.new(repo)

default_branch = repo.references["refs/remotes/origin/HEAD"]
walker.push(default_branch.target_id)

processed_commits = 0

dict = Hash.new(0)
walker.each do |c|
	# Skip commits with too many change files
	next if c.diff.deltas.count > max_files_changed_per_commit
	# Skip merge commits
	next if c.parents.count > 1
	processed_commits += 1
	break if max_commits < processed_commits
	print "Processed commits: #{processed_commits}\r"
	c.diff.deltas.each do |d1|
		c.diff.deltas.each do |d2|
			f1 = d1.new_file[:path]
			f2 = d2.new_file[:path]
			if f1 != f2
				key = "#{f1}|#{f2}"
				dict[key] = dict[key] + 1
			end
		end
	end
end

connections = dict.sort_by(&:last).reverse
puts "Total file connections: #{connections.count}"

File.open(output_file, "w") do |to_file|
	Marshal.dump(connections, to_file)
end

puts "Connections saved!"
