#!/usr/bin/env ruby
require_relative "./parser.rb"

# File for easily running the program and setting some flags for the program that one may want to use
# -debug : Enables rdparse debug
# -norun : Makes the program not run after parsing
# -tree  : Prints the program in a nice tree structure

if(ARGV.length == 0)
    raise "No arguments given"
end

filename = ARGV[ARGV.length - 1]

parser = BaljanLang.new()
parser.log(false)

no_run = false
tree = false

# Sets all given flags
ARGV.each_with_index do |arg, index|
    if(index > ARGV.length - 2)
        break
    end
    if(arg.downcase == "-debug")
        parser.log(true)
    elsif(arg.downcase == "-norun")
        no_run = true
    elsif(arg.downcase == "-tree")
        tree = true
    end
end

# Parse the file
parser.parse_file(filename)

# Print tree if flag was given
if(tree)
    parser.tree
end

# Run the program if norun flag was not given
if(not no_run)
    parser.run()
end