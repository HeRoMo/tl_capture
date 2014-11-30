require 'spec_helper'
require 'timecop'

describe TlCapture::TwClient do
  it 'has a version number' do
    expect(TlCapture::VERSION).not_to be nil
  end

  context "#out_filename" do
    before {
      Timecop.travel(2014,11,29,0,0,0)
      @twc = TlCapture::TwClient.new('spec/streamtest_config.yml')
    }
    it {
      expect(@twc.send(:out_filename, "/hoge/fugo/inputfile.csv")).to eq "/hoge/fugo/inputfile_20141129.csv"
    }
  end
end
