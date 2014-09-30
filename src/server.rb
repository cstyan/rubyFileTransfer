#!/usr/bin/env ruby 

#----------------------------------------------------------------------------------------------------------------
#-- SOURCE FILE: server.rb - Contains implementation of all functions needed for the server.
#--
#-- PROGRAM: COMP 7005 - File Transfer
#--
#-- FUNCTIONS:
#--  sendThread(cmdSock, sock, fName)
#--  recvThread(cmdSock, sock, fName)
#--  getCmd(fName, cmdSock, sock)
#--  sendCmd(fName, cmdSock, sock)
#--  listCmd(cmdSock, sock)
#--  quitCmd
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

size = 1024

#function definitions

#------------------------------------------------------------------------------------------------------------------
#-- FUNCTION: sendThread
#--
#-- LAST REVISION: September 29, 2014
#--
#-- DESIGNER: Callum Styan
#--
#-- PROGRAMMER: Callum Styan
#--
#-- INTERFACE: sendThread(cmdSock, sock, fName)
#--              cmdSock: socket for the transfer of commands
#--				 sock: socket for the transfer of file data
#--              fName: name of the file we requested from the server
#--
#-- NOTES:
#-- This function handles sending all file data to a client.  It checks to see if the requested
#-- file exists.  If it doesn't it returns a failure and error message to the client, otherwise it
#-- loops to send data to the client until the entire file has been sent.
#-- The function is called sendThread but is not run in it's own thread, this is planning ahead
#-- in case we want multithread to allow multiple file transfers client side concurrently.
#----------------------------------------------------------------------------------------------------------------------
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

#------------------------------------------------------------------------------------------------------------------
#-- FUNCTION: recvThread
#--
#-- LAST REVISION: September 29, 2014
#--
#-- DESIGNER: Callum Styan
#--
#-- PROGRAMMER: Callum Styan
#--
#-- INTERFACE: recvThread(cmdSock, sock, fName)
#--              cmdSock: socket for the transfer of commands
#--				 sock: socket for the transfer of file data
#--              fName: name of the file we requested from the server
#--
#-- NOTES:
#-- This function handles recieving all file data from a client.  It checks to see if the requested
#-- file exists.  If it does it returns a failure and error message to the client, otherwise it
#-- loops to read all file data from the client until the data recieved is equal to the filesize.
#-- The function is called recvThread but is not run in it's own thread, this is planning ahead
#-- in case we want multithread to allow multiple file transfers client side concurrently.
#----------------------------------------------------------------------------------------------------------------------
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

#------------------------------------------------------------------------------------------------------------------
#-- FUNCTION: getCmd
#--
#-- LAST REVISION: September 29, 2014
#--
#-- DESIGNER: Callum Styan
#--
#-- PROGRAMMER: Callum Styan
#--
#-- INTERFACE: getCmd(fName, cmdSock, sock)
#--              fName: name of the file we requested from the server
#--              cmdSock: socket for the transfer of commands
#--				 sock: socket for the transfer of file data
#--
#-- NOTES:
#--	This function handles the client sending a GET command.  It confirms command type and then calls sendThread.
#----------------------------------------------------------------------------------------------------------------------
def getCmd (fName, cmdSock, sock)
	puts "Client sent a get command"
	puts fName
	sendThread(cmdSock, sock, fName)
	#respond to client
	#open new socket to client on 7006
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
#-- INTERFACE: sendCmd(fName, cmdSock, sock)
#--              fName: name of the file we requested from the server
#--              cmdSock: socket for the transfer of commands
#--				 sock: socket for the transfer of file data
#--
#-- NOTES:
#--	This function handles the client sending a SEND command.  It confirms command type and then calls recvThread.
#----------------------------------------------------------------------------------------------------------------------
def sendCmd (fName, cmdSock, sock)
	puts "Client sent a send command"
	recvThread(cmdSock, sock, fName)
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
#-- INTERFACE: sendCmd(cmdSock, sock)
#--              cmdSock: socket for the transfer of commands
#--				 sock: socket for the transfer of file data
#--
#-- NOTES:
#--	This function handles the client sending a LIST command.  It confirms command type, creates an array of all files
#-- available to the client, and then sends each file name to client.
#----------------------------------------------------------------------------------------------------------------------
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

#------------------------------------------------------------------------------------------------------------------
#-- FUNCTION: quitCmd
#--
#-- LAST REVISION: September 29, 2014
#--
#-- DESIGNER: Callum Styan
#--
#-- PROGRAMMER: Callum Styan
#--
#-- INTERFACE: quitCmd
#--
#-- NOTES:
#--	This function handles the client sending a LIST command.  IT's probably unnecessary for suh a small program to 
#-- actually do anything here.
#----------------------------------------------------------------------------------------------------------------------
def quitCmd
	puts "Cient sent a quit command"
end

#------------------------------------------------------------------------------------------------------------------
#-- FUNCTION: clientFunc
#--
#-- LAST REVISION: September 29, 2014
#--
#-- DESIGNER: Callum Styan
#--
#-- PROGRAMMER: Callum Styan
#--
#-- INTERFACE: clientFunc(sock, dataServer)
#--              sock: initial socket created on accept call, used for command transfers
#--              dataServer: TCPServer object, used to create a second socket connection for file data transfer
#--
#-- NOTES:
#--	This function loops to recieve commands from a connected client and then calls the appropriate function for based
#-- on the command it was sent.
#----------------------------------------------------------------------------------------------------------------------
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


#main script, initializes server sockets and then starts loop
#to accept client connections
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