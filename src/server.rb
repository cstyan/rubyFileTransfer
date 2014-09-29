#!/usr/bin/env ruby 

require 'socket'

size = 1024

def sendThread(cmdSock, sock, fName)
	size = 1024
	puts "Sending a file"
	path = File.expand_path("..", Dir.pwd) + "/testFiles/" + fName
	fExists = File.exists?(path)
	#if the file exists attempt to open it and send to client
	if fExists == true
		begin
			#notify client of valid file name
			cmdSock.puts("1")
			File.open(path, "rb") do |file|
				cmdSock.puts(file.size)
				while data = file.gets do
					sock.puts(data)
				end
			end
			puts "done sending file"
		rescue SystemCallError
			raise StandardError
			puts "Unable to open file"
			#notify client of invalid file name
			cmdSock.puts("0")
			cmdSock.puts("Error opening file, make sure the"\
				" file you're trying to open exists (LIST command)")
		end
	else
		puts "file doesn't exist"
		#notify client of invalid file name
		cmdSock.puts("0")
		cmdSock.puts("Requested file does not exist, check the available"\
			" files (LIST command)")
	end
end

def recvThread(cmdSock, sock, fName)
	puts "Recieving a file"
	path = File.expand_path("..", Dir.pwd) + "/testFiles/" + fName
	fExists = File.exists?(path)
	#if the file does not exist accept the file from the client
	if fExists == false
		#notify client we're accepting their file
		cmdSock.puts("1")
		filesize = cmdSock.gets.chomp
		run = 1
		currentSize = 0
		File.open(path, 'wb') do |file|
			while run == 1
				#read data from socket and update current size of download
				data = sock.gets
				size = data.size
				currentSize += size
				#write data to file
				file.write(data)
				if currentSize == filesize.to_i
					run = 0
				end
			end
		end
		puts "Done recieving file!"
	else
		puts "Client is trying sending a file we already have"
		cmdSock.puts("0")
		cmdSock.puts("The file you're tryng to send already exists" \
			" on the server (LIST command)")
		puts "test"
	end
end

def getCmd (fName, cmdSock, sock)
	puts "Client sent a get command"
	puts fName
	sendThread(cmdSock, sock, fName)
	#respond to client
	#open new socket to client on 7006
end

def sendCmd (fName, cmdSock, sock)
	puts "Client sent a send command"
	recvThread(cmdSock, sock, fName)
end

def listCmd(cmdSock, sock)
	puts "Client sent a list command"
	#get all files from the directory but ignore hidden . and ..
	path = File.expand_path("..", Dir.pwd) + "/testFiles"
	dirFiles = Dir.entries(path).reject{|entry| entry == "." || entry ==".."}
	#tell the client how many files there are
	numFiles = dirFiles.length
	cmdSock.puts(numFiles)
	puts "Sent # of files to client"
	#for each file in the directoy
	for fileName in dirFiles
		#send the filename
		sock.puts(fileName)
	end
	puts "Sent all file names"
end

def quitCmd
	puts "Cient sent a quit command"
end

def clientFunc(sock, dataServer)
	#read command from socket
	puts "Getting a command from client"
	command = sock.gets.chomp
	puts command
	dataSocket = dataServer.accept
	case command
	when 'GET'
		fName = sock.gets.chomp
		puts fName
		getCmd(fName, sock, dataSocket)	

	when 'SEND'
		fName = sock.gets.chomp
		puts fName
		sendCmd(fName, sock, dataSocket)

	when 'LIST'
		listCmd(sock, dataSocket)

	when 'QUIT'
		quitCmd
		client.close
		dataSocket.close
	else
		puts "Unknown command"

	end
	dataSocket.close
end

server = TCPServer.open(7005) # Server bound to port 7000
dataServer = TCPServer.open(7006) #server for data transfers

run = 1
while run == 1 do
  	Thread.start(server.accept) do |client|
	  	#infinite loop to handle client
	  	puts "A new client connected!"
	  	i = 1
	  	while i == 1 do
		  	clientFunc(client, dataServer)
		end
  	end
end