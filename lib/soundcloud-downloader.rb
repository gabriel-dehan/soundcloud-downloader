require 'net/http'
require 'securerandom'
require 'tempfile'
require 'fileutils'

# Public: Basic SoundCloud Stream Client, allows to get the url of a sound from it's API url
#         and download the sound even if private by following the redirection.
#
# Classes:
#
#   SoundCloud::Downloader::Helpers <-- Display helpers
#   SoundCloud::Downloader::Client  <-- Download Client
#
module SoundCloud
  module Downloader
    class Error < StandardError; end

    class Helpers
      # Public: Displays a progress bar
      #
      # char - A unique Character, respresenting the progress in the progress bar.
      # end_char - A unique Character, showed on the end of the progress bar.
      # position - A Number, the current position.
      #
      #  Examples:
      #
      #    SoundCloud::Downloader::Helpers.progress_bar('=', '>', 5)
      #    # =====>
      #    SoundCloud::Downloader::Helpers.progress_bar('=', '>', 10)
      #    # ==========>
      #
      def self.progress_bar(char, end_char, position)
        print "\r\e[0K" + (char * position) + end_char
        $stdout.flush
      end
    end

    class Client

      attr_reader :client_id, :path, :fs_location, :url

      # Public: Constructor
      #
      # opts - A Hash of options
      #        :client_id - The soundcloud client id as a String.
      #        :path      - A String, path to a directory where downloaded files will be stored. If no path is specified, downloaded files will be saved in a temporary directory and deleted upon exit
      #
      # Returns an instance of StreamClient
      def initialize(opts)
        @client_id = opts[:client_id]
        @path      = opts[:path]
        @url       = nil
      end

      # Public: Simplest method to download a file
      #
      # file_name - The file name as a String
      # url - The stream URL of the soundclound sound as a String
      #
      # Returns a File
      def download(url, opts = { display_progress: true, file_name: "unknown" })
        self.resolve(url)
        self.load opts[:file_name] do |length, position, chunk|
          SoundCloud::Downloader::Helpers.progress_bar("=", ">", position) if opts[:display_progress]
        end
      end

      # Public: resolves a soundcloud API url
      #
      # url - The URL to resolve as a String.
      #
      # Returns the direct URL to the corresponding mp3 file as a String.
      def resolve url
        uri = URI.parse(url)
        res = Net::HTTP.start('api.soundcloud.com', 443, use_ssl: true) do |http|
          http.request(Net::HTTP::Get.new("#{uri.path}?client_id=#{@client_id}"))
        end

        if res.code == '302'
          @url = res.header['Location']
        end
      end

      # Public: loads a file, either downloading it in the specified directory or in a temporory file
      #
      # name  - A String, the downloaded mp3 file name. If none specified, a random name will be given. If a file already exists, it will not be reloaded.
      # block - A Proc, Lambda, Block, called with the following arguments : content_size, progress, content
      #
      # Returns the location of the downloaded file as a String.
      def load(name = SecureRandom.hex, &block)
        unless @url
          raise SoundCloud::Downloader::Error.new('URL not found, did you call `#resolve` first ?')
        end

        uri       = URI.parse(@url)
        file_path = fs_location(name)

        unless File.exists?(file_path)
          Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
            request = Net::HTTP::Get.new(@url)

            http.request request do |response|
              open fs_location(name), 'w' do |io|

                position = 0
                length = response['Content-Length'].to_i

                response.read_body do |chunk|
                  if block_given?
                    position += chunk.length
                    block.call(length.fdiv(length) * 100, (position.fdiv(length) * 100).to_i, chunk)
                  end
                  io.write chunk
                end
              end
            end
          end
        end

        @fs_location
      end

      # Public: deletes the last loaded file
      #
      # force - A Boolean Flag, if set to :force, or true, it will also delete the file in your `path` directory.
      #
      # Returns Nothing.
      def end_stream(force = false)
        raise SoundCloud::Downloader::Error.new('No files were loaded, nothing to clean up.') unless @fs_location
        if (force && @path) || (!@path)
          FileUtils.rm(@fs_location)
        end
      end

      private

      # Private: determines the location of the downloaded file on the file system
      #
      # name - the name of the file as a String
      #
      # Returns the path as a String.
      def fs_location(name)
        @fs_location =
          if @path
            FileUtils.mkdir(@path) unless File.directory?(@path)
            "#@path/#{name}.mp3"
          else
            Tempfile.new(['souncloud', '.mp3'])
          end
      end
    end
  end
end
