require 'spec_helper'

class Test
  include PbActor

  attr_accessor :foo, :bar

  def initialize foo
    self.foo = foo
  end

  def hello something
    "hello #{something}"
  end
end

describe PbActor do
  before :each do
    @test = Test.new 'foo'
  end

  after :each do
    @test.terminate! if @test && @test.alive?
  end

  it 'initialize should work' do
    wait_until do
      @test.foo
    end
    @test.foo.should == 'foo'
  end

  it 'pass block should raise error' do
    expect do
      @test.hello('world') do
        'nothing'
      end
    end.to raise_error(ArgumentError)
  end

  it 'sync call should work' do
    @test.hello('actor').should == 'hello actor'
  end

  it 'async call should work' do
    @test.async.bar= 'bar'
    wait_until do
      @test.bar
    end
    @test.bar.should == 'bar'
  end

  it 'future call should work' do
    params = [1, 2, 3]
    futures = params.map{ |n| @test.future.hello n }
    futures.each{ |f| f.should.is_a? PbActor::Future }
    futures.map(&:value).should == params.map{ |n| "hello #{n}"}
  end

  it 'terminate should work' do
    @test.alive?.should == true
    @test.terminate
    @test.alive?.should == false
    expect{@test.foo}.to raise_error(PbActor::DeadActorError)
    expect{@test.terminate}.to raise_error(PbActor::DeadActorError)
  end

  it 'terminate! should work' do
    @test.alive?.should == true
    @test.terminate!
    wait_until do
      @test.alive? == false
    end
    @test.alive?.should == false
    expect{@test.terminate!}.to raise_error(PbActor::DeadActorError)
  end

  it 'to_s should correct' do
    @test.to_s.should == 'PbActor::Proxy(Test)'
    @test.async.to_s.should == 'PbActor::AsyncProxy(Test)'
    @test.future.to_s.should == 'PbActor::FutureProxy(Test)'
  end
end
