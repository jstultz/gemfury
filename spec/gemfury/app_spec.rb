require 'spec_helper'

describe Gemfury::Command::App do
  Endpoint = "www.gemfury.com"
  class MyApp < Gemfury::Command::App
    def read_config_file
      { :gemfury_api_key => 'DEADBEEF' }
    end
  end

  describe '#push' do
    it 'should cause errors for no gems specified' do
      out = capture(:stdout) { MyApp.start(['push']) }
      a_request(:any, Endpoint).should_not have_been_made
      out.should =~ /No valid packages/
    end

    it 'should cause errors for an invalid gem path' do
      out = capture(:stdout) { MyApp.start(['push', 'bad.gem']) }
      a_request(:any, Endpoint).should_not have_been_made
      out.should =~ /No valid packages/
    end

    it 'should upload a valid gem' do
      stub_post("gems")
      args = ['push', fixture('fury-0.0.2.gem')]
      out = capture(:stdout) { MyApp.start(args) }
      ensure_gem_uploads(out, 'fury')
    end

    it 'should upload multiple packages' do
      stub_post("gems")
      args = ['push', fixture('fury-0.0.2.gem'), fixture('bar-0.0.2.gem')]
      out = capture(:stdout) { MyApp.start(args) }
      ensure_gem_uploads(out, 'bar', 'fury')
    end
  end

  describe '#migrate' do
    it 'should cause errors for no gems specified' do
      out = capture(:stdout) { MyApp.start(['migrate']) }
      a_request(:any, Endpoint).should_not have_been_made
      out.should =~ /No valid packages/
    end

    it 'should cause errors for an invalid path' do
      out = capture(:stdout) { MyApp.start(['migrate', 'deadbeef']) }
      a_request(:any, Endpoint).should_not have_been_made
      out.should =~ /No valid packages/
    end

    it 'should not upload gems without confirmation' do
      stub_post("gems")
      $stdin.should_receive(:gets).and_return('n')
      args = ['migrate', fixture_path]
      out = capture(:stdout) { MyApp.start(args) }
      a_post("gems").should_not have_been_made
      out.should =~ /bar.*/
      out.should =~ /fury.*/
    end

    it 'should upload gems after confirmation' do
      stub_post("gems")
      $stdin.should_receive(:gets).and_return('y')
      args = ['migrate', fixture_path]
      out = capture(:stdout) { MyApp.start(args) }
      ensure_gem_uploads(out, 'bar', 'fury')
    end
  end

private
  def ensure_gem_uploads(out, *gems)
    a_post("gems").should have_been_made.times(gems.size)
    gems.each do |g|
      out.should =~ /Uploading #{g}.*done/
    end
  end
end