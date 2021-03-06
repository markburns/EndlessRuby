#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'rubygems'

module Kernel

  alias endlessruby_original_require require

  # EndlessRuby によって再定義された require です。
  # たいていのこのrequireはオリジナルなrequireまたはrubygemsのrequireがSyntaxErrorによって失敗した場合のみ機能します。
  # SytanxError によってrequireが失敗した場合、pathを探してpathまたはpath.erの名前のファイルをEndlessRubyの構文として評価します。
  # pathが./または/で以外で始まる場合は$LOAD_PATHと$:をそれぞれ参照してpathを探します。
  # もしpathがそれらで始まる場合はそれぞれ参照しません。(つまり通常のrequireの動作と同じです)
  def require path
    at = caller
    endlessruby_original_require path
  rescue SyntaxError, LoadError
    case path
    when /^\.\/.*?$/, /^\/.*?$/
      unless File.exist? path
        if File.exist? "#{path}.er"
          path = "#{path}.er"
        else
          $@ = at
          raise LoadError, "no such file to load -- #{path}"
        end
      end

      if File.directory? path
        $@ = at
        raise LoadError, "Is a directory - #{path}"
      end

      open(path) do |file|
        begin
          EndlessRuby.ereval file.read, TOPLEVEL_BINDING, path
        rescue Exception => e
          $@ = at
          raise e
        end
        return true
      end
    else
      is_that_dir = false
      ($LOAD_PATH | $:).each do |load_path|
        real_path = File.join load_path, path
        unless File.exist? real_path
          if File.exist? "#{real_path}.er"
            real_path = "#{real_path}.er"
          else
            next
          end
        end

        next is_that_dir = true if File.directory? real_path
        open(real_path) do |file|
          begin
            EndlessRuby.ereval file.read, TOPLEVEL_BINDING, real_path
          rescue Exception => e
            $@ = at
            raise e
          end
        end
        return true
      end
      $@ = at
      if is_that_dir
        raise LoadError, "Is a directory - #{path}"
      else
        raise LoadError, "no such file to load -- #{path}"
      end
    end
  end
end