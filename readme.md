# Ruby - SoundCloud Downloader

This library provides three things :

- A way to download any Soundcloud sound in a temporary directory to stream the mp3 file
- A way to download any Soundcloud sound in a less temporary fashion so you can save the mp3 file
- A way to display a progress bar as the retrieving of the Souncloud stream is, well, progressing.

The only thing you need are a **SoundCloud CLIENT_ID** and the stream URL of a track which is fetchable through [the API](https://developers.soundcloud.com/docs/api/reference#tracks)

## Installation

```
$ gem install soundcloud-downloader
```

Or in `Gemfile`
```
$ gem soundcloud-downloader
```

## Usage

```ruby
require 'soundcloud-downloader'
```

## Basicaly

```ruby
downloader = SoundCloud::Downloader::Client.new(client_id: SOUNDCLOUD_CLIENT_ID, path: 'download')
downloader.download(url, { file_name: "file name you want", display_progress: true })
# Will display a download progress bar and download the file in the 'download' directory
```

## Advanced

Example 1 : Get sounds and stores them in temporary files

```ruby

# We instanciate the downloader client (don't forget to replace SOUNDCLOUD_CLIENT_ID with your real Client id)
downloader = SoundCloud::Downloader::Client.new(client_id: SOUNDCLOUD_CLIENT_ID)

# The downloader requires you to give it a Soundcloud API download_url
downloader.resolve("https://api.soundcloud.com/tracks/147462663/stream")

# This will retrieve the previous URL's content and store it in a temporary file
file = downloader.load do |length, position, data|
# This will display a progress_bar when downloading the file
SoundCloud::Downloader::Helpers.progress_bar("=", ">", position)
end

puts file # => /tmp/fosdjiofw2343242.mp3

# Here you do your stuff with the file (Play it for example !)

# Delete the temporary files
downloader.end_stream
```


Example 2 : Get sounds and stores them in a directory

```ruby

# The path variables is the directory in which you want to download your soundcloud files
downloader = SoundCloud::Downloader::Client.new(client_id: SOUNDCLOUD_CLIENT_ID, path: 'downloads')

downloader.resolve("https://api.soundcloud.com/tracks/147462663/stream")
file = downloader.load "myMusicFile" do |length, position, chunk|
SoundCloud::Downloader::Helpers.progress_bar("=", ">", position)
end

puts file # => downloads/myMusicFile.mp3

# BE CAREFUL ! The following line will DELETE the last downloaded file, you might not want to do that
downloader.end_stream :force

# You can download as many files as you want :
downloader.resolve("https://api.soundclound.com/blabla/other_url")
file2 = downloader.load "myOtherMusicFile"
downloader.resolve("https://api.soundclound.com/blabla/yet_another_other_url")
file3 = downloader.load "myOtherMusicFile3"

```
