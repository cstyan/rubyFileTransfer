#!/usr/bin/env ruby 

require 'socket'

size = 1024

def sendThread(sock, fName)
	#puts "sending file"
	#puts file.is_a?(file)
	size = 1024
	puts "sending a file"
	path = File.expand_path("..", Dir.pwd) + "/testFiles/" + fName
	fExists = File.exists?(path)
	#if the file exists attempt to open it and send to client
	if fExists == true
		puts "file exists"
		begin
			#notify client of valid file name
			sock.puts("1")
			#open data socket on port 7006
			puts "1"
			File.open(path, "rb") do |file|
				sock.puts(file.size)
				while data = file.gets do
					puts "read data"
					sock.puts(data)
				end
			end
			puts "done sending file"
		rescue SystemCallError
			raise StandardError
			puts "Unable to open file"
			#notify client of invalid file name
			sock.puts("0")
			sock.puts("Error opening file, make sure the"\
				" file you're trying to open exists (LIST command)")
		end
	else
		puts "file doesn't exist"
		#notify client of invalid file name
		sock.puts("0")
		sock.puts("Requested file does not exist, check the available"\
			" files (LIST command)")
	end
end

def recvThread(sock, fName)
	puts "recieving a file"
	puts sock
	puts fName
	path = File.expand_path("..", Dir.pwd) + "/testFiles/" + fName
	fExists = File.exists?(path)
	puts fExists
	#if the file does not exist accept the file from the client
	if fExists == false
		#notify client we're accepting their file
		sock.puts("1")
		#open data socket on port 7006
		puts "1"
		File.open(fName, 'wb') do |file|
			while run == 1
				data = sock.gets
				size = data.size
				currentSize += size
				#puts "read data"
				file.write(data)
				puts data
				if currentSize == filesize.to_i
					run = 0
				end
			end
			puts "end of read loop"
		end
		puts "done sending file"
	else
		puts "client is sending a file we already have"
		sock.puts("0")
		sock.puts("The file you're tryng to send already exists" \
			" on the server (LIST command)")
	end
end

def getCmd (fName, sock)
	puts "Client sent a get command"
	puts file
	sendThread(sock, fName)
	#respond to client
	#open new socket to client on 7006
end

def sendCmd (fName, sock)
	puts "Client sent a send command"
	recvThread(sock, fName)
end

def listCmd(sock)
	puts "Client sent a list command"
	#get all files from the directory but ignore hidden . and ..
	path = File.expand_path("..", Dir.pwd) + "/testFiles"
	dirFiles = Dir.entries(path).reject{|entry| entry == "." || entry ==".."}
	#tell the client how many files there are
	numFiles = dirFiles.length
	sock.puts(numFiles)
	#for each file in the directoy
	for fileName in dirFiles
		#send the filename
		sock.puts(fileName)
	end
	puts "sent all file names"
end

def quitCmd
	puts "Cient sent a quit command"
end

def clientFunc(sock)
	#read command from socket
	puts "Getting a command from client"
	command = sock.gets.chomp
	puts command
	
	case command
	when 'GET'
		fName = sock.gets.chomp
		puts fName
		getCmd(fName, sock)

	when 'SEND'
		fName = sock.gets.chomp
		puts fName
		sendCmd(fName, sock)

	when 'LIST'
		listCmd(sock)

	when 'QUIT'
		quitCmd
	else
		puts "Unknown command"

	end
end

server = TCPServer.open(7005) # Server bound to port 7000

loop do
  Thread.start(server.accept) do |client|
  	puts 'sending data'
  	i = 1
  	#infinite loop to handle client
  	while i == 1 do
	#File.open('/home/callum/Desktop/git', 'rb') do |file|
	 # 	while data = file.read(size)
	  #		puts 'sent'
	  #		client.write(data)
	  #	end
	  clientFunc(client)
	puts 'end of file'
	end
    client.close
  end
end