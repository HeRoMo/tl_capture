require 'spec_helper'
require 'timecop'

describe TlCapture::TwClient do

  before {
    @twc = TlCapture::TwClient.new('spec/spectest_config.yml')
  }
  after {
    ['output.csv','spec/fixtures/update_follow_list_20160229.csv'].each do |file|
      File.delete file if File.exists? file
    end
  }

  describe '#show_follows' do

    context 'successfully' do
      it 'output to stdout' do
        VCR.use_cassette 'twitter_api/friends_list' do
          expect{@twc.show_follows}.to output(read('spec/fixtures/follows.csv')).to_stdout
        end
      end

      it 'output to file' do
        VCR.use_cassette 'twitter_api/friends_list' do
          @twc.show_follows 'output.csv'
          expect(read 'output.csv').to eq read('spec/fixtures/follows.csv')
        end
      end
    end
  end

  describe '#add_follows' do
    context '2 new follow, 3 followed users' do
      subject{@twc.add_follows 'spec/fixtures/follows_list.csv'}
      it {
        VCR.use_cassette 'twitter_api/friendship_create' do
          expect(subject.size).to be 2
        end
      }
    end
    context 'follow list file does not exist' do
      it {
        expect{@twc.add_follows 'spec/fixtures/not_exist.csv'}.to raise_error(Errno::ENOENT,"No such file or directory @ rb_sysopen - spec/fixtures/not_exist.csv")
      }
    end
  end

  describe '#update_follow_list' do
    context 'with output file' do
      it {
        VCR.use_cassette 'twitter_api/update_follow_list' do
          @twc.update_follow_list('spec/fixtures/update_follow_list.csv','output.csv')
        end
        expect(read 'output.csv').to eq read('spec/fixtures/update_follow_list_output.csv')
      }
    end

    context 'without output file' do
      it {
        Timecop.freeze(2016,02,29,0,0,0){
          VCR.use_cassette 'twitter_api/update_follow_list' do
            @twc.update_follow_list('spec/fixtures/update_follow_list.csv')
          end
        }
        expect(read 'spec/fixtures/update_follow_list_20160229.csv').to eq read('spec/fixtures/update_follow_list_output.csv')
      }
    end
  end



  describe "#out_filename" do
    it {
      Timecop.freeze(2014,11,29,0,0,0){
        twc = TlCapture::TwClient.new('spec/spectest_config.yml')
        expect(twc.send(:out_filename, "/hoge/fugo/inputfile.csv")).to eq "/hoge/fugo/inputfile_20141129.csv"
      }
    }
  end

  describe '#split_array' do
    context 'array.size < num' do
      subject{
        array = (1..8).to_a
        @twc.send(:split_array, array, 10)
      }
      it{
        expect(subject.size).to eq 1
        expect(subject).to eq [[1,2,3,4,5,6,7,8]]
      }
    end
    context 'array.size == num' do
      subject{
        array = (1..10).to_a
        @twc.send(:split_array, array, 10)
      }
      it{
        expect(subject.size).to eq 1
        expect(subject).to eq [[1,2,3,4,5,6,7,8,9,10]]
      }
    end
    context 'array.size > num' do
      subject{
        array = (1..19).to_a
        @twc.send(:split_array, array, 10)
      }
      it{
        expect(subject.size).to eq 2
        expect(subject).to eq [[1,2,3,4,5,6,7,8,9,10],[11,12,13,14,15,16,17,18,19]]
      }
    end
    context 'array.size >> num' do
      subject{
        array = (1..123).to_a
        @twc.send(:split_array, array, 10)
      }
      it{
        expect(subject.size).to eq 13
        expect(subject[3]).to eq [31,32,33,34,35,36,37,38,39,40]
        expect(subject[12]).to eq [121,122,123]
      }
    end
  end

end
