#!/usr/bin/env ruby 

path = File.expand_path("..", Dir.pwd) + "/testFiles"
Dir.chdir path
output = `ls`
p output

begin
	path = File.join(File.expand_path("..", Dir.pwd),  "/testFiles/out.txt")
	#fullpath = File.join(path,)
	puts path
	puts File.exsts?(path)
	fHandle = File.open(path, r)
rescue
	puts"shit broke"
end