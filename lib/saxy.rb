require 'saxy/version'

module Saxy
  class << self
    def parse(*args, &blk)
      parser = Parser.new(*args)

      if blk
        parser.each(blk)
      else
        parser.each
      end
    end

  end
end

require 'saxy/element'
require 'saxy/parser'
require 'saxy/parsing_error'
