require 'spec_helper'

describe Saxy::Parser do
  include FixturesHelper

  let(:parser) { Saxy::Parser.new(fixture_file("webstore.xml"), "product") }
  let(:file_io) { File.new(fixture_file("webstore.xml")) }
  let(:io_like) { IOLike.new(file_io) }

  it "should accept string filename for parsing" do
    xml_file = fixture_file("webstore.xml")
    parser = Saxy::Parser.new(xml_file, "product")
    parser.each.to_a.size.should == 2
  end

  it "should accept IO for parsing" do
    parser = Saxy::Parser.new(file_io, "product")
    parser.each.to_a.size.should == 2
  end

  it "should accept an IO-like for parsing" do
    parser = Saxy::Parser.new(io_like, "product")
    parser.each.to_a.size.should == 2
  end

  it "should have empty tag stack" do
    parser.tags.should == %w( )
  end

  it "should push/pop tag names on/from tag stack when going down/up the XML tree" do
    parser.tags.should == %w( )

    parser.start_element('webstore')
    parser.tags.should == %w( webstore )

    parser.start_element('products')
    parser.tags.should == %w( webstore products )

    parser.start_element('product')
    parser.tags.should == %w( webstore products product )

    parser.end_element('product')
    parser.tags.should == %w( webstore products )

    parser.end_element('products')
    parser.tags.should == %w( webstore )

    parser.end_element('webstore')
    parser.tags.should == %w( )
  end

  context "when detecting object tag opening" do
    before do
      parser.start_element("product")
    end

    it "should add new element to stack" do
      parser.elements.size.should == 1
    end
  end

  context "when detecting other tag opening" do
    before do
      parser.start_element("other")
    end

    it "should not add new element to stack" do
      parser.elements.should be_empty
    end
  end

  context "with non-empty element stack" do
    before do
      parser.start_element("product")
      parser.elements.should_not be_empty
    end

    context "when detecting object tag opening" do
      before do
        parser.start_element("product")
      end

      it "should add new element to stack" do
        parser.elements.size.should == 2
      end
    end

    context "when detecting other tag opening" do
      before do
        parser.start_element("other")
      end

      it "should not add new element to stack" do
        parser.elements.size.should == 2
      end
    end

    context "when detecting any tag closing" do
      before do
        parser.end_element("any")
      end

      it "should pop element from stack" do
        parser.elements.should be_empty
      end
    end

    context "with callback defined" do
      before do
        @callback = lambda { |object| object }
        parser.stub(:callback).and_return(@callback)
      end

      it "should yield the object inside the callback after detecting object tag closing" do
        @callback.should_receive(:call).with(parser.current_element.to_h)
        parser.end_element("product")
      end

      it "should not yield the object inside the callback after detecting other tag closing" do
        parser.start_element("other")
        @callback.should_not_receive(:call)
        parser.end_element("other")
      end
    end

    it "should append cdata block's contents to top element's value when detecting cdata block" do
      parser.current_element.should_receive(:append_value).with("foo")
      parser.cdata_block("foo")
    end

    it "should append characters to top element's value when detecting characters block" do
      parser.current_element.should_receive(:append_value).with("foo")
      parser.current_element.should_receive(:append_value).with("bar")
      parser.characters("foo")
      parser.characters("bar")
    end

    it "should set element's attribute after processing tags" do
      element = parser.current_element

      element.should_receive(:set_attribute).with("foo", "bar")

      parser.start_element("foo")
      parser.characters("bar")
      parser.end_element("foo")
    end

    it "should set element's attributes when opening tag with attributes" do
      parser.start_element("foo", [["bar", "baz"]])
      parser.current_element.to_h[:bar].should == "baz"
    end
  end

  it "should raise Saxy::ParsingError on error" do
    lambda { parser.error("Error message.") }.should raise_error(Saxy::ParsingError, "Error message.")
  end

  it "should return Enumerator when calling #each without a block" do
    parser.each.should be_instance_of Enumerator
  end

  context 'with parent_element' do

    it 'only emits the target elements inside of the parent' do
      file = fixture_file('webstore-parent.xml')
      parser = Saxy::Parser.new(file, 'product', within: 'retailstore')

      uids = parser.each.map { |element| element.fetch(:uid) }

      expect(uids).to eq %w(FFCF178 FFCF179 FFCF180)
    end

    it 'only emits the target element inside of the parent' do
      file = fixture_file('webstore-parent.xml')
      parser = Saxy::Parser.new(file, 'products', within: 'retailstore')

      products = parser.each.to_a

      expect(products.size).to eq 1
    end

    it 'emits no elements when none are matched ' do
      file = fixture_file('webstore-parent.xml')
      parser = Saxy::Parser.new(file, 'product', within: 'doesntexist')

      elements = parser.each.to_a

      expect(elements.size).to eq 0
    end

  end

end
