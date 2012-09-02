# -*- encoding: UTF-8 -*-
require 'date'
require 'optparse'
require 'open-uri'
require 'nokogiri'

force = false
opt = OptionParser.new
opt.on('-f'){|v| force = v}
opt.parse!(ARGV)

if ARGV.empty?
	source = nil
	count = 0
	until source
		begin
			source = open('http://blog.tatsuru.com/').read
		rescue Timeout::Error, StandardError
			puts "#{count += 1}:#{Time.now}"
			sleep 30
			next
		end
	end
	doc = Nokogiri(source.gsub('<em>', '((*').gsub('</em>', '*))'))
	date = doc.at('h2.date-header').inner_text
	title = doc.at('h3.entry-header').inner_text
	body = doc.at('div.entry-body').inner_html
	issue = '(' + date + ' のエントリより転載)'

	gap = Date.today - Date.parse(date.gsub('.', '-'))
	gap_text = case gap
	when 0
		'今日'
	when 1
		'昨日'
	else
		'%d 日前に' % [gap]
	end
	STDERR.puts ('最新のエントリは ' + date + ' で ' + gap_text + '更新されたものです。').encode('SJIS')
else
	target = ARGV.first.gsub('-', '/') + '.php'
	date = ARGV.first.split('_').first.gsub('-', '.')
	uri = 'http://blog.tatsuru.com/' + target
	source = open(uri).read rescue raise(uri)
	doc = Nokogiri(source.gsub('<em>', '((*').gsub('</em>', '*))'))
	title = doc.at('#archive-title').inner_text
	body = doc.at('div.entry-body').inner_html
	issue = '(アーカイブ ' + date + ' のエントリより転載)'
end

body_text = body.strip.gsub(/<[^>]+>/, '')
size = body_text.size

case
when 500 > size
	raise "このエントリは #{size} 文字で、通天で紹介するのは不適切です。".encode('SJIS')
when 1000 > size
	warn "このエントリは #{size} 文字で、通天で紹介するには短過ぎます。".encode('SJIS')
	unless force
		STDERR.puts "敢えて作成するなら強制オプション(-f)を指定して下さい。".encode('SJIS')
		raise
	else
		STDERR.puts '強制オプション(-f)が指定されたので、 txt ファイルを生成します。'.encode('SJIS')
	end
when 2000 > size
	warn "このエントリは #{size} 文字で、通天で紹介するには、短過ぎるかもしれません。".encode('SJIS')
end

out_file = 'tatsuru' + date.gsub('.', '') + '.txt'
open(out_file, 'w') do |txt|
	txt.puts '■内田樹の研究室(分室)'
	txt.puts '§' + title
	txt.puts issue
	txt.puts body_text
end
