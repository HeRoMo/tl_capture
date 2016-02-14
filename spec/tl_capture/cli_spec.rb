require 'spec_helper'
require 'timecop'

describe TlCapture::CLI do
  before {
    @config = 'spec/spectest_config.yml'
  }
  after {
    ['output.csv','spec/fixtures/update_follow_list_20160229.csv'].each do |file|
      File.delete file if File.exists? file
    end
  }

  describe '#tw_stream' do
    # TODO impliment
  end

  describe '#follows' do
    context 'without output file option' do
      it 'output to stdout' do
        VCR.use_cassette 'twitter_api/friends_list' do
          expect{TlCapture::CLI.new.invoke(:follows,[@config])}.to output(read('spec/fixtures/follows.csv')).to_stdout
        end
      end
    end

    context 'with output file option' do
      before {
        VCR.use_cassette 'twitter_api/friends_list' do
          TlCapture::CLI.new.invoke(:follows, [@config],output_file:'output.csv')
        end
      }
      it 'output to file' do
        expect(File.exist? 'output.csv').to be true
        expect(read 'output.csv').to eq read('spec/fixtures/follows.csv')
      end
    end
    context 'with invalid config file' do
      it 'show error message to stderr' do
        expect{TlCapture::CLI.new.invoke(:follows, ['not/exist_file.yml'])}
            .to output("No such file or directory @ rb_sysopen - not/exist_file.yml\n").to_stderr
      end
    end
    context 'with invalid output file option' do
      it 'show error message to stderr' do
        VCR.use_cassette 'twitter_api/friends_list' do
          expect{TlCapture::CLI.new.invoke(:follows, [@config],output_file:'not/exist/output.csv')}.to output("No such file or directory @ rb_sysopen - not/exist/output.csv\n").to_stderr
        end
      end
    end
  end

  describe '#add_follows' do
    context '2 new follow, 3 followed users' do
      it 'show 2 new follow screen_name and count' do
        VCR.use_cassette 'twitter_api/friendship_create' do
          expect{TlCapture::CLI.new.invoke(:add_follows,[@config],input_file:'spec/fixtures/follows_list.csv')}
              .to output("Fukuicity_Bosai\nnaracity_bosai\n2 follows added.\n").to_stdout
        end
      end
    end
    context 'with invalid input_file' do
      it 'show error message' do
        VCR.use_cassette 'twitter_api/friendship_create' do
          expect{TlCapture::CLI.new.invoke(:add_follows,[@config],input_file:'not/exist_file.csv')}
              .to output("No such file or directory @ rb_sysopen - not/exist_file.csv\n").to_stderr
        end
      end
    end
  end

  describe 'update_follow_list' do
    after {
      ['output.csv','spec/fixtures/update_follow_list_20120229.csv'].each do |file|
        File.delete file if File.exists? file
      end
    }
    context 'with only input_file option' do
      before {
        Timecop.freeze(2012,02,29,0,0,0){
          VCR.use_cassette 'twitter_api/update_follow_list' do
            TlCapture::CLI.new.invoke(:update_follow_list,[@config],input_file:'spec/fixtures/update_follow_list.csv')
          end
        }
      }
      it 'output to date added file' do
        expect(File.exist? 'spec/fixtures/update_follow_list_20120229.csv').to be true
        expect(read 'spec/fixtures/update_follow_list_20120229.csv').to eq read('spec/fixtures/update_follow_list_output.csv')
      end
    end
    context 'with only input_file and output_file option' do
      before {
        VCR.use_cassette 'twitter_api/update_follow_list' do
          TlCapture::CLI.new.invoke(:update_follow_list,[@config],input_file:'spec/fixtures/update_follow_list.csv', output_file:'output.csv')
        end
      }
      it 'output to output.csv' do
        expect(File.exist? 'output.csv').to be true
        expect(read 'output.csv').to eq read('spec/fixtures/update_follow_list_output.csv')
      end
    end
  end
end