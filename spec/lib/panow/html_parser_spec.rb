# -*- encoding: utf-8 -*-

#require './lib/parser.rb'
# for guard auto reload
require 'panow'

describe "パーサー" do
  before do
    url     = 'http://localhost:18764/index.html'
    #url     = 'http://d.hatena.ne.jp/takuya_1st/20110706/1309900873'
    url_euc = 'http://localhost:18764/index_euc.html'
    @parser          = Panow::HtmlParser.new(url)
    @parser_euc      = Panow::HtmlParser.new(url_euc)
    @image_urls      = @parser.image_urls
    @image_urls_euc  = @parser_euc.image_urls
    @images          = @parser.images
    @images_euc      = @parser_euc.images
    @image_save_root = File::dirname(__FILE__) + '/../../../workspace/test_image_save_root/'
  end

  context 'HtmlParserのスタティックメソッド' do
    it 'get_uri_dir' do
      Panow::HtmlParser.get_uri_dir('http://yahoo.co.jp').should eq 'http://yahoo.co.jp:80/'
      Panow::HtmlParser.get_uri_dir('http://yahoo.co.jp/test').should eq 'http://yahoo.co.jp:80/'
      Panow::HtmlParser.get_uri_dir('http://yahoo.co.jp/test/').should eq 'http://yahoo.co.jp:80/test/'
      Panow::HtmlParser.get_uri_dir('http://yahoo.co.jp/test/1.jpg').should eq 'http://yahoo.co.jp:80/test/'
      Panow::HtmlParser.get_uri_dir('http://yahoo.co.jp/test/do.aspx?test=1').should eq 'http://yahoo.co.jp:80/test/'
    end
  end

  context "localhost:18764へのテスト" do
    context 'utf 8 page' do
      it "image_urls size" do
        @image_urls.size.should eq 6
      end

      it "image_urls first item" do
        img = @parser.get_image(@image_urls[0])
        img.ext.should eq '.jpg'
        img.width.should eq 578
        img.height.should eq 537
        img.md5hash.should eq '16805f3d99c02baf5fd05a5bc30a8e06'

        img.md5hashslash.should eq '1680/5f3d/99c0/2baf/5fd0/5a5b/c30a/8e06'
      end

      it "image_urls fifth item" do
        img = @parser.get_image(@image_urls[5])
        img.ext.should eq '.gif'
      end

      it "images" do
        # 一つ小さい画像があるので
        @images.size.should eq 5
        @images.each do |img|
          if img.md5hash == '16805f3d99c02baf5fd05a5bc30a8e06'
            img.width.should eq 578
            img.save_root_dir = @image_save_root
            img.save
            File.exists?(@image_save_root + "/1680/5f3d/99c0/2baf/5fd0/5a5b/c30a/8e06#{img.ext}").should eq true
          end
        end
      end

      it 'title' do
        @parser.title.should eq 'タイトルUTF'
      end
    end

    context 'euc page' do
      it "image_urls size" do
        @image_urls_euc.size.should eq 6
      end

      it "image_urls first item" do
        img = @parser_euc.get_image(@image_urls_euc[0])
        img.ext.should eq '.jpg'
        img.width.should eq 578
        img.height.should eq 537
        img.md5hash.should eq '16805f3d99c02baf5fd05a5bc30a8e06'

        img.md5hashslash.should eq '1680/5f3d/99c0/2baf/5fd0/5a5b/c30a/8e06'
      end

      it "image_urls fifth item" do
        img = @parser_euc.get_image(@image_urls_euc[5])
        img.ext.should eq '.gif'
      end

      it "images" do
        @images_euc.size.should eq 5
        @images_euc.each do |img|
          if img.md5hash == '16805f3d99c02baf5fd05a5bc30a8e06'
            img.width.should eq 578
            img.save_root_dir = @image_save_root
            img.save
            File.exists?(@image_save_root + "/1680/5f3d/99c0/2baf/5fd0/5a5b/c30a/8e06#{img.ext}").should eq true
          end
        end
      end

      it 'title' do
        @parser_euc.title.should eq 'タイトルEUC'
      end
    end
  end
end
