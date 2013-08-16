require 'spec_helper'

describe PbActor::Message do
  before :each do
    @r, @w = IO.pipe
  end

  after :each do
    [@r, @w].each do |io|
      io.close unless io.closed?
    end
  end

  it 'send should broken when read io close' do
    @r.close
    expect{PbActor::Message.send "message", @w}.to raise_error(PbActor::DeadActorError)
  end

  it 'recv should broken when write io close' do
    @w.close
    expect{PbActor::Message.recv @r}.to raise_error(PbActor::DeadActorError)
  end
end
