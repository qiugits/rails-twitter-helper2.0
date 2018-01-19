# -*- coding:utf-8 -*-
#!/bin/bash
require 'json'
require 'oauth'


class TwitterController < ApplicationController
  #viewを持っているアクション
  def mentions
    #Tweet.mention_timeline #ここに置くと重くなるのでリフレッシュボタンへ変更。
    @timeline = Tweet.inbox
    #render 'mentions' #よくわからん.使い分け？：　http://blog.markusproject.org/?p=3313
  end

  def search
    @results = Tweet.search_result
  end

  def reflesh
    #Tweet.mention_timeline
    #redirect_to action: 'mentions'
  end

  #機能だけでviewを持たないアクション
  def button
    if button = params[:reply_button]
      Tweet.reply(params[:rep_text],params[:id])
      Tweet.change_tag(params[:id],'replied')
      redirect_to action: 'mentions' #ここはrenderじゃダメで、redirect_to.使い分けわかんない
    elsif button = params[:archive_button]
      archive_id = button
      Tweet.change_tag(archive_id,'archived')
      redirect_to action: 'mentions'
    elsif button = params[:search_button]
      Tweet.destroy_all(tag: 'search')
      Tweet.search(params[:keyword])
      redirect_to action: 'search'
    elsif button = params[:reflesh_button]
      Tweet.mention_timeline
      redirect_to action: 'mentions'
    end
  end

  def conversation #(reply_from_id)
    #params id 受け取って
    #表示
    #conversation(params[tweet-id])
  end

=begin
  def self.origintweetid(id)
    result = Array.new
    while true
      #GET
      #https://dev.twitter.com/rest/reference/get/statuses/show/%3Aid
      response = Timeline.endpoint(@@VaingloryJP).get("https://api.twitter.com/1.1/statuses/show.json?id=#{id}")
      res = JSON.parse(response.body)
      result.unshift(res) #unshiftで前から挿入
      next if id = res["in_reply_to_status_id"]
      break
    end
    Timeline.viewtl(result)
  end
=end
end
