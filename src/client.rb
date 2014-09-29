#!/usr/bin/env ruby 

require 'socket'

#accept and control channels always use port 7005
#data channels always use port 7006
#server responses are 1 for success 0 for error

#constants
size = 1024

#use command types in messages

#Function definitions
def recvFile (sock)
	fRecv = File.open('./out', 'wb')
	while data = sock.gets
		puts "test"
		fRecv.write(data)
	end

	#while data = sock.read(size) # Read lines from socket
	#  fRecv.write(data)         # and print them
	#end
end

def recvThread (fName, filesize, sock)
	#create new socket for data transfer
	currentSize = 0
	#amount to read
	size = 1024
	puts "Starting to read file data from socket"
	run = 1

	File.open(fName, 'wb') do |file|
		while run == 1
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
	puts "End of file!"
end

def sendThread (cmdSock, sock, fName)
	path = File.expand_path("..", Dir.pwd) + "/testFiles/" + fName
	begin
		File.open(fName, "rb") do |file|
			cmdSock.puts(file.size)
			while data = file.gets do
				sock.puts(data)
			end
		end
		puts "Done sending file!"
	rescue SystemCallError
		raise StandardError
		puts "Unable to open file"
		#notify client of invalid file name
		sock.puts("0")
		sock.puts("Error opening file, make sure the"\
			" file you're trying to open exists (LIST command)")
	end

end

def getCmd (cmdSock, sock, fName)
	#send get command and file name
	cmdSock.puts('GET')
	cmdSock.puts(fName)
	#get response from server
	response = cmdSock.gets.chomp
	#switch on response
	case response
	when '1'#success
		#start new thread for data transfer
		fSize = cmdSock.gets.chomp
		recvThread(fName, fSize, sock)
	when '0' #failure (file doesn't exist) 
		puts "failure"
		response = sock.gets.chomp
		puts response
	end
end

def sendCmd (cmdSock, sock, fName)
	#send command and file name
	cmdSock.puts('SEND')
	cmdSock.puts(fName)
	response = cmdSock.gets.chomp

	case response
	when '1'#success
		#start a new thread for data transfer
		sendThread(cmdSock, sock, fName)
	when '0'#failure (file already exists)
		response = cmdSock.gets.chomp
		puts response
	end
end

def listCmd (cmdSock, sock)
	cmdSock.puts('LIST')
	numFiles = cmdSock.gets.chomp
	puts numFiles
	i = 0
	if numFiles == 0
		puts "No files available in the servers current file directory, try sending some files."
	else
		run = 1
		while run == 1
			i += 1
			fName = sock.gets.chomp
			out = i.to_s + ") " + fName
			puts out
			if i == numFiles.to_i
				run = 0
			end
		end
		puts "End of list"
	end
end

def commandLoop (sock, serverIP)
	i = 1
	while i == 1 do
		puts "Available commands: GET, SEND, LIST, QUIT"
		STDOUT.flush
		command = STDIN.gets.chomp
		dataSocket = TCPSocket.new serverIP, 7006
		case command
		when 'GET'
			puts "Please enter the name of the file you want to download:"
			fName = STDIN.gets.chomp
			getCmd(sock, dataSocket, fName)
		
		when 'SEND'
			puts "NOTE: files for sending must be in the same directory "\
				"that you're running the client from."
			puts "Please enter the name of the file you want to send:"
			fName = STDIN.gets.chomp
			sendCmd(sock, dataSocket, fName)
		
		when 'LIST'
			listCmd(sock, dataSocket)
		
		when 'QUIT' 
			puts command
			sock.puts('QUIT')
			i = 0
		end 
		dataSocket.close	
	end

end

#main script

#get ip address for server
puts "Please enter the IP address of the server you want to connect to: "
ip = STDIN.gets.chomp
s = TCPSocket.new ip, 7005
commandLoop(s, ip)
s.close             # close socket when done