require 'nokogiri'
require 'zipruby'
require 'pathname'
require 'fileutils'
require 'aws-sdk'

def build_xml_manifest(dir, name)
  base = Pathname.new(dir)
  mp4_path = base + (name + '.mp4')
  xml_path = base + (name + '.xml')
  xml_file = File.open(xml_path, 'w+')
  builder = Nokogiri::XML::Builder.new('encoding' => 'UTF-8') do |xml|
    xml.assets {
      xml.repVideoFIleName mp4_path
    }
  end
  xml_file << builder.to_xml
  xml_file.close
end

def pack_up(name)
  path = Pathname(File.expand_path(File.dirname(__FILE__))) + name
  Dir.mkdir(path)
  current = Pathname(File.expand_path(File.dirname(__FILE__)))
  FileUtils.mv(current + (name + '.mp4'), path + (name + '.mp4'))
  FileUtils.mv(current + (name + '.xml'), path + (name + '.xml'))

  Zip::Archive.open((path.to_s + '.zip'), Zip::CREATE) do |zip|
    zip.add_dir path.to_s
  end
end

def ship(zip_file_location)
  resp = ''
  creds = Aws::Credentials.new(
    '',
    ''
  )
  s3 = Aws::S3::Client.new(
            region: 'us-west-2',
            credentials: creds
          )

  File.open(zip_file_location.to_s, 'r') do |file|
    resp = s3.put_object(bucket: 'backlog-pointway', key: zip_file_location.to_s, body: file)
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
  name = Dir["#{File.expand_path(File.dirname(__FILE__))}/" + '*.mp4'].first.split(/[\/|\\]/).last.gsub('.mp4', '') || ARGV[0]
  build_xml_manifest(dir, name)
  pack_up(name)
  ship(Pathname.new(dir) + (name + '.zip'))
  pbcopy(name)
  name
end

run
