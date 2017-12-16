# encoding: utf-8
require 'json'
require './Domain/Detail'

class HomuBlockParser
  def initialize contents, isGetfromArchive
    @isGetfromArchive = isGetfromArchive
    @contents = contents
    @detail_format = /(.{0,})\s\n\s(.{0,})\s(\d\d\/\d\d\/\d\d)\(.\)(\d\d:\d\d:\d\d)\sID:(.{0,})\sNo.([\d]+)\sdel/
    @detail_format_a = /(.{0,})\n姓名:\s(.{0,})\s\[(\d\d\/\d\d\/\d\d)\(.\)(\d\d:\d\d:\d\d)\sID:(.{0,})\]\sNo.([\d]+)/
    @picture_format = /檔名：([\d]+\.[\w]+)-\([\d]+\sB\)\n(以縮圖顯示，點擊後以原尺寸顯示。|)/
    @picture_format_a = /檔名：([\d]+\.[\w]+)-\([\d]+\sKB, [\d]+x[\d]+\)/
    @content_format = /\{ \"Head\":[\d]+, \"Body\":[\d]+ \}/
    @hiden_body_format = /回應有([\d]+)篇被省略。要閱讀所有回應請按下返信連結。/
  end

  def Parse block
    block_hash = Hash.new
    bodies = []
    dialogs = block.css('div.post')

    dialogs.each do |dialog|
      detail = do_match dialog
      if block_hash['Head'].nil?
        block_hash['Head'] = detail.to_hash
      else
        bodies << detail.to_hash
      end
    end
    block_hash['Bodies'] = bodies
    return block_hash
  end

  private

  def do_match dialog
    detail = match_detail dialog
    detail.Picture = match_picture dialog
    detail.Content = match_content dialog
    detail.HidenBodyCount = match_hiden_body dialog
    return detail
  end

  def match_detail dialog
    # format = @isGetfromArchive ? @detail_format_a : @detail_format
    # matched = dialog.match format
    # dialog.sub! matched[0], ''
    datas = ['nil']
    datas.push(dialog.css('span.title').text)
    datas.push(dialog.css('span.name').text)
    matched = dialog.css('span.now').text.match /(\d\d\/\d\d\/\d\d)\(.\)((\d\d:\d\d:\d\d\.\d\d\d)|(\d\d:\d\d:\d\d\.\d\d)|(\d\d:\d\d:\d\d)|(\d\d:\d\d))\sID:(.{8})/
    datas.push(matched[1]) # date
    datas.push(matched[2]) # time
    datas.push(matched[6]) # id
    datas.push(dialog.css('span.qlink').text.split('.')[1])
    return Detail.new datas
  end

  def match_picture dialog
    # format = @isGetfromArchive ? @picture_format_a : @picture_format
    # matched = dialog.match format
    # if matched
    #   dialog.sub! matched[0], ''
    #   return matched[1]
    # end
    matched = dialog.css('div.file-text a').text
    if matched.strip != ''
      return matched
    end
    return nil
  end

  def match_content dialog
    # matched = dialog.match @content_format
    # dialog.sub! matched[0], ''
    # content = JSON.parse matched[0]
    # return @contents[content['Head']][content['Body']]
    matched = dialog.css('div.quote').text
    if matched
      return matched.strip
    end
    return nil
  end

  def match_hiden_body dialog
    # matched = dialog.match @hiden_body_format
    # if matched
    #   dialog.sub! matched[0], ''
    #   return matched[1]
    # end
    # return nil

    matched = dialog.css('span.warn_txt2').text.match(/有回應\s(\d+)\s篇被省略。要閱讀所有回應請按下回應連結。/)
    if matched
      return matched[1]
    end
    return nil
  end
end
