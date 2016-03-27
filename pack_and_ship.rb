# so  here is the steps
# 1. save file runs script
# 2. ruby builds XML
# 3. ruby zips file
# 4. copy to S3
# 5. put url in paste buffer
# 6. display URL
# 7. give status (file copied,,,)
require 'nokogiri'
require 'zipruby'
require 'byebug'
require 'pathname'
require 'fileutils'

def build_xml_manifest(name)
  mp4 = Pathname.new("#{File.expand_path(File.dirname(__FILE__))}/#{name}.mp4")
  png = Pathname.new("#{File.expand_path(File.dirname(__FILE__))}/#{name}.png")
  builder = Nokogiri::XML::Builder.new('encoding' => 'UTF-8') do |xml|
    xml.assets {
      xml.repVideoFIleName mp4
      xml.headshot png
    }
  end
  builder.to_xml
end

def pack_up(name)
  path = Pathname(File.expand_path(File.dirname(__FILE__))) + name
  Dir.mkdir(path)
  current = Pathname(File.expand_path(File.dirname(__FILE__)))
  FileUtils.mv(current + (name + '.mp4'), path + (name + '.mp4'))
  FileUtils.mv(current + (name + '.png'), path + (name + '.png'))
  FileUtils.mv(current + (name + '.xml'), path + (name + '.xml'))

  Zip::Archive.open(path, Zip::CREATE) do |zip|
    zip.add_dir path
  end
end

def ship(name)
  resp = ''
  creds = Aws::Credentials.new(
    ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY']
  )

  File.open(location, 'r') do |file|
    resp = s3.put_object(bucket: 'backlog-pointway', key: xml_file_name, body: file)
    file.close
  end

  zip_file_name # figure out a way to get the url or hard code it
end

def give_url_to_public(name)
  byebug
  puts url
end

def run(name)
  build_xml_manifest(name)
  pack_up(name)
  ship(name)
  give_url_to_public(name)
end


run(Dir["#{File.expand_path(File.dirname(__FILE__))}/*.mp4"].first.split(/[\/,\\]/).last.gsub('.mp4', '') || ARGV[0])