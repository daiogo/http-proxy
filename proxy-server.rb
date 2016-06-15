require 'socket'                									# Get sockets from stdlib

################## CONSTANTS ##################

# Files will be served from this directory
WEB_ROOT = './public'

# Map extensions to their content type
CONTENT_TYPE_MAPPING = {
	'html' => 'text/html',
	'txt' => 'text/plain',
	'png' => 'image/png',
	'jpg' => 'image/jpeg'
}

# Treat as binary data if content type cannot be found
DEFAULT_CONTENT_TYPE = 'application/octet-stream'

PROXY_SERVER_PORT = 3000
HTTP_SERVER_HOSTNAME = 'localhost'
HTTP_SERVER_PORT = 2345

################## FUNCTIONS ##################

# Parses the extension of the requested file and then looks up its content type.
def content_type(path)
	ext = File.extname(path).split(".").last
	CONTENT_TYPE_MAPPING.fetch(ext, DEFAULT_CONTENT_TYPE)
end

################## PROXY SERVER ##################

proxy_server_socket = TCPServer.open(PROXY_SERVER_PORT)   			# Socket to listen on port 2000

loop {                          									# Servers run forever
	Thread.start(proxy_server_socket.accept) do |client|

		request_line = client.gets

		STDERR.puts request_line

		proxy_client_socket = TCPSocket.open(HTTP_SERVER_HOSTNAME, HTTP_SERVER_PORT)

		proxy_client_socket.puts request_line

		http_server_response = ''

		while line = proxy_client_socket.gets   					# Read lines from the socket
		  http_server_response += line      						# And print with platform line terminator
		end

		proxy_client_socket.close               					# Close the socket when done

		if http_server_response =~ /Monitoring/

			# Make sure the file exists and is not a directory
			# before attempting to open it.
			path = './public/not_authorized.html'

			if File.exist?(path) && !File.directory?(path)
				File.open(path, "rb") do |file|
				client.print 	"HTTP/1.1 200 OK\r\n" +
								"Content-Type: #{content_type(file)}\r\n" +
								"Content-Length: #{file.size}\r\n" +
								"Connection: close\r\n"

				client.print 	"\r\n"

				# write the contents of the file to the socket
				IO.copy_stream(file, client)
				end

			else
				message = "File not found\n"

				# respond with a 404 error code to indicate the file does not exist
				client.print "HTTP/1.1 404 Not Found\r\n" +
				"Content-Type: text/plain\r\n" +
				"Content-Length: #{message.size}\r\n" +
				"Connection: close\r\n"

				client.print "\r\n"

				client.print message
			end

		else
			client.puts http_server_response
		end
		client.close                								# Disconnect from the client
	end
}