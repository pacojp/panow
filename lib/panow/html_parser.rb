# -*- encoding: utf-8 -*-
require 'nokogiri'
require 'open-uri'
require 'parallel'
require 'fileutils'
require 'image_size'
require 'active_support/all'


module Panow
  class Image
    attr_accessor :data,:format,:width,:height,:save_root_dir
    def initialize(hash={})
      hash.each do |key,value|
        self.instance_variable_set("@#{key.to_s}",value)
      end
    end

    def md5hash
      @_md5hash ||= Digest::MD5.new.update(@data).to_s
    end

    def md5hashslash
      return @_md5hashslash ||= (0..7).map do |i|
        self.md5hash[(i * 4)..(i*4) + 3]
      end.join('/')
    end

    # TODO
    def thumbnail
    end

    def original_file_path
      @save_root_dir + "/#{self.md5hashslash}#{self.ext}"
    end

    def save(with_thumbnail=true)
      raise 'must set @save_root_dir first' if @save_root_dir.blank?
      FileUtils.mkdir_p(File::dirname(self.original_file_path))
      File.open(original_file_path,'w') do |f|
        f.puts @data
      end
    end

    def ext
      if @format
        if @format == :jpeg
          return '.jpg'
        end
        return ".#{@format.to_s}"
      else
        nil
      end
    end
  end

  class HtmlParser
    attr_accessor :url,:html,:header_option,:contents,:title
    DEFAULT_USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_2) AppleWebKit/535.2 (KHTML, like Gecko) Chrome/15.0.874.121 Safari/535.2"

    def initialize(url,header_option={})
      @url = url
      @header_option = {
        "User-Agent" => DEFAULT_USER_AGENT,
        "Referer" => "http://detail.chiebukuro.yahoo.co.jp/qa/question_detail/q#{Time.now.to_i}"
      }
      @header_option = self.class.merge_header_option(@header_option,header_option)
    end

    #
    # オリジナルを残したいときもあるので引数二つ
    #
    def self.merge_header_option(ori,opt)
      ori = ori.clone
      opt.each do |key,value|
        ori[key.to_s] = value
      end
      ori
    end

    def html
      #return @html if @html
      #@html = open(@url,'r:utf-8',@header_option).read
      #
      # responce ヘッダーにエンコーディングが入ってれば大丈夫なんだけど
      # まぁ信じない方向で
      # 基本utfでもし違うならばhtmlのheadに書いてるでしょ〜〜って事で
      #
      @html = open(@url,'r:ASCII-8BIT',@header_option).read
      enc = 'utf-8'
      if @html =~ %r|<meta .*?charset=([\w_-]+).*?>|mi
        enc = $1
      end
      @html.force_encoding(enc)
      @html = @html.encode("utf-8", :invalid => :replace, :undef => :replace)
      @html
    end

    def parse
      an =  Panow::ExtractContent::analyse(self.html)
      @title = an[1]
      @contents = an[0]
    end

    def title
      parse unless @title
      @title
    end

    def contents
      parse unless @contents
      @contetnts
    end

    def image_urls
      #puts 'call image_urls'
      ret = []
      doc = Nokogiri::HTML(html)
      #p doc
      (doc/:img).each do |elem|
        ret << elem[:src]
      end
      ret
    end

    def images
      results = Parallel.map(self.image_urls, :in_threads=>10) do |img_url|
        img = self.get_image(img_url,{},{:Referer=>url})
      end
      results
    end

    def self.get_uri_dir(url)
      uri = URI.parse(url)
      paths = uri.path.to_s.split('/',-1)
      if paths.size > 1
        paths.delete_at(paths.size - 1)
      end

      ret = "#{uri.scheme}://#{uri.host}#{uri.port == '' ? '' : ":#{uri.port}" }#{paths.join('/')}/"
      #p ret
      ret
    end

    def self.get_uri_root(url)
      uri = URI.parse(url)
      paths = uri.path.to_s.split('/',-1)
      if paths.size > 1
        paths.delete_at(paths.size - 1)
      end

      ret = "#{uri.scheme}://#{uri.host}#{uri.port == '' ? '' : ":#{uri.port}" }/"
      #p ret
      ret
    end

    def get_image(image_url,image_option={},header_option={})
      opt = self.header_option.clone
      opt = self.class.merge_header_option(@header_option,opt)

      iurl = image_url.clone
      unless iurl =~ /^http:\/\//
        if iurl =~ /^\//
          iurl = self.class.get_uri_root(@url) + iurl
        else
          iurl = self.class.get_uri_dir(@url) + iurl
        end
      end

      data = open(iurl,opt).read
      img = ImageSize.new(data)
      # 画像サイズチェック
      if image_option[:min_width].present?  ||
        image_option[:max_width].present?  ||
        image_option[:min_height].present? ||
        image_option[:max_height].present?

        image_option[:max_width] ||= 10000
        image_option[:max_height] ||= 10000

        # TODO テストサイトにサイズがでかいファイルを入れて
        # ちゃんとはじかれるかのチェック
        # 取得上限を超えた画像は取得しない
        if image_option[:min_width].to_i  > img.width  ||
           image_option[:max_width].to_i  < img.width  ||
           image_option[:min_height].to_i > img.height ||
           image_option[:max_height].to_i < img.height

          return nil
        end
      end
      return Image.new(:data=>data,:format=>img.format,:width=>img.width,:height=>img.height)
    end
  end
end
