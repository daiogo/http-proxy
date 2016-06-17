require 'socket'

# Defines constants
PROXY_SERVER_PORT = 3000
HTTP_SERVER_PORT = 80

# Opens TCP connection with proxy server
proxy_server_socket = TCPServer.open(PROXY_SERVER_PORT)

# Makes proxy server run forever
loop do

	# Creates a new thread for each incoming request from clients
	Thread.start(proxy_server_socket.accept) do |proxy_client_socket|

		# Retrieves client's HTTP request
		client_request = proxy_client_socket.gets

		# Uses regex to match URL
		server_hostname = client_request.match(/([\da-z\.-]+)\.([a-z\.]{2,6})/).to_s

		# Opens TCP connection with HTTP server on the matched URL
		http_client_socket = TCPSocket.open(server_hostname, HTTP_SERVER_PORT)

		# Sends request to HTTP server
		http_client_socket.puts "GET / HTTP/1.1"
		http_client_socket.puts "Host: " + server_hostname
		http_client_socket.puts "\r\n\r\n"

		# Prints HTTP response code and IP addresses
		response_code = http_client_socket.gets
		puts "------RESPONSE------"
		puts response_code
		puts "----PROXY SERVER ADDRESS----"
		puts proxy_client_socket.peeraddr[3]
		puts "----HTTP SERVER ADDRESS----"
		puts http_client_socket.peeraddr[3]
		puts "\n"

		# Gets HTTP server response
		http_server_response = ''
		while line = http_client_socket.gets
			http_server_response += line
		end

		# Checks if it contains the undesired word
		if http_server_response =~ /[Mm]onitorando/
			http_server_response = "<!DOCTYPE html><html><head><title>Warning!</title></head><body><p>Access not authorized!</p></body></html>"
		else
			http_server_response = response_code + http_server_response
		end

		proxy_client_socket.puts http_server_response

		http_client_socket.close
		proxy_client_socket.close

	end
end