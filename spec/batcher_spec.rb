require "spec_helper"

RSpec.describe Batcher do
  let(:queue) { Queue.new }
  let(:logger) { double(:logger) }
  let(:on_error) { Proc.new { puts "logs error" } }

  let :action do
    -> (batch) { queue << batch }
  end

  before do
    allow(Batcher).to receive(:logger).and_return(logger)
    allow(logger).to receive(:info)
    allow(logger).to receive(:error)
    allow(logger).to receive(:debug)
  end

  it "call actions with batch of defined sizes" do
    batcher = described_class.new("test", 10, 1, on_error, &action)
    20.times.each { |i| batcher << i  }
    batcher.shutdown!

    batches = consume(queue)
    expect(batches).to eq [Array(0..9), Array(10..19)]
  end

  it "calls actions respecting max size when ticking" do
    batcher = described_class.new("test", 10, 0.05, on_error, &action)

    10.times.each do |i|
      batcher << i
      sleep(0.1) if i == 7
    end

    batcher.shutdown!
    batches = consume(queue)
    expect(batches).to eq([Array(0..7), Array(8..9)])
  end

  it "handles errors properly" do
    already_failed = false
    batcher = described_class.new("test", 5, 1, on_error,) do |batch|
      will_fail, already_failed = !already_failed, true
      raise "some error" if will_fail
      queue << batch
    end

    10.times.each { |i| batcher << i }
    batcher.shutdown!

    batches = consume(queue)
    expect(batches).to eq([Array(5..9)])
  end

  it "calls action with remaining items when shutting down" do
    batcher = described_class.new("test", 10, 10, on_error, &action)
    batcher << 1
    batcher.shutdown!

    batches = consume(queue)
    expect(batches).to eq([[1]])
  end

  it "fails to add items after shutdown" do
    batcher = described_class.new("test", 10, 10, on_error, &action)
    batcher.shutdown!
    expect { batcher << 1 }.to raise_error(Batcher::StoppedError)
  end

  private

  def consume(queue)
    consumed = []
    consumed << queue.pop(true) while queue.size > 0
    consumed
  end
end
