require 'byebug'
require 'nokogiri'
require 'zipruby'
require 'pathname'
require 'fileutils'
require 'aws-sdk'
require 'dotenv'

def build_xml_manifest(dir, name)
  base = Pathname.new(dir)
  mov_path = base + (name + '.mov')
  xml_path = base + (name + '.xml')
  xml_file = File.open(xml_path, 'w+')
  url = "http://  "
  builder = Nokogiri::XML::Builder.new('encoding' => 'UTF-8') do |xml|
    xml.assets {
      xml.repVideoFIleName 
    }
  end
  xml_file << builder.to_xml
  xml_file.close
end

def pack_up(name)
  path = Pathname(File.expand_path(File.dirname(__FILE__))) + name
  Dir.mkdir(path)
  current = Pathname(File.expand_path(File.dirname(__FILE__)))
  FileUtils.mv(current + (name + '.mov'), path + (name + '.mov'))
  FileUtils.mv(current + (name + '.xml'), path + (name + '.xml'))

  Zip::Archive.open((path.to_s + '.zip'), Zip::CREATE) do |zip|
    zip.add_dir path.to_s
  end
end

def ship(zip_file_location)
  resp = ''
  Dotenv.load
  creds = Aws::Credentials.new(ENV['KEY'], ENV['SECRET'])
  s3 = Aws::S3::Client.new(region: 'us-west-2', credentials: creds)

  File.open(zip_file_location.to_s, 'r') do |file|
    key = zip_file_location.to_s.split(/[\/|\\]/).last
    resp = s3.put_object(bucket: 'backlog-pointway', key: key, body: file)
    file.close
  end

  zip_file_location # figure out a way to get the url or hard code it
end

def pbcopy(input)
  str = input.to_s
  IO.popen('pbcopy', 'w') { |f| f << str }
  str
end

def run
  dir = File.expand_path(File.dirname(__FILE__))
  name = Dir["#{File.expand_path(File.dirname(__FILE__))}/" + '*.mov'].first.split(/[\/|\\]/).last.gsub('.mov', '') || ARGV[0]
  byebug
  build_xml_manifest(dir, name)
  pack_up(name)
  ship(Pathname.new(dir) + (name + '.zip'))
  pbcopy(name)
  name
end

run
