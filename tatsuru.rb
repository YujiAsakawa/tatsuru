# -*- encoding: UTF-8 -*-
require 'date'
require 'optparse'
require 'open-uri'
require 'nokogiri'

force = false
repeat = 1
opt = OptionParser.new
opt.on('-f', 'Forced output.'){|v| force = v}
opt.on('-r NUM', 'Repeated get by number.'){|v| repeat = v.to_i}
opt.parse!(ARGV)

$stdout.set_encoding('Shift_JIS')
$stderr.set_encoding('Shift_JIS')

prev_uri = nil
begin
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
      out_time = doc.at('.post-footers').inner_text.gsub("\n", '').sub(/\A.*?(\d+)年(\d+)月(\d+)日 (\d+):(\d+).*\z/, '\1\2\3_\4\5')
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
      STDERR.puts('最新のエントリは ' + date + ' で ' + gap_text + '更新されたものです。')
   else
      unless prev_uri
         target = ARGV.first.gsub('-', '/') + '.php'
         date = ARGV.first.split('_').first.gsub('-', '.')
         uri = 'http://blog.tatsuru.com/' + target
      else
         uri = prev_uri
      end
      source = open(uri).read rescue raise(uri)
      doc = Nokogiri(source.gsub('<em>', '((*').gsub('</em>', '*))'))
      title = doc.at('#archive-title').inner_text
      body = doc.at('div.entry-body').inner_html
      out_time = doc.at('.post-footers').inner_text.gsub("\n", '').sub(/^.*?(\d+)年(\d+)月(\d+)日 (\d+):(\d+).*$/, '\1\2\3_\4\5')
      prev_uri = doc.at('.module-welcome .module-content a').attributes['href'].value
      issue = '(アーカイブ ' + date + ' のエントリより転載)'
   end
   p [out_time, title]

   body_text = body.strip.gsub(/<[^>]+>/, '')
   size = body_text.size

   not_output = false
   case
   when 500 > size
      warn "このエントリは #{size} 文字で、通天で紹介するのは不適切です。"
      not_output = true
   when 1000 > size
      warn "このエントリは #{size} 文字で、通天で紹介するには短過ぎます。"
      unless force
         warn "敢えて作成するなら強制オプション(-f)を指定して下さい。"
         not_output = true
      else
         warn '強制オプション(-f)が指定されたので、 txt ファイルを生成します。'
      end
   when 2000 > size
      warn "このエントリは #{size} 文字で、通天で紹介するには、短過ぎるかもしれません。"
   end
   
   unless not_output
      out_file = 'tatsuru' + out_time + '.txt'
      open(out_file, 'w') do |txt|
         txt.puts '■内田樹の研究室(分室)'
         txt.puts '§' + title
         txt.puts issue
         txt.puts body_text
      end
   end
   repeat -= 1
end until(repeat.zero?)