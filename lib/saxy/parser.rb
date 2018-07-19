require 'nokogiri'

module Saxy
  class Parser < Nokogiri::XML::SAX::Document
    include Enumerable

    # Stack of XML tags built while traversing XML tree
    attr_reader :tags

    # Stack of elements built while traversing XML tree
    #
    # First element is pushed to the stack only after finding the object_tag in
    # the XML tree.
    attr_reader :elements

    # Will yield objects inside the callback after they're built
    attr_reader :callback

    # an optional parent object tag to constrain which object_tags will match.
    attr_reader :parent_tag

    # whether or not the parser is currently inside the of the parent element
    attr_accessor :inside_parent

    def initialize(object, object_tag, within: nil)
      @object, @object_tag = object, object_tag
      @parent_tag = within
      @tags, @elements = [], []
    end

    def start_element(tag, attributes=[])
      @tags << tag

      if tag == parent_tag
        self.inside_parent = tag
        return
      end

      tag_matches = tag == @object_tag
      no_parent_or_inside_parent = !parent_tag || inside_parent
      inside_object_tag = elements.any?

      if tag_matches && no_parent_or_inside_parent || inside_object_tag
        elements << Element.new

        attributes.each do |(attr, value)|
          current_element.set_attribute(attr, value)
        end
      end
    end

    def end_element(tag)
      tags.pop

      if tag.equal?(@parent_tag)
        self.inside_parent = nil
      end

      if element = elements.pop
        object = element.to_h

        if current_element
          current_element.set_attribute(tag, object)
        elsif callback
          callback.call(object)
        end
      end
    end

    def cdata_block(cdata)
      current_element.append_value(cdata) if current_element
    end

    def characters(chars)
      current_element.append_value(chars) if current_element
    end

    def error(message)
      raise ParsingError.new(message)
    end

    def current_element
      elements.last
    end

    def each(&blk)
      return to_enum unless blk

      @callback = blk

      parser = Nokogiri::XML::SAX::Parser.new(self)

      if @object.respond_to?(:read) && @object.respond_to?(:close)
        parser.parse_io(@object)
      else
        parser.parse_file(@object)
      end
    end
  end
end
