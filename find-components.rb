#!/usr/bin/env ruby
#
# This script uses the output of the `analyze-history.rb` script and generates
# a graph of the files that have been changed with each other in a commit.
#
# It only looks at file pairs that have been changed at least 3 times together.
# Afterwards independent subgraphs in this graph are searched for and printed.
#
# That is a pretty simple approach. A more advanced approach might use
# machine learning with topic models. See https://en.wikipedia.org/wiki/Topic_model
#
# ## INSTALL:
# Install the required gems: `gem install rgl`
#
# ## USAGE:
# Run the script with the file written by `analyze-history.rb` as first argument
#
# ## EXAMPLE:
# ./find-components.rb connections.file
#

require 'rgl/base'
require 'rgl/adjacency'
require 'rgl/connected_components'

if ARGV.length < 1
  puts "Too few arguments"
  exit
end

input_file = ARGV[0]

puts "Reading components from #{input_file}..."

graph = RGL::AdjacencyGraph.new

File.open(input_file, "r") do |from_file|
	connections = Marshal.load(from_file)
	connections.each do |key, count|
		# Only look at files that have been changed together at least 3 times
		if count > 2
			files = key.split("|")
			graph.add_edge(files[0], files[1])
		end
	end
end

components = []
graph.each_connected_component { |c| components <<  c }
components.each do |c|
	# Show only components with at least 3 files
	if c.length > 2
		puts "Component"
		puts "---------"
		c.sort.each do |f|
			puts f
		end
		puts ""
	end
end
