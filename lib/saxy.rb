require 'saxy/version'

module Saxy
  class << self
    def parse(xml_file, object_tag, &blk)
      parser = Parser.new(xml_file, object_tag)

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
