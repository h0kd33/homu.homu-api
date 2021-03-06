# frozen_string_literal: true

require './lib/homu_getter'
require './lib/homu_block_parser'

class HomuApi
  class << self
    def get_page(page_number)
      homu_getter = HomuGetter.new
      homu_getter.download_page page_number
      do_parse homu_getter
    rescue StandardError => e
      puts "GetPage failed: #{e.inspect}"
    end

    def get_res(res_no)
      homu_getter = HomuGetter.new
      homu_getter.download_res res_no
      res = do_parse homu_getter
      res.first
    rescue StandardError => e
      puts "GetPage failed: #{e.inspect}"
    end

    private

    def do_parse(homu_getter)
      parser = HomuBlockParser.new
      hashes = homu_getter.blocks.map { |block| parser.parse(block) }
      save_result_to_posts(hashes)
      hashes
    end

    def save_result_to_posts(hashes)
      numbers = hashes.map do |hash|
        [hash['Head']['No'], hash['Bodies'].map { |body| body['No'] }]
      end.flatten
      posts = Post.where(number: numbers)
      post_index = posts.index_by(&:number)
      return if (numbers - post_index.keys).blank?
      Post.transaction { save_each_posts(hashes, post_index) }
    end

    def save_each_posts(hashes, post_index)
      hashes.map do |hash|
        head_post = save_or_update_head(hash['Head'], post_index)
        hash['Bodies'].each { |body| save_bodies(head_post, body, post_index) }
      end
    end

    def save_or_update_head(hash, post_index)
      head = Detail.from_hash(hash)
      head_post = post_index[head.no]
      if head_post.present?
        head_post.hidden_body_count = head.hidden_body_count
        head_post.save if head_post.hidden_body_count_changed?
      else
        head_post = head.create_post
      end
      head_post
    end

    def save_bodies(head_post, body, post_index)
      body = Detail.from_hash(body)
      return if post_index[body.no].present?
      body.create_post(head_post)
    end
  end
end
