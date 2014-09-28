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
	puts "starting to read file data from socket"
	run = 1

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
	puts "end of file"
	puts "done reading file from socket"
end

def sendThread (sock, fName)
	begin
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

end

def getCmd (sock, fName)
	#send get command and file name
	sock.puts('GET')
	sock.puts(fName)
	#get response from server
	response = sock.gets.chomp
	puts response
	
	case response
	when '1'#success
		#start new thread for data transfer
		fSize = sock.gets.chomp
		recvThread(file, fSize, sock)
	when '0' #failure (file doesn't exist) 
		response = sock.gets.chomp
		puts response
	end
end

def sendCmd (sock, fName)
	#send command and file name
	sock.puts('SEND')
	sock.puts(fName)

	response = sock.gets.chomp
	puts response

	case response
	when '1'#success
		#start a new thread for data transfer
		sendThread(sock, fName)
	when '0'#failure (file already exists)
		response = sock.gets.chomp
		puts response
	end
end

def listCmd (sock)
	sock.puts('LIST')
	numFiles = sock.gets.chomp
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
				puts "ending loop"
				run = 0
			end
		end
		puts "end of list"
	end

end

def commandLoop (sock)
	i = 1
	while i == 1 do
		puts "Available commands: GET, SEND, LIST, QUIT"
		STDOUT.flush
		command = STDIN.gets.chomp
		case command
		when 'GET'
			puts "Please enter the name of the file you want to download:"
			fName = STDIN.gets.chomp
			getCmd(sock, fName)
		
		when 'SEND'
			puts "NOTE: files for sending must be in the same directory "\
				"that you're running the client from."
			puts "Please enter the name of the file you want to send:"
			fName = STDIN.gets.chomp
			sendCmd(sock, fName)
		
		when 'LIST'
			listCmd(sock)
		
		when 'QUIT' 
			puts command
			i = 0
		end 	
	end

end

#main script
#getInput
#asdf = gets.chomp
#puts asdf

#get ip address for client
#ip address = gets.chomp
s = TCPSocket.new 'localhost', 7005
commandLoop(s)
s.close             # close socket when done