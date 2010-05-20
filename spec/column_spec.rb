require File.join(File.dirname(__FILE__), 'spec_helper')

describe FixedWidth::Column do
  before(:each) do
    @name = :id
    @length = 5
    @column = FixedWidth::Column.new(@name, @length)
  end

  describe "when being created" do
    it "should have a name" do
      @column.name.should == @name
    end

    it "should have a length" do
      @column.length.should == @length
    end

    it "should have a default padding" do
      @column.padding.should == ' '
    end

    it "should have a default alignment" do
      @column.alignment.should == :right
    end
  end

  describe "when specifying an alignment" do
    before(:each) do
      @column = FixedWidth::Column.new(@name, @length, :align => :left)
    end

    it "should only accept :right or :left for an alignment" do
      lambda{ FixedWidth::Column.new(@name, @length, :align => :bogus) }.should raise_error(ArgumentError, "Option :align only accepts :right (default) or :left")
    end

    it "should override the default alignment" do
      @column.alignment.should == :left
    end
  end

  describe "when specifying padding" do
    before(:each) do
      @column = FixedWidth::Column.new(@name, @length, :padding => '0')
    end
    
    it "should check the length of the padding and warn" do
      pending
    end

    it "should override the default padding" do
      @column.padding.should == '0'
    end
  end

  it "should return the proper unpack value for a string" do
    @column.send(:unpacker).should == 'A5'
  end

  describe "when parsing a value from a file" do
    it "should default to a string" do
      pending("need to split into l and r aligned")
      @column.parse('    name ').should == 'name'
      @column.parse('      234').should == '234'
      @column.parse('000000234').should == '000000234'
      @column.parse('12.34').should == '12.34'
    end

    it "should support the integer type" do
      @column = FixedWidth::Column.new(:amount, 10, :type=> :integer)
      @column.parse('234     ').should == 234
      @column.parse('     234').should == 234
      @column.parse('00000234').should == 234
      @column.parse('Ryan    ').should == 0
      @column.parse('00023.45').should == 23
    end

    it "should support the float type" do
      @column = FixedWidth::Column.new(:amount, 10, :type=> :float)
      @column.parse('  234.45').should == 234.45
      @column.parse('234.5600').should == 234.56
      @column.parse('     234').should == 234.0
      @column.parse('00000234').should == 234.0
      @column.parse('Ryan    ').should == 0
      @column.parse('00023.45').should == 23.45
    end

    it "should support the date type" do
      @column = FixedWidth::Column.new(:date, 10, :type => :date)
      dt = @column.parse('2009-08-22')
      dt.should be_a(Date)
      dt.to_s.should == '2009-08-22'
    end

    it "should use the format option with date type if available" do
      @column = FixedWidth::Column.new(:date, 10, :type => :date, :date_format => "%m%d%Y")
      dt = @column.parse('08222009')
      dt.should be_a(Date)
      dt.to_s.should == '2009-08-22'
    end
  end

  describe "when applying formatting options" do
    it "should respect a right alignment" do
      @column = FixedWidth::Column.new(@name, @length, :align => :right)
      @column.format(25).should == '   25'
    end

    it "should respect a left alignment" do
      @column = FixedWidth::Column.new(@name, @length, :align => :left)
      @column.format(25).should == '25   '
    end

    it "should respect padding with spaces" do
      @column = FixedWidth::Column.new(@name, @length, :padding => ' ')
      @column.format(25).should == '   25'
    end

    it "should respect padding with zeros with integer types" do
      @column = FixedWidth::Column.new(@name, @length, :type => :integer, :padding => '0')
      @column.format(25).should == '00025'
    end

    describe "that is a float type" do
      it "should respect padding with zeros aligned right" do
        @column = FixedWidth::Column.new(@name, @length, :type => :float, :padding => '0', :align => :right)
        @column.format(4.45).should == '04.45'
      end

      it "should respect padding with zeros aligned left" do
        @column = FixedWidth::Column.new(@name, @length, :type => :float, :padding => '0', :align => :left)
        @column.format(4.45).should == '4.450'
      end
    end
  end

  describe "when formatting values for a file" do
    it "should default to a string" do
      @column = FixedWidth::Column.new(:name, 10)
      @column.format('Bill').should == '      Bill'
    end

    describe "whose size is too long" do
      it "should raise an error if truncate is false" do
        @value = "XX" * @length
        lambda { @column.format(@value) }.should raise_error(
          FixedWidth::FormattedStringExceedsLengthError,
          "The formatted value '#{@value}' in column '#{@name}' exceeds the allowed length of #{@length} chararacters."
        )
      end

      it "should truncate from the left if truncate is true and aligned left" do
        @column = FixedWidth::Column.new(@name, @length, :truncate => true, :align => :left)
        @column.format("This is too long").should == "This "
      end

      it "should truncate from the right if truncate is true and aligned right" do
        @column = FixedWidth::Column.new(@name, @length, :truncate => true, :align => :right)
        @column.format("This is too long").should == " long"
      end
    end

    it "should support the integer type" do
      @column = FixedWidth::Column.new(:amount, 10, :type => :integer)
      @column.format(234).should        == '       234'
      @column.format('234').should      == '       234'
    end

    it "should support the float type" do
      @column = FixedWidth::Column.new(:amount, 10, :type => :float)
      @column.format(234.45).should       == '    234.45'
      @column.format('234.4500').should   == '    234.45'
      @column.format('3').should          == '       3.0'
    end

    it "should support the float type with a format" do
      @column = FixedWidth::Column.new(:amount, 10, :type => :float, :float_format => "%.3f")
      @column.format(234.45).should       == '   234.450'
      @column.format('234.4500').should   == '   234.450'
      @column.format('3').should          == '     3.000'
    end

    it "should support the float type with a format, alignment and padding" do
      @column = FixedWidth::Column.new(:amount, 10, :type => :float, :float_format => "%.2f", :align => :left, :padding => '0')
      @column.format(234.45).should       == '234.450000'
      @column = FixedWidth::Column.new(:amount, 10, :type => :float, :float_format => "%.2f", :align => :right, :padding => '0')
      @column.format('234.400').should    == '0000234.40'
      @column = FixedWidth::Column.new(:amount, 10, :type => :float, :float_format => "%.4f", :align => :left, :padding => ' ')
      @column.format('3').should          == '3.0000    '
    end
    
    it "should support the date type" do
      dt = Date.new(2009, 8, 22)
      @column = FixedWidth::Column.new(:date, 10, :type => :date)
      @column.format(dt).should == '2009-08-22'
    end

    it "should support the date type with a :format" do
      dt = Date.new(2009, 8, 22)
      @column = FixedWidth::Column.new(:date, 8, :type => :date, :date_format => "%m%d%Y")
      @column.format(dt).should == '08222009'
    end 
  end

end