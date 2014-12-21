#!/usr/bin/ruby
require 'json'

inputFileName = "colours.json"
outputHeaderFileName = "Colours.h"
outputSourceFileName = "Colours.m"
outputXMLFileName = "colors.xml"

headerTemplateFileName 	= "Template.h"
sourceTemplateFileName 	= "Template.m"
xmlTemplateFilename 	= "Template.xml"


def isHex (stringForCheck)
	return stringForCheck[0] == '#'
end

def isFloat (stringForCheck)
	return stringForCheck.include? '.'
end

def isAlphaHex (stringForCheck)
	hexARGBLength = 9
	hexRGBLength = 7
	
	return stringForCheck.length == hexARGBLength
end

def extractHex (hexString)
	a = "FF"
	r = ""
	g = ""
	b = ""
	if isAlphaHex(hexString)
		r = hexString[1..2];
		g = hexString[3..4];
		b = hexString[5..6];
		a = hexString[7..8];
	else
		r = hexString[1..2];
		g = hexString[3..4];
		b = hexString[5..6];
	end
	return Hash["a"=>a.hex / 255.0, "r"=>r.hex / 255.0,"g"=>g.hex / 255.0, "b"=>b.hex / 255.0, "html" => hexString]
end

def extractFloat (floatString)
	a = 1.0

	chunks = floatString.split(",")
	r = chunks[0].to_f
	g = chunks[1].to_f
	b = chunks[2].to_f

	
	a = chunks[3].to_f if chunks.size == 4

	html = "#"
	html << (r * 255).to_i.to_s(16)
	html << (g * 255).to_i.to_s(16)
	html << (b * 255).to_i.to_s(16)
	html << (a * 255).to_i.to_s(16) if chunks.size == 4

	return Hash["a"=>a, "r"=>r,"g"=>g, "b"=>b, "html" => html]
end

def extractDecimal (floatString)
	a = 255

	chunks = floatString.split(",")
	r = chunks[0].to_f
	g = chunks[1].to_f
	b = chunks[2].to_f

	a = chunks[3].to_f if chunks.size == 4

	html = "#"
	html << r.to_i.to_s(16)
	html << g.to_i.to_s(16)
	html << b.to_i.to_s(16)
	html << a.to_i.to_s(16) if chunks.size == 4

	return Hash["a"=>a / 255.0, "r"=>r / 255.0,"g"=>g / 255.0, "b"=>b / 255.0,"html" => html]
end	

def processColour (colour)

	if isHex(colour)
		result = extractHex(colour)
	elsif isFloat(colour)
		result = extractFloat(colour)
	else
		result = extractDecimal(colour)
	end


	return result

end


inputFile = File.read(inputFileName)
parsed = JSON.parse(inputFile)["colours"]
converted = []

parsed.each do |val|
	converted.push(Hash["name" =>val["name"], "val"=>processColour(val["value"])])
end

headerString = ""
sourceString = ""
xmlString = ""

converted.each do |val|
	methodDef = "+ (UIColor *) app_" << val["name"]

	headerString << methodDef << ";\n"

	sourceString << methodDef << "\n{\n"

	sourceString << "\tstatic UIColor *c;\n"

	sourceString << "\tstatic dispatch_once_t onceToken;\n"
	sourceString << "\tdispatch_once(&onceToken, ^{\n"
	sourceString << "\t\tCGFloat a = " << val["val"]["a"].to_s << "f;\n"
	sourceString << "\t\tCGFloat r = " << val["val"]["r"].to_s << "f;\n"
	sourceString << "\t\tCGFloat g = " << val["val"]["g"].to_s << "f;\n"
	sourceString << "\t\tCGFloat b = " << val["val"]["b"].to_s << "f;\n"
	sourceString << "\t\tc = [UIColor colorWithRed:r green:g blue:b alpha:a];\n"
	sourceString << "\t});\n"
	sourceString << "\treturn c;"
	sourceString << "\n}\n\n"

	xmlString << "<color name=\"#{val["name"]}\">#{val["val"]["html"]}</color>\n"
end	

headerTemplate = File.read(headerTemplateFileName)
sourceTemplate = File.read(sourceTemplateFileName)
xmlTemplate = File.read(xmlTemplateFilename)

headerTemplate = headerTemplate.gsub(/headerCode/, headerString)
sourceTemplate = sourceTemplate.gsub(/sourceCode/, sourceString)
xmlTemplate = xmlTemplate.gsub(/xmlCode/, xmlString)

File.open(outputHeaderFileName, "w") { |file| file.puts (headerTemplate)}
File.open(outputSourceFileName, "w") { |file| file.puts (sourceTemplate)}
File.open(outputXMLFileName, "w") { |file| file.puts (xmlTemplate)}

puts "Done"

