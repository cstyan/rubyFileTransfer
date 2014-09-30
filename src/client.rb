#!/usr/bin/env ruby 

#----------------------------------------------------------------------------------------------------------------
#-- SOURCE FILE: client.rb - Contains implementation of all functions needed for the client.
#--
#-- PROGRAM: COMP 7005 - File Transfer
#--
#-- FUNCTIONS:
#--  recvThread(fName, filesize, sock)
#--  sendThread(cmdSock, sock, fName)
#--  getCmd(cmdSock, sock, fName)
#--  sendCmd(cmdSock, sock, fName)
#--  listCmd(cmdSock, sock)
#--  commandLoop(sock, serverIP)
#--
#-- DATE: September 29, 2014
#--
#-- REVISIONS: (Date and Description)
#--
#-- DESIGNER: Callum Styan
#--
#-- PROGRAMMER: Callum Styan
#--
#-- NOTES:
#-- This file contains all the necessary function implementations the client portion of this assignment, which
#-- handles sending commands to the server and all data transfer related to files.
#----------------------------------------------------------------------------------------------------------------------

#libraries
require 'socket'

#accept and control channels always use port 7005
#data channels always use port 7006
#server responses are 1 for success 0 for error

#constants
size = 1024

#Function definitions

#------------------------------------------------------------------------------------------------------------------
#-- FUNCTION: recvThread
#--
#-- LAST REVISION: September 29, 2014
#--
#-- DESIGNER: Callum Styan
#--
#-- PROGRAMMER: Callum Styan
#--
#-- INTERFACE: recvThread(fName, filesize, sock)
#--              fName: name of the file we requested from the server
#--              filesize: size of the file we requested from the server
#--				 sock: socket for the transfer of file data
#--
#-- NOTES:
#-- This function handles downloading all file data from the server.  It opens a file and then
#-- loops to read data from the socket until the amount of data recieved is equal to the filesize.
#-- The function is called recvThread but is not run in it's own thread, this is planning ahead
#-- in case we want multithread to allow multiple file transfers client side concurrently.
#----------------------------------------------------------------------------------------------------------------------
def recvThread (fName, filesize, sock)
	currentSize = 0
	#amount to read
	size = 1024
	puts "Starting to read file data from socket"
	run = 1
	File.open(fName, 'wb') do |file|
		puts "File is downloading . . . "		
		while run == 1
			data = sock.gets
			#for some reason this check is necessary when
			#transferring mp3 files
			if data.class == NilClass
				run = 0
				next 
			end
			size = data.size
			currentSize += size
			#write data to file
			file.write(data)
			if currentSize == filesize.to_i
				run = 0
			end
		end
		puts " 	"
	end
	puts "End of file download!"
end

#------------------------------------------------------------------------------------------------------------------
#-- FUNCTION: sendThread
#--
#-- LAST REVISION: September 29, 2014
#--
#-- DESIGNER: Callum Styan
#--
#-- PROGRAMMER: Callum Styan
#--
#-- INTERFACE: sendThread(fName, filesize, sock)
#--              fName: name of the file we requested from the server
#--              filesize: size of the file we requested from the server
#--				 sock: socket for the transfer of file data
#--
#-- NOTES:
#-- This function handles sending all file data to the server.  It opens a file and then
#-- loops to send data to the socket until the entire file has been sent.
#-- The function is called sendThread but is not run in it's own thread, this is planning ahead
#-- in case we want multithread to allow multiple file transfers client side concurrently.
#----------------------------------------------------------------------------------------------------------------------
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

#------------------------------------------------------------------------------------------------------------------
#-- FUNCTION: getCmd
#--
#-- LAST REVISION: September 29, 2014
#--
#-- DESIGNER: Callum Styan
#--
#-- PROGRAMMER: Callum Styan
#--
#-- INTERFACE: getCmd(cmdSock, sock, fName)
#--              cmdSock: socket for the transfer of commands
#--				 sock: socket for the transfer of file data
#--              fName: name of the file we requested from the server
#--
#-- NOTES:
#--	This function handles the client sending a GET command.  It sends the command and filename were requesting.
#-- Then the function reads the servers response and will continue based on the response.  If the command succeeded
#-- the client will begin downloading the file by calling recvThread, otherwise it will read an error message from
#-- the server.
#----------------------------------------------------------------------------------------------------------------------
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

#------------------------------------------------------------------------------------------------------------------
#-- FUNCTION: sendCmd
#--
#-- LAST REVISION: September 29, 2014
#--
#-- DESIGNER: Callum Styan
#--
#-- PROGRAMMER: Callum Styan
#--
#-- INTERFACE: sendCmd(cmdSock, sock, fName)
#--              cmdSock: socket for the transfer of commands
#--				 sock: socket for the transfer of file data
#--              fName: name of the file we requested from the server
#--
#-- NOTES:
#--	This function handles the client sending a SEND command.  It sends the command and filename were sending.
#-- Then the function reads the servers response and will continue based on the response.  If the command succeeded
#-- the client will begin sending the file by calling sendThread, otherwise it will read an error message from
#-- the server.
#----------------------------------------------------------------------------------------------------------------------
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

#------------------------------------------------------------------------------------------------------------------
#-- FUNCTION: listCmd
#--
#-- LAST REVISION: September 29, 2014
#--
#-- DESIGNER: Callum Styan
#--
#-- PROGRAMMER: Callum Styan
#--
#-- INTERFACE: listCmd(cmdSock, sock)
#--              cmdSock: socket for the transfer of commands
#--				 sock: socket for the transfer of file data
#--
#-- NOTES:
#--	This function handles the client sending a LIST command.  It sends the command and then reads the number of files
#-- from the cmdSock.  It then loops until it reads the name of each file from the socket.
#----------------------------------------------------------------------------------------------------------------------
def listCmd (cmdSock, sock)
	cmdSock.puts('LIST')
	numFiles = cmdSock.gets.chomp
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

#------------------------------------------------------------------------------------------------------------------
#-- FUNCTION: commandLoop
#--
#-- LAST REVISION: September 29, 2014
#--
#-- DESIGNER: Callum Styan
#--
#-- PROGRAMMER: Callum Styan
#--
#-- INTERFACE: commandLoop(sock, serverIP)
#--				 sock: socket for the transfer of file data
#--              fName: name of the file we requested from the server
#--
#-- NOTES:
#--	This function loops (until a QUIT command is sent) to handle client commands.  It reads a command and then calls
#-- the appropriate function to handle that command.  Note that a second socket is created for transfering file data.
#----------------------------------------------------------------------------------------------------------------------
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
		else
			puts "Invalid command, please try again"
		end 
		dataSocket.close	
	end

end

#main script, intializes socket and then calls command loop
#get ip address for server
puts "Please enter the IP address of the server you want to connect to: "
ip = STDIN.gets.chomp
s = TCPSocket.new ip, 7005
commandLoop(s, ip)
s.close             # close socket when done