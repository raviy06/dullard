require 'dullard'

describe "test.xlsx," do
  before(:each) do
    @file = File.open(File.expand_path("../test.xlsx", __FILE__))
  end

  describe "when it has no user defined formats," do
    before(:each) do
      @xlsx = Dullard::Workbook.new @file
    end

    it "can open a file" do
      @xlsx.should_not be_nil
    end

    it "can find sheets" do
      @xlsx.sheets.count.should == 1
    end

    it "reads the right number of columns, even with blanks" do
      rows = @xlsx.sheets[0].rows
      rows.next.count.should == 300
      rows.next.count.should == 9
    end

    it "reads the right number of rows" do
      @xlsx.sheets[0].row_count.should == 117
    end

    it "reads the right number of rows from the metadata when present" do
      @xlsx.sheets[0].rows.size.should == 117
    end

    it "reads date/time properly" do
      count = 0
      @xlsx.sheets[0].rows.each do |row|
        count += 1

        if count == 116
          row[0].strftime("%Y-%m-%d %H:%M:%S").should == "2012-10-18 00:00:00"
          row[1].strftime("%Y-%m-%d %H:%M:%S").should == "2012-10-18 00:17:58"
          row[2].strftime("%Y-%m-%d %H:%M:%S").should == "2012-07-01 21:18:48"
          [row[3].hours, row[3].minutes, row[3].seconds].should == [13, 0, 0]
        end
      end
      count.should == 117
    end
  end

  describe "when it has user defined formats," do
    before(:each) do
      @xlsx = Dullard::Workbook.new @file, {'GENERAL' => :string, 'm/d/yyyy' => :date, 'M/D/YYYY' => :date,}
    end

    it "converts the user defined formatted cells properly" do
      count = 0
      @xlsx.sheets[0].rows.each do |row|
        count += 1

        if count == 117
          row[0].should == 'teststring'
          row[1].strftime("%Y-%m-%d %H:%M:%S").should == "2012-10-18 00:00:00"
          row[2].strftime("%Y-%m-%d %H:%M:%S").should == "2012-10-18 00:17:58"
          row[3].strftime("%Y-%m-%d %H:%M:%S").should == "2012-07-01 21:18:48"
          row[4].strftime("%Y-%m-%d %H:%M:%S").should == "2012-07-01 21:18:52"
        end
      end
      count.should == 117
    end
  end
end

describe "test2.xlsx" do
  before(:each) do
    @file = File.open(File.expand_path("../test2.xlsx", __FILE__))
  end

  it "should not skip nils" do
    rows = Dullard::Workbook.new(@file).sheets[0].rows.to_a
    rows.should == [
      [1],
      [nil, 2],
      [nil, nil, 3]
    ]
  end
end

describe "date_bool.xlsx" do
  before(:each) do
    @file = File.open(File.expand_path("../date_bool.xlsx", __FILE__))
  end

  it "should read boolean cells following dates" do
    rows = Dullard::Workbook.new(@file).sheets[0].rows
    rows.next.should == [DateTime.new(2015, 1, 2)]
    rows.next.should == [true]
  end
end

describe "error handling" do
  it "should raise an error when a cell is missing r attr" do
    @file = File.expand_path("../error_missing_r.xlsx", __FILE__)
    book = Dullard::Workbook.new(@file)
    sheet = book.sheets[0]
    expect {
      sheet.rows.to_a
    }.to raise_error(Dullard::Error)
  end

  it "should succeed when styles are missing" do
    file = File.expand_path("../error_missing_metadata.xlsx", __FILE__)
    book = Dullard::Workbook.new(file)
    sheet = book.sheets[0]
    expect {
      sheet.rows.to_a
    }.not_to raise_error
  end

  it "should raise an error with invalid shared string index" do
    file = File.expand_path("../error_missing_ss.xlsx", __FILE__)
    book = Dullard::Workbook.new(file)
    sheet = book.sheets[0]
    expect {
      sheet.rows.to_a
    }.to raise_error(Dullard::Error)
  end
end
