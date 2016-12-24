require 'nokogiri'
require 'open-uri'
require 'v8'
require 'net/http'
require 'fileutils'

url = ARGV[0]

topics = {}

@doc = Nokogiri::HTML(open(url))
mainSection = @doc.css(".t_f").first

def getTopics(mainSection)
	topics = {}
	mainSection.css("div > ul > li").each do |li|
		a = li.css("a").first
		key = a.attr("href").split("#").last
		topics[key] = a.text
	end
	topics
end

def getVideos(mainSection, topics)
	topics.each do |hash, topic|
		mainSection.css("##{hash} > span").each do |span|
			url = span.attr("href")
			videoDoc = Nokogiri::HTML(open(url))
			encryptedText = videoDoc.css("script")[-2].text
			jsCode =  "var fuck = " + encryptedText[5...-2] + "; fuck"
			cxt = V8::Context.new
			decompiledJsCode =  cxt.eval(jsCode)

			filesJson = /(?:sources:)(.*)(?:,tracks:)/.match(decompiledJsCode)[1]
			files = eval(filesJson)
			videoUrl = files.last[:file]
			download(videoUrl, topic)
		end
	end
end

def download(url, name)
	puts "Downloading #{name}..."
	FileUtils::mkdir_p "collections/#{getCollectionName}"
	open("collections/#{getCollectionName}/#{name}.mp4", 'wb') do |file|
		file << open(url).read
		puts "Done."
	end
end

def getCollectionName()
	@collectionName ||= @doc.css(".album h1").text
end

topics = getTopics(mainSection)
getVideos(mainSection, topics)
